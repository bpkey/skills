---
name: claude-toggle-permissions
description: Resume the CURRENT Claude Code conversation in a sibling Apple Terminal tab (default) or window with the bypass-permissions mode flipped. Use when the user invokes /claude-toggle-permissions, /claude-toggle-permissions tab, /claude-toggle-permissions window, or asks to "switch this session to bypass mode", "turn off dangerously-skip-permissions", "toggle permissions", "continue this chat without permission prompts", "reopen this conversation in bypass mode", "drop out of bypass mode but keep the context". Because `--dangerously-skip-permissions` is a launch-time flag that can't be toggled inside a live session, this keeps the full conversation by seeding a NEW session from the current transcript via `claude --resume <id> --fork-session`, adding or dropping `--dangerously-skip-permissions` so the new session lands in the opposite bypass state. Original session keeps running unchanged; both can run side by side. Claude Code only.
---

# /claude-toggle-permissions

Continues the current Claude Code conversation in a new tab or window, but with the **bypass-permissions** dimension flipped:

- If this session is in **bypass** mode (launched with `--dangerously-skip-permissions`), the new session opens in **normal** mode — permission prompts back on.
- If this session is **not** in bypass mode (default / plan / accept-edits), the new session opens in **bypass** mode — no prompts.

The current session keeps running where it is. The new session is seeded from the full current transcript (so it has all the context) but gets its own new session ID, so the two can run safely in parallel.

## Why a relaunch (and not shift+tab)

`--dangerously-skip-permissions` is a **launch-time flag** — there's no in-session toggle for the bypass dimension, so the only way to flip it is to start a fresh `claude` process. To avoid losing the conversation, this resumes the current transcript into that new process with `claude --resume <id> --fork-session`, flipping the flag in the process.

Forking (rather than resuming the same session ID in place) means the original and the toggled copy never fight over one session's transcript — both stay alive and usable.

## Modes

- `/claude-toggle-permissions` → same as `/claude-toggle-permissions tab`
- `/claude-toggle-permissions tab` → new tab in the current Terminal window (Cmd+T)
- `/claude-toggle-permissions window` → brand-new Terminal window

Any other argument exits with an error.

## How to run

First **derive a slug**, then **launch**.

**Derive the slug.** A short kebab-case slug (1–4 words, lowercase, hyphens, no spaces or punctuation) summarising what the conversation is about — e.g. `dns-cleanup`, `prd-draft`, `auth-refactor`. It's used to name the toggled session **only when the current session has no display name**; otherwise the existing name wins. If you genuinely can't tell what the conversation is about, pass an empty slug and the script falls back to a session-id stub.

**Launch.** The launcher takes two positional args — `mode` (`tab` or `window`, default `tab`) and the optional fallback slug:

```bash
~/.claude/skills/claude-toggle-permissions/scripts/claude-toggle-permissions.sh tab dns-cleanup
~/.claude/skills/claude-toggle-permissions/scripts/claude-toggle-permissions.sh window dns-cleanup
~/.claude/skills/claude-toggle-permissions/scripts/claude-toggle-permissions.sh tab   # empty slug — uses session name or id stub
```

Echo the script's stdout (e.g. `toggled default -> bypassPermissions (no prompts): forked <session-id> into a new tab as 'dns-cleanup-bypass' in <dir>`) so the user can see which way it flipped. On non-zero exit, surface stderr verbatim.

## Session naming

Every toggled session is launched with `claude -n <name>` so it's labelled in the prompt box, `/resume` picker, and terminal title. The name encodes the **target** mode so the two sessions are easy to tell apart:

- `-bypass` suffix → the new session has bypass turned **on**.
- `-safe` suffix → the new session has bypass turned **off** (normal prompts).

The base is chosen in this order:

1. **`<current-session-name>`** — if the source session has a name (set via `/rename` or `claude -n`).
2. **`<fallback-slug>`** — if the caller passed a slug as the second arg.
3. **`chat-<first-8-of-session-id>`** — last-resort stub.

Any existing `-bypass`/`-safe` suffix on the base is stripped first, so flipping back and forth stays clean: `dns-cleanup-bypass` → toggle → `dns-cleanup-safe` → toggle → `dns-cleanup-bypass`, never `dns-cleanup-bypass-safe`.

## First-time execution (Accessibility permission for `tab` mode)

`tab` mode sends Cmd+T to the front Terminal window via System Events, which macOS gates behind **Accessibility permission**. If the permission dialog doesn't appear automatically, `osascript` fails with `not allowed to send keystrokes. (1002)`.

Set it up once:

1. **System Settings → Privacy & Security → Accessibility**
2. Enable **Terminal** and **claude** (click + to add if missing — `which claude` shows the path).
3. Quit and relaunch Claude Code.

`window` mode uses `do script` with no keystrokes and needs no Accessibility permission.

## How it works

1. **Tool guard.** Confirms it's running inside Claude Code (via `CLAUDECODE` / `CLAUDE_CODE_ENTRYPOINT` / `CLAUDE_CODE_SESSION_ID`). If not, it prints which tool it detected, that it's Claude Code-only, and why (it resumes a Claude Code session from `~/.claude/projects/`, which only Claude Code writes), then exits.
2. Finds the current session's transcript: prefers `$CLAUDE_CODE_SESSION_ID`, then `lsof -p $PPID` (the Bash shell's parent is the running `claude` process), then the newest JSONL under `~/.claude/projects/<encoded-cwd>/`.
3. Reads the latest `permissionMode` from the transcript. `bypassPermissions` → flip **off** (launch without the flag); anything else → flip **on** (append `--dangerously-skip-permissions`). If no mode can be read, it warns and assumes not-bypass (switches bypass on).
4. Reads the current session's display name (if any) from `~/.claude/sessions/<pid>.json` and builds the `-bypass` / `-safe` fork name.
5. Activates Terminal.app and either sends Cmd+T (`tab`) or calls `do script` with no `in` clause (`window`).
6. `cd`s to the current directory and runs `claude --resume <session-id> --fork-session -n <fork-name>` (plus `--dangerously-skip-permissions` only when toggling bypass on).

If `tab` is requested but no Terminal window is open, the script falls back to `window` automatically.

## Relationship to the sibling skills

- **`/claude-forkchat`** forks the current conversation but **inherits** the same permission mode. `/claude-toggle-permissions` is the same kind of fork but deliberately **flips** the bypass dimension — use it when the *only* thing you want to change is whether permission prompts are on.
- **`/claude-samefolder`** opens a *fresh* (no-context) session in the same folder.

Unlike those two, this skill has **no git-worktree step** — flipping permission mode is a same-folder continuation of one conversation, not parallel work on the tree.

## Caveats

- The toggled session is seeded from whatever has been **flushed to disk** at invocation time. The in-flight `/claude-toggle-permissions` turn itself may not appear in the new session.
- `bypassPermissions` (`--dangerously-skip-permissions`) disables permission prompts entirely — only toggle it on in a directory you trust.
- Apple Terminal only. Other terminals (`iTerm.app`, `WarpTerminal`, `ghostty`) trigger a stderr warning and the script falls back to driving Terminal.app anyway.
- Requires `lsof`, `osascript`, `git`, and `claude` on `$PATH`.
