# Skills

- **`/architecture`** — designs, reviews, and refactors codebase *structure* (module boundaries, layering, where new code lives, naming) to satisfy senior human reviewers and stay legible to AI agents. Greenfield: test-first by default. Brownfield: conform to the prevailing pattern, split god-files before they grow, and ratchet toward TDD without rewriting everything. Triggers on "design the architecture", "where should this live", "review the structure", "is this the right abstraction", or any change crossing module boundaries — not for single-file edits or styling.
- **`/dig-into <topic> [startingPoint]`** — explains something *gradually*, top-down instead of as one info-dump: builds a layered map, shows the lay of the land, then descends one level at a time with a check-in after each — calibrated to what you already know, so you skip the familiar and dig into the rest. Works on a codebase (shallow-recons it first) or an abstract concept, with a "you are here" breadcrumb so you never get lost. For onboarding to a new project or learning any topic at the right depth. Cross-tool; uses checkbox / y-n prompts to let you steer.
- **`/claude-samefolder [tab|window]`** — opens a fresh `claude` session in a new Terminal tab (default) or window, `cd`'d into your current project. (Plain Cmd+T lands in `~`.)
- **`/claude-forkchat [tab|window]`** — forks the *current* conversation alongside this one. Like built-in `/branch`, but keeps both threads alive instead of swapping the current terminal into the fork. Backed by `claude --resume <id> --fork-session`.
- **`/claude-toggle-permissions [tab|window]`** — continues the *current* conversation in a new tab/window with the bypass-permissions mode **flipped** (`--dangerously-skip-permissions` on↔off). Since that flag is launch-time-only, it forks the session (`claude --resume <id> --fork-session`) so you keep all the context; the toggled copy is named `-bypass`/`-safe` so you can tell them apart, and both sessions stay alive.
- **`/claude-statusline`** — sets up the Claude Code status line to show `context% $cost  cwd [branch] [worktree]  model  effort` on every turn. Installs a small renderer to `~/.claude/statusline.sh` and merges `.statusLine` into `settings.json` (backed up first) — the same end state `/statusline` produces, but pinned to this exact layout.
- **`/web-audit-with-google-guidelines`** — audits a website codebase against Google's Search Quality Rater Guidelines (E-E-A-T, YMYL, page purpose, attribution, spam patterns, trust signals). Writes a findings report and offers to fix high-severity issues one at a time. A content-quality and trust audit — not a technical SEO/Lighthouse check.
- **`/schedule-local <what to schedule>`** — schedules persistent local background jobs on macOS (launchd-backed, cron syntax): plain shell commands or agentic `claude -p` prompts run headless. Survives reboots and catches up after sleep — unlike crontab, which silently skips runs missed while the Mac is asleep. With no arguments it prints a numbered dashboard of all jobs with per-job run-now/remove/update commands ("run 2", "delete 3"). Jobs live in `~/.local/state/schedule-local/` and keep running even if the skill is uninstalled.
- **`/google-io-2026`** — a categorized, sourced reference catalog of every AI product, model, and feature Google announced at Google I/O 2026 (Gemini 3.5, Gemini Omni, Antigravity, Search AI, Workspace, Android XR, pricing tiers). Answers "what is X", "which Google AI tool for Y", and "was this actually announced at I/O 2026" — with official links and status tags. Reference-only.

## Install

**Install all skills from this repo:**

```bash
npx skills add bpkey/skills -y -g
```

**Install a single skill:**

```bash
npx skills add bpkey/skills -s <skill-name> -y -g
```

Replace `<skill-name>` with the folder name (e.g. `claude-forkchat`).

**Update:**

```bash
npx skills update
```

**Uninstall:**

```bash
npx skills remove <skill-name> [<skill-name> ...] -y -g
```

## Requirements

Each skill checks its own prerequisites and tells you what to do if something's missing (e.g. extra OS permissions on first run) — no need to set anything up in advance.
