#!/usr/bin/env bash
# Open a fresh `claude` session in a new Apple Terminal tab (default) or
# window, in the same working directory. See SKILL.md for details.

set -euo pipefail

err() { printf '%s\n' "$*" >&2; }

mode="${1:-tab}"
case "$mode" in
    tab|window) ;;
    *)
        err "claude-samefolder: unknown mode '$mode' (expected 'tab' or 'window')"
        exit 2
        ;;
esac

# Carry over the current session's permission mode. If the parent session is
# running in bypassPermissions (launched with --dangerously-skip-permissions,
# or toggled there via shift+tab), the new session should inherit the same
# setting. The latest permissionMode entry in the current transcript reflects it.
# Locate the transcript: prefer the session-id env var, fall back to lsof.
session_path=""
if [[ -n "${CLAUDE_CODE_SESSION_ID:-}" ]]; then
    encoded_cwd="$(printf '%s' "$PWD" | sed 's|/|-|g')"
    cand="$HOME/.claude/projects/$encoded_cwd/$CLAUDE_CODE_SESSION_ID.jsonl"
    [[ -f "$cand" ]] && session_path="$cand"
fi
if [[ -z "$session_path" ]] && command -v lsof >/dev/null 2>&1; then
    session_path="$(lsof -p "$PPID" 2>/dev/null | awk '/\.jsonl$/ {print $NF}' | head -1 || true)"
fi

dangerous_flag=""
if [[ -n "$session_path" && -f "$session_path" ]]; then
    last_mode="$(grep -o '"permissionMode":"[^"]*"' "$session_path" 2>/dev/null | tail -1 | sed 's/.*:"\([^"]*\)"$/\1/' || true)"
    if [[ "$last_mode" == "bypassPermissions" ]]; then
        dangerous_flag=" --dangerously-skip-permissions"
    fi
fi

quoted_pwd="$(printf '%q' "$PWD")"
inner_cmd="cd $quoted_pwd && claude$dangerous_flag"

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
            err "claude-samefolder: 'tab' mode needs macOS Accessibility permission to send Cmd+T."
            err "       1. System Settings → Privacy & Security → Accessibility"
            err "       2. Enable Terminal and claude (click + to add if missing — \`which claude\` shows the path)"
            err "       3. Quit and relaunch Claude Code so the new permission takes effect"
            err "       Or use \`/claude-samefolder window\` (no Accessibility needed)."
        fi
        return $status
    fi
}

term="${TERM_PROGRAM:-}"
if [[ -n "$term" && "$term" != "Apple_Terminal" ]]; then
    err "claude-samefolder: TERM_PROGRAM=$term not yet supported, falling back to Apple Terminal"
fi

case "$mode" in
    window)
        open_in_new_window "$inner_cmd"
        printf 'opened new window with fresh claude in %s\n' "$PWD"
        ;;
    tab)
        front_count="$(osascript -e 'tell application "Terminal" to count windows' 2>/dev/null || echo 0)"
        if [[ "${front_count:-0}" -eq 0 ]]; then
            err "claude-samefolder: no front Terminal window — opening a new window instead"
            open_in_new_window "$inner_cmd"
            printf 'opened new window with fresh claude in %s\n' "$PWD"
        else
            open_in_new_tab "$inner_cmd"
            printf 'opened new tab with fresh claude in %s\n' "$PWD"
        fi
        ;;
esac
