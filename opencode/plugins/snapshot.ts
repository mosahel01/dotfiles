#!/usr/bin/env bun
/**
 * Snapshot engine: before a recoverable destructive command runs, copy what it is
 * about to destroy into a restore store, so a mistake inside the boundary is
 * reversible.
 *
 * Separate from guard.ts on purpose. This runs on the tool hook, after the
 * permission decision, and its failure mode is "nothing got copied" rather than
 * "a destructive command ran" -- so a bug here cannot take boundary enforcement
 * down with it. It shares only the parsing substrate and the git helpers.
 *
 * Fails open: any internal error returns no note, because a guardrail bug must
 * never lock the user out of the session.
 */

import {
  copyFileSync,
  cpSync,
  existsSync,
  lstatSync,
  mkdirSync,
  readdirSync,
  realpathSync,
  statSync,
  writeFileSync,
} from "node:fs"
import { basename, dirname, join, normalize, sep } from "node:path"

import {
  Denied,
  BRANCH_CREATING,
  commandIndex,
  collectInlineWrites,
  collectMutatingArgs,
  collectRedirects,
  DIRTY_GIT_OPS,
  isDirectory,
  isProtected,
  isRootTarget,
  lexists,
  MUTATING_COMMANDS,
  resolvePathFrom,
  segments,
  tokenize,
} from "./lib/parse.ts"
import type { Target } from "./lib/parse.ts"
import { git, gitDirtyFiles, isRecoverableFromGit, resetCoverage } from "./lib/git.ts"

// ------------------------------------------------------------------ settings

const envStr = (key: string, fallback: string) =>
  process.env[`OPENCODE_${key}`] ?? process.env[`CODEX_${key}`] ?? fallback

const envNum = (key: string, fallback: number) => {
  const v = envStr(key, "")
  if (v === "") return fallback
  const n = Number(v)
  return Number.isFinite(n) ? n : fallback
}

// The store lives under the system temp dir on purpose. It is ephemeral by
// design, which removes the need for pruning, size caps, and any "store is full"
// warning -- the problem was solved by choosing a location, not by managing the
// volume.
// The path is /tmp's real form rather than $TMPDIR: on macOS /tmp links to
// /private/tmp, so realpath() gives that spelling; on Linux it stays /tmp. Either
// way it is a root the guard already allows, so a snapshot needs no approval.
// Consequences worth knowing: macOS clears /tmp by access time at roughly three
// days, not only at reboot, so retention is days rather than weeks. And /tmp is
// world-readable (1777), so snapshot contents are readable by other local users.
const BACKUP_ROOT = envStr(
  "BACKUP_ROOT",
  join(
    (() => {
      try {
        return realpathSync("/tmp")
      } catch {
        return "/tmp"
      }
    })(),
    "opencode-backups",
  ),
)
const MAX_COPY_BYTES = envNum("BACKUP_MAX_FILE", 50 * 1024 * 1024)
const MAX_SNAPSHOT_BYTES = envNum("BACKUP_MAX_SNAPSHOT", 200 * 1024 * 1024)
const MAX_FILES_PER_SNAPSHOT = envNum("BACKUP_MAX_FILES", 2000)

const SKIP_DIRS = new Set([".git", "node_modules", ".next", "dist", ".astro", ".turbo", "target", ".venv"])

const PROTECTED_EXCEPT = [BACKUP_ROOT]

// ------------------------------------------------------------------ protection

function isProtectedSnap(absPath: string): boolean {
  for (const exc of PROTECTED_EXCEPT) {
    if (absPath === exc || absPath.startsWith(exc + sep)) return false
  }
  return isProtected(absPath)
}

// ------------------------------------------------------------------- targeting

/** Everything about to be destroyed, plus labels for the note. */
export function collectTargets(command: string, cwd: string): { targets: Target[]; labels: string[] } {
  const targets: Target[] = []
  const labels: string[] = []
  let workdir = cwd

  for (const seg of segments(command)) {
    const toks = tokenize(seg)
    if (!toks.length) continue
    const i = commandIndex(toks)
    if (i >= toks.length) continue
    const name = basename(toks[i])
    const args = toks.slice(i + 1)

    if (name === "cd") {
      if (args.length) workdir = resolvePathFrom(args[0], workdir)
      continue
    }

    if (name === "mv") {
      // A move destroys the source's location and may overwrite the
      // destination, so both sides are worth a restore point. A trailing
      // directory is just a container (`mv file /tmp/`), and snapshotting
      // /tmp would be absurd, so it is skipped.
      const rest = args.filter((a) => !a.startsWith("-"))
      const keep = rest.slice(0, -1)
      const last = rest[rest.length - 1]
      if (last && !isDirectory(resolvePathFrom(last, workdir))) keep.push(last)
      targets.push(...keep.map((t) => ({ raw: t, cwd: workdir })))
      labels.push("mv")
      continue
    }

    if (["rm", "trash", "rimraf"].includes(name)) {
      const flags = args.filter((a) => a.startsWith("-"))
      const rest = args.filter((a) => !a.startsWith("-"))
      if (name !== "rm") {
        targets.push(...rest.map((t) => ({ raw: t, cwd: workdir })))
        labels.push(name)
        continue
      }
      if (flags.some((f) => /[rR]/.test(f))) {
        for (const t of rest) {
          if (isRootTarget(t)) {
            throw new Denied(
              `recursive delete of a root or home path is blocked (${t}). Use \`trash\` on a specific subdirectory instead.`,
            )
          }
        }
        targets.push(...rest.map((t) => ({ raw: t, cwd: workdir })))
      } else {
        // Every target must be checked and recorded. Taking only the first
        // meant `rm a.txt b.txt` destroyed both files but snapshotted one.
        for (const t of rest) {
          if (isRootTarget(t)) throw new Denied(`forced delete of a root or home path is blocked (${t}).`)
        }
        targets.push(...rest.map((t) => ({ raw: t, cwd: workdir })))
      }
      labels.push("rm")
      continue
    }

    if (name in MUTATING_COMMANDS) {
      targets.push(...collectMutatingArgs(name, args, workdir).map((t) => ({ raw: t, cwd: workdir })))
      labels.push(`${name} (in-place write)`)
      continue
    }

    if (name === "find" && args.some((a) => /^-\w*delete/.test(a))) {
      const roots = args.filter((a) => !a.startsWith("-"))
      targets.push({ raw: roots[0] ?? ".", cwd: workdir })
      labels.push("find -delete")
      continue
    }

    if (name === "git" && args.length) {
      const sub = basename(args[0])
      const subargs = args.slice(1)
      if (!DIRTY_GIT_OPS.has(sub)) continue
      if (sub === "reset" && !subargs.includes("--hard")) continue
      if (sub === "stash" && !subargs.includes("drop")) continue
      if (sub === "checkout" || sub === "restore" || sub === "switch") {
        const dashdash = subargs.indexOf("--")
        const pathArgs = (dashdash >= 0 ? subargs.slice(dashdash + 1) : subargs).filter((a) => !a.startsWith("-"))

        if (dashdash >= 0) {
          if (!pathArgs.length) continue
          targets.push(...pathArgs.map((p) => ({ raw: p, cwd: workdir })))
          labels.push(`git ${sub}`)
          continue
        }

        // git restore has no safe form: every variant discards working-tree
        // content, and a bare `git restore` discards all of it.
        if (sub === "restore") {
          if (pathArgs.length) targets.push(...pathArgs.map((p) => ({ raw: p, cwd: workdir })))
          else targets.push({ raw: "__GIT_DIRTY__", cwd: workdir })
          labels.push("git restore")
          continue
        }

        // checkout/switch without `--` are branch operations and are safe --
        // git refuses when a switch would drop local changes. The same syntax
        // with a path (`git checkout .`, `git checkout file.txt`) discards
        // work, and only git can tell those apart.
        if (!pathArgs.length) continue
        if (BRANCH_CREATING.some((f) => subargs.includes(f))) continue
        if (pathArgs.every((a) => git(["rev-parse", "--verify", "--quiet", a], workdir) !== null)) continue

        targets.push({ raw: "__GIT_DIRTY__", cwd: workdir })
        labels.push(`git ${sub}`)
        continue
      }
      targets.push({ raw: "__GIT_DIRTY__", cwd: workdir })
      labels.push(`git ${sub}`)
      continue
    }

    // Name-independent writes: a redirect or an interpreter one-liner can clobber
    // a file no matter which binary does it.
    const writes = [...collectRedirects(seg, workdir), ...collectInlineWrites(seg, workdir)]
    if (writes.length) {
      targets.push(...writes.map((t) => ({ raw: t, cwd: workdir })))
      labels.push("redirect/inline write")
    }
  }

  return { targets, labels }
}

// ------------------------------------------------------------------- backups

function copyInto(pairs: Target[], dest: string) {
  const copied: string[] = []
  const skipped: string[] = []
  let total = 0
  let recoverable = 0

  for (const { raw, cwd } of pairs) {
    const src = resolvePathFrom(raw, cwd)
    if (!lexists(src)) {
      skipped.push(`${raw} (missing)`)
      continue
    }
    // Protected paths are NOT skipped here. Protection means "a destructive
    // command may not destroy this" -- enforced by the deny in evaluate(). It
    // never meant "never make a restore point", which left the agent's own
    // config as the one file with no backup.
    if (!lstatSync(src).isDirectory() && isRecoverableFromGit(src, cwd)) {
      skipped.push(`${raw} (tracked and clean; git can restore it)`)
      continue
    }
    try {
      const st = lstatSync(src)
      if (st.isSymbolicLink()) {
        skipped.push(`${raw} (symlink)`)
        continue
      }
      if (st.isDirectory()) {
        if (SKIP_DIRS.has(basename(src.replace(/\/+$/, "")))) {
          skipped.push(`${raw} (generated directory, nothing to preserve)`)
          continue
        }
        const target = join(dest, `dir__${basename(src.replace(/\/+$/, ""))}`)
        let count = 0
        let budgetHit = false
        let fileCap = false
        const walk = (dir: string) => {
          if (count >= MAX_FILES_PER_SNAPSHOT || total >= MAX_SNAPSHOT_BYTES) {
            budgetHit = true
            return
          }
          for (const entry of readdirSync(dir, { withFileTypes: true })) {
            if (entry.isDirectory()) {
              if (!SKIP_DIRS.has(entry.name)) walk(join(dir, entry.name))
              continue
            }
            if (!entry.isFile()) continue
            if (count >= MAX_FILES_PER_SNAPSHOT) {
              fileCap = true
              return
            }
            const sp = join(dir, entry.name)
            if (isRecoverableFromGit(sp, cwd)) {
              recoverable++
              continue
            }
            let size = 0
            try {
              size = statSync(sp).size
            } catch {
              continue
            }
            if (size > MAX_COPY_BYTES || total + size > MAX_SNAPSHOT_BYTES) {
              budgetHit = true
              continue
            }
            const t = join(target, sp.slice(src.length + 1))
            mkdirSync(dirname(t), { recursive: true })
            copyFileSync(sp, t)
            total += size
            count++
          }
        }
        walk(src)
        // Hitting the file cap is also a partial snapshot, and the note has to
        // say so or a truncated restore looks like a complete one.
        budgetHit = budgetHit || count >= MAX_FILES_PER_SNAPSHOT
        let note = `${raw}/ (${count} files)`
        if (recoverable) note += `, ${recoverable} recoverable from git`
        if (budgetHit) note += " PARTIAL"
        copied.push(note)
        if (fileCap || budgetHit) skipped.push(`${raw}/ hit the per-snapshot cap; restore from git instead`)
      } else {
        const size = st.size
        if (size > MAX_COPY_BYTES) {
          skipped.push(`${raw} (${Math.floor(size / 1048576)}MB, over the per-file limit)`)
          continue
        }
        if (total + size > MAX_SNAPSHOT_BYTES) {
          skipped.push(`${raw} (${Math.floor(size / 1048576)}MB, would exceed the ${Math.floor(MAX_SNAPSHOT_BYTES / 1048576)}MB snapshot budget)`)
          continue
        }
        copyFileSync(src, join(dest, basename(src)))
        total += size
        copied.push(raw)
      }
    } catch (e) {
      skipped.push(`${raw} (${e instanceof Error ? e.constructor.name : "Error"})`)
    }
  }
  return { copied, skipped, total }
}

function timestamp(): string {
  const d = new Date()
  const p = (n: number) => String(n).padStart(2, "0")
  return `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`
}

export function snapshot(pairs: Target[], label: string, cwd: string): string {
  resetCoverage()
  const stamp = timestamp()
  const slug = label.replace(/[^a-zA-Z0-9]+/g, "-").slice(0, 40).replace(/^-+|-+$/g, "") || "op"
  let dest = join(BACKUP_ROOT, `${stamp}-${slug}`)
  let n = 1
  while (existsSync(dest)) dest = join(BACKUP_ROOT, `${stamp}-${slug}-${++n}`)
  mkdirSync(dest, { recursive: true })

  const root = git(["rev-parse", "--show-toplevel"], cwd)
  if (root) {
    const head = (git(["rev-parse", "HEAD"], cwd) ?? "").trim()
    const branch = (git(["rev-parse", "--abbrev-ref", "HEAD"], cwd) ?? "").trim()
    const status = git(["status", "--porcelain"], cwd) ?? ""
    writeFileSync(
      join(dest, "GIT_STATE.txt"),
      `repo: ${root.trim()}\nbranch: ${branch}\nhead: ${head}\n\nstatus --porcelain at backup time:\n${status}\n\nUntracked/modified files are copied into this snapshot.\n`,
    )
  }

  const { copied, skipped, total } = copyInto(pairs, dest)
  writeFileSync(
    join(dest, "MANIFEST.txt"),
    `created: ${stamp}\nlabel: ${label}\ncwd: ${cwd}\ncopied: ${copied.join(", ") || "-"}\nskipped: ${skipped.join("; ") || "-"}\nbytes: ${total}\n`,
  )

  const note = [
    `Pre-run backup: ${dest}`,
    `trigger: ${label}`,
    `saved: ${copied.join(", ") || "nothing"}`,
  ]
  if (skipped.length) note.push(`not saved: ${skipped.join("; ")}`)
  if (existsSync(join(dest, "GIT_STATE.txt"))) note.push("GIT_STATE.txt records branch/HEAD/status for restore.")
  note.push("If this command was wrong, restore from the snapshot before continuing.")
  note.push(`Snapshots are ephemeral (${BACKUP_ROOT}); this one may not survive a few days.`)
  return note.join("\n")
}

// -------------------------------------------------------------------- decision

export type SnapshotDecision = { deny?: string; note?: string }

/** The snapshot half of the decision. Never throws except `Denied`. */
export function evaluateSnapshot(command: string, cwd: string): SnapshotDecision {
  if (!command.trim()) return {}

  const { targets, labels } = collectTargets(command, cwd)
  const needsDirty = targets.some((t) => t.raw === "__GIT_DIRTY__")
  if (!targets.length && !needsDirty) return {}

  for (const t of targets) {
    if (t.raw === "__GIT_DIRTY__") continue
    if (isProtectedSnap(normalize(resolvePathFrom(t.raw, t.cwd))))
      return { deny: `Refusing to run a destructive command against the agent's own config (${t.raw}). Back it up and edit it with the editor instead.` }
  }

  let concrete = targets.filter((t) => t.raw !== "__GIT_DIRTY__")
  if (needsDirty) {
    const dirtyCwd = targets.find((t) => t.raw === "__GIT_DIRTY__")!.cwd
    const { files, root } = gitDirtyFiles(dirtyCwd)
    concrete = concrete.concat(files.map((f) => ({ raw: f, cwd: root })))
  }
  if (!concrete.length) return {}

  // Drop what git can restore on its own BEFORE creating anything, so a delete
  // of only recoverable files leaves no empty snapshot behind.
  const recoverable: string[] = []
  const worthCopying = concrete.filter((t) => {
    if (isRecoverableFromGit(resolvePathFrom(t.raw, t.cwd), t.cwd)) {
      recoverable.push(t.raw)
      return false
    }
    return true
  })
  if (!worthCopying.length) return {}

  let note = snapshot(worthCopying, [...new Set(labels)].sort().join(","), cwd)
  if (recoverable.length) {
    note += `\nnot copied, git can restore it (tracked and clean): ${recoverable.join(", ")}`
  }
  return { note }
}

// ------------------------------------------------------------------ file write

/**
 * Copy a file or directory aside next to itself: <path>.bak-<stamp>[-label].
 *
 * Unlike snapshot(), this keeps the copy beside the original instead of in the
 * pruned store, so it survives eviction. That is the whole point: a restore
 * point you have to wonder about is not a restore point. Never overwrites an
 * existing backup; same-second collisions get -2, -3.
 *
 * Returns the new path, or null if the target does not exist.
 */
export function bakFile(target: string, label = ""): string | null {
  if (!existsSync(target)) return null

  const slug = label
    .replace(/[^a-zA-Z0-9]+/g, "-")
    .slice(0, 40)
    .replace(/^-+|-+$/g, "")

  const base_ = `${target}.bak-${timestamp()}${slug ? `-${slug}` : ""}`
  let dest = base_
  let n = 1
  while (existsSync(dest)) dest = `${base_}-${++n}`

  cpSync(target, dest, { recursive: true })
  return dest
}

/**
 * Snapshot a file before an editor-style tool overwrites it.
 *
 * Pure additions have nothing to lose and are skipped.
 */
export function guardFileWrite(files: string[], cwd: string, label = "edit"): SnapshotDecision {
  const paths = files.map((f) => f.trim()).filter(Boolean)
  if (!paths.length) return {}
  // An editor targets one known file, so a side-by-side .bak beats a store
  // snapshot: it sits next to the file, it cannot be pruned away, and it does
  // not consume the rotating budget.
  //
  // No protected-path refusal: an edit is intentional and reversible, and
  // refusing left the agent's own config as the one file with no restore point.
  // Destructive commands still deny via the guard plugin.
  const saved: string[] = []
  const recoverable: string[] = []
  for (const p of paths) {
    const abs = resolvePathFrom(p, cwd)
    if (!existsSync(abs)) continue
    // Only untracked or modified files need a copy; a tracked file with no
    // uncommitted changes is already recoverable with git checkout.
    if (isRecoverableFromGit(abs, cwd)) {
      recoverable.push(p)
      continue
    }
    const dest = bakFile(abs, label)
    if (dest) saved.push(`  ${p} -> ${dest}`)
  }
  if (!saved.length && !recoverable.length) return {}
  const note = [`Side-by-side backup before ${label}:`, ...saved, "If the change was wrong, move the .bak file back."]
  if (recoverable.length) {
    note.push(`Skipped, already in git with no uncommitted changes: ${recoverable.join(", ")}`)
  }
  return { note: note.join("\n") }
}

// --------------------------------------------------------------------- plugin

type ToolEvent = {
  tool: string
  id: string
  input?: { command?: string; workdir?: string; path?: string; filePath?: string; file_path?: string }
  result?: any
}

// This was a denylist ("anything that is not shell/webfetch/websearch"), which
// classified `read` as a writer: every read of an existing file left a .bak
// beside it and showed up as untracked in the repo. Failing toward writing is
// the wrong direction for an unknown tool, so this is an allowlist plus a
// shape check. Read tools carry a path and range, never content.
const WRITE_TOOLS = new Set(["edit", "write", "patch", "apply_patch", "multiedit"])
const WRITE_INPUT_KEYS = ["content", "newString", "new_string", "oldString", "old_string", "patch", "edits"]

export function isFileWriter(tool: string, input: unknown): boolean {
  if (WRITE_TOOLS.has(tool)) return true
  const i = (input ?? {}) as Record<string, unknown>
  return WRITE_INPUT_KEYS.some((k) => typeof i[k] === "string" && i[k] !== "")
}

const targetPath = (input: ToolEvent["input"]) => input?.path ?? input?.filePath ?? input?.file_path

export default {
  id: "snapshot",
  async setup(ctx: any) {
    const pending = new Map<string, string>()

    // Same resolver guard.ts uses: the Location directory, canonicalised.
    // `process.cwd()` alone is whatever directory the server was launched
    // from, so a relative target in a shell command resolved against the home
    // dir and was reported "missing" instead of copied. Resolved per event
    // rather than captured at setup so a worktree or directory change is
    // respected instead of silently using a stale root.
    const workspace = (): string => {
      const dir = ctx?.location?.directory ?? ctx?.location?.project?.canonical ?? process.cwd()
      try {
        return realpathSync(dir)
      } catch {
        return dir
      }
    }

    await ctx.tool.hook("execute.before", async (event: ToolEvent) => {
      try {
        if (!event?.tool) return
        const cwd = event.input?.workdir ?? workspace()
        let r: SnapshotDecision = {}

        if (event.tool === "shell") {
          const command = event.input?.command
          if (!command) return
          r = evaluateSnapshot(command, cwd)
        } else if (isFileWriter(event.tool, event.input)) {
          const path = targetPath(event.input)
          if (!path) return
          r = guardFileWrite([path], cwd, event.tool)
        } else {
          return
        }

        if (r.note) pending.set(event.id, r.note)
        if (r.deny) throw new Denied(r.deny)
      } catch (e) {
        if (e instanceof Denied) throw e
        /* fail open */
      }
    })

    await ctx.tool.hook("execute.after", async (event: ToolEvent) => {
      try {
        const note = pending.get(event.id)
        if (!note) return
        pending.delete(event.id)

        // `content` is what the model reads; `output` is a legacy copy, so
        // writing there succeeds and shows nothing.
        const content = event.result?.content
        if (Array.isArray(content)) {
          event.result = { ...event.result, content: [{ type: "text", text: note }, ...content] }
          return
        }
        const output = event.result?.output
        if (output && typeof output.output === "string") {
          event.result = { ...event.result, output: { ...output, output: `${note}\n\n${output.output}` } }
        }
      } catch {
        /* fail open */
      }
    })
  },
}