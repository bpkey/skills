# Project rules — `bpkey/skills`

## Skill naming convention

New skills in this repo use **lowercase-with-dashes** (kebab-case) for both:

- The folder name at the repo root (e.g. `claude-newtab/`)
- The `name:` field in the skill's `SKILL.md` frontmatter (which is what becomes the slash command)

Skills that only work with a single tool — e.g. only useful inside Claude Code, only useful inside Cursor — prefix the name with the tool, in the form **`<toolname>-<feature>`**:

- `claude-newtab` — Claude Code only
- `claude-newwindow` — Claude Code only
- `cursor-something` — Cursor only

Skills that work across multiple tools skip the prefix and just describe the feature: `to-prd`, `grill-me`, etc.

## Tool-specific skills must declare incompatibility at runtime

A skill prefixed with `<toolname>-` (e.g. `claude-*`, `cursor-*`) is, by definition, *not* expected to work in any other tool. Because `npx skills` installs every skill into every detected AI client, a user running `cursor-foo` from inside Claude Code (or vice versa) will otherwise see a confusing failure.

To prevent this, every tool-specific skill **must**, as the first thing it does when invoked:

1. Detect which AI tool is currently running it (env vars like `CLAUDE_CODE`, `CURSOR_*`, `WINDSURF_*`, the parent process, etc. — pick whatever signal is most reliable for the target tool).
2. If the current tool is **not** the supported one, print an informational note that includes:
   - The detected current tool's name (or "unknown tool" if it can't be detected).
   - The single tool this skill *is* designed for.
   - A one-sentence explanation of *why* it won't work in the current tool (e.g. "needs to read Claude Code's session transcript from `~/.claude/projects/`, which only Claude Code writes" — not just "won't work here").
3. Exit gracefully (non-zero is fine) without attempting the operation.

The note should be informational, not apologetic — the user installed it knowing it's tool-specific, the message just confirms the situation and the reason so they can decide what to do.

## Skill structure

Each skill is a top-level folder containing:

- `SKILL.md` with YAML frontmatter (at minimum `name:` and `description:`) — this is what `npx skills` and Claude Code both read.
- Optional `scripts/` subdirectory for shell scripts the skill invokes.

Run `/skill-creator` inside Claude Code for the canonical SKILL.md anatomy — don't reproduce the frontmatter schema from memory.

## Skills must be generic — they ship to other people

Every skill in this repo is **public** and gets installed by anyone via `npx skills add bpkey/skills`. The person running a skill is almost never this repo's author and almost never on this machine. So a skill must work for **any user on any machine**, deriving everything it needs at runtime:

- **Never hardcode this author's paths** (`~/repo/...`, `/Users/olivier/...`), usernames, repo names, or machine-specific layout. Compute paths at runtime (`git rev-parse --show-toplevel`, `$HOME`, `${XDG_CONFIG_HOME:-$HOME/.config}`, `basename`, etc.).
- **Never assume other private skills or tools are present** (e.g. `/ide`, `tools-config/bin` scripts, the author's personal config). If a skill needs something, it must detect or create it itself, or degrade gracefully.
- **Persist state in standard, per-user locations**, not author-specific ones — e.g. `${XDG_CONFIG_HOME:-$HOME/.config}/<skill>/…` or `~/.claude/…`, keyed by the *current* user/repo/cwd, never a baked-in path.
- You **may** inspect the author's own setup for background understanding while building, but **never bake those specifics into the shipped skill** — only the generic, runtime-derived form belongs in the committed code.

When in doubt, ask: "if a stranger installed only this one skill on a fresh machine, would it still work?" If not, it's not generic enough.

## Install path

Users install via [`npx skills`](https://github.com/vercel-labs/skills) (the Vercel Labs CLI), not a custom installer. The repo's job is only to host compliant skill folders — frontmatter with `name` + `description`, optional `scripts/`. No bespoke install machinery to maintain.
