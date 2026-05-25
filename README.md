# Skills

AI skills to get more done.

- **`/claude-samefolder [tab|window]`** — opens a fresh `claude` session in a new Terminal tab (default) or window, `cd`'d into your current project. (Plain Cmd+T lands in `~`.)
- **`/claude-forkchat [tab|window]`** — forks the *current* conversation alongside this one. Like built-in `/branch`, but keeps both threads alive instead of swapping the current terminal into the fork. Backed by `claude --resume <id> --fork-session`.
- **`/claude-statusline`** — sets up the Claude Code status line to show `cwd [branch] [worktree]  model  effort  context%` on every turn. Installs a small renderer to `~/.claude/statusline.sh` and merges `.statusLine` into `settings.json` (backed up first) — the same end state `/statusline` produces, but pinned to this exact layout.
- **`/audit-website-referencing`** — audits a website codebase against Google's Search Quality Rater Guidelines (E-E-A-T, YMYL, page purpose, attribution, spam patterns, trust signals). Writes a findings report and offers to fix high-severity issues one at a time. A content-quality and trust audit — not a technical SEO/Lighthouse check.
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
