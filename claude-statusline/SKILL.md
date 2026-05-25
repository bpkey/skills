---
name: claude-statusline
description: Set up Claude Code's status line to show, left to right, the current working directory, the git branch in [brackets], the git worktree in [brackets], the model name, the reasoning effort level, and the percentage of the context window used. Use whenever the user invokes /claude-statusline, or asks to "set up my status line", "configure the statusline", "show branch and context in my status bar", "add the model and context percent to my status line", "give me a status line with cwd, branch, model, and context %", or otherwise wants this specific status line layout in Claude Code. Claude Code only — it writes ~/.claude/settings.json's .statusLine key, which no other AI tool reads.
---

# /claude-statusline

Configures the Claude Code status line to render this layout on every turn:

```
<cwd> [<branch>] [<worktree>]  <model>  <effort>  <context%>
```

For example:

```
~/repo/skills [main] [feat-x]  Opus 4.7  high  37%
```

This is the same end state the built-in `/statusline` command produces, but pinned to this exact layout and installed deterministically — no LLM regenerates the script each time, so the result is identical on every machine.

## What each segment is

| Segment | Source | Notes |
|---|---|---|
| cwd | `.workspace.current_dir` (falls back to `.cwd`) | `$HOME` shown as `~` |
| `[branch]` | `git branch --show-current` in the session's cwd | branch isn't in the JSON, so it's read from git |
| `[worktree]` | `.workspace.git_worktree` (falls back to `.worktree.name`) | only shown in a linked git worktree |
| model | `.model.display_name` | e.g. `Opus 4.7` |
| effort | `.effort.level` | only shown on models with a reasoning-effort knob |
| context% | `.context_window.used_percentage` | omitted until the first model response sets it |

Any segment whose data isn't available is dropped, so the line stays clean outside a repo, before the first response, or on a model with no effort setting.

## How to run

Run the installer and relay its output to the user:

```bash
~/.claude/skills/claude-statusline/scripts/install.sh
```

It does two things, both safe to re-run:

1. Copies `scripts/statusline.sh` to `~/.claude/statusline.sh` (a stable path, so the status line keeps working even if this skill is later moved or uninstalled).
2. Backs up `~/.claude/settings.json`, then **merges** `.statusLine` into it with `jq` — existing hooks, plugins, and permissions are left untouched.

Echo the script's stdout back to the user. On a non-zero exit, surface stderr verbatim. The status line shows up on the user's next message; no restart needed.

## Caveats

- **Claude Code only.** The installer detects the host tool first and exits with an explanation if it isn't Claude Code, because `.statusLine` is a setting only Claude Code reads.
- Requires `jq` to merge `settings.json` safely. If `jq` is missing, the installer still drops in the renderer and prints the one key for the user to paste in by hand.
- The renderer itself degrades gracefully without `jq`, falling back to a bare current-directory path.

## Changing the layout later

To tweak what's shown, edit `~/.claude/statusline.sh` directly (it's a small, commented bash script), or re-run the installer to restore this skill's version. To remove the status line entirely, delete the `.statusLine` key from `~/.claude/settings.json`.
