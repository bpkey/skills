#!/usr/bin/env bash
# Continue the CURRENT Claude Code conversation IN PLACE — taking over THIS
# Apple Terminal tab — with the bypass-permissions mode FLIPPED.
#
# `--dangerously-skip-permissions` is a launch-time flag — it can't be toggled
# inside a live session — so switching it means relaunching `claude`. This skill
# does the relaunch in the SAME tab: it seeds a new session from the current
# transcript with `claude --resume <id> --fork-session` (adding or dropping
# `--dangerously-skip-permissions` so the new session lands in the opposite
# bypass state), then ENDS the current session so the flipped one takes its
# place in this tab.
#
# Because a child process can't re-exec the live `claude` that spawned it, the
# takeover is done by a tiny detached watcher: it waits for this session to end,
# then drives Terminal (`do script ... in <this tab>`) to launch the flipped
# session on the now-free shell prompt. The watcher is what ends the current
# session, so the handoff is automatic. See SKILL.md for the full contract.

set -euo pipefail

err() { printf '%s\n' "$*" >&2; }

# ---------------------------------------------------------------------------
# 0. Tool-compatibility guard.
#    This skill reads the current Claude Code session transcript from
#    ~/.claude/projects/ and relaunches `claude` — both are Claude-Code-only.
#    `npx skills` installs every skill into every AI client, so a user running
#    this from another tool must get a clear, non-cryptic note, not a failure.
# ---------------------------------------------------------------------------
if [[ -z "${CLAUDECODE:-}" && -z "${CLAUDE_CODE_ENTRYPOINT:-}" && -z "${CLAUDE_CODE_SESSION_ID:-}" ]]; then
    current_tool="unknown tool"
    if [[ -n "${CURSOR_TRACE_ID:-}${CURSOR_AGENT:-}" ]]; then
        current_tool="Cursor"
    elif [[ -n "${WINDSURF_USER:-}${WINDSURF_SESSION_ID:-}" ]]; then
        current_tool="Windsurf"
    elif [[ -n "${TERM_PROGRAM:-}" ]]; then
        current_tool="$TERM_PROGRAM"
    fi
    err "claude-toggle-permissions is a Claude Code-only skill, but it looks like it's running under: $current_tool"
    err ""
    err "It takes over the current Claude Code conversation (via \`claude --resume <id> --fork-session\`)"
    err "by reading that session's transcript from ~/.claude/projects/, which only Claude Code"
    err "writes — so there's no conversation for it to flip the permission mode of in $current_tool."
    exit 1
fi

# ---------------------------------------------------------------------------
# 0b. Terminal guard.
#     The in-place takeover ENDS the current session and relaunches in this
#     exact tab, which it can only do for Apple Terminal. Refuse on any other
#     known terminal rather than killing the session and spawning a foreign
#     window. An empty TERM_PROGRAM is treated as Apple Terminal (best effort).
# ---------------------------------------------------------------------------
term="${TERM_PROGRAM:-}"
if [[ -n "$term" && "$term" != "Apple_Terminal" ]]; then
    err "claude-toggle-permissions: this skill takes over the current tab in place, which is only"
    err "       supported in Apple Terminal — but TERM_PROGRAM=$term. Refusing so it doesn't end"
    err "       your session and open an unrelated Terminal.app window instead."
    exit 1
fi

# A terminal multiplexer runs the session on its own pty that no Terminal.app
# tab reports, so the takeover would kill the session and open a stray window —
# exactly what this skill exists to avoid. screen leaves TERM_PROGRAM as the
# host terminal (so the guard above misses it); catch it (and tmux) explicitly.
if [[ -n "${TMUX:-}" || -n "${STY:-}" || "${TERM:-}" == screen* || "${TERM:-}" == tmux* ]]; then
    mux="tmux"; { [[ -n "${STY:-}" || "${TERM:-}" == screen* ]]; } && mux="screen"
    err "claude-toggle-permissions: you're inside $mux. The session runs on a $mux-allocated pty that"
    err "       Apple Terminal can't address, so the takeover would end your session and open an"
    err "       unrelated window. Refusing — detach from $mux and re-run in a plain Terminal tab."
    exit 1
fi

# Optional arg: a fallback base-name (kebab-case slug) the caller derives from
# the conversation. Used only when the current session has no name set. There
# are no tab/window modes — the takeover always happens in this tab.
fallback_base="${1:-}"

# Same folder as the current session — toggling the permission mode is a
# continuation of one conversation, not parallel work, so there's no worktree
# step here.
launch_dir="$PWD"

# ---------------------------------------------------------------------------
# 1. Identify the interactive `claude` that owns THIS Terminal tab.
#
#    CRITICAL: $PPID is NOT that process. When Claude Code runs this script by
#    path it wraps it in a transient `zsh -c`/`bash -c` that (a) has NO
#    controlling tty and (b) exits the instant the script returns. The old code
#    used $PPID for both the kill target and the tab tty, which is why the
#    takeover failed two ways at once: it "killed" an already-dead wrapper (so
#    the real session lived on) and read a "??" tty (so the relaunch opened a
#    NEW window instead of taking over the tab).
#
#    Fix: walk up the process tree to the nearest ancestor that is `claude` AND
#    has a real ttys* controlling terminal. That ancestor IS this session, and
#    its tty IS this tab. Requiring `claude` (not just any tty-bearing ancestor)
#    means we never accidentally target the login shell — killing that would
#    close the tab/log out. Works whether $PPID is the wrapper (script-path
#    invocation) or claude itself (inline invocation): the loop just stops at
#    the first qualifying ancestor.
# ---------------------------------------------------------------------------
session_pid=""
session_tty=""
walk="$PPID"
for _ in 1 2 3 4 5 6 7 8 9 10; do
    [[ -z "$walk" || "$walk" -le 1 ]] && break
    # `|| true` on each: under `set -euo pipefail` a ps that fails on a dead pid
    # would otherwise abort the script (system bash 3.2) instead of letting the
    # loop fall through to the helpful guard below.
    walk_comm="$(ps -o comm= -p "$walk" 2>/dev/null | tr -d ' ' || true)"
    walk_tty="$(ps -o tty= -p "$walk" 2>/dev/null | tr -d '[:space:]' || true)"
    if [[ "$walk_comm" == *claude* && "$walk_tty" == ttys* ]]; then
        session_pid="$walk"
        session_tty="$walk_tty"
        break
    fi
    walk="$(ps -o ppid= -p "$walk" 2>/dev/null | tr -d ' ' || true)"
done

if [[ -z "$session_pid" || -z "$session_tty" ]]; then
    err "claude-toggle-permissions: couldn't identify the interactive 'claude' process that owns"
    err "       this terminal tab — walked up from \$PPID=$PPID and found no 'claude' ancestor with"
    err "       a real tty. Not ending any session (nothing to safely take over). This skill must"
    err "       run as a Claude Code Bash tool inside an Apple Terminal tab."
    exit 1
fi

# Start time of the target, so the watcher can re-verify identity right before it
# kills (see section 5). Guards the (vanishingly rare) case where this exact PID
# exits on its own and gets recycled during the watcher's ~2s window — without
# this, the recycled PID's new owner would be killed.
session_lstart="$(ps -o lstart= -p "$session_pid" 2>/dev/null | tr -s ' ' || true)"

# ---------------------------------------------------------------------------
# 2. Locate the current session's transcript JSONL.
#    Primary: the session id is globally unique, so glob it across ALL project
#    buckets. This is encoding- AND cwd-agnostic — it sidesteps Claude Code's
#    project-dir encoding (which maps not just '/' but also '.', '_' and spaces
#    to '-', so a hand-rolled `sed 's|/|-|g'` is wrong for those paths) and the
#    case where $PWD differs from the session's launch dir.
#    Fallbacks (only when the env var is absent): lsof on the interactive claude
#    (usually empty — claude doesn't hold the fd open), then newest transcript in
#    the cwd bucket (best-effort; can be wrong, so it warns).
# ---------------------------------------------------------------------------
session_path=""
if [[ -n "${CLAUDE_CODE_SESSION_ID:-}" ]]; then
    session_path="$(ls -t "$HOME/.claude/projects/"*/"$CLAUDE_CODE_SESSION_ID.jsonl" 2>/dev/null | head -1 || true)"
fi
if [[ -z "$session_path" ]] && command -v lsof >/dev/null 2>&1; then
    session_path="$(lsof -p "$session_pid" 2>/dev/null | awk '/\.jsonl$/ {print $NF}' | head -1 || true)"
fi
if [[ -z "$session_path" ]]; then
    encoded_cwd="$(printf '%s' "$PWD" | sed 's|/|-|g')"
    project_dir="$HOME/.claude/projects/$encoded_cwd"
    if [[ -d "$project_dir" ]]; then
        session_path="$(ls -t "$project_dir"/*.jsonl 2>/dev/null | head -1 || true)"
        [[ -n "$session_path" ]] && err "claude-toggle-permissions: warning — no session-id env var; guessing the newest transcript in this dir ($session_path). The toggled session may not be this exact conversation."
    fi
fi

if [[ -z "$session_path" || ! -f "$session_path" ]]; then
    err "claude-toggle-permissions: could not locate the current session's transcript file."
    err "       checked \$CLAUDE_CODE_SESSION_ID (glob across project buckets), lsof on the interactive"
    err "       claude (pid $session_pid), and ~/.claude/projects/<encoded-cwd>/"
    exit 1
fi

session_id="$(basename "$session_path" .jsonl)"

# ---------------------------------------------------------------------------
# 3. Read the current bypass state and compute its opposite.
#    The latest "permissionMode" entry in the transcript reflects the live mode
#    (bypassPermissions when launched with --dangerously-skip-permissions, or
#    when toggled there in-session). The "bypass" dimension is what we flip:
#      - currently bypassPermissions  -> new session WITHOUT the flag (normal)
#      - anything else (default/plan/acceptEdits) -> new session WITH the flag
# ---------------------------------------------------------------------------
last_mode="$(grep -o '"permissionMode":"[^"]*"' "$session_path" 2>/dev/null | tail -1 | sed 's/.*:"\([^"]*\)"$/\1/' || true)"

if [[ -z "$last_mode" ]]; then
    err "claude-toggle-permissions: could not read the current permission mode from the transcript;"
    err "       assuming the session is NOT in bypass mode and switching it ON."
    last_mode="default"
fi

if [[ "$last_mode" == "bypassPermissions" ]]; then
    dangerous_flag=""           # toggle bypass OFF
    target_label="safe"
    from_desc="bypassPermissions"
    to_desc="normal (permission prompts on)"
else
    dangerous_flag=" --dangerously-skip-permissions"   # toggle bypass ON
    target_label="bypass"
    from_desc="$last_mode"
    to_desc="bypassPermissions (no prompts)"
fi

# ---------------------------------------------------------------------------
# 4. Name the relaunched session after the target mode so it's obvious which
#    way it landed in the prompt box, /resume picker, and terminal title.
#    Base name priority: current session name > caller slug > id stub. Any prior
#    -bypass/-safe suffix is stripped first so flipping back and forth doesn't
#    pile up suffixes (dns-cleanup-bypass -> dns-cleanup-safe -> ...).
# ---------------------------------------------------------------------------
current_name=""
sessions_dir="$HOME/.claude/sessions"
if [[ -d "$sessions_dir" ]]; then
    match="$(grep -l "\"sessionId\":\"$session_id\"" "$sessions_dir"/*.json 2>/dev/null | head -1 || true)"
    if [[ -n "$match" ]]; then
        current_name="$(grep -o '"name":"[^"]*"' "$match" | head -1 | sed 's/^"name":"\(.*\)"$/\1/' || true)"
    fi
fi

if [[ -n "$current_name" ]]; then
    base="$current_name"
elif [[ -n "$fallback_base" ]]; then
    base="$fallback_base"
else
    base="chat-${session_id:0:8}"
fi
base="$(printf '%s' "$base" | sed -E 's/-(bypass|safe)$//')"
fork_name="${base}-${target_label}"

# ---------------------------------------------------------------------------
# 5. Build the relaunch command and hand it to a detached watcher that takes
#    over THIS tab once the current session ends.
# ---------------------------------------------------------------------------
quoted_pwd="$(printf '%q' "$launch_dir")"
quoted_name="$(printf '%q' "$fork_name")"

# A breadcrumb the new tab prints before relaunching, so the flip is visible.
summary_line="claude-toggle-permissions: $from_desc -> $to_desc (took over this tab as '$fork_name')"
summary_q="'$(printf '%s' "$summary_line" | sed "s/'/'\\\\''/g")'"

relaunch="cd $quoted_pwd && echo $summary_q && claude --resume $session_id --fork-session -n $quoted_name$dangerous_flag"

# Pre-flight the one prerequisite: macOS Automation permission to drive Terminal
# via AppleScript. Do it HERE, in the foreground (so the user sees the result),
# BEFORE the watcher ends the session — otherwise a missing permission would
# kill the session and then fail silently in the detached watcher, leaving a
# dead tab. On a fresh machine this harmless `count windows` triggers the
# one-time "… wants to control Terminal" consent dialog; approving it grants the
# same permission the relaunch needs.
if ! automation_err="$(osascript -e 'tell application "Terminal" to count windows' 2>&1)"; then
    err "claude-toggle-permissions: can't control Terminal via AppleScript, so the in-place"
    err "       takeover can't run. Your current session is left untouched."
    err ""
    err "osascript said: $automation_err"
    err ""
    err "macOS needs Automation permission for this. To grant it:"
    err "  1. Open System Settings -> Privacy & Security -> Automation"
    err "  2. Find \"Terminal\" in the list and turn ON its \"Terminal\" toggle"
    err "  3. Re-run /claude-toggle-permissions"
    err ""
    err "If \"Terminal\" isn't listed under Automation yet, run this once and click Allow at"
    err "the prompt, then re-run the skill:"
    err "  osascript -e 'tell application \"Terminal\" to count windows'"
    exit 1
fi

# The interactive claude to end, and this tab's tty — both discovered above by
# walking the process tree (NOT $PPID, which is the ttyless transient wrapper).
my_tty="/dev/$session_tty"
claude_pid="$session_pid"

# The watcher must outlive the `claude` it kills (its own grandparent), so it
# ignores HUP/TERM/INT and is launched detached with nohup. It is written to a
# temp file (rather than `bash -c`) to keep the AppleScript quoting sane.
watcher="$(mktemp "${TMPDIR:-/tmp}/claude-toggle-perms.XXXXXX")"
cat > "$watcher" <<'WSCRIPT'
#!/usr/bin/env bash
# args: <claude_pid> <my_tty> <relaunch_cmd> <expected_lstart>
trap '' HUP TERM INT
claude_pid="$1"
my_tty="$2"
relaunch="$3"
expected_lstart="$4"
self="$0"

# Re-verify the pid is STILL our claude (same comm + same start time) before
# every signal. PIDs can be recycled during the wait below, and we must never
# kill an innocent process that happened to inherit this pid.
still_target() {
    [[ "$(ps -o comm= -p "$claude_pid" 2>/dev/null | tr -d ' ')" == *claude* ]] || return 1
    [[ "$(ps -o lstart= -p "$claude_pid" 2>/dev/null | tr -s ' ')" == "$expected_lstart" ]] || return 1
    return 0
}

# Give the current session a moment to render this turn before it goes away.
sleep 1.5

# End the current session so the shell in this tab returns to its prompt —
# re-checking identity at each step so a recycled pid is never signalled.
still_target && kill -TERM "$claude_pid" 2>/dev/null || true
for _ in $(seq 1 25); do
    still_target || break
    sleep 0.2
done
still_target && kill -KILL "$claude_pid" 2>/dev/null || true

# Let the shell reach its prompt and re-init the tty before we type into it.
sleep 0.6

# AppleScript-escape the relaunch command (backslash, then double-quote).
esc="$(printf '%s' "$relaunch" | sed 's/\\/\\\\/g; s/"/\\"/g')"

# Run the relaunch in THIS tab (matched by tty); fall back to a new window if
# the tab is gone (e.g. the shell exited when the session ended). The session is
# already over by now, so if AppleScript can't run at all (e.g. Automation
# permission was revoked after pre-flight), drop the exact relaunch command onto
# this tab's tty as a last resort so the user can paste it and continue.
if ! osascript <<OSA
tell application "Terminal"
    activate
    set targetTab to missing value
    repeat with w in windows
        repeat with t in tabs of w
            try
                if (tty of t) is "$my_tty" then
                    set targetTab to t
                    exit repeat
                end if
            end try
        end repeat
        if targetTab is not missing value then exit repeat
    end repeat
    if targetTab is missing value then
        do script "$esc"
    else
        do script "$esc" in targetTab
    end if
end tell
OSA
then
    printf '\n[claude-toggle-permissions] Could not auto-relaunch into this tab (AppleScript could not\nrun — Automation permission for Terminal may be missing). Paste this to continue your\ntoggled session:\n\n  %s\n\n' "$relaunch" > "$my_tty" 2>/dev/null || true
fi

rm -f "$self"
WSCRIPT

nohup bash "$watcher" "$claude_pid" "$my_tty" "$relaunch" "$session_lstart" </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true

printf "toggling %s -> %s: this tab will end the current session and relaunch %s in place as '%s' (in %s)\n" \
    "$from_desc" "$to_desc" "$session_id" "$fork_name" "$launch_dir"
