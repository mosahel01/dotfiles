#!/usr/bin/env bun
/**
 * Security core: boundary enforcement and hard denies.
 *
 * Two jobs:
 *
 *   1. Boundary. opencode.jsonc owns the decision: `external_directory` is
 *      `deny`, so anything the built-in scanner places outside the workspace is
 *      refused before a hook runs. That scanner catches a `cd` target and the
 *      tool workdir but not file arguments or redirect targets, so this plugin
 *      re-scans every shell command and applies the same deny to the paths it
 *      names. One policy, two enforcement points.
 *   2. Deny. Irreversibly destructive commands are denied outright, and
 *      irreversible-but-intentional ones (publish/deploy) ask first. None of it
 *      asks the model to behave; every check is deterministic.
 *
 * Division of labour with opencode.jsonc, which is deliberate and not
 * redundant:
 *
 *   - Config holds the boundary (`external_directory: deny`) and the coarse
 *     `rm -rf / *` family. A configured deny is final: the permission hook is
 *     never invoked for one, so those fire before this plugin loads.
 *   - This plugin holds everything a command prefix cannot see. Root-target
 *     deletes are the reason: `rm -fr /`, `rm -r -f /`, `rm -Rf /`, `rm -rf -- /`
 *     and `rm -rf $HOME` are all denied by isRootTarget(), and none of them
 *     match a config pattern. The parser splits flags from operands and tests
 *     the flag set, so order, case, and the `--` end-of-flags marker are handled
 *     structurally rather than by a regex on the flag string.
 *
 * Keep this file small and readable: it is the part that has to be correct, and
 * it should be auditable in one pass. The snapshot machinery lives in
 * snapshot.ts and shares only the parsing substrate in lib/parse.ts, so a bug
 * there cannot take boundary enforcement down with it.
 *
 * OPENCODE_* env vars are preferred; the original CODEX_* names still work.
 */

import { realpathSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, sep } from "node:path";

import {
  Denied,
  basename,
  commandIndex,
  isRootTarget,
  resolvePathFrom,
  segments,
  tokenize,
} from "./lib/parse.ts";

// ------------------------------------------------------------------- boundary

// A shell command touching a path outside these roots is denied.
//
// Scratch space: tmpdir() reads $TMPDIR and falls back to /tmp, so the one call
// covers Linux and macOS (where $TMPDIR is /var/folders/<2>/<hash>/T, per-account
// and per-device). It is cleared at startup, which is why it is free.
//
// /tmp stays listed by name because that is what commands actually spell. There
// is no /private/tmp entry: macOS links /tmp to /private/tmp, and boundaryRoots()
// realpaths the root, so the canonical form is already the one that gets compared.
const TMP_ROOT = tmpdir();

// OpenCode's own cache and data directories. Package downloads and session
// storage: an agent reads and greps these constantly, and none of it is
// enforcement code, so paying a prompt per lookup buys nothing.
//
// ~/.config/opencode is deliberately NOT here. It holds guard.ts and
// opencode.jsonc, and trusting it means an agent can rewrite the boundary and
// the permission rules that produced this list without asking. Keep it asking.
//
// XDG_CACHE_HOME and XDG_DATA_HOME are honoured when set, but macOS sets
// neither by default, so the literal ~/.cache and ~/.local/share spellings
// are what actually apply here.
const HOME = process.env.HOME?.replace(/\/+$/, "");
const AGENT_DATA_ROOTS = [
  process.env.XDG_CACHE_HOME,
  process.env.XDG_DATA_HOME,
  ...(HOME ? [`${HOME}/.cache/opencode`, `${HOME}/.local/share/opencode`] : []),
].filter((r): r is string => typeof r === "string" && r.length > 0);

const BOUNDARY_EXTRA_ROOTS = [TMP_ROOT, "/tmp", ...AGENT_DATA_ROOTS];

// -------------------------------------------------------------------- the floor

// Reads outside the workspace are denied by the boundary, with one extra floor:
// the trees that hold credentials. `deny`, not `ask`, because an ask is exactly
// what a prompt injection turns into a plausible-sounding approval request.
//
// This is a floor, not a completeness claim. No list of "files that can hold a
// secret" can be complete, so completeness is not what this is for. Each entry
// is a whole tree refused at the path level, so piping or re-encoding the bytes
// does not get around it. A tree nobody listed is still outside, so the boundary
// refuses it.
//
// The public half of a key pair, the files that hold public keys, and the SSH
// client config are not secrets. The floor exempts them, which matters when the
// Location is $HOME and the store is inside the boundary; from a project,
// external_directory refuses the whole store before this runs.
const FLOOR_DIRS = HOME
  ? [
      ".ssh",
      ".aws",
      ".gnupg",
      ".kube",
      ".docker",
      ".password-store",
      ".config/gh",
      ".config/gcloud",
      ".config/sops",
      ".local/share/keyrings",
      "Library/Keychains",
      "Library/Application Support/Google/Chrome",
      "Library/Application Support/Firefox",
    ].map((d) => safeRealpath(join(HOME, d)))
  : [];

const FLOOR_PUBLIC = /^(?:.*\.pub|config|known_hosts.*|authorized_keys)$/;

/** The credential store this path sits in, or undefined. Canonical both sides. */
export function floorReason(p: string): string | undefined {
  const real = safeRealpath(p);
  if (FLOOR_PUBLIC.test(basename(real))) return undefined;
  return FLOOR_DIRS.find((d) => real === d || real.startsWith(d + sep));
}

/** Roots that never need approval, canonicalised where possible. */
export function boundaryRoots(workspace: string): string[] {
  const roots = [workspace, ...BOUNDARY_EXTRA_ROOTS];
  const out: string[] = [];
  for (const r of roots) {
    if (!r) continue;
    // realpath collapses /tmp -> /private/tmp and any symlinked workspace, so
    // comparing canonical forms on both sides is what makes the check symlink
    // safe. Falling back to the raw path keeps a not-yet-created root usable.
    out.push(safeRealpath(r));
  }
  return [...new Set(out)];
}

function safeRealpath(p: string): string {
  try {
    return realpathSync(p);
  } catch {
    // A path that does not exist yet: canonicalise the deepest existing
    // ancestor and re-append the remainder, so /a/b/c with a missing /a still
    // resolves against the real /a rather than a symlinked spelling of it.
    let head = p;
    let tail = "";
    for (;;) {
      const parent = dirname(head);
      if (parent === head) return p;
      tail = head.slice(parent.length) + tail;
      head = parent;
      try {
        return join(realpathSync(head), tail);
      } catch {
        /* keep walking up */
      }
    }
  }
}

/** True when the canonical path is inside one of the roots. */
function isInsideBoundary(absPath: string, roots: string[]): boolean {
  let real: string;
  try {
    real = realpathSync(absPath);
  } catch {
    real = safeRealpath(absPath);
  }
  return roots.some((root) => real === root || real.startsWith(root + sep));
}

// Longest first, or `&>>` would split as `&>` + `>`. The dup forms are included
// so `2>&1` reduces to bare digits, which `add` then drops.
const REDIRECT_OP = /(&>>|&>|>>|<<|<>|>\||>&|>|<)/;
const OP_ONLY = /^[<>&|]+$/;

// Shells whose `-c` argument is a command, for innerCommands() below.
const SHELLS = new Set(["sh", "bash", "zsh", "dash", "ksh", "ash", "fish"]);

/**
 * Commands that this command hands to something which will execute them: a
 * shell's `-c` argument, whatever `eval` is given, and `$(…)`/backtick
 * substitution. One level only; callers recurse.
 *
 * A destructive command can hide one level down (`sh -c 'rm -rf /'`,
 * `$(rm -rf /)`) and the checks read the tokens of the command they are handed,
 * so they never see the payload unless it is pulled out first. Only the forms
 * that actually EXECUTE their argument are unwrapped -- otherwise `git commit -m
 * "fix rm -rf /"` would be mistaken for the commit it quotes, and a deny is far
 * too blunt to fire on a false positive.
 *
 * shortcut: a `$(…)` nested inside another substitution is not unwrapped (the
 * pattern stops at the first `)`), and neither is `python -c` or `node -e`.
 * Extend only if one of those shows up as a real evasion.
 */
function innerCommands(command: string): string[] {
  const out: string[] = [];
  for (const seg of segments(command)) {
    const toks = tokenize(seg);
    if (!toks.length) continue;
    const i = commandIndex(toks);
    if (i >= toks.length) continue;
    const name = basename(toks[i]);
    const args = toks.slice(i + 1);
    if (name === "eval") {
      if (args.length) out.push(args.join(" "));
      continue;
    }
    const c = SHELLS.has(name) ? args.indexOf("-c") : -1;
    if (c >= 0 && args[c + 1]) out.push(args[c + 1]);
  }
  for (const m of command.matchAll(/\$\(([^()]*)\)|`([^`]*)`/g)) {
    const inner = m[1] ?? m[2];
    if (inner) out.push(inner);
  }
  return out;
}

/**
 * Every path a command might touch, for the boundary check.
 *
 * Deliberately wider than the snapshot engine's collectTargets: that one only
 * cares about what is about to be DESTROYED, so `cat /etc/hosts` returns nothing
 * from it. The boundary answers a different question -- did this command reach
 * outside at all -- so it collects any operand that looks like a path, whether it
 * is read or written.
 *
 * Best effort by nature. This cannot see through a path assembled at runtime. It
 * is strictly more capable than OpenCode's own directory inference (which handles
 * `cd` and the tool workdir but not file arguments), not a replacement for
 * sandboxing.
 */
export function extractPaths(command: string, cwd: string): string[] {
  const out: string[] = [];

  // tokenize keeps a redirection glued to its target (`>out`, `foo>out`, `2>out`),
  // so the operator is split out here. Without this the target is never resolved
  // and `echo pwn >/etc/hosts` reaches the shell as an allow.
  const add = (raw: string | undefined) => {
    if (!raw) return;
    for (const t of raw.trim().split(REDIRECT_OP)) {
      // `/dev/null` is a sink, not a path: reading and writing it reveals and
      // destroys nothing, and `>/dev/null` is far too common to prompt on.
      if (!t || t === "-" || t === "/dev/null" || OP_ONLY.test(t) || /^\d+$/.test(t)) continue;
      // Skip option flags; a bare `-R` or `--recursive` is not a path. Long flags
      // that take a path as the next arg are handled by the caller-side heuristic
      // of just examining every operand, which is cheaper and errs toward asking.
      if (/^--?[A-Za-z]/.test(t) && !t.includes("/")) continue;
      out.push(t);
    }
  };

  // Whatever this command hands to something that will execute it is re-scanned
  // as a command in its own right, so `sh -c 'head -5 /etc/shadow'` cannot hide
  // behind a shell. The heuristic in the loop below answers a narrower question
  // -- does a quoted operand of some *other* command look like a command -- and
  // misses `head`, `xxd` and `install` alike.
  for (const inner of innerCommands(command)) {
    for (const p of extractPaths(inner, cwd)) add(p);
  }

  for (const seg of segments(command)) {
    const toks = tokenize(seg);
    if (!toks.length) continue;
    const i = commandIndex(toks);
    if (i >= toks.length) continue;
    const name = basename(toks[i]);
    const args = toks.slice(i + 1);

    // A redirect can be glued to the command name itself (`date>/etc/x`), which
    // puts the target in the name position, where operands are never scanned.
    if (REDIRECT_OP.test(toks[i])) add(toks[i]);

    // `cd` and `pushd` contribute only their target: a relative operand after
    // them is resolved against the session cwd by the caller, so tracking the
    // new directory here would not change the answer.
    if ((name === "cd" || name === "pushd") && args.length) {
      add(args[0]);
      continue;
    }

    for (const a of args) {
      add(a);
      // A quoted argument is opaque to the tokenizer: `sh -c 'cat /etc/hosts'`
      // arrives as one token whose interior paths would otherwise be invisible.
      // Re-scan anything that embeds a command, or that starts like one. The
      // start anchor matters now that outside is deny: a commit message such as
      // "fix rm -rf / handling" is prose, and a hard deny must not fire on prose.
      if (
        (/[;|&]/.test(a) ||
          /^(?:(?:sudo|env|command|exec|nohup|time)\s+)*(?:cat|rm|mv|cp|tee|dd|chmod|chown|sed|awk|grep|find|ln|tr)\b/.test(
            a,
          )) &&
        /[\s'"]/.test(a)
      ) {
        for (const inner of extractPaths(a, cwd)) add(inner);
      }
    }
  }

  return out;
}

/**
 * Classify every path in a command against the boundary.
 * Returns the absolute paths that fall outside, deduplicated.
 */
export function pathsOutsideBoundary(command: string, cwd: string, roots: string[]): string[] {
  const outside: string[] = [];
  for (const raw of extractPaths(command, cwd)) {
    const abs = resolvePathFrom(raw, cwd);
    if (!isInsideBoundary(abs, roots)) outside.push(abs);
  }
  return [...new Set(outside)];
}

/**
 * Paths in the command that name a `.env` file. `.env*` rather than a survey of
 * where secrets live, so unlike a keyfile list it cannot rot as tools change.
 *
 * Matches `.env`, `.env.local`, `.env.production`, `.envrc`: anything that is
 * `.env` plus a suffix. The example/sample/template/dist variants are exempt --
 * they hold placeholders by convention, so gating them buys nothing and costs a
 * prompt on every repo that ships one.
 *
 * Applies everywhere, including inside the workspace, because inside is exactly
 * where it matters -- the boundary never fires there and every other check is
 * path-based, so a `.env` in the repo you are editing was otherwise wide open.
 *
 * KNOWN GAP: an implicit scan names no path. `grep -r pattern` searches hidden
 * files, so it reads `.env` without ever appearing here; `rg` skips hidden files
 * unless given `--hidden` or `-uu`. A wildcard operand (`cat .env*`) is missed
 * for the same reason: this sees the literal token and the shell expands it
 * afterwards. Both cases are covered by AGENTS.md, not by this function.
 */
const ENV_FILE = /^\.env(?:rc|\..*)?$/i;
const ENV_EXAMPLE = /^\.env\.(?:example|sample|template|dist|defaults?)(?:\..*)?$/i;

export function sensitiveReads(command: string, cwd: string): string[] {
  const hits: string[] = [];
  for (const raw of extractPaths(command, cwd)) {
    const name = basename(raw);
    if (ENV_FILE.test(name) && !ENV_EXAMPLE.test(name)) hits.push(resolvePathFrom(raw, cwd));
  }
  return [...new Set(hits)];
}

// ------------------------------------------------------------- outside verdict

/**
 * What to do about a command that names paths outside the boundary. Config
 * already denies the paths its scanner infers; this covers the ones it misses.
 * The answer is the same for every outside path, reader or not: deny.
 */
export type OutsideVerdict =
  | { effect: "allow" }
  | { effect: "deny"; message: string };

export function outsideVerdict(outside: string[]): OutsideVerdict {
  if (!outside.length) return { effect: "allow" };
  const store = outside.map((p) => floorReason(p)).find(Boolean);
  return {
    effect: "deny",
    message: store
      ? `${store} is a credential store. Refused.`
      : `Outside the workspace and named directly: ${outside[0]}. Refused.`,
  };
}

// --------------------------------------------------------------- deny tables

const DENY: [RegExp, string][] = [
  [/(?:^|[\s;|&(])sudo(?:\s|$)/, "sudo is not available in this setup."],
  [
    /\bgit\s+push\b[^|;&]*(?:--force(?!-with-lease)|(?:^|\s)-f(?:\s|$))/,
    "force push blocked. Use --force-with-lease if this is genuinely required.",
  ],
  [/\bgit\s+push\b[^|;&]*\s(?:--delete|-d)\s/, "deleting a remote branch is blocked."],
  [
    /\bgit\s+reset\s+--hard\s+(?!$|\s)[^|;&]*\S/,
    "git reset --hard against a ref is blocked; it can discard remote work.",
  ],
  [
    /\bchmod\b[^|;&]*-R\s+(?:-[a-zA-Z]+\s+)*777\b/,
    "recursive world-writable permissions are blocked.",
  ],
  [
    /(?:^|[\s;|&])(?:mkfs(?:\.\w+)?|fdisk|diskutil\s+erase)\b/,
    "filesystem-level operation blocked.",
  ],
  [/>\s*\/dev\/(?:sd|disk|hd)/, "writing directly to a block device is blocked."],
  [/:\(\)\s*\{\s*:\|:&\s*\}\s*;\s*:/, "fork bomb blocked."],
];

const PUBLISH_SUBCOMMANDS: Record<string, Set<string>> = {
  npm: new Set(["publish", "unpublish", "dist-tag", "owner"]),
  pnpm: new Set(["publish", "unpublish", "deploy"]),
  bun: new Set(["publish", "unpublish"]),
  yarn: new Set(["publish", "unpublish"]),
  cargo: new Set(["publish", "yank"]),
  deno: new Set(["publish"]),
  uv: new Set(["publish"]),
  poetry: new Set(["publish"]),
  twine: new Set(["upload"]),
  gcloud: new Set(["deploy"]),
  vercel: new Set(["deploy"]),
  netlify: new Set(["deploy"]),
  flyctl: new Set(["deploy"]),
  fly: new Set(["deploy"]),
  terraform: new Set(["apply", "destroy"]),
  pulumi: new Set(["up", "destroy"]),
  kubectl: new Set(["apply", "delete", "drain", "cordon"]),
  wrangler: new Set(["deploy", "publish"]),
};

const PUBLISH_PAIRS: Record<string, Set<string>> = {
  "gcloud app": new Set(["deploy", "delete"]),
  "gcloud functions": new Set(["deploy", "delete"]),
  "doctl apps": new Set(["create", "delete"]),
  "doctl databases": new Set(["create", "delete"]),
  "aws s3": new Set(["sync", "rm"]),
  "aws ec2": new Set(["terminate-instances"]),
  heroku: new Set(["run", "destroy"]),
};

/**
 * Publish/deploy detection.
 *
 * Returns a reason to PROMPT rather than throwing. These mutate remote
 * infrastructure, not the local filesystem, so the directory boundary cannot
 * judge them -- but unlike `rm -rf /` they are not mistakes, they are decisions.
 * Blocking outright was wrong friction; asking is the right level, and the user
 * gets to say "yes, ship it".
 */
function checkPublish(command: string): string | undefined {
  for (const seg of segments(command)) {
    const toks = tokenize(seg);
    const i = commandIndex(toks);
    if (i >= toks.length) continue;
    const name = basename(toks[i]);
    const args = toks.slice(i + 1).filter((a) => !a.startsWith("-"));
    let subs = new Set(PUBLISH_SUBCOMMANDS[name] ?? []);
    for (let pos = 0; pos < args.length; pos++) {
      for (const key of [`${name} ${args[pos]}`, `${name} ${args[pos]} ${args[pos + 1] ?? ""}`]) {
        for (const s of PUBLISH_PAIRS[key] ?? []) subs.add(s);
      }
    }
    if (!subs.size) continue;
    for (const arg of args) {
      if (subs.has(arg)) {
        return `\`${name} ${arg}\` publishes or deploys. This can't be undone once it reaches the remote.`;
      }
    }
  }
  return undefined;
}

// ------------------------------------------------------------- root protection

/**
 * Root-target deletes. The reason this plugin exists at all: config patterns
 * cannot reach these. Every one of these is denied by parsing the operands, not
 * by matching the command string, so flag order (`-fr`), flag case (`-Rf`),
 * split flags (`-r -f`), the `--` end-of-flags marker, and `~`/`$HOME`
 * expansion are all handled.
 */
function checkRootTargets(command: string): void {
  for (const seg of segments(command)) {
    const toks = tokenize(seg);
    if (!toks.length) continue;
    const i = commandIndex(toks);
    if (i >= toks.length) continue;
    const name = basename(toks[i]);
    if (!["rm", "trash", "rimraf"].includes(name)) continue;
    const flags = toks.slice(i + 1).filter((a) => a.startsWith("-"));
    const operands = toks.slice(i + 1).filter((a) => !a.startsWith("-") && a !== "--");
    for (const t of operands) {
      if (!isRootTarget(t)) continue;
      const recursive = name !== "rm" || flags.some((f) => /[rR]/.test(f));
      throw new Denied(
        recursive
          ? `recursive delete of a root or home path is blocked (${t}). Use \`trash\` on a specific subdirectory instead.`
          : `forced delete of a root or home path is blocked (${t}).`,
      );
    }
  }
}

// ------------------------------------------------------------ git force push

/**
 * Force pushes a prefix matcher cannot see.
 *
 * `git -c k=v push --force` puts a flag between the verb and the subcommand, and
 * `git push origin +main` forces a ref with no flag at all. Both are found by
 * token, the way root targets are: a regex wide enough to reach past the flags
 * also reaches `--force` inside a commit message, and a false deny cannot be
 * approved away.
 *
 * The DENY table keeps its own git patterns for a `git` sitting after something
 * that is not a wrapper (`nice git push --force`); this covers the rest.
 */
function checkGitForce(command: string): void {
  for (const seg of segments(command)) {
    const toks = tokenize(seg);
    if (!toks.length) continue;
    const i = commandIndex(toks);
    if (basename(toks[i]) !== "git") continue;
    const args = toks.slice(i + 1);
    const sub = args.indexOf("push");
    if (sub < 0) continue;
    const rest = args.slice(sub + 1);
    if (rest.some((t) => t === "--force" || t === "-f")) {
      throw new Denied("force push blocked. Use --force-with-lease if this is genuinely required.");
    }
    if (rest.some((t) => t.startsWith("+"))) {
      throw new Denied(
        "force push blocked (+refspec). Use --force-with-lease if this is genuinely required.",
      );
    }
    if (rest.some((t) => t === "--delete" || t === "-d")) {
      throw new Denied("deleting a remote branch is blocked.");
    }
  }
}

// ------------------------------------------------------------------ unwrapping

/**
 * Every command nested anywhere inside this one, so the checks see the payloads
 * of payloads. Depth-capped because a chain of substitutions has no natural end.
 */
function nestedCommands(command: string, depth = 0): string[] {
  if (depth > 3) return [];
  return innerCommands(command).flatMap((c) => [c, ...nestedCommands(c, depth + 1)]);
}

// -------------------------------------------------------------------- decision

export type Decision = { deny?: string; prompt?: string; note?: string };

/**
 * The security decision for one command.
 *
 * Returns a decision rather than throwing, because the permission hook runs this
 * inside a fail-open try/catch: a `Denied` that escaped as an exception would be
 * swallowed and `rm -rf /` would sail through as `allow`. Convert at the boundary.
 *
 * Two severities:
 *   deny  -- never runs. Root targets and filesystem-level destruction.
 *   prompt -- asks first. Publish/deploy: irreversible, but intentional.
 */
export function evaluateSecurity(command: string): Decision {
  if (!command.trim()) return {};

  // The command itself plus anything it is quoting that will be executed: a
  // `rm -rf /` behind `sh -c` has to be judged by the same rules as one typed
  // at the prompt, or the deny is only as strong as its most obvious spelling.
  const candidates = [command, ...nestedCommands(command)];

  for (const c of candidates) {
    for (const [pattern, reason] of DENY) {
      if (pattern.test(c)) return { deny: reason };
    }
  }
  try {
    for (const c of candidates) {
      const publish = checkPublish(c);
      if (publish) return { prompt: publish };
      checkRootTargets(c);
      checkGitForce(c);
    }
  } catch (e) {
    if (e instanceof Denied) return { deny: e.message };
    // An unexpected internal error must not become a silent allow for a
    // destructive command, so it fails closed here specifically.
    return { deny: `internal check failed, refusing to run: ${String(e).slice(0, 120)}` };
  }
  return {};
}

// --------------------------------------------------------------------- plugin

export default {
  id: "guard",
  async setup(ctx: any) {
    // The workspace root is the Location directory, canonicalised once. Resolved
    // per event rather than captured at setup so a worktree or directory change
    // is respected instead of silently enforcing a stale root.
    const workspace = (): string => {
      const dir = ctx?.location?.directory ?? ctx?.location?.project?.canonical ?? process.cwd();
      try {
        return realpathSync(dir);
      } catch {
        return dir;
      }
    };

    // A permission hook, not a tool hook: this is the only place that sees every
    // shell command BEFORE it runs and can escalate the decision. Hooks fire for
    // `allow` and `ask` but never for a configured `deny`, so config's boundary
    // and rm rules are already final by the time this runs. This covers the
    // paths the built-in scanner does not infer.
    //
    // Only `allow` is escalated. Rewriting an existing `ask` would attach a reason
    // to a prompt the user is already going to see, and rewriting a `deny` is
    // impossible anyway.
    try {
      await ctx.permission.hook("evaluate", async (event: any) => {
        try {
          if (event?.action !== "shell") return;
          if (event.effect !== "allow") return;

          const resources: string[] = Array.isArray(event.resources) ? event.resources : [];
          const cwd = workspace();
          const roots = boundaryRoots(cwd);

          for (const command of resources) {
            if (typeof command !== "string" || !command.trim()) continue;

            // Deny tables run first. A hard deny must stay hard even if the
            // boundary logic below has a bug, and the reason is more useful than
            // a generic "outside the workspace" refusal.
            const d = evaluateSecurity(command);
            if (d.deny) {
              event.effect = "deny";
              event.message = d.deny;
              return;
            }
            // Publish/deploy: irreversible but intentional, so ask rather than
            // block. Checked before the boundary because the reason is more
            // specific and the command may well sit inside the workspace.
            if (d.prompt) {
              event.effect = "ask";
              event.message = d.prompt;
              return;
            }

            // .env is checked before the boundary: it lives inside the
            // workspace, where the boundary never fires.
            const secrets = sensitiveReads(command, cwd);
            if (secrets.length) {
              event.effect = "ask";
              event.message = `Reads ${secrets.join(", ")}.\n.env holds credentials. Approve only to put its contents in the transcript.`;
              return;
            }

            // Same answer config gives the paths its scanner infers. This is the
            // backstop for the file arguments and redirect targets it misses.
            const outside = pathsOutsideBoundary(command, cwd, roots);
            const verdict = outsideVerdict(outside);
            if (verdict.effect === "deny") {
              event.effect = "deny";
              event.message = verdict.message;
              return;
            }
          }
        } catch {
          /* fail OPEN: a boundary bug must never lock the user out */
        }
      });
    } catch {
      /* older plugin API without permission.hook: skip the boundary */
    }

    // Denies are re-checked here as a belt-and-braces measure, because the DENY
    // table covers forms a config pattern cannot express. Deliberately deny-only:
    // a prompt cannot be raised from inside execute.before, so `d.prompt` is left
    // to the permission hook above, which runs earlier and can actually ask.
    // `sudo` stays out of the table on purpose: it is legitimate inside /tmp, and
    // the boundary check already denies anything outside the workspace.
    await ctx.tool.hook("execute.before", async (event: any) => {
      try {
        // The floor covers the read tool as well. external_directory already
        // refuses an outside path; this is what still refuses the store when the
        // Location is $HOME and the store is inside the boundary.
        if (event?.tool === "read") {
          const file = event.input?.filePath ?? event.input?.path;
          if (typeof file === "string" && file) {
            const store = floorReason(resolvePathFrom(file, workspace()));
            if (store) {
              throw new Denied(
                `${store} is a credential store. Refused.\nRead the specific file you need, or ask the user to run this.`,
              );
            }
          }
          return;
        }

        if (event?.tool !== "shell") return;
        const command = event.input?.command;
        if (typeof command !== "string" || !command) return;
        const d = evaluateSecurity(command);
        if (d.deny) throw new Denied(d.deny);
      } catch (e) {
        if (e instanceof Denied) throw e;
        /* fail open on internal errors */
      }
    });
  },
};
