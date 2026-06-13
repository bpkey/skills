---
name: schedule-local
description: Schedule persistent local background jobs on macOS via launchd — plain shell commands or agentic Claude prompts run headless on a cron schedule, surviving reboots and catching up after sleep. Use whenever the user invokes /schedule-local, or asks to "schedule a job", "run this every morning", "cron this command", "set up a recurring local task", "have Claude check something every day", "list my scheduled jobs", "show the job dashboard", or wants to delete, reschedule, or manually trigger an existing local job — even if they say "cron" rather than launchd, and even if they don't name the skill. With no arguments (or "list"/"dashboard"/"overview") it prints a numbered markdown table of all jobs with per-job run-now/remove/update commands. macOS only. Agentic jobs run claude -p with --dangerously-skip-permissions and need the claude CLI installed; shell jobs work without it.
---

# /schedule-local — persistent local scheduled jobs (macOS)

Schedules jobs that run on this Mac on a cron schedule, independent of any Claude
session. The user describes the schedule in cron's familiar 5-field syntax (or
natural language that you translate to it), but the backend is a launchd
LaunchAgent per job — deliberately, because classic cron silently skips any run
that comes due while the Mac is asleep, whereas launchd coalesces missed runs
into one run at wake. Schedules are local time. launchd will not *wake* a
sleeping Mac; the job fires when it next wakes.

All commands go through the bundled CLI:

```bash
python3 ~/.claude/skills/schedule-local/scripts/schedule-local.py <subcommand> ...
```

State lives in `~/.local/state/schedule-local/` (job registry, per-job logs, and
a stable copy of the CLI that the LaunchAgents reference). Because of that
stable copy, **jobs keep running even if this skill is updated or uninstalled**
— the only way to stop a job is `remove` (or manual `launchctl bootout`).

## Two kinds of job

- **shell** (`--command`) — a literal shell command, script path, or binary
  invocation. Pick this when the user gives you something directly runnable.
- **agent** (`--prompt`) — a task needing reading, judgment, or multi-step work
  ("check my PRs and summarize what needs attention"). Runs
  `claude -p "<prompt>" --dangerously-skip-permissions` headless. Always tell
  the user explicitly that agentic jobs run **fully unattended with permission
  checks disabled** when you create one — they are trusting the prompt with the
  same access an unattended `claude --dangerously-skip-permissions` session has.

Both run via `/bin/zsh -lc` in the job's workdir, so the user's `~/.zshenv` /
`~/.zprofile` (PATH, exported keys) are loaded — but `~/.zshrc` is NOT (login
non-interactive shell). If a job needs an env var that only lives in `.zshrc`,
tell the user to move the export to `.zshenv` or `.zprofile`.

## Interpreting a scheduling request

1. **Classify** shell vs agent (see above). When the request is genuinely
   ambiguous between the two, prefer shell — it is cheaper and more predictable
   — and say so.
2. **Compose the cron expression** from the natural-language schedule. Supported
   syntax — 5 fields (minute hour day-of-month month day-of-week), `*`, lists
   `1,15`, ranges `9-17`, steps `*/5` and `9-17/2`, 3-letter names (`mon-fri`,
   `jan`), and `@hourly @daily @midnight @weekly @monthly @yearly`. `@reboot`
   is rejected. When day-of-month and day-of-week are both restricted, cron's
   either-matches semantics are preserved.
3. **Derive the id** — a short kebab slug from the task (`morning-report`,
   `nightly-backup`). The CLI enforces `^[a-z0-9][a-z0-9-]{0,40}$`.
4. **Pick the workdir** — the current project directory when the task clearly
   references it; otherwise omit `--workdir` (defaults to `~`).
5. **Always pass `--description`** — a one-line human summary; the dashboard
   shows it.
6. Ask at most ONE clarifying question, and only when genuinely ambiguous
   (e.g. "every morning" with no time → ask the time). Otherwise pick sensible
   defaults and state them in your reply.

## Command reference

```bash
# SL=~/.claude/skills/schedule-local/scripts/schedule-local.py  (shorthand used below;
# invoke as `python3 "$SL" ...` — quoted, so it works in zsh and bash alike)

python3 "$SL" add --id <slug> --cron "<expr>" --command "<sh>"   [--workdir <dir>] [--description "<text>"]
python3 "$SL" add --id <slug> --cron "<expr>" --prompt "<text>"  [--workdir <dir>] [--description "<text>"]
python3 "$SL" list                  # numbered markdown dashboard (also the no-args default)
python3 "$SL" run-now <id>          # trigger immediately (launchctl kickstart)
python3 "$SL" remove <id>           # unload agent, delete plist + registry entry + log
python3 "$SL" update <id> [--cron ...] [--command ...|--prompt ...] [--workdir ...] [--description ...]
python3 "$SL" logs <id> [--lines N] # tail of the per-job log (default 40 lines)
```

**Example — shell job** ("back up my notes every night at 2am"):

```bash
python3 "$SL" add --id notes-backup --cron "0 2 * * *" \
  --command "rsync -a ~/notes/ ~/Backups/notes/" \
  --description "Nightly rsync of ~/notes to ~/Backups"
```

**Example — agent job** ("every weekday at 7:30 have Claude summarize overnight CI failures in my api repo"):

```bash
python3 "$SL" add --id ci-morning-report --cron "30 7 * * 1-5" \
  --prompt "Check the CI status of this repo and write a short summary of overnight failures to ci-report.md" \
  --workdir ~/repo/api \
  --description "Weekday 07:30 CI failure summary"
```

## Dashboard and numbered references

When the user invokes the skill with no arguments, or says "list", "dashboard",
or "overview", run `list` and relay its output verbatim — it is already
formatted markdown: a numbered table plus, per job, the exact `run-now` /
`remove` / `update` commands.

The row numbers are a conversational shortcut. After you have shown the
dashboard, map "run 2", "delete 1", "reschedule 3 to 8am" to the job id in that
row of the table you just displayed, then run the matching CLI command. The CLI
itself only accepts ids — numbers are your mapping job, so re-list first if
there is any chance the numbering has changed since it was last shown.

`list` also self-heals visibility: it flags registry entries whose plist has
gone missing (with the command to recreate it) and orphan
`com.schedule-local.*` plists no longer in the registry (with cleanup commands).

## After adding a job

Offer to verify immediately: `run-now <id>` then `logs <id>`. Do this
especially for the user's first agentic job — it surfaces a missing `claude`
binary or auth problem right away instead of at 7am tomorrow. Each run logs
`START` / `END exit=<code>` lines around the payload's own output. Logs are
tail-truncated at 1 MiB, and launchd never overlaps runs of the same job — a
fire that comes due while the previous run is still going is skipped.

## Requirements and limits

- **macOS only** (launchd LaunchAgents). The CLI exits with a clear message on
  other platforms — point Linux users at crontab or systemd timers.
- **python3** — present once Xcode Command Line Tools are installed.
- **claude CLI** — needed only for agent jobs, at job *runtime*; `add --prompt`
  preflights for it and warns (job still created).
- The Mac must be awake (or asleep-then-woken) for jobs to run; nothing here
  wakes the machine on a schedule.
- Each job registers in System Settings → Login Items & Extensions as a
  background item named `schedule-local.<id>` (a tiny per-job launcher in
  `~/.local/state/schedule-local/launchers/`), so macOS's "App Background
  Activity" notification names the job instead of a generic "python3".
