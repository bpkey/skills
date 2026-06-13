#!/usr/bin/env python3
"""schedule-local — persistent local scheduled jobs on macOS, backed by launchd.

Jobs are defined with standard 5-field cron expressions, translated to
LaunchAgent StartCalendarInterval entries. Unlike cron, launchd coalesces
runs missed while the Mac was asleep into one run at wake.

A job is either a shell command or an "agent" prompt run headless via
`claude -p <prompt> --dangerously-skip-permissions`.

State lives in ~/.local/state/schedule-local/ (registry, logs, and a stable
copy of this script that the LaunchAgent plists reference — so jobs keep
running even if the skill that bundles this file is updated or removed).

Python 3.9 compatible, stdlib only.
"""

import argparse
import fcntl
import json
import os
import plistlib
import re
import shlex
import subprocess
import sys
import time
from contextlib import contextmanager
from datetime import datetime
from pathlib import Path

STATE_DIR = Path.home() / ".local" / "state" / "schedule-local"
LOGS_DIR = STATE_DIR / "logs"
REGISTRY = STATE_DIR / "jobs.json"
LOCK_FILE = STATE_DIR / ".lock"
STABLE_SCRIPT = STATE_DIR / "schedule-local.py"
LAUNCH_AGENTS = Path.home() / "Library" / "LaunchAgents"
LABEL_PREFIX = "com.schedule-local."

ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]{0,40}$")
MAX_CALENDAR_ENTRIES = 512
LOG_MAX_BYTES = 1024 * 1024  # truncate above this...
LOG_KEEP_BYTES = 256 * 1024  # ...keeping this much tail

MONTH_NAMES = {"jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
               "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12}
DAY_NAMES = {"sun": 0, "mon": 1, "tue": 2, "wed": 3, "thu": 4, "fri": 5, "sat": 6}
DAY_DISPLAY = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

SHORTCUTS = {
    "@hourly": "0 * * * *",
    "@daily": "0 0 * * *",
    "@midnight": "0 0 * * *",
    "@weekly": "0 0 * * 0",
    "@monthly": "0 0 1 * *",
    "@yearly": "0 0 1 1 *",
    "@annually": "0 0 1 1 *",
}


def die(msg):
    sys.stderr.write("schedule-local: %s\n" % msg)
    sys.exit(1)


def now_iso():
    return datetime.now().astimezone().isoformat(timespec="seconds")


# ---------------------------------------------------------------- cron parsing

class CronError(ValueError):
    pass


def _parse_value(text, lo, hi, names, field_name):
    key = text.strip().lower()
    if key in names:
        return names[key]
    try:
        val = int(text)
    except ValueError:
        raise CronError("%s: %r is not a number or recognized name" % (field_name, text))
    if not lo <= val <= hi:
        raise CronError("%s: %d out of range %d-%d" % (field_name, val, lo, hi))
    return val


def _parse_field(field, lo, hi, names, field_name):
    """Return None for unrestricted (*), else a sorted list of ints."""
    if field == "*":
        return None
    values = set()
    for token in field.split(","):
        token = token.strip()
        if not token:
            raise CronError("%s: empty list item" % field_name)
        step = 1
        if "/" in token:
            base, step_s = token.split("/", 1)
            try:
                step = int(step_s)
            except ValueError:
                raise CronError("%s: step %r is not a number" % (field_name, step_s))
            if step < 1:
                raise CronError("%s: step must be >= 1" % field_name)
        else:
            base = token
        if base == "*":
            lo_b, hi_b = lo, hi
        elif "-" in base:
            a_s, b_s = base.split("-", 1)
            lo_b = _parse_value(a_s, lo, hi, names, field_name)
            hi_b = _parse_value(b_s, lo, hi, names, field_name)
            if lo_b > hi_b:
                raise CronError("%s: range %s is reversed (wraparound not supported)"
                                % (field_name, base))
        else:
            if step != 1:
                raise CronError("%s: a step requires a range or *, got %r"
                                % (field_name, token))
            values.add(_parse_value(base, lo, hi, names, field_name))
            continue
        values.update(range(lo_b, hi_b + 1, step))
    return sorted(values)


def parse_cron(expr):
    """Parse a 5-field cron expression (or @shortcut).

    Returns (minute, hour, dom, month, dow) where each is None (unrestricted)
    or a sorted list of ints. dow is normalized to 0-6 (0=Sunday).
    """
    expr = expr.strip()
    if expr.startswith("@"):
        if expr.lower() == "@reboot":
            raise CronError("@reboot is not supported (that is launchd RunAtLoad, "
                            "out of scope) — use a time-based schedule")
        rewritten = SHORTCUTS.get(expr.lower())
        if rewritten is None:
            raise CronError("unknown shortcut %r (known: %s)"
                            % (expr, " ".join(sorted(SHORTCUTS))))
        expr = rewritten
    fields = expr.split()
    if len(fields) != 5:
        raise CronError("expected 5 fields (minute hour day-of-month month "
                        "day-of-week), got %d in %r" % (len(fields), expr))
    minute = _parse_field(fields[0], 0, 59, {}, "field 1 (minute)")
    hour = _parse_field(fields[1], 0, 23, {}, "field 2 (hour)")
    dom = _parse_field(fields[2], 1, 31, {}, "field 3 (day-of-month)")
    month = _parse_field(fields[3], 1, 12, MONTH_NAMES, "field 4 (month)")
    dow = _parse_field(fields[4], 0, 7, DAY_NAMES, "field 5 (day-of-week)")
    if dow is not None:
        dow = sorted(set(0 if d == 7 else d for d in dow))
    return (minute, hour, dom, month, dow)


def cron_to_calendar_intervals(parsed):
    """Expand parsed cron fields to a list of StartCalendarInterval dicts.

    When both day-of-month and day-of-week are restricted, cron fires when
    EITHER matches, but keys within one launchd dict are ANDed — so emit two
    dict families (one without Weekday, one without Day) to reproduce the OR.
    """
    minute, hour, dom, month, dow = parsed

    def expand(dom_part, dow_part):
        combos = [{}]
        for key, vals in (("Minute", minute), ("Hour", hour), ("Day", dom_part),
                          ("Month", month), ("Weekday", dow_part)):
            if vals is None:
                continue
            combos = [dict(c, **{key: v}) for c in combos for v in vals]
        return combos

    if dom is not None and dow is not None:
        entries = expand(dom, None) + expand(None, dow)
    else:
        entries = expand(dom, dow)
    unique = []
    for e in entries:
        if e not in unique:
            unique.append(e)
    if len(unique) > MAX_CALENDAR_ENTRIES:
        raise CronError("schedule expands to %d calendar entries (max %d) — "
                        "use a coarser expression" % (len(unique), MAX_CALENDAR_ENTRIES))
    return unique


def humanize_cron(parsed):
    """Best-effort human reading for common shapes; None when unrecognized."""
    minute, hour, dom, month, dow = parsed
    if dom is not None or month is not None:
        return None

    def day_set_text(days):
        if days == list(range(days[0], days[-1] + 1)) and len(days) > 1:
            return "%s–%s" % (DAY_DISPLAY[days[0]], DAY_DISPLAY[days[-1]])
        return ", ".join(DAY_DISPLAY[d] for d in days)

    if hour is None and dow is None:
        if minute is None:
            return "every minute"
        if len(minute) == 1:
            return "hourly at :%02d" % minute[0]
        n = minute[1] - minute[0]
        if n > 0 and minute == list(range(minute[0], 60, n)):
            return "every %d min" % n
        return None
    if hour is not None and len(hour) == 1 and minute is not None and len(minute) == 1:
        at = "%02d:%02d" % (hour[0], minute[0])
        if dow is None:
            return "daily at %s" % at
        return "%s %s" % (at, day_set_text(dow))
    return None


# ------------------------------------------------------------- registry & lock

@contextmanager
def registry_lock():
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    with open(LOCK_FILE, "w") as fh:
        fcntl.flock(fh, fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(fh, fcntl.LOCK_UN)


def load_registry():
    if not REGISTRY.exists():
        return {"version": 1, "jobs": {}}
    try:
        with open(REGISTRY) as fh:
            return json.load(fh)
    except (json.JSONDecodeError, OSError) as e:
        die("registry %s is unreadable (%s) — fix or delete it" % (REGISTRY, e))


def save_registry(reg):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    tmp = REGISTRY.with_suffix(".json.tmp")
    with open(tmp, "w") as fh:
        json.dump(reg, fh, indent=2, sort_keys=True)
        fh.write("\n")
    os.replace(tmp, REGISTRY)


def self_sync():
    """Copy this script to the stable path the LaunchAgent plists reference."""
    me = Path(os.path.realpath(__file__))
    if STABLE_SCRIPT.exists() and me.samefile(STABLE_SCRIPT):
        return
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    tmp = STABLE_SCRIPT.with_suffix(".py.tmp")
    tmp.write_bytes(me.read_bytes())
    tmp.chmod(0o755)
    os.replace(tmp, STABLE_SCRIPT)


# ------------------------------------------------------------------- launchctl

def label_for(job_id):
    return LABEL_PREFIX + job_id


def plist_path_for(job_id):
    return LAUNCH_AGENTS / (label_for(job_id) + ".plist")


def log_path_for(job_id):
    return LOGS_DIR / (job_id + ".log")


def launchctl(*args, check=False):
    proc = subprocess.run(["launchctl"] + list(args),
                          capture_output=True, text=True)
    if check and proc.returncode != 0:
        die("launchctl %s failed: %s" % (" ".join(args),
                                         proc.stderr.strip() or proc.stdout.strip()))
    return proc


def gui_domain():
    return "gui/%d" % os.getuid()


def write_plist(job):
    LAUNCH_AGENTS.mkdir(parents=True, exist_ok=True)
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    log = str(log_path_for(job["id"]))
    data = {
        "Label": label_for(job["id"]),
        "ProgramArguments": ["/usr/bin/python3", str(STABLE_SCRIPT),
                             "_run", job["id"]],
        "StartCalendarInterval": cron_to_calendar_intervals(parse_cron(job["cron"])),
        "StandardOutPath": log,
        "StandardErrorPath": log,
    }
    path = plist_path_for(job["id"])
    with open(path, "wb") as fh:
        plistlib.dump(data, fh)
    return path


def load_job(job_id):
    job = load_registry()["jobs"].get(job_id)
    if job is None:
        die("no job %r — run `list` to see existing jobs" % job_id)
    return job


def reload_agent(job):
    path = write_plist(job)
    launchctl("bootout", "%s/%s" % (gui_domain(), label_for(job["id"])))
    launchctl("bootstrap", gui_domain(), str(path), check=True)


def preflight_claude():
    proc = subprocess.run(["/bin/zsh", "-lc", "command -v claude"],
                          capture_output=True, text=True)
    if proc.returncode != 0:
        sys.stderr.write(
            "schedule-local: WARNING — `claude` was not found in a login shell.\n"
            "  Agentic jobs will fail at run time until the claude CLI is installed\n"
            "  and reachable from /bin/zsh -lc (PATH set in ~/.zshenv or ~/.zprofile).\n")


# -------------------------------------------------------------------- commands

def shorten_home(path):
    return str(path).replace(str(Path.home()), "~")


def skill_invocation():
    return "python3 ~/.claude/skills/schedule-local/scripts/schedule-local.py"


def validate_payload_args(args):
    if bool(args.command) == bool(args.prompt):
        die("exactly one of --command or --prompt is required")


def resolve_workdir(workdir):
    path = Path(workdir).expanduser().resolve() if workdir else Path.home()
    if not path.is_dir():
        sys.stderr.write("schedule-local: WARNING — workdir %s does not exist; "
                         "runs will fall back to ~\n" % path)
    return str(path)


def describe_job(job, parsed):
    human = humanize_cron(parsed)
    schedule = "`%s`%s" % (job["cron"], " (%s)" % human if human else "")
    payload = job["command"] if job["type"] == "shell" else job["prompt"]
    print("Scheduled job %r" % job["id"])
    print("  schedule:  %s" % schedule)
    print("  type:      %s" % job["type"])
    print("  payload:   %s" % payload)
    print("  workdir:   %s" % shorten_home(job["workdir"]))
    print("  log:       %s" % shorten_home(log_path_for(job["id"])))
    print("  agent:     %s" % label_for(job["id"]))
    print("Verify with:")
    print("  %s run-now %s" % (skill_invocation(), job["id"]))
    print("  %s logs %s" % (skill_invocation(), job["id"]))


def cmd_add(args):
    if not ID_RE.match(args.id):
        die("invalid id %r — use a kebab slug (lowercase letters, digits, "
            "hyphens, max 41 chars)" % args.id)
    validate_payload_args(args)
    try:
        parsed = parse_cron(args.cron)
        cron_to_calendar_intervals(parsed)
    except CronError as e:
        die("cron %r: %s" % (args.cron, e))
    self_sync()
    with registry_lock():
        reg = load_registry()
        if args.id in reg["jobs"]:
            die("job %r exists — use `update %s ...` or `remove %s`"
                % (args.id, args.id, args.id))
        job = {
            "id": args.id,
            "description": args.description or "",
            "cron": args.cron,
            "type": "shell" if args.command else "agent",
            "command": args.command,
            "prompt": args.prompt,
            "workdir": resolve_workdir(args.workdir),
            "created": now_iso(),
            "last_run": None,
            "last_exit": None,
        }
        reg["jobs"][args.id] = job
        save_registry(reg)
    reload_agent(job)
    if job["type"] == "agent":
        preflight_claude()
    describe_job(job, parsed)


def cmd_update(args):
    if not any([args.cron, args.command, args.prompt, args.workdir,
                args.description is not None]):
        die("nothing to update — pass at least one of --cron --command "
            "--prompt --workdir --description")
    if args.command and args.prompt:
        die("pass --command or --prompt, not both")
    self_sync()
    with registry_lock():
        reg = load_registry()
        job = reg["jobs"].get(args.id)
        if job is None:
            die("no job %r — run `list` to see existing jobs" % args.id)
        if args.cron:
            try:
                parsed = parse_cron(args.cron)
                cron_to_calendar_intervals(parsed)
            except CronError as e:
                die("cron %r: %s" % (args.cron, e))
            job["cron"] = args.cron
        if args.command:
            job.update(type="shell", command=args.command, prompt=None)
        if args.prompt:
            job.update(type="agent", prompt=args.prompt, command=None)
        if args.workdir:
            job["workdir"] = resolve_workdir(args.workdir)
        if args.description is not None:
            job["description"] = args.description
        save_registry(reg)
    reload_agent(job)
    if args.prompt:
        preflight_claude()
    describe_job(job, parse_cron(job["cron"]))


def cmd_remove(args):
    with registry_lock():
        reg = load_registry()
        if args.id not in reg["jobs"]:
            die("no job %r — run `list` to see existing jobs" % args.id)
        del reg["jobs"][args.id]
        save_registry(reg)
    launchctl("bootout", "%s/%s" % (gui_domain(), label_for(args.id)))
    removed = []
    for path in (plist_path_for(args.id), log_path_for(args.id)):
        if path.exists():
            path.unlink()
            removed.append(shorten_home(path))
    print("Removed job %r (unloaded %s%s)"
          % (args.id, label_for(args.id),
             "; deleted " + ", ".join(removed) if removed else ""))


def cmd_run_now(args):
    load_job(args.id)
    proc = launchctl("kickstart", "%s/%s" % (gui_domain(), label_for(args.id)))
    if proc.returncode != 0:
        die("kickstart failed (%s) — the job may already be running, or the "
            "agent is not loaded; try `update %s --cron \"<same expr>\"` to "
            "reload it" % (proc.stderr.strip() or proc.stdout.strip(), args.id))
    print("Triggered %r — output goes to %s"
          % (args.id, shorten_home(log_path_for(args.id))))
    print("  %s logs %s" % (skill_invocation(), args.id))


def cmd_logs(args):
    load_job(args.id)
    path = log_path_for(args.id)
    print("# %s" % shorten_home(path))
    if not path.exists():
        print("(no runs logged yet)")
        return
    lines = path.read_text(errors="replace").splitlines()
    for line in lines[-args.lines:]:
        print(line)


def cmd_list(_args):
    reg = load_registry()
    jobs = sorted(reg["jobs"].values(), key=lambda j: j.get("created") or "")
    inv = skill_invocation()
    print("## Scheduled jobs (schedule-local)")
    print()
    if not jobs:
        print("No jobs scheduled. Ask for one, e.g. "
              "/schedule-local run my backup script every night at 2am.")
        return
    print("| # | id | schedule | type | payload | last run | log |")
    print("|---|----|----------|------|---------|----------|-----|")
    for i, job in enumerate(jobs, 1):
        try:
            human = humanize_cron(parse_cron(job["cron"]))
        except CronError:
            human = None
        schedule = "`%s`%s" % (job["cron"], " (%s)" % human if human else "")
        payload = (job["command"] if job["type"] == "shell" else job["prompt"]) or ""
        payload = payload.replace("|", "\\|").replace("\n", " ")
        if len(payload) > 50:
            payload = payload[:49] + "…"
        if job.get("last_run"):
            last = "%s exit %s" % (job["last_run"][:16].replace("T", " "),
                                   job.get("last_exit"))
        else:
            last = "—"
        print("| %d | %s | %s | %s | %s | %s | %s |"
              % (i, job["id"], schedule, job["type"], payload, last,
                 shorten_home(log_path_for(job["id"]))))
    print()
    print("### Manage")
    for i, job in enumerate(jobs, 1):
        desc = " — %s" % job["description"] if job.get("description") else ""
        print("**%d — %s**%s" % (i, job["id"], desc))
        print("```")
        print("%s run-now %s" % (inv, job["id"]))
        print("%s remove %s" % (inv, job["id"]))
        print("%s update %s --cron \"<new expr>\"" % (inv, job["id"]))
        print("```")
        if not plist_path_for(job["id"]).exists():
            print("⚠️ plist missing for %r — recreate it with: "
                  "%s update %s --cron \"%s\""
                  % (job["id"], inv, job["id"], job["cron"]))
    orphans = []
    if LAUNCH_AGENTS.is_dir():
        for path in sorted(LAUNCH_AGENTS.glob(LABEL_PREFIX + "*.plist")):
            jid = path.name[len(LABEL_PREFIX):-len(".plist")]
            if jid not in reg["jobs"]:
                orphans.append((jid, path))
    if orphans:
        print()
        print("### Orphan agents (plist exists but job is not in the registry)")
        for jid, path in orphans:
            print("- `%s` — clean up with:" % path.name)
            print("```")
            print("launchctl bootout %s/%s%s" % (gui_domain(), LABEL_PREFIX, jid))
            print("rm %s" % shorten_home(path))
            print("```")


# ---------------------------------------------------------------------- runner

def rotate_log_inplace(path):
    """Tail-truncate keeping the same inode (launchd holds an append fd)."""
    try:
        if not path.exists() or path.stat().st_size <= LOG_MAX_BYTES:
            return
        with open(path, "r+b") as fh:
            fh.seek(-LOG_KEEP_BYTES, os.SEEK_END)
            tail = fh.read()
            fh.seek(0)
            fh.write(b"[log truncated]\n" + tail)
            fh.truncate()
    except OSError:
        pass


def cmd_internal_run(args):
    job_id = args.id
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    log = log_path_for(job_id)
    rotate_log_inplace(log)
    job = load_registry()["jobs"].get(job_id)
    with open(log, "a") as lf:
        if job is None:
            lf.write("[%s] ERROR no job %r in registry — remove the agent with: "
                     "launchctl bootout %s/%s%s && rm %s\n"
                     % (now_iso(), job_id, gui_domain(), LABEL_PREFIX, job_id,
                        plist_path_for(job_id)))
            sys.exit(78)  # EX_CONFIG
        lf.write("[%s] START %s (%s)\n" % (now_iso(), job_id, job["type"]))
        lf.flush()
        if job["type"] == "shell":
            payload = job["command"]
        else:
            payload = ("claude -p %s --dangerously-skip-permissions"
                       % shlex.quote(job["prompt"]))
        workdir = job.get("workdir") or str(Path.home())
        if not Path(workdir).is_dir():
            lf.write("[%s] WARNING workdir %s is gone — running in ~\n"
                     % (now_iso(), workdir))
            workdir = str(Path.home())
        start = time.monotonic()
        rc = subprocess.run(["/bin/zsh", "-lc", payload], cwd=workdir,
                            stdout=lf, stderr=lf).returncode
        lf.write("[%s] END %s exit=%d duration=%ds\n"
                 % (now_iso(), job_id, rc, int(time.monotonic() - start)))
    with registry_lock():
        reg = load_registry()
        if job_id in reg["jobs"]:
            reg["jobs"][job_id]["last_run"] = now_iso()
            reg["jobs"][job_id]["last_exit"] = rc
            save_registry(reg)
    sys.exit(rc)


# ------------------------------------------------------------------------ main

def main():
    if sys.platform != "darwin":
        die("this tool schedules jobs via macOS launchd LaunchAgents and only "
            "works on macOS. On Linux, use crontab or systemd timers instead.")
    parser = argparse.ArgumentParser(
        prog="schedule-local",
        description="Persistent local scheduled jobs on macOS (launchd-backed).")
    sub = parser.add_subparsers(dest="cmd")

    p = sub.add_parser("add", help="schedule a new job")
    p.add_argument("--id", required=True, help="kebab-slug job id")
    p.add_argument("--cron", required=True, help='5-field cron expression, e.g. "30 7 * * 1-5"')
    p.add_argument("--command", help="shell command to run (shell job)")
    p.add_argument("--prompt", help="prompt for headless claude -p (agent job)")
    p.add_argument("--workdir", help="working directory (default ~)")
    p.add_argument("--description", help="human-readable description")
    p.set_defaults(func=cmd_add)

    p = sub.add_parser("list", aliases=["dashboard", "overview"],
                       help="numbered markdown dashboard of all jobs")
    p.set_defaults(func=cmd_list)

    p = sub.add_parser("run-now", help="trigger a job immediately")
    p.add_argument("id")
    p.set_defaults(func=cmd_run_now)

    p = sub.add_parser("remove", help="unload and delete a job (plist, registry entry, log)")
    p.add_argument("id")
    p.set_defaults(func=cmd_remove)

    p = sub.add_parser("update", help="change a job's schedule, payload, workdir, or description")
    p.add_argument("id")
    p.add_argument("--cron")
    p.add_argument("--command")
    p.add_argument("--prompt")
    p.add_argument("--workdir")
    p.add_argument("--description")
    p.set_defaults(func=cmd_update)

    p = sub.add_parser("logs", help="show the tail of a job's log")
    p.add_argument("id")
    p.add_argument("--lines", type=int, default=40)
    p.set_defaults(func=cmd_logs)

    p = sub.add_parser("_run", help=argparse.SUPPRESS)
    p.add_argument("id")
    p.set_defaults(func=cmd_internal_run)

    args = parser.parse_args(sys.argv[1:] or ["list"])
    if not getattr(args, "func", None):
        parser.print_help()
        sys.exit(2)
    args.func(args)


if __name__ == "__main__":
    main()
