#!/usr/bin/env bun
/**
 * Hook wiring tests: does the plugin actually REGISTER its hooks, and does the
 * permission hook escalate the right decisions?
 *
 * Drives setup() with a mock ctx and invokes the hooks by hand. This is the only
 * way to observe an `ask` in isolation -- an `opencode run --auto` session
 * auto-approves asks while still enforcing denies, so the command runs either
 * way and looks identical from outside.
 *
 *   bun run tests/hook-wiring.test.ts
 */
import { mkdtempSync, rmSync } from "node:fs"
import { join } from "node:path"
import { tmpdir } from "node:os"

const WS = mkdtempSync(join(tmpdir(), "guard-hook-"))

let permHook: ((e: any) => Promise<void>) | null = null
const toolHooks: Record<string, ((e: any) => Promise<void> | void)[]> = {}

const ctx: any = {
  location: { directory: WS, project: { canonical: WS } },
  permission: {
    hook: async (name: string, fn: any) => {
      if (name === "evaluate") permHook = fn
    },
  },
  tool: {
    hook: async (name: string, fn: any) => {
      ;(toolHooks[name] ??= []).push(fn)
    },
  },
}

const mod = await import("../guard.ts")
await mod.default.setup(ctx)

let pass = 0
let fail = 0
const t = (label: string, ok: boolean, detail = "") => {
  if (ok) pass++
  else fail++
  console.log(`  ${ok ? "ok  " : "FAIL"}  ${label}${detail ? "  -> " + detail : ""}`)
}

async function evalCmd(command: string, effect: "allow" | "ask" = "allow") {
  const event: any = { sessionID: "ses_test", action: "shell", resources: [command], effect }
  await permHook!(event)
  return event as { effect: string; message?: string }
}

console.log("\nREGISTRATION")
t('permission.hook("evaluate") registered', permHook !== null)
t('tool.hook("execute.before") registered', (toolHooks["execute.before"] ?? []).length > 0)

console.log("\nBOUNDARY: writes and deletes outside the workspace -> deny")
for (const c of [
  "echo x > /usr/local/foo",
  "cd /etc && cat hosts",
  "sed -i '' s/a/b/ ~/.zshrc",
  "rg pattern /etc | head",
  "cp ~/.zshrc ~/.zshrc.bak",
]) {
  const e = await evalCmd(c)
  t(c, e.effect === "deny", `effect=${e.effect}`)
}

console.log("\nOUTSIDE READS: denied like everything outside")
for (const c of ["cat /etc/hosts", "cat ~/.zshrc", "rg pattern ~/.config", "jq . /etc/hosts"]) {
  const e = await evalCmd(c)
  t(c, e.effect === "deny", `effect=${e.effect}`)
}

console.log("\nFLOOR: refused, not prompted")
for (const c of [
  "cat ~/.ssh/id_rsa",
  "cat ~/.aws/credentials",
  "rg -uu KEY ~",
  "grep -r KEY ~",
]) {
  const e = await evalCmd(c)
  t(c, e.effect === "deny", `effect=${e.effect}`)
}

console.log("\nFLOOR: public halves are still outside")
for (const c of ["cat ~/.ssh/id_rsa.pub", "cat ~/.ssh/config"]) {
  const e = await evalCmd(c)
  t(c, e.effect === "deny", `effect=${e.effect}`)
}

console.log("\nREAD TOOL: the floor applies here too")
{
  const before = toolHooks["execute.before"][0]
  const denied = async (filePath: string) => {
    try {
      await before({ tool: "read", input: { filePath } })
      return false
    } catch {
      return true
    }
  }
  t("read ~/.ssh/id_rsa is denied", await denied("~/.ssh/id_rsa"))
  t("read ~/.aws/credentials is denied", await denied("~/.aws/credentials"))
  t("read ~/.ssh/id_rsa.pub is not denied", !(await denied("~/.ssh/id_rsa.pub")))
  t("read ~/notes.md is not denied", !(await denied("~/notes.md")))
  t("read inside the workspace is not denied", !(await denied(join(WS, "a.txt"))))
}

console.log("\nOUTSIDE: metadata verbs are denied too")
for (const c of ["ls ~/.ssh", "wc -l /etc/passwd", "du -sh ~/.cache", "shasum ~/.bashrc"]) {
  const e = await evalCmd(c)
  t(c, e.effect === "deny", `effect=${e.effect}`)
}

console.log("\nINSIDE: unchanged, no friction")
for (const c of [
  "ls -la",
  "bun test",
  "cargo build --release",
  "cat package.json",
  "echo hi > /tmp/scratch.txt",
  "cat /tmp/scratch.txt",
  "rm -rf /tmp/scratch",
]) {
  const e = await evalCmd(c)
  t(c, e.effect === "allow", `effect=${e.effect}`)
}

console.log("\nDENY: never runs (mistakes, not decisions)")
for (const c of [
  "rm -rf /",
  "rm -fr /",
  "rm -r -f /",
  "rm -Rf /",
  "rm -rf -- /",
  "rm -rf ~",
  "rm -rf $HOME",
  "rm -rf ${HOME}",
  // A glob of the root or of home is the same delete spelled differently.
  "rm -rf /*",
  "rm -rf *",
  "rm -rf ~/*",
  "rm -rf $HOME/*",
  "rm -rf ${HOME}/*",
  "rm -rf ~/**",
  // Normalisation is the rule: the same root with a trailing slash, `.`, `..`,
  // doubled slashes, or quotes resolves to the same target.
  "rm -rf ~//",
  "rm -rf ~/.",
  "rm -rf ~/Documents/..",
  "rm -rf ${HOME}/",
  "rm -rf $HOME/",
  "rm -rf $HOME/.",
  "rm -rf //",
  "rm -rf /./",
  "rm -rf /../",
  "rm -rf /private/..",
  "rm -rf /tmp/..",
  `rm -rf "$HOME"`,
  `rm -rf "~/"`,
  `rm -rf '/'`,
  // Flag spelling and order are not part of the rule: the operand is examined as
  // an operand, so `-fr`, `-r -f`, `-f -r`, long forms, `--`, and flags placed
  // after the target all deny the same way `-rf` does.
  "rm -fr ~/*",
  "rm -r -f ~/*",
  "rm -f -r ~/*",
  "rm -f -r /",
  "rm -Rf $HOME/*",
  "rm --recursive --force ~/*",
  "rm -rf -- ~/*",
  "rm ~/* -rf",
  "chmod -R 777 /tmp/x",
  "git push --force",
  "git push --delete origin main",
  "sudo rm -rf /",
  "mkfs.ext4 /dev/disk0",
  ":(){ :|:& };:",
  // A destructive payload one level down. The deny is only as strong as its
  // most obvious spelling unless the wrapper is unwrapped first.
  "sh -c 'rm -rf /'",
  "bash -c 'rm -rf /'",
  `sh -c "sudo rm -rf /"`,
  "eval 'rm -rf /'",
  "$(rm -rf /)",
  "`rm -rf /`",
]) {
  const e = await evalCmd(c)
  t(c, e.effect === "deny", `effect=${e.effect}`)
}

console.log("\nQUOTING IS NOT RUNNING: mentioning the command must not deny it")
for (const c of [
  `git commit -m "fix rm -rf / handling"`,
  `git commit -m "revert rm -fr ~ change"`,
  `echo "see docs: rm -rf / is blocked"`,
]) {
  const e = await evalCmd(c)
  t(c, e.effect !== "deny", `effect=${e.effect}`)
}

console.log("\nA `>` inside an argument is not a redirect target")
for (const c of [
  `git commit -m "fix gzip > files note"`,
  "printf 'a>b'",
]) {
  const e = await evalCmd(c)
  t(c, e.effect === "allow", `effect=${e.effect}`)
}

console.log("\nHOME: a named subdirectory is denied by the boundary now")
for (const c of ["rm -rf ~/Documents", "rm -rf ~/Documents/*"]) {
  const e = await evalCmd(c)
  t(c, e.effect === "deny", `effect=${e.effect}`)
}

console.log("\nINSIDE: relative targets are not root targets")
for (const c of ["rm -rf ./build", "rm -rf src", "rm -rf node_modules"]) {
  const e = await evalCmd(c)
  t(c, e.effect === "allow", `effect=${e.effect}`)
}

console.log("\nGIT FORCE PUSH: flags and refspecs do not hide it")
for (const c of [
  "git push --force origin main",
  "git push -f",
  "git -c k=v push --force",
  "git -C /elsewhere push --force",
  "git --no-pager push --force origin main",
  "git push origin +main",
  "git -c k=v push --delete origin main",
]) {
  const e = await evalCmd(c)
  t(c, e.effect === "deny", `effect=${e.effect}`)
}

console.log("\nGIT FORCE PUSH: the safe forms still run")
for (const c of [
  "git push",
  "git push origin main",
  "git push --force-with-lease origin main",
  "git push --force-with-lease=origin/main origin main",
  "git push --follow-tags origin main",
  "git commit -m \"push --force\"",
  "git commit -m \"always use push --force carefully\"",
]) {
  const e = await evalCmd(c)
  t(c, e.effect === "allow", `effect=${e.effect}`)
}

console.log("\nPROMPT: irreversible but intentional -> ask, not deny")
for (const c of [
  "npm publish",
  "kubectl apply -f k8s/deploy.yaml",
  "terraform apply",
  "terraform destroy",
  "cargo publish",
  "aws s3 rm s3://bucket/x",
  "vercel deploy",
  "gcloud functions deploy x",
]) {
  const e = await evalCmd(c)
  t(c, e.effect === "ask", `effect=${e.effect}`)
}

console.log("\nA prompt carries a reason")
{
  const e = await evalCmd("npm publish")
  t("npm publish has a message", !!e.message && e.message.length > 10)
}

console.log("\nAN EXISTING ask is not rewritten (no double prompt)")
{
  const e = await evalCmd("cat /etc/hosts", "ask")
  t("already-ask stays ask", e.effect === "ask")
}

console.log("\nNON-SHELL actions are ignored")
{
  const event: any = { sessionID: "s", action: "read", resources: ["/etc/hosts"], effect: "allow" }
  await permHook!(event)
  t("read /etc/hosts untouched by the shell hook", event.effect === "allow")
}

console.log(`\n${pass} passed, ${fail} failed`)
rmSync(WS, { recursive: true, force: true })
process.exit(fail ? 1 : 0)