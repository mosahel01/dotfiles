#!/usr/bin/env bun
/**
 * Test runner. `bun run plugins/tests/run.ts`
 *
 * Each suite is a separate process so that module-level state (the git coverage
 * cache, BACKUP_ROOT read at import time) cannot leak between them.
 */
import { spawnSync } from "node:child_process"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

const here = dirname(fileURLToPath(import.meta.url))

const suites = ["boundary.test.ts", "hook-wiring.test.ts", "policies.test.ts", "snapshot.test.ts"]

let failed = 0
for (const suite of suites) {
  console.log(`\n${"=".repeat(60)}\n${suite}\n${"=".repeat(60)}`)
  const r = spawnSync(process.execPath, [join(here, suite)], { stdio: "inherit" })
  if (r.status !== 0) failed++
}

console.log(`\n${"=".repeat(60)}`)
console.log(failed ? `${failed} suite(s) FAILED` : `all ${suites.length} suites passed`)
process.exit(failed ? 1 : 0)