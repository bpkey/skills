---
name: claude-statusline
description: Set up Claude Code's status line to show, left to right, the percentage of the context window used, the conversation cost in USD, a compact account+usage token (the signed-in Anthropic account's @name joined with the 5-hour and 7-day plan-usage percentages, e.g. @example_12%_40%), a short model name carrying that model's own weekly-limit percentage and the hours until it resets when the plan has such a window (e.g. fable(78%..19hr)), the reasoning effort level, the last two components of the working directory, the git branch behind a fork glyph, and the git worktree behind a joined-squares glyph. Use whenever the user invokes /claude-statusline, or asks to "set up my status line", "configure the statusline", "show branch and context in my status bar", "add the model and context percent to my status line", "show my weekly model usage in the status line", "give me a status line with cwd, branch, model, and context %", or otherwise wants this specific status line layout in Claude Code. Claude Code only — it writes ~/.claude/settings.json's .statusLine key, which no other AI tool reads.
---

# /claude-statusline

Configures the Claude Code status line to render this layout on every turn:

```
<context%> <$cost> <@account_5h%_7d%> <model>(<model week%>) <effort>  <cwd> ⑂ <branch> ⧉ <worktree>
```

For example:

```
12% $1.23 @example_12%_40% opus|1M high  repo/skills ⑂ main ⧉ feat-x
12% $1.23 @example_12%_40% fable(78%..19hr) high  repo/skills ⑂ main ⧉ feat-x
```

The second line is a plan that meters that model on its own weekly window:
78% of it is spent and it resets in 19 hours.

This is the same end state the built-in `/statusline` command produces, but pinned to this exact layout and installed deterministically — no LLM regenerates the script each time, so the result is identical on every machine.

## What each segment is

| Segment | Source | Notes |
|---|---|---|
| context% | `.context_window.used_percentage` | omitted until the first model response sets it; **orange at 25–34%, red at 35%+**, plain below 25% |
| $cost | `.cost.total_cost_usd` | conversation cost in USD, rounded to cents; omitted when not reported |
| @account_5h%_7d% | `.oauthAccount.emailAddress` in `~/.claude.json` + `.rate_limits.five_hour` / `.seven_day` `.used_percentage` | one underscore-joined token: the account domain's first label (`@example`, not `@example.com`) so two accounts are told apart at a glance, then usage against the rolling 5-hour and 7-day plan limits; each part drops out when unavailable |
| model | `.model.display_name` | shortened to the family name plus a `\|1M` marker for long-context variants — `Opus 5 (1M context)` renders as `opus\|1M` |
| (model week%..hr) | `GET /api/oauth/usage`, the `weekly_scoped` entry whose `scope.model.display_name` matches the model family | the **current model's own weekly limit** — the bar `/usage` draws as "Current week (Fable)" — followed by the hours until it resets: `fable(78%..19hr)`. Orange from 75%, red from 90%. Absent when the plan has no per-model window for that model. Not in the status-line JSON, so it is fetched and cached; see the caveat below |
| effort | `.effort.level` | only shown on models with a reasoning-effort knob |
| cwd | `.workspace.current_dir` (falls back to `.cwd`) | only the **last two path components**, so a deep path can't crowd out everything else; `$HOME` shows as `~` |
| `⑂ branch` | `git branch --show-current` in the session's cwd | branch isn't in the JSON, so it's read from git — using the full path, before it's shortened |
| `⧉ worktree` | `.workspace.git_worktree` (falls back to `.worktree.name`) | only shown in a linked git worktree |
| @domain | `.oauthAccount.emailAddress` in `~/.claude.json` | the signed-in Anthropic account's domain, so two accounts are told apart at a glance; not in the status-line JSON, so it's read from the CLI's own config |
| 5h% / 7d% | `.rate_limits.five_hour` / `.seven_day` `.used_percentage` | account usage against the rolling 5-hour and 7-day plan limits; each drops out when the API doesn't report it |

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
- **The per-model weekly percentage is fetched, not handed over.** The status-line JSON carries only the account-wide 5-hour and 7-day windows; Claude Code keeps the per-model buckets on an object it does not pipe to the script. So the renderer calls `GET /api/oauth/usage` itself — the same endpoint `/usage` reads — at most once a minute across every running session (a `mkdir` lock elects one refresher), and caches the answer in `~/.claude/cache/oauth-usage.json`. **Rendering never waits on that call**: the fetch runs detached, a stale cache is used as it stands, and a missing one simply drops the segment. The OAuth token comes from the login Keychain on macOS (`Claude Code-credentials`) or `~/.claude/.credentials.json` on Linux, and reaches curl through a config on stdin, so it never appears in a command line or a process listing. Delete the `refresh_usage` function and the block that reads its cache to opt out; everything else keeps working.
- Requires `jq` to merge `settings.json` safely. If `jq` is missing, the installer still drops in the renderer and prints the one key for the user to paste in by hand.
- The renderer itself degrades gracefully without `jq`, falling back to a bare current-directory path.
- **The two glyphs rely on font fallback.** `⑂` (U+2442 OCR FORK) marks the branch and `⧉` (U+29C9 TWO JOINED SQUARES) marks the worktree, so the two can't be confused for each other the way two bracketed names can. Both are ordinary BMP characters, not private-use Nerd Font icons, so no patched font is needed — but most monospace fonts don't carry them and the terminal substitutes a symbol font (Apple Symbols on macOS). If your terminal shows a box instead, swap them for ASCII markers in `~/.claude/statusline.sh` (see below).

## Changing the layout later

To tweak what's shown, edit `~/.claude/statusline.sh` directly (it's a small, commented bash script), or re-run the installer to restore this skill's version. To remove the status line entirely, delete the `.statusLine` key from `~/.claude/settings.json`.
