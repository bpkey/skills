---
name: claude-samefolder
description: Open a fresh (non-resumed) `claude` session in a new Apple Terminal tab or window, in the same working directory as the current session. Use whenever the user invokes /claude-samefolder, /claude-samefolder tab, /claude-samefolder window, or asks to "open another claude in this folder", "start a fresh claude alongside this one", "spawn a new claude in the same project", "open a parallel claude session". Defaults to a new tab; pass `window` for a new window. When run in the main checkout of a git repo, first offers to open the new session in its own git worktree (isolated checkout) for collision-free parallel work, remembering the choice per repo. Differs from /claude-forkchat — /claude-forkchat carries the *current* conversation forward, whereas /claude-samefolder starts with no prior context. The current session keeps running unchanged.
---

# /claude-samefolder

Opens a fresh `claude` session in a new Apple Terminal tab (default) or window, in the same working directory as the current session.

Cmd+T natively lands in `~`. This skill `cd`s into the original `cwd` first, so the new session boots straight into your current project — no manual navigation needed.

## Permission mode is inherited

If the current session is running in `bypassPermissions` (launched with `--dangerously-skip-permissions`, or toggled there via shift+tab), the new session inherits it — the script reads the latest `permissionMode` from the current transcript and appends `--dangerously-skip-permissions` to the `claude` launch. If the mode was later toggled back to default/acceptEdits/plan, the new session starts without bypass.

## Modes

- `/claude-samefolder` → same as `/claude-samefolder tab`
- `/claude-samefolder tab` → new tab in the current Terminal window (Cmd+T)
- `/claude-samefolder window` → brand-new Terminal window

Any other argument exits with an error.

## How to run

Two steps: a **worktree pre-step** (decide *where* the new session opens), then the **launch**. Do them in order.

### Step 1 — Worktree pre-step

Run the resolver from the user's current directory:

```bash
~/.claude/skills/claude-samefolder/scripts/worktree-prep.sh resolve
```

Parse its `KEY=VALUE` output:

- **`NEED_ASK=0`** → the directory is already decided. Read `LAUNCH_DIR=<dir>` and go straight to Step 2 with it. (`REASON` tells you why — `not-a-git-repo`, `already-in-worktree`, `pref-never`, or `pref-always` where a worktree was just created for you.)
- **`NEED_ASK=1`** → you're in the **main checkout of a git repo** and the user has no saved preference for this repo. The output also gives `TOPLEVEL`, `SUGGESTED_SLUG`, and `SUGGESTED_DIR`. Ask the user (next paragraph).

**Asking (only when `NEED_ASK=1`).** Use the **AskUserQuestion** tool with two questions in one call:

1. *Worktree or same folder?* — e.g. "You're in the main checkout of `<TOPLEVEL>`. Open the new parallel Claude session in its own git worktree (an isolated checkout at `<SUGGESTED_DIR>`, new branch `<SUGGESTED_SLUG>`) so the two sessions don't step on each other's files?" Options: **Use a worktree** / **Same folder**.
2. *Remember for this repo?* — "Remember this choice for `<TOPLEVEL>` so I don't ask again here?" Options: **Remember** / **Ask each time**.

Then act on the answers:

- If **Remember**: run `worktree-prep.sh remember always` (worktree chosen) or `worktree-prep.sh remember never` (same folder). It prints `SAVED=<file>` — tell the user the choice was saved there (it lives under `~/.blueprintkey/parallel-sessions/`).
- If **Use a worktree**: run `worktree-prep.sh create` and read `LAUNCH_DIR=<dir>` from its output. If `create` exits non-zero (e.g. parent dir not writable), tell the user and fall back to the current directory.
- If **Same folder**: `LAUNCH_DIR` is just the current directory.

If you genuinely cannot prompt the user (non-interactive run), skip the worktree and use the current directory — the safe, non-destructive default.

### Step 2 — Launch

Run the launcher, exporting the chosen directory. Pass the user's mode argument through (default `tab`):

```bash
PARALLEL_LAUNCH_DIR="<LAUNCH_DIR>" ~/.claude/skills/claude-samefolder/scripts/claude-samefolder.sh tab     # default
PARALLEL_LAUNCH_DIR="<LAUNCH_DIR>" ~/.claude/skills/claude-samefolder/scripts/claude-samefolder.sh window
```

If `LAUNCH_DIR` is the current directory you may omit the env var. Echo the script's stdout back to the user. On non-zero exit, surface stderr verbatim.

## First-time execution (Accessibility permission for `tab` mode)

`tab` mode sends Cmd+T to the front Terminal window via System Events, which macOS gates behind **Accessibility permission**. If the permission dialog doesn't appear automatically, `osascript` fails with `not allowed to send keystrokes. (1002)`.

Set it up once:

1. **System Settings → Privacy & Security → Accessibility**
2. Enable **Terminal** and **claude** (click + to add if missing — `which claude` shows the path).
3. Quit and relaunch Claude Code (Accessibility state is captured at launch).

`window` mode uses `do script` with no keystrokes and needs no Accessibility permission.

## Git worktree for parallel work

When you launch a second session in the *same* folder of a git repo, both sessions share one working tree — edits, branch switches, and stashes collide. A **git worktree** gives the new session its own checkout (its own directory and branch) off the current `HEAD`, so the two can work in true parallel without stepping on each other.

This is why Step 1 offers a worktree, but only when it actually helps: you're **inside a git repo** and **in its main checkout** (not already in a linked worktree). Outside a repo, or already in a worktree, the question is skipped and the session just opens in the current folder.

- **Where it's created.** `git worktree add <parent>/<repo>-<slug> -b <slug>` — a sibling directory next to the repo, on a new branch named `<slug>` (auto-named `parallel-1`, `parallel-2`, … and uniquified if taken). No extra prompt.
- **Fresh checkout at HEAD.** The new worktree contains your committed `HEAD`, *not* the current folder's uncommitted changes — that isolation is the point. Commit or stash first if you want in-progress work carried over.
- **Remembering the choice.** "Remember" saves an `always` / `never` decision **per repository** (keyed by the repo's top-level path) so you're not asked again in that repo. It's stored in:

  ```
  ~/.blueprintkey/parallel-sessions/prefs.conf
  ```

  Delete that file (or the line for a repo) to be asked again. The same preference is shared with `/claude-forkchat`.

## Caveats

- Apple Terminal only. Other terminals (`iTerm.app`, `WarpTerminal`, `ghostty`) trigger a stderr warning and the script falls back to driving Terminal.app anyway.
- If `tab` is requested but no Terminal window is open, the script falls back to `window` automatically.
- Requires `osascript`, `git`, and `claude` on `$PATH`.
