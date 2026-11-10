#!/usr/bin/env bun
/**
 * Config tests: the policy patterns in opencode.jsonc, including the ones that
 * only make sense once the wildcard rules are expanded the way OpenCode does.
 *
 * This pins the patterns, not OpenCode's matcher. The matcher here follows the
 * documented rules: whole value, `*` matches zero or more (including `/`), `?`
 * matches one, and the last matching statement wins.
 *
 *   bun run tests/policies.test.ts
 */
import { readFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

const here = dirname(fileURLToPath(import.meta.url))
const source = readFileSync(join(here, "..", "..", "opencode.jsonc"), "utf8")

/** Drop // and block comments, leaving quoted strings untouched. */
function stripComments(src: string): string {
  let out = ""
  let str = false
  let esc = false
  for (let i = 0; i < src.length; i++) {
    const c = src[i]
    if (str) {
      out += c
      if (esc) esc = false
      else if (c === "\\") esc = true
      else if (c === '"') str = false
      continue
    }
    if (c === '"') {
      str = true
      out += c
      continue
    }
    if (c === "/" && src[i + 1] === "/") {
      while (i < src.length && src[i] !== "\n") i++
      continue
    }
    if (c === "/" && src[i + 1] === "*") {
      i += 2
      while (i < src.length && !(src[i] === "*" && src[i + 1] === "/")) i++
      i++
      continue
    }
    out += c
  }
  return out
}

/** Remove trailing commas, leaving quoted strings untouched. */
function stripTrailingCommas(src: string): string {
  let out = ""
  let str = false
  let esc = false
  for (let i = 0; i < src.length; i++) {
    const c = src[i]
    if (str) {
      out += c
      if (esc) esc = false
      else if (c === "\\") esc = true
      else if (c === '"') str = false
      continue
    }
    if (c === '"') {
      str = true
      out += c
      continue
    }
    if (c === ",") {
      let j = i + 1
      while (j < src.length && /\s/.test(src[j])) j++
      if (src[j] === "}" || src[j] === "]") continue
    }
    out += c
  }
  return out
}

const config = JSON.parse(stripTrailingCommas(stripComments(source)))

let pass = 0
let fail = 0
function t(label: string, ok: boolean, detail = "") {
  if (ok) pass++
  else fail++
  console.log(`  ${ok ? "ok  " : "FAIL"}  ${label}${detail ? "  -> " + detail : ""}`)
}

const expand = (s: string) =>
  s.replace(/\{env:([A-Za-z_][A-Za-z0-9_]*)\}/g, (_m, name: string) => process.env[name] ?? "")

/** Whole-value wildcard matching. */
function matches(pattern: string, value: string): boolean {
  const body = expand(pattern)
    .replace(/[.+^${}()|[\]\\]/g, "\\$&")
    .replace(/\*/g, ".*")
    .replace(/\?/g, ".")
  return new RegExp(`^${body}$`).test(value)
}

/** Docs: a shell pattern ending in " *" also matches the command without args. */
function glob(pattern: string, value: string): boolean {
  if (matches(pattern, value)) return true
  return pattern.endsWith(" *") && matches(pattern.slice(0, -2), value)
}

/** Last matching statement wins. No match is "none", not "allow". */
function effect(action: string, resource: string): "allow" | "deny" | "none" {
  let result: "allow" | "deny" | "none" = "none"
  for (const p of config.policies ?? []) {
    if (p.action !== action) continue
    if (glob(p.resource, resource)) result = p.effect
  }
  return result
}

/** Same, for permissions (external_directory lives here, not in policies). */
function perm(action: string, resource: string): "allow" | "deny" | "none" {
  let result: "allow" | "deny" | "none" = "none"
  for (const p of config.permissions ?? []) {
    if (p.action !== action) continue
    if (glob(p.resource, resource)) result = p.effect
  }
  return result
}

console.log("\nSTRUCTURE")
{
  const top = [...source.matchAll(/^  "([^"]+)":/gm)].map((m) => m[1])
  const dupes = top.filter((k, i) => top.indexOf(k) !== i)
  t("no duplicate top-level keys", dupes.length === 0, dupes.join(", "))
  t(
    "every statement has action/resource/effect",
    [...(config.policies ?? []), ...(config.permissions ?? [])].every(
      (p: any) =>
        typeof p.action === "string" &&
        typeof p.resource === "string" &&
        (p.effect === "allow" || p.effect === "deny" || p.effect === "ask"),
    ),
  )
}

console.log("\nRM POLICIES: the wildcard is glued to the path")
const rm = (cmd: string) => effect("tool.use", `shell:${cmd}`)
for (const cmd of [
  "rm -rf ~",
  "rm -rf ~/",
  "rm -rf ~/Documents",
  "rm -rf ~/**",
  "rm -rf /",
  "rm -rf / x",
]) {
  const got = rm(cmd)
  t(cmd, got === "deny", got)
}
t("rm -rf /tmp/x is scratch", rm("rm -rf /tmp/x") !== "deny", rm("rm -rf /tmp/x"))

// Flag order and a glob of the root are guard.ts's job, not a prefix pattern's.
// So is /private: this box has no such tree, and anything there is outside the
// workspace, which the plugin already refuses.
for (const cmd of ["rm -fr /", "rm -r -f /", "rm --recursive --force /", "rm -rf /*"]) {
  const got = rm(cmd)
  t(`${cmd} is guard.ts's job`, got !== "deny", got)
}
t("rm -rf /usr is not caught by a prefix", rm("rm -rf /usr") !== "deny", rm("rm -rf /usr"))

console.log("\nENV POLICIES: deny first, example last")
for (const [res, want] of [
  ["read:.env", "deny"],
  ["read:.env.local", "deny"],
  ["read:.env.production", "deny"],
  ["read:.envrc", "deny"],
  ["read:.env.example", "allow"],
  ["read:.env.local.example", "allow"],
  ["read:.env.example.bak", "deny"],
  ["edit:.env", "deny"],
  ["edit:.env.local.example", "allow"],
] as const) {
  const got = effect("tool.use", res)
  t(res, got === want, got)
}

console.log("\nEXTERNAL DIRECTORY: deny first, scratch after")
const home = process.env.HOME ?? ""
for (const [p, want] of [
  ["/etc/hosts", "deny"],
  ["/tmp/x", "allow"],
  [`${home}/.cache/opencode/x`, "allow"],
  [`${home}/.local/share/opencode/x`, "allow"],
  [`${home}/.config/opencode/x`, "deny"],
] as const) {
  const got = perm("external_directory", p)
  t(p, got === want, got)
}
// The literal is account-independent, so it does not read TMPDIR at all.
for (const p of [
  "/private/var/folders/zz/0000000000000000000000000000/T/x",
  "/private/var/folders/7g/gtzfm4h176qbb_4442bkhlvc0000gn/T/x",
]) {
  const got = perm("external_directory", p)
  t(p, got === "allow", got)
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail ? 1 : 0)
