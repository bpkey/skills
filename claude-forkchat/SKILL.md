---
name: claude-forkchat
description: Fork the current Claude Code conversation into a sibling Apple Terminal tab (default) or window. Use when the user invokes /claude-forkchat, /claude-forkchat tab, /claude-forkchat window, or asks to "fork this chat", "branch this conversation into another tab/window", "open a fork alongside", "clone this session", "duplicate this session". Original session keeps running unchanged; the fork starts fresh with its own new session ID, seeded from the current transcript via `claude --resume <id> --fork-session`. When run in the main checkout of a git repo, first offers to fork into its own git worktree (isolated checkout) for collision-free parallel work, remembering the choice per repo. Differs from the built-in `/branch` command, which switches the *current* terminal into the fork — /claude-forkchat keeps both alive side-by-side.
---

# /claude-forkchat

Forks the current Claude Code session and opens it alongside the original. The current session keeps running where it is; the new tab or window opens a forked copy with its own session ID, seeded from the current transcript.

Built-in `/branch` already exists, but it switches the active terminal into the fork. Use `/claude-forkchat` when you want both threads alive at once.

## Modes

- `/claude-forkchat` → same as `/claude-forkchat tab`
- `/claude-forkchat tab` → new tab in the current Terminal window (Cmd+T)
- `/claude-forkchat window` → brand-new Terminal window

Any other argument exits with an error.

## How to run

First **derive a slug**, then run a **worktree pre-step**, then **launch**.

**Derive the slug.** A short kebab-case slug (1–4 words, lowercase, hyphens, no spaces or punctuation) that summarises what the user has been doing in this conversation — e.g. `dns-cleanup`, `prd-draft`, `forkchat-tweak`. It does double duty: it names the fork (when the session has no display name) *and* names the worktree branch in the pre-step. If you genuinely cannot tell what the conversation is about, use an empty slug and the script falls back to a session-id stub (and the worktree, if any, to `parallel-N`).

### Step 1 — Worktree pre-step

Run the resolver from the user's current directory, passing the slug so a worktree (if created) is named after the conversation:

```bash
~/.claude/skills/claude-forkchat/scripts/worktree-prep.sh resolve dns-cleanup
```

Parse its `KEY=VALUE` output:

- **`NEED_ASK=0`** → directory decided. Read `LAUNCH_DIR=<dir>` and go to Step 2. (`REASON`: `not-a-git-repo`, `already-in-worktree`, `pref-never`, or `pref-always` where the worktree was just created.)
- **`NEED_ASK=1`** → you're in the **main checkout of a git repo** with no saved preference for it. Output also gives `TOPLEVEL`, `SUGGESTED_SLUG`, `SUGGESTED_DIR`. Ask the user.

**Asking (only when `NEED_ASK=1`).** Use the **AskUserQuestion** tool with two questions in one call:

1. *Worktree or same folder?* — "You're in the main checkout of `<TOPLEVEL>`. Fork into its own git worktree (isolated checkout at `<SUGGESTED_DIR>`, new branch `<SUGGESTED_SLUG>`) so the forked session can work in parallel without touching this one's files?" Options: **Use a worktree** / **Same folder**.
2. *Remember for this repo?* — "Remember this for `<TOPLEVEL>` so I don't ask again here?" Options: **Remember** / **Ask each time**.

Then:

- If **Remember**: run `worktree-prep.sh remember always` (worktree) or `worktree-prep.sh remember never` (same folder). It prints `SAVED=<file>` — tell the user it's saved there (under `~/.blueprintkey/parallel-sessions/`).
- If **Use a worktree**: run `worktree-prep.sh create dns-cleanup` and read `LAUNCH_DIR=<dir>`. If `create` exits non-zero, tell the user and fall back to the current directory.
- If **Same folder**: `LAUNCH_DIR` is the current directory.

If you cannot prompt the user (non-interactive run), skip the worktree and use the current directory.

### Step 2 — Launch

The launcher takes two positional args — `mode` (`tab` or `window`, default `tab`) and the optional `fallback-base` slug — plus the chosen directory via `PARALLEL_LAUNCH_DIR`:

```bash
PARALLEL_LAUNCH_DIR="<LAUNCH_DIR>" ~/.claude/skills/claude-forkchat/scripts/claude-forkchat.sh tab dns-cleanup
PARALLEL_LAUNCH_DIR="<LAUNCH_DIR>" ~/.claude/skills/claude-forkchat/scripts/claude-forkchat.sh window dns-cleanup
PARALLEL_LAUNCH_DIR="<LAUNCH_DIR>" ~/.claude/skills/claude-forkchat/scripts/claude-forkchat.sh tab   # empty slug — uses session name or id stub
```

If `LAUNCH_DIR` is the current directory you may omit the env var. The slug is still only used for the fork name if the current session has no display name; otherwise the existing name takes priority. Echo the script's stdout (`forked from <session-id> into new tab as '<fork-name>' in <dir>`). On non-zero exit, surface stderr verbatim.

## Fork naming

Every fork is launched with `claude -n <name>` so it shows up labelled in the prompt box, `/resume` picker, and terminal title. The name is chosen in this order:

1. **`<current-session-name>-fork`** — if the source session has a name (set via `/rename` or `claude -n`).
2. **`<fallback-base>-fork`** — if the caller passed a slug as the second arg.
3. **`fork-<first-8-of-session-id>`** — last-resort stub.

So a session named `dns-cleanup` always forks to `dns-cleanup-fork`; an unnamed session forks to whatever slug the LLM derived from the conversation, suffixed with `-fork`.

## First-time execution (Accessibility permission for `tab` mode)

`tab` mode sends Cmd+T to the front Terminal window via System Events, which macOS gates behind **Accessibility permission**. If the permission dialog doesn't appear automatically, `osascript` fails with `not allowed to send keystrokes. (1002)`.

Set it up once:

1. **System Settings → Privacy & Security → Accessibility**
2. Enable **Terminal** and **claude** (click + to add if missing — `which claude` shows the path).
3. Quit and relaunch Claude Code.

`window` mode uses `do script` with no keystrokes and needs no Accessibility permission.

## How it works

1. Finds the current session's transcript file via `lsof -p $PPID` (the Bash shell's parent is the running `claude` process).
2. Falls back to the most recently modified JSONL under `~/.claude/projects/<encoded-cwd>/` if `lsof` returns nothing.
3. Reads the current session's display name (if any) from `~/.claude/sessions/<pid>.json`, where Claude Code stores per-session metadata keyed by PID with `sessionId` and an optional `name` field set via `/rename`.
4. Reads the latest `permissionMode` from the transcript. If the current session is in `bypassPermissions` (launched with `--dangerously-skip-permissions`, or toggled there via shift+tab), the fork inherits it by appending `--dangerously-skip-permissions` to the launch command. If the mode was later toggled back, the fork does *not* inherit bypass.
5. Activates Terminal.app and either sends Cmd+T (`tab`) or calls `do script` with no `in` clause (`window`).
6. `cd`s to `PARALLEL_LAUNCH_DIR` (the worktree chosen in Step 1, or the original `cwd` when none) and runs `claude --resume <session-id> --fork-session -n <fork-name>` (plus `--dangerously-skip-permissions` when inherited).

If `tab` is requested but no Terminal window is open, the script falls back to `window` automatically.

## Git worktree for parallel work

When you fork into the *same* folder of a git repo, both sessions share one working tree — their edits and branch switches collide. A **git worktree** gives the fork its own checkout (its own directory and branch) off the current `HEAD`, so the forked conversation can run in true parallel. Step 1 offers this only when it helps: you're **inside a git repo** and **in its main checkout** (not already in a linked worktree).

- **Where it's created.** `git worktree add <parent>/<repo>-<slug> -b <slug>` — a sibling directory on a new branch named after the conversation slug (`dns-cleanup`, …), or `parallel-N` when there's no slug. Uniquified if the name is taken. No extra prompt.
- **Fresh checkout at HEAD.** The worktree holds your committed `HEAD`, not the current folder's uncommitted changes. Since the fork resumes the *conversation* (which may reference in-progress edits that live only in the main checkout), commit or stash first if the fork needs them.
- **Remembering the choice.** "Remember" saves an `always` / `never` decision **per repository** so you're not asked again in that repo, in:

  ```
  ~/.blueprintkey/parallel-sessions/prefs.conf
  ```

  Delete that file (or a repo's line) to be asked again. The preference is shared with `/claude-samefolder`.

## Caveats

- The fork is seeded from whatever has been **flushed to disk** at invocation time. The in-flight `/claude-forkchat` turn itself may not appear in the cloned session.
- Apple Terminal only. Other terminals (`iTerm.app`, `WarpTerminal`, `ghostty`) trigger a stderr warning and the script falls back to driving Terminal.app anyway.
- Apple Terminal's split panes (Cmd+D) aren't cleanly addressable via AppleScript, so `tab` creates a *tab*, not a literal split pane.
- Requires `lsof`, `osascript`, `git`, and `claude` on `$PATH`.
