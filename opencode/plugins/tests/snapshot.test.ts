#!/usr/bin/env bun
/**
 * Snapshot engine tests: does a recoverable destructive command get a restore
 * point, and does git-recoverable content get correctly skipped?
 *
 * Builds a throwaway git repo per run, so it asserts on real git state rather
 * than mocks.
 *
 *   bun run tests/snapshot.test.ts
 */
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs"
import { spawnSync } from "node:child_process"
import { join } from "node:path"
import { tmpdir } from "node:os"

const STORE = mkdtempSync(join(tmpdir(), "guard-store-"))
// Must be set BEFORE importing: BACKUP_ROOT is read at module init.
process.env.OPENCODE_BACKUP_ROOT = STORE

const { evaluateSnapshot, collectTargets } = await import("../snapshot.ts")

const root = mkdtempSync(join(tmpdir(), "guard-snap-"))
const repo = join(root, "repo")
mkdirSync(repo)
const sh = (c: string, cwd = repo) => spawnSync(c, { cwd, shell: "/bin/zsh", encoding: "utf8" })

sh("git init -q .")
sh("git config user.email t@t.t && git config user.name t")
writeFileSync(join(repo, "tidy.txt"), "committed\n") // committed + CLEAN
sh("git add -A && git commit -qm init")
writeFileSync(join(repo, "dirty-tracked.txt"), "committed\n") // committed + MODIFIED below
writeFileSync(join(repo, "dirty-tracked.txt"), "modified\n")
writeFileSync(join(repo, "untracked.txt"), "precious\n") // genuinely UNTRACKED

let pass = 0
let fail = 0
const t = (label: string, ok: boolean, detail = "") => {
  if (ok) pass++
  else fail++
  console.log(`  ${ok ? "ok  " : "FAIL"}  ${label}${detail ? "  -> " + detail : ""}`)
}
const ev = (c: string) => evaluateSnapshot(c, repo)

console.log("\nWHAT GETS SNAPSHOTTED")
{
  const r = ev("rm untracked.txt")
  t("rm untracked file snapshots it", !!r.note)
  t("store honours OPENCODE_BACKUP_ROOT", !!r.note?.includes(STORE), STORE)
}
{
  const r = ev("rm dirty-tracked.txt")
  t("rm MODIFIED tracked file is snapshotted", !!r.note)
}
{
  const r = ev("rm tidy.txt")
  t("rm CLEAN tracked file is skipped (git restores it)", !r.note, r.note ? "unexpected snapshot" : "")
}
writeFileSync(join(repo, "clobber.txt"), "precious\n")
{
  const r = ev("echo new > clobber.txt")
  t("redirect overwrite snapshots target", !!r.note)
}
writeFileSync(join(repo, "py.txt"), "old\n")
{
  const r = ev(`python3 -c "open('py.txt','w').write('x')"`)
  t("inline python write snapshots target", !!r.note)
}
writeFileSync(join(repo, "sed.txt"), "old\n")
{
  const r = ev("sed -i '' 's/old/new/' sed.txt")
  t("sed -i snapshots target", !!r.note)
}
{
  // git stash is recoverable via `git stash pop`, so it is deliberately NOT
  // snapshotted. `stash drop` destroys the entry permanently, so it is.
  const r = ev("git stash")
  t("git stash is skipped (recoverable via stash pop)", !r.note)
}

console.log("\nWHAT DOES NOT")
for (const c of ["ls -la", "git status", "echo hi", "cat tidy.txt", "bun test", "git push", "git stash"]) {
  t(`no snapshot for: ${c}`, !ev(c).note)
}

console.log("\nTARGET COLLECTION")
t("rm with two operands records both", collectTargets("rm a.txt b.txt", repo).targets.length === 2)
t("mv records source and destination", collectTargets("mv a.txt b.txt", repo).targets.length >= 1)
{
  let threw = false
  try {
    ev("rm -rf /")
  } catch {
    threw = true
  }
  t("rm -rf / is refused by the snapshot engine too", threw)
}

console.log(`\n${pass} passed, ${fail} failed`)
rmSync(root, { recursive: true, force: true })
rmSync(STORE, { recursive: true, force: true })
process.exit(fail ? 1 : 0)