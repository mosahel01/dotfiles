#!/usr/bin/env bun
/**
 * Boundary tests: which shell commands name a path outside the boundary.
 *
 * Pure logic -- calls pathsOutsideBoundary() directly. For the wiring (does the
 * permission hook actually register and escalate?) see hook-wiring.test.ts.
 *
 *   bun run tests/boundary.test.ts
 */
import { mkdirSync, mkdtempSync, rmSync, symlinkSync, writeFileSync } from "node:fs"
import { join } from "node:path"
import { homedir } from "node:os"

import {
  boundaryRoots,
  extractPaths,
  outsideVerdict,
  pathsOutsideBoundary,
  sensitiveReads,
} from "../guard.ts"

// Fixtures are anchored under the home directory, not tmpdir(). boundaryRoots()
// now treats $TMPDIR as a free root, so a workspace created there would make
// every "outside the workspace" assertion inside the boundary by definition --
// including the symlink-escape cases, whose targets live beside the workspace.
// Home sits outside /tmp and $TMPDIR, which is the property these tests
// need. Both are dot-prefixed and rmSync'd before exit.
const WS = mkdtempSync(join(homedir(), ".guard-ws-"))
const roots = boundaryRoots(WS)

let pass = 0
let fail = 0
function t(cmd: string, wantOutside: boolean, cwd = WS) {
  let got: string[]
  try {
    got = pathsOutsideBoundary(cmd, cwd, roots)
  } catch (e) {
    console.log(`  THROW  ${cmd}\n        ${e}`)
    fail++
    return
  }
  const ok = (got.length > 0) === wantOutside
  if (ok) pass++
  else fail++
  console.log(
    `  ${ok ? "ok  " : "FAIL"}  ${cmd.padEnd(46)} ${got.length ? "outside: " + got[0] : "inside"}`,
  )
}

console.log("\nINSIDE the boundary (must not ask)")
t("cat package.json", false)
t("ls -la", false)
t("git status", false)
t("bun test", false)
t("cargo build --release", false)
t("terraform plan", false)
t("sqlite3 data.db .tables", false)
t("dd if=/dev/zero of=out.bin", false)
t("kubectl get pods", false)
t("kubectl apply -f k8s/deploy.yaml", false)
t("cat src/index.ts", false)
t("./scripts/build.sh", false)
t("echo hi > /tmp/scratch.txt", false)
t("cat /tmp/scratch.txt", false) // the scratch root, canonicalised by boundaryRoots()
// Quoted prose that mentions a command is not a command. This is the case that
// used to be an ask and would now be a hard deny without the start anchor.
t(`git commit -m "fix rm -rf / handling"`, false)
t(`git commit -m "revert rm -fr ~ change"`, false)
t(`git commit -m "rm old handler"`, false)
t(`echo "see docs: rm -rf / is blocked"`, false)
// Glued redirection, and the fd-duplication and sink forms that must not look
// like paths: `2>&1` reduces to digits, `/dev/null` is a sink.
t("bun test 2>&1", false)
t("echo hi >/dev/null 2>&1", false)
if (process.env.TMPDIR) {
  t(`echo hi > ${process.env.TMPDIR}probe.txt`, false) // $TMPDIR, cleared at startup
  t(`cat ${process.env.TMPDIR.replace(/\/+$/, "")}/probe.txt`, false)
}

console.log("\nOUTSIDE the boundary (must be caught)")
t("cat /etc/hosts", true)
// A quoted message that starts with a command and names an absolute path is
// still re-scanned. That errs toward refusing, which is the safe direction.
t(`git commit -m "rm /etc/foo"`, true)
t("cat /etc", true)
t("echo x > /usr/local/foo", true)
// The operator glued to its target. This is the case the plugin exists for:
// OpenCode's inference cannot see a redirect target at all, and tokenize keeps
// `>/etc/hosts` and `foo>/etc/hosts` whole, so an operand-only scan misses both.
t("echo x >/usr/local/foo", true)
t("echo pwn >>/etc/hosts", true)
t("cat pkg.json >~/.zshrc.new", true)
t("date>/etc/hosts", true) // glued to the command name, not an operand
t("sh -c 'echo pwn >/etc/hosts'", true)
t("cat ~/.zshrc", true)
t("rm -rf ~/Documents", true)
t("cat ../sibling-project/file.txt", true)
t("cd /etc && cat hosts", true)
t("cp package.json /Users/$(whoami)/other/x.json", true)
t("sh -c 'cat /etc/hosts'", true) // quoted payload must be re-scanned
// The payload of a shell `-c` is a command, so it is re-scanned whatever verb it
// names. The verb heuristic below this line only looks at quoted operands of
// other commands, and `head`/`xxd`/`install` are not on its list.
t("sh -c 'head -5 /etc/shadow'", true)
t("bash -c 'xxd /etc/passwd'", true)
t("sh -c 'install -m 600 /tmp/x /etc/y'", true)
t("eval 'cat /etc/hosts'", true)
// ...but a shell payload with nothing outside it stays quiet.
t("sh -c 'make build'", false)
t("bash -c 'bun test'", false)

console.log("\nSYMLINK escapes (a link inside the boundary must not launder a path outside)")
// The link lives INSIDE the workspace so its own path passes the boundary, and
// its target lives in a separate temp dir that is outside every root -- which is
// the whole point. The target must exist, or realpath() fails and the check
// falls back to the lexical path and proves nothing.
const lab = join(WS, "lab")
const outsideTarget = mkdtempSync(join(homedir(), ".guard-outside-"))
mkdirSync(join(lab, "inside"), { recursive: true })
writeFileSync(join(lab, "inside", "ok.txt"), "fine\n")
writeFileSync(join(outsideTarget, "secret.txt"), "sensitive\n")
symlinkSync(outsideTarget, join(lab, "escape-dir"))
symlinkSync(join(outsideTarget, "secret.txt"), join(lab, "escape-file"))
t("cat inside/ok.txt", false, lab)
t("cat escape-dir/secret.txt", true, lab)
t("cat escape-file", true, lab)

console.log("\nCHILD PROCESSES AND previously-unseen commands")
t("bash -c 'cat /etc/hosts'", true)
t("zsh -lc 'cat /etc/passwd'", true)
t("make install", false)
t("docker build .", false)
t("tmux new-session", false)

console.log("\nSENSITIVE: .env asks anywhere, workspace included")
function v(cmd: string, wantHit: boolean, cwd = WS) {
  let got: string[]
  try {
    got = sensitiveReads(cmd, cwd)
  } catch (e) {
    console.log(`  THROW  ${cmd}\n        ${e}`)
    fail++
    return
  }
  const ok = (got.length > 0) === wantHit
  if (ok) pass++
  else fail++
  console.log(`  ${ok ? "ok  " : "FAIL"}  ${cmd.padEnd(46)} ${got.length ? "-> " + got[0] : "clean"}`)
}

// Explicit operands, inside and outside the workspace alike.
v("cat .env", true)
v("cat ./.env", true)
v("cat ~/projects/app/.env", true)
v("head -5 .env", true)
v("sed -i '' s/a/b/ .env", true)
v("wc -l .env", true)
// Any .env suffix holds secrets; the suffix names the environment, not a scope.
v("cat .env.local", true)
v("cat .env.production", true)
v("cat .env.development.local", true)
v("cat .envrc", true)
// Placeholder files are exempt by convention.
v("cat .env.example", false)
v("cat .env.sample", false)
v("cat .env.template", false)
v("cat .env.dist", false)
v("cat .env.defaults", false)
v("cat .env.example.local", false)
// Neighbours must not trip it.
v("cat env", false)
v("cat .environment", false)
v("cat README.md", false)
// Only a leading placeholder suffix is exempt. An unrecognized qualifier first
// (`bak`) means the file is treated as real, which is the fail-safe direction.
v("cat .env.bak.example", true)
// The documented gap: an implicit scan names no path to judge.
v("rg SECRET", false)

console.log("\nOUTSIDE: denied, reader or not")
function o(cmd: string, want: "allow" | "deny", cwd = WS) {
  let got: string
  try {
    got = outsideVerdict(pathsOutsideBoundary(cmd, cwd, roots)).effect
  } catch (e) {
    console.log(`  THROW  ${cmd}\n        ${e}`)
    fail++
    return
  }
  const ok = got === want
  if (ok) pass++
  else fail++
  console.log(`  ${ok ? "ok  " : "FAIL"}  ${cmd.padEnd(46)} ${got}`)
}

// Config owns the boundary now, so the answer no longer depends on the verb.
for (const cmd of [
  "cat /etc/hosts",
  "head -20 /etc/passwd",
  "cat $HOME/.zshrc",
  "cat '~/.ssh/id_rsa'",
  "rm -rf /tmp/..",
  "rg TODO ~/Documents/dev-projects",
  "jq . ~/notes.json",
  "diff ~/a.txt ~/b.txt",
  "sed -n 1,5p /etc/hosts",
  "cat ~/.ssh/id_rsa",
  "cat ~/.aws/credentials",
  "cat ~/.ssh/id_rsa.pub",
  "cat ~/.ssh/config",
  "rg KEY ~",
  "rg --hidden KEY ~",
  "grep -r KEY ~",
  "ls ~/.ssh",
  "wc -l ~/.bashrc",
  "cp /etc/hosts ~/x",
  "rm -rf ~/Documents",
  "sed -i '' s/a/b/ ~/notes.md",
  "awk -f ./p.awk ~/d/f.txt",
  "cat ~/a | tee ~/b",
]) o(cmd, "deny")

// Inside still passes.
o("cat package.json", "allow")
o("echo hi > /tmp/scratch.txt", "allow")
o("rm -rf /tmp/x", "allow")

console.log(`\n${pass} passed, ${fail} failed`)

console.log("\nextractPaths spot-checks:")
for (const c of ["cat /etc/hosts", "cd /etc && cat hosts", "rm -rf ~/x", "bun test"]) {
  console.log(`  ${c.padEnd(26)} -> ${JSON.stringify(extractPaths(c, WS))}`)
}

rmSync(WS, { recursive: true, force: true })
rmSync(outsideTarget, { recursive: true, force: true })
process.exit(fail ? 1 : 0)