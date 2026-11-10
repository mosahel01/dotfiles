#!/usr/bin/env bun
/**
 * Shared substrate: shell parsing, path resolution, and target collection.
 *
 * Both the security guard and the snapshot engine depend on this. It exists as a
 * separate module so that (a) the security core stays small enough to audit in
 * one read and (b) a bug in the git/backup machinery cannot take down boundary
 * enforcement. This module is deliberately side-effect free: no git calls, no
 * filesystem writes, no decisions.
 *
 * Not a plugin. Import it; do not load it.
 */

// -------------------------------------------------------------------- imports

import { lstatSync } from "node:fs"
import { homedir } from "node:os"
import { basename, join, normalize, sep } from "node:path"

// Re-exported so consumers get one import surface for path helpers.
export { basename }

// ------------------------------------------------------------------ constants

// Only OpenCode's own config is protected. ~/.codex is deliberately absent: this
// guard belongs to OpenCode, and protecting a directory we no longer own would
// block snapshots of files that are still perfectly restorable.
export const PROTECTED = [join(homedir(), ".config", "opencode")]

export const WRAPPERS = new Set(["env", "command", "nohup", "time", "xargs"])
export const REDIRECT_OPS = new Set([">", ">>", ">|", "&>", "&>>"])
export const DUP_OPS = new Set([">&", "<&", "<<", "<<"])
export const PUNCT_CHARS = "();<>|&"

// Flags that mean "create a branch", which never discards working-tree content.
export const BRANCH_CREATING = ["-b", "-B", "-c", "-C", "--orphan", "--track", "--detach"]

// Git subcommands that can discard work with no path operands.
export const DIRTY_GIT_OPS = new Set(["clean", "reset", "checkout", "restore", "stash", "switch"])

export class Denied extends Error {}

// ------------------------------------------------------------------ protection

export function isProtected(absPath: string): boolean {
  return PROTECTED.some((p) => absPath === p || absPath.startsWith(p + sep))
}

/** Expand ~ and $VAR the way a shell would, then make the result absolute. */
export function resolvePathFrom(p: string, cwd: string): string {
  let s = p
  // A naive replace of `~` leaves a trailing slash, and normalize keeps it, so
  // `~` would never compare equal to homedir().
  if (s === "~") s = homedir()
  else if (s.startsWith("~/")) s = join(homedir(), s.slice(2))
  s = s.replace(/\$\{HOME\}(?=\/|$)/g, homedir()).replace(/\$HOME(?=\/|$)/g, homedir())
  if (s === p) {
    s = p.replace(/^\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?/, (_m, name: string) => process.env[name] ?? _m)
  }
  return s.startsWith("/") ? normalize(s) : join(cwd, s)
}

/** True if the token names /, ~, $HOME, a glob of either, or a protected root. */
export function isRootTarget(tok: string | undefined): boolean {
  if (!tok) return false
  const raw = tok.trim().replace(/^['"]|['"]$/g, "")
  if (!raw) return false

  let norm: string
  try {
    // normalize("/") is "/", and stripping the trailing slash leaves "", so ""
    // stands in for the filesystem root here.
    norm = normalize(resolvePathFrom(raw, homedir())).replace(/\/+$/, "")
  } catch {
    return true // unparseable target: refuse rather than guess
  }

  // A glob of the root or of home is the same delete spelled differently:
  // `rm -rf /*`, `rm -rf *`, `rm -rf ~/*`, `rm -rf $HOME/*`. `~` and `$HOME` are
  // already absolute by the time they get here, so home is recognised by its
  // resolved value -- an earlier `startsWith("~/")` test could never fire.
  // Matching the wildcard as the FIRST path component is what leaves
  // `~/Documents/*` to the boundary check, where a named subdirectory belongs.
  if (norm.startsWith("/*") || norm.startsWith(join(homedir(), "*"))) return true
  return new Set(["", "/", homedir(), ...PROTECTED]).has(norm)
}

export const lexists = (p: string) => {
  try {
    lstatSync(p)
    return true
  } catch {
    return false
  }
}

export const isDirectory = (p: string) => {
  try {
    return lstatSync(p).isDirectory()
  } catch {
    return false
  }
}

// -------------------------------------------------------------------- parsing

/**
 * Split a command line into segments. Quote-aware: a `;` or `|` inside quotes is
 * data, and an interpreter one-liner is almost entirely quoted, so a naive split
 * shreds `python3 -c "open(\'a.txt\',\'w\')"` into pieces that no longer contain
 * the write they describe.
 */
export function segments(command: string): string[] {
  const out: string[] = []
  let cur: string[] = []
  let quote: string | null = null
  let escaped = false
  let depth = 0
  let i = 0

  const flush = () => {
    const seg = cur.join("").trim()
    if (seg && !["&&", "||", "|", ";", "(", ")"].includes(seg)) out.push(seg)
    cur = []
  }

  while (i < command.length) {
    const ch = command[i]
    if (escaped) {
      cur.push(ch)
      escaped = false
      i++
      continue
    }
    if (ch === "\\" && quote !== "'") {
      cur.push(ch)
      escaped = true
      i++
      continue
    }
    if (quote) {
      cur.push(ch)
      if (ch === quote) quote = null
      i++
      continue
    }
    if (ch === '"' || ch === "'") {
      quote = ch
      cur.push(ch)
      i++
      continue
    }
    if (ch === "(") {
      depth++
      cur.push(ch)
      i++
      continue
    }
    if (ch === ")") {
      depth = Math.max(0, depth - 1)
      cur.push(ch)
      i++
      continue
    }

    // Separator must be matched AT the cursor. JS RegExp.exec searches the whole
    // string while python's re.match anchors at 0, so exec here would grab a
    // separator from anywhere and skip the characters before it.
    const rest = command.slice(i)
    let token: string | null = null
    if (rest.startsWith("||")) token = "||"
    else if (rest.startsWith("&&")) token = "&&"
    else if (rest.startsWith("|")) token = "|"
    else if (rest.startsWith(";")) token = ";"
    else if (rest.startsWith("\n")) token = "\n"
    else if (rest.startsWith("(")) token = "("
    else if (rest.startsWith(")")) token = ")"

    if (token && !(ch === "|" && rest.startsWith("||"))) {
      if (depth === 0 || token === "(" || token === ")") {
        if (depth === 0) {
          flush()
          i += token.length
          continue
        }
      }
    }
    cur.push(ch)
    i++
  }
  flush()
  return out
}

/** POSIX-ish tokenisation, the equivalent of python's shlex.split(posix=True). */
export function tokenize(seg: string): string[] {
  const out: string[] = []
  let cur = ""
  let has = false
  let quote: string | null = null
  let i = 0
  while (i < seg.length) {
    const ch = seg[i]
    if (ch === "\\" && quote !== "'") {
      cur += seg[i + 1] ?? ""
      has = true
      i += 2
      continue
    }
    if (quote) {
      if (ch === quote) quote = null
      else cur += ch
      i++
      continue
    }
    if (ch === '"' || ch === "'") {
      quote = ch
      has = true
      i++
      continue
    }
    if (/\s/.test(ch)) {
      if (has) out.push(cur)
      cur = ""
      has = false
      i++
      continue
    }
    cur += ch
    has = true
    i++
  }
  if (has) out.push(cur)
  return out
}

/** Like tokenize, but shell punctuation becomes its own token so `a>b` splits. */
export function tokenizePunct(seg: string): string[] {
  const out: string[] = []
  let cur = ""
  const push = () => {
    if (cur) out.push(cur)
    cur = ""
  }
  for (const ch of seg) {
    if (/\s/.test(ch)) {
      push()
    } else if (PUNCT_CHARS.includes(ch)) {
      push()
      out.push(ch)
    } else {
      cur += ch
    }
  }
  push()
  return out
}

export function commandIndex(toks: string[]): number {
  let i = 0
  while (i < toks.length && (WRAPPERS.has(toks[i]) || /^[A-Za-z_][A-Za-z0-9_]*=/.test(toks[i]))) i++
  return i
}

// ------------------------------------------------------------------- targeting

export type Target = { raw: string; cwd: string }

export type MutatingPredicate = (args: string[]) => boolean

export const MUTATING_COMMANDS: Record<string, MutatingPredicate | null> = {
  tee: null,
  truncate: null,
  shred: null,
  install: null,
  dd: null,
  sed: (a) => a.some((f) => f === "--in-place" || /^-i/.test(f)),
  perl: (a) => a.some((f) => f.startsWith("-i") && f !== "-in"),
  ruby: (a) => a.includes("-i"),
}

// The leading \\? lets a quote survive a level of shell escaping: inside
// `python3 -c "open(\'a.txt\',\'w\')"` the inner quotes are backslash-escaped,
// and a pattern that only accepts a bare quote silently matches nothing.
const Q = String.raw`(?:\\*['"])?([^\s'"\\]+)(?:\\*['"])?`

// The global flag is required: matchAll throws without it, and a throw here
// would fail the whole guard open, silently snapshotting nothing.
export const INLINE_WRITES: [RegExp, number][] = ([
  [String.raw`\bopen\(\s*f?${Q}\s*,\s*f?['"\\]*[rwa]`, 1],
  [String.raw`\.write_(?:text|bytes)\(\s*f?${Q}`, 1],
  [String.raw`\bPath\(\s*f?${Q}\s*\)\s*\.\s*write_`, 1],
  [String.raw`\bshutil\.(?:copy2?|copytree|move|rmtree)\(\s*f?${Q}`, 1],
  [String.raw`\bos\.(?:remove|unlink|rmdir|removedirs)\(\s*f?${Q}`, 1],
  [String.raw`\bos\.(?:replace|rename)\(\s*f?${Q}`, 1],
  [String.raw`\b(?:truncate|chmod|chown)\(\s*f?${Q}`, 1],
] as [string, number][]).map(([src, group]) => [new RegExp(src, "g"), group] as [RegExp, number])

/** Existing files a `>`-style redirect in this segment would overwrite. */
export function collectRedirects(seg: string, workdir: string): string[] {
  const toks = tokenizePunct(seg)
  const out: string[] = []
  for (let i = 0; i < toks.length; i++) {
    if (!REDIRECT_OPS.has(toks[i]) || i + 1 >= toks.length) continue
    const tgt = toks[i + 1]
    if (DUP_OPS.has(tgt) || /^\d+$/.test(tgt) || tgt === "-" || tgt.startsWith("/dev/")) continue
    if (lexists(resolvePathFrom(tgt, workdir))) out.push(tgt)
  }
  return out
}

export function collectInlineWrites(seg: string, workdir: string): string[] {
  const out: string[] = []
  for (const [pattern, group] of INLINE_WRITES) {
    for (const m of seg.matchAll(pattern)) {
      const tgt = m[group]
      if (tgt && lexists(resolvePathFrom(tgt, workdir))) out.push(tgt)
    }
  }
  return out
}

export function collectMutatingArgs(name: string, args: string[], workdir: string): string[] {
  if (!(name in MUTATING_COMMANDS)) return []
  const pred = MUTATING_COMMANDS[name]
  if (pred && !pred(args)) return []
  let paths: string[]
  if (name === "dd") {
    const of = args.find((a) => a.startsWith("of="))
    paths = of ? [of.slice(3)] : []
  } else {
    paths = args.filter((a) => !a.startsWith("-"))
  }
  return paths.filter((t) => t && lexists(resolvePathFrom(t, workdir)))
}