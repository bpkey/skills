#!/usr/bin/env bash
# Resume the CURRENT Claude Code conversation in a sibling Apple Terminal tab
# (default) or window, with the bypass-permissions mode FLIPPED.
#
# `--dangerously-skip-permissions` is a launch-time flag — it can't be toggled
# inside a live session — so switching it means relaunching `claude`. To keep
# the full conversation context while flipping the flag (and to let both
# sessions run safely in parallel), this seeds a NEW session from the current
# transcript with `claude --resume <id> --fork-session`, adding or dropping
# `--dangerously-skip-permissions` so the new session lands in the opposite
# bypass state. See SKILL.md for the full contract.

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
    err "It resumes the current Claude Code conversation (via \`claude --resume <id> --fork-session\`)"
    err "by reading that session's transcript from ~/.claude/projects/, which only Claude Code"
    err "writes — so there's no conversation for it to flip the permission mode of in $current_tool."
    exit 1
fi

mode="${1:-tab}"
case "$mode" in
    tab|window) ;;
    *)
        err "claude-toggle-permissions: unknown mode '$mode' (expected 'tab' or 'window')"
        exit 2
        ;;
esac

# Optional second arg: a fallback base-name (kebab-case slug) the caller derives
# from the conversation. Used only when the current session has no name set.
fallback_base="${2:-}"

# Same folder as the current session — toggling the permission mode is a handoff,
# not parallel work, so there's no worktree step here.
launch_dir="$PWD"

# ---------------------------------------------------------------------------
# 1. Locate the current session's transcript JSONL.
#    Prefer the session-id env var Claude Code exports; fall back to lsof on the
#    host `claude` process (the Bash tool's $PPID), then to the newest transcript
#    under the encoded-cwd project dir.
# ---------------------------------------------------------------------------
session_path=""
if [[ -n "${CLAUDE_CODE_SESSION_ID:-}" ]]; then
    encoded_cwd="$(printf '%s' "$PWD" | sed 's|/|-|g')"
    cand="$HOME/.claude/projects/$encoded_cwd/$CLAUDE_CODE_SESSION_ID.jsonl"
    [[ -f "$cand" ]] && session_path="$cand"
fi
if [[ -z "$session_path" ]] && command -v lsof >/dev/null 2>&1; then
    session_path="$(lsof -p "$PPID" 2>/dev/null | awk '/\.jsonl$/ {print $NF}' | head -1 || true)"
fi
if [[ -z "$session_path" ]]; then
    encoded_cwd="$(printf '%s' "$PWD" | sed 's|/|-|g')"
    project_dir="$HOME/.claude/projects/$encoded_cwd"
    if [[ -d "$project_dir" ]]; then
        session_path="$(ls -t "$project_dir"/*.jsonl 2>/dev/null | head -1 || true)"
    fi
fi

if [[ -z "$session_path" || ! -f "$session_path" ]]; then
    err "claude-toggle-permissions: could not locate the current session's transcript file."
    err "       checked \$CLAUDE_CODE_SESSION_ID, lsof -p \$PPID, and ~/.claude/projects/<encoded-cwd>/"
    exit 1
fi

session_id="$(basename "$session_path" .jsonl)"

# ---------------------------------------------------------------------------
# 2. Read the current bypass state and compute its opposite.
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
# 3. Name the forked session after the target mode so the two are easy to tell
#    apart in the prompt box, /resume picker, and terminal title.
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

quoted_pwd="$(printf '%q' "$launch_dir")"
quoted_name="$(printf '%q' "$fork_name")"
inner_cmd="cd $quoted_pwd && claude --resume $session_id --fork-session -n $quoted_name$dangerous_flag"

escape_for_applescript() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

open_in_new_window() {
    local escaped
    escaped="$(escape_for_applescript "$1")"
    osascript \
        -e "tell application \"Terminal\" to do script \"$escaped\"" \
        -e 'tell application "Terminal" to activate' >/dev/null
}

open_in_new_tab() {
    local escaped err_output status
    escaped="$(escape_for_applescript "$1")"
    set +e
    err_output=$(osascript \
        -e 'tell application "Terminal" to activate' \
        -e 'delay 0.15' \
        -e 'tell application "System Events" to tell process "Terminal" to keystroke "t" using command down' \
        -e 'delay 0.30' \
        -e "tell application \"Terminal\" to do script \"$escaped\" in front window" 2>&1 >/dev/null)
    status=$?
    set -e
    if [[ $status -ne 0 ]]; then
        printf '%s\n' "$err_output" >&2
        if [[ "$err_output" == *"not allowed to send keystrokes"* ]]; then
            err ""
            err "claude-toggle-permissions: 'tab' mode needs macOS Accessibility permission to send Cmd+T."
            err "       1. System Settings → Privacy & Security → Accessibility"
            err "       2. Enable Terminal and claude (click + to add if missing — \`which claude\` shows the path)"
            err "       3. Quit and relaunch Claude Code so the new permission takes effect"
            err "       Or use \`/claude-toggle-permissions window\` (no Accessibility needed)."
        fi
        return $status
    fi
}

term="${TERM_PROGRAM:-}"
if [[ -n "$term" && "$term" != "Apple_Terminal" ]]; then
    err "claude-toggle-permissions: TERM_PROGRAM=$term not yet supported, falling back to Apple Terminal"
fi

case "$mode" in
    window)
        open_in_new_window "$inner_cmd"
        printf "toggled %s -> %s: forked %s into a new window as '%s' in %s\n" \
            "$from_desc" "$to_desc" "$session_id" "$fork_name" "$launch_dir"
        ;;
    tab)
        front_count="$(osascript -e 'tell application "Terminal" to count windows' 2>/dev/null || echo 0)"
        if [[ "${front_count:-0}" -eq 0 ]]; then
            err "claude-toggle-permissions: no front Terminal window — opening a new window instead"
            open_in_new_window "$inner_cmd"
            printf "toggled %s -> %s: forked %s into a new window (no front window for tab) as '%s' in %s\n" \
                "$from_desc" "$to_desc" "$session_id" "$fork_name" "$launch_dir"
        else
            open_in_new_tab "$inner_cmd"
            printf "toggled %s -> %s: forked %s into a new tab as '%s' in %s\n" \
                "$from_desc" "$to_desc" "$session_id" "$fork_name" "$launch_dir"
        fi
        ;;
esac
