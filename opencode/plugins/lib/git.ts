#!/usr/bin/env bun
/**
 * Git introspection: which files can git hand back on its own, and which files
 * are at risk of being discarded.
 *
 * Shared by the snapshot engine (to decide what is worth copying) and by the
 * `__GIT_DIRTY__` handling for commands that discard work with no path operands.
 * Separate from parse.ts because it shells out to git on every call and carries
 * a memo cache -- neither belongs in a parsing module.
 */

import { spawnSync } from "node:child_process"
import { realpathSync } from "node:fs"
import { relative } from "node:path"

export function git(args: string[], cwd: string): string | null {
  try {
    const r = spawnSync("git", args, { cwd, encoding: "utf8", timeout: 15_000 })
    return r.status === 0 && typeof r.stdout === "string" ? r.stdout : null
  } catch {
    return null
  }
}

/** Every file git considers modified or untracked: the real exposure. */
export function gitDirtyFiles(cwd: string): { files: string[]; root: string } {
  const out = git(["status", "--porcelain", "-z", "--untracked-files=all"], cwd)
  if (!out) return { files: [], root: cwd }
  const files: string[] = []
  for (const p of out.split("\0")) {
    if (p.length < 4) continue
    const code = p.slice(0, 2).trim()
    const path = p.slice(3)
    if (code === "D") continue // already deleted; nothing left to save
    if (["node_modules/", "/.next/", "/dist/", "/.astro/"].some((s) => path.includes(s))) continue
    files.push(path)
  }
  const root = git(["rev-parse", "--show-toplevel"], cwd)?.trim() || cwd
  return { files, root }
}

/**
 * Which files git can hand back on its own.
 *
 * A tracked file with no uncommitted changes is fully recoverable with
 * `git checkout -- <path>`, so copying it into the store buys nothing and just
 * churns the budget. Untracked or modified files are the real exposure, and
 * those are exactly what gets copied.
 *
 * The set is fetched once per repo per snapshot rather than per file, so a
 * 2000-file directory costs two git calls, not 4000.
 */
export type GitCoverage = { root: string; tracked: Set<string>; dirty: Set<string> }
const coverageCache = new Map<string, GitCoverage | null>()

export function gitCoverage(cwd: string): GitCoverage | null {
  if (coverageCache.has(cwd)) return coverageCache.get(cwd)!

  let result: GitCoverage | null = null
  const root = git(["rev-parse", "--show-toplevel"], cwd)
  if (root) {
    const listed = git(["ls-files", "-z"], cwd)
    // `--ignored=matching` is deliberately NOT used: an ignored file is
    // untracked and unrecoverable, so it must not be mistaken for clean.
    const status = git(["status", "--porcelain", "-z", "--untracked-files=all"], cwd)
    if (listed !== null && status !== null) {
      const tracked = new Set(listed.split("\0").filter(Boolean))
      const dirty = new Set<string>()
      for (const entry of status.split("\0")) {
        if (entry.length < 4) continue
        const code = entry.slice(0, 2).trim()
        const path = entry.slice(3)
        // A staged add is not yet recoverable, so treat it as dirty.
        if (code !== "D") dirty.add(path)
      }
      result = { root: root.trim(), tracked, dirty }
    }
  }
  coverageCache.set(cwd, result)
  return result
}

/** True when git alone can restore this file to its current contents. */
export function isRecoverableFromGit(absPath: string, cwd: string): boolean {
  const cov = gitCoverage(cwd)
  if (!cov) return false
  // Both sides must be canonicalised. On macOS /var is a symlink to /private/var,
  // so git reports a realpath while the target is still the symlinked form, and
  // relative() would put every file "..outside" the repo.
  const real = (p: string) => {
    try {
      return realpathSync(p)
    } catch {
      return p
    }
  }
  const rel = relative(real(cov.root), real(absPath))
  if (!rel || rel.startsWith("..") || rel.startsWith("/")) return false
  return cov.tracked.has(rel) && !cov.dirty.has(rel)
}

/** Drop the memoised coverage. Called per snapshot so long-lived servers
 *  do not act on a stale index. */
export function resetCoverage() {
  coverageCache.clear()
}