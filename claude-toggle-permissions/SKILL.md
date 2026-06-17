---
name: claude-toggle-permissions
description: Continue the CURRENT Claude Code conversation IN PLACE — taking over the current Apple Terminal tab — with the bypass-permissions mode flipped. Use when the user invokes /claude-toggle-permissions or asks to "switch this session to bypass mode", "turn off dangerously-skip-permissions", "toggle permissions", "continue this chat without permission prompts", "reopen this conversation in bypass mode", "drop out of bypass mode but keep the context". Because `--dangerously-skip-permissions` is a launch-time flag that can't be toggled inside a live session, this keeps the full conversation by seeding a NEW session from the current transcript via `claude --resume <id> --fork-session`, adding or dropping `--dangerously-skip-permissions` so the new session lands in the opposite bypass state, then ENDS the current session so the flipped one takes over this same tab. Claude Code only.
---

# /claude-toggle-permissions

Continues the current Claude Code conversation **in this same terminal tab**, but with the **bypass-permissions** dimension flipped:

- If this session is in **bypass** mode (launched with `--dangerously-skip-permissions`), the flipped session opens in **normal** mode — permission prompts back on.
- If this session is **not** in bypass mode (default / plan / accept-edits), the flipped session opens in **bypass** mode — no prompts.

The flipped session is seeded from the full current transcript (so it has all the context) and **takes over this tab**: the current session ends and the flipped one relaunches in its place. You end up with **one** session, in the opposite bypass state — not two side by side.

## Why a relaunch (and not shift+tab)

`--dangerously-skip-permissions` is a **launch-time flag** — there's no in-session toggle for the bypass dimension, so the only way to flip it is to start a fresh `claude` process. To avoid losing the conversation, this resumes the current transcript into that new process with `claude --resume <id> --fork-session`, flipping the flag in the process.

A child process can't re-exec the live `claude` that spawned it, so the takeover is handled by a tiny **detached watcher**: it ends the current session, waits for this tab's shell to return to its prompt, then drives Terminal to relaunch the flipped session on that prompt — in the same tab. Forking (rather than resuming the same id) means the new session reads the transcript as a clean seed, with no chance of two processes touching one transcript during the handoff.

This is close to the built-in `/branch` command (which also switches the current terminal into a continuation) — except `/claude-toggle-permissions` deliberately **flips the bypass flag** as it hands over, which `/branch` can't do.

## How to run

First **derive a slug**, then **launch**.

**Derive the slug.** A short kebab-case slug (1–4 words, lowercase, hyphens, no spaces or punctuation) summarising what the conversation is about — e.g. `dns-cleanup`, `prd-draft`, `auth-refactor`. It's used to name the flipped session **only when the current session has no display name**; otherwise the existing name wins. If you genuinely can't tell what the conversation is about, pass nothing and the script falls back to a session-id stub.

**Launch.** The launcher takes one optional positional arg — the fallback slug:

```bash
~/.claude/skills/claude-toggle-permissions/scripts/claude-toggle-permissions.sh dns-cleanup
~/.claude/skills/claude-toggle-permissions/scripts/claude-toggle-permissions.sh   # no slug — uses session name or id stub
```

There are no `tab`/`window` modes — the takeover always happens in this tab.

Keep your post-launch reply to the user **short** — a one-line confirmation — because the current session is torn down about 1.5 seconds after the script runs, and anything still rendering then is cut off. Echo the script's stdout (e.g. `toggling default -> bypassPermissions (no prompts): this tab will end the current session and relaunch <session-id> in place as 'dns-cleanup-bypass' (in <dir>)`) so the flip direction is recorded. On non-zero exit, surface stderr verbatim.

## Session naming

The flipped session is launched with `claude -n <name>` so it's labelled in the prompt box, `/resume` picker, and terminal title. The name encodes the **target** mode so it's obvious which way it landed:

- `-bypass` suffix → bypass turned **on**.
- `-safe` suffix → bypass turned **off** (normal prompts).

The base is chosen in this order:

1. **`<current-session-name>`** — if the source session has a name (set via `/rename` or `claude -n`).
2. **`<fallback-slug>`** — if the caller passed a slug.
3. **`chat-<first-8-of-session-id>`** — last-resort stub.

Any existing `-bypass`/`-safe` suffix on the base is stripped first, so flipping back and forth stays clean: `dns-cleanup-bypass` → toggle → `dns-cleanup-safe` → toggle → `dns-cleanup-bypass`, never `dns-cleanup-bypass-safe`.

## Prerequisite — Automation permission (one-time)

The takeover drives Terminal via AppleScript `do script` (Terminal scripting its own window), which macOS gates behind **Automation** permission. The script **pre-flights** this before it ends anything: it runs a harmless `osascript ... count windows` in the foreground first, so:

- On a fresh machine the first run triggers the standard **"… wants to control Terminal"** consent dialog — approve it once.
- If the permission is **missing or denied**, the script prints step-by-step instructions and exits **without touching the current session** (it never kills a session it can't relaunch).

To grant it manually: **System Settings → Privacy & Security → Automation**, find **Terminal**, and turn on its **Terminal** toggle.

No **Accessibility** permission is needed — this skill sends no synthetic keystrokes (no Cmd+T), so there is nothing to enable under Privacy & Security → Accessibility.

## How it works

1. **Tool guard.** Confirms it's running inside Claude Code (via `CLAUDECODE` / `CLAUDE_CODE_ENTRYPOINT` / `CLAUDE_CODE_SESSION_ID`). If not, it prints which tool it detected, that it's Claude Code-only, and why (it resumes a Claude Code session from `~/.claude/projects/`, which only Claude Code writes), then exits.
2. **Terminal guard.** Because the takeover ends the current session and relaunches in this exact tab, it only supports Apple Terminal. On any other known terminal (`iTerm.app`, `WarpTerminal`, `ghostty`, …) it refuses up front rather than killing the session and opening a stray Terminal.app window. An empty `TERM_PROGRAM` is treated as Apple Terminal (best effort).
3. Finds the current session's transcript: prefers `$CLAUDE_CODE_SESSION_ID`, then `lsof -p $PPID` (the Bash shell's parent is the running `claude` process), then the newest JSONL under `~/.claude/projects/<encoded-cwd>/`.
4. Reads the latest `permissionMode` from the transcript. `bypassPermissions` → flip **off** (relaunch without the flag); anything else → flip **on** (append `--dangerously-skip-permissions`). If no mode can be read, it warns and assumes not-bypass (switches bypass on).
5. Reads the current session's display name (if any) from `~/.claude/sessions/<pid>.json` and builds the `-bypass` / `-safe` name.
6. **Pre-flights Automation permission** (a foreground `osascript ... count windows`). If it can't drive Terminal, it prints how to grant the permission and exits *without ending the session*.
7. Spawns a **detached watcher** (`nohup`, ignores HUP/TERM/INT) and prints a one-line summary. The watcher then: gives this turn ~1.5s to render → `kill -TERM` (escalating to `-KILL`) the current `claude` so the tab's shell returns to its prompt → finds the tab whose `tty` matches this one → runs `cd <dir> && echo <breadcrumb> && claude --resume <id> --fork-session -n <name> [--dangerously-skip-permissions]` in that tab.

If the tab's shell happens to exit when the session ends (so the tab is gone), the watcher relaunches in a new window instead. And if AppleScript can't run at all once the session is already gone, the watcher writes the exact relaunch command to the tab's tty so it can be pasted by hand.

## Relationship to the sibling skills

- **`/claude-forkchat`** forks the current conversation into a **separate** tab/window and **inherits** the same permission mode — both sessions keep running side by side.
- **`/claude-samefolder`** opens a *fresh* (no-context) session in a separate tab/window.

`/claude-toggle-permissions` is different on both axes: it is **in-place** (takes over this tab, ends the current session) and it **flips** the bypass dimension. Use it when the *only* thing you want to change is whether permission prompts are on, and you want to stay in this one tab. Like those two, it has **no git-worktree step** — flipping permission mode is a same-folder continuation of one conversation, not parallel work on the tree.

## Caveats

- The flipped session is seeded from whatever has been **flushed to disk** at invocation time. The in-flight `/claude-toggle-permissions` turn itself may not appear in the new session.
- The takeover **ends the current session** (`SIGTERM`, then `SIGKILL` if needed). It is not a graceful in-session exit — the relaunch happens ~2 seconds after you invoke it.
- `bypassPermissions` (`--dangerously-skip-permissions`) disables permission prompts entirely — only toggle it on in a directory you trust.
- Apple Terminal only — the skill refuses to run in other terminals (see the Terminal guard) so it never kills your session in a terminal it can't take over.
- Relies on `$PPID` being the host `claude` process (true for the Claude Code Bash tool) to read the tab's tty and end the session.
- Requires `lsof`, `osascript`, `ps`, and `claude` on `$PATH`.
