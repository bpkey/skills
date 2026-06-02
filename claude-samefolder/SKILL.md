---
name: claude-samefolder
description: Open a fresh (non-resumed) `claude` session in a new Apple Terminal tab or window, in the same working directory as the current session. Use whenever the user invokes /claude-samefolder, /claude-samefolder tab, /claude-samefolder window, or asks to "open another claude in this folder", "start a fresh claude alongside this one", "spawn a new claude in the same project", "open a parallel claude session". Defaults to a new tab; pass `window` for a new window. Differs from /claude-forkchat — /claude-forkchat carries the *current* conversation forward, whereas /claude-samefolder starts with no prior context. The current session keeps running unchanged.
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

Pass the user's argument straight through to the helper (default `tab` if none):

```bash
~/.claude/skills/claude-samefolder/scripts/claude-samefolder.sh tab     # default
~/.claude/skills/claude-samefolder/scripts/claude-samefolder.sh window
```

Echo the script's stdout back to the user. On non-zero exit, surface stderr verbatim.

## First-time execution (Accessibility permission for `tab` mode)

`tab` mode sends Cmd+T to the front Terminal window via System Events, which macOS gates behind **Accessibility permission**. If the permission dialog doesn't appear automatically, `osascript` fails with `not allowed to send keystrokes. (1002)`.

Set it up once:

1. **System Settings → Privacy & Security → Accessibility**
2. Enable **Terminal** and **claude** (click + to add if missing — `which claude` shows the path).
3. Quit and relaunch Claude Code (Accessibility state is captured at launch).

`window` mode uses `do script` with no keystrokes and needs no Accessibility permission.

## Caveats

- Apple Terminal only. Other terminals (`iTerm.app`, `WarpTerminal`, `ghostty`) trigger a stderr warning and the script falls back to driving Terminal.app anyway.
- If `tab` is requested but no Terminal window is open, the script falls back to `window` automatically.
- Requires `osascript` and `claude` on `$PATH`.
