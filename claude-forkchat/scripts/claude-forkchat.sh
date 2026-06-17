#!/usr/bin/env bash
# Fork the current Claude Code session into a sibling Apple Terminal tab
# (default) or window. See SKILL.md for the full contract.

set -euo pipefail

err() { printf '%s\n' "$*" >&2; }

mode="${1:-tab}"
case "$mode" in
    tab|window) ;;
    *)
        err "claude-forkchat: unknown mode '$mode' (expected 'tab' or 'window')"
        exit 2
        ;;
esac

# Optional second arg: a fallback base-name (kebab-case slug) the caller derives
# from the conversation. Used only when the current session has no name set.
fallback_base="${2:-}"

# Where the fork boots. Defaults to the current dir; the worktree pre-step
# (see SKILL.md / worktree-prep.sh) may point it at a freshly created git
# worktree via PARALLEL_LAUNCH_DIR. Session/transcript detection below stays
# anchored to $PWD — that's where the *current* session's state lives.
launch_dir="${PARALLEL_LAUNCH_DIR:-$PWD}"

# 1. Resolve the current session ID.
#    The Bash tool spawns shells whose $PPID is the host `claude` process,
#    which holds the live transcript JSONL open for writing. lsof tells us which.
session_path=""
if command -v lsof >/dev/null 2>&1; then
    session_path="$(lsof -p "$PPID" 2>/dev/null | awk '/\.jsonl$/ {print $NF}' | head -1 || true)"
fi

# Fallback: most recently modified transcript under the encoded-cwd project dir.
if [[ -z "$session_path" ]]; then
    encoded_cwd="$(printf '%s' "$PWD" | sed 's|/|-|g')"
    project_dir="$HOME/.claude/projects/$encoded_cwd"
    if [[ -d "$project_dir" ]]; then
        session_path="$(ls -t "$project_dir"/*.jsonl 2>/dev/null | head -1 || true)"
    fi
fi

if [[ -z "$session_path" || ! -f "$session_path" ]]; then
    err "claude-forkchat: could not locate the current session's transcript file."
    err "       checked lsof -p \$PPID and ~/.claude/projects/<encoded-cwd>/"
    exit 1
fi

session_id="$(basename "$session_path" .jsonl)"

# 2. Look up the current session's display name (if any) in
#    ~/.claude/sessions/<pid>.json — those files are one-line JSON keyed by PID
#    with sessionId and an optional name field set via /rename.
current_name=""
sessions_dir="$HOME/.claude/sessions"
if [[ -d "$sessions_dir" ]]; then
    match="$(grep -l "\"sessionId\":\"$session_id\"" "$sessions_dir"/*.json 2>/dev/null | head -1 || true)"
    if [[ -n "$match" ]]; then
        current_name="$(grep -o '"name":"[^"]*"' "$match" | head -1 | sed 's/^"name":"\(.*\)"$/\1/' || true)"
    fi
fi

# 3. Derive fork name. Priority: existing name > caller-supplied fallback > id stub.
if [[ -n "$current_name" ]]; then
    fork_name="${current_name}-fork"
elif [[ -n "$fallback_base" ]]; then
    fork_name="${fallback_base}-fork"
else
    fork_name="fork-${session_id:0:8}"
fi

# 4. Carry over the current session's permission mode. If the parent session is
#    running in bypassPermissions (launched with --dangerously-skip-permissions,
#    or toggled there via shift+tab), the latest permissionMode entry in the
#    transcript reflects it — so the fork should inherit the same setting.
dangerous_flag=""
last_mode="$(grep -o '"permissionMode":"[^"]*"' "$session_path" 2>/dev/null | tail -1 | sed 's/.*:"\([^"]*\)"$/\1/' || true)"
if [[ "$last_mode" == "bypassPermissions" ]]; then
    dangerous_flag=" --dangerously-skip-permissions"
fi

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
            err "claude-forkchat: 'tab' mode needs macOS Accessibility permission to send Cmd+T."
            err "       1. System Settings → Privacy & Security → Accessibility"
            err "       2. Enable Terminal and claude (click + to add if missing — \`which claude\` shows the path)"
            err "       3. Quit and relaunch Claude Code so the new permission takes effect"
            err "       Or use \`/claude-forkchat window\` (no Accessibility needed)."
        fi
        return $status
    fi
}

term="${TERM_PROGRAM:-}"
if [[ -n "$term" && "$term" != "Apple_Terminal" ]]; then
    err "claude-forkchat: TERM_PROGRAM=$term not yet supported, falling back to Apple Terminal"
fi

case "$mode" in
    window)
        open_in_new_window "$inner_cmd"
        printf "forked from %s into new window as '%s' in %s\n" "$session_id" "$fork_name" "$launch_dir"
        ;;
    tab)
        front_count="$(osascript -e 'tell application "Terminal" to count windows' 2>/dev/null || echo 0)"
        if [[ "${front_count:-0}" -eq 0 ]]; then
            err "claude-forkchat: no front Terminal window — opening a new window instead"
            open_in_new_window "$inner_cmd"
            printf "forked from %s into new window (no front window for tab) as '%s' in %s\n" "$session_id" "$fork_name" "$launch_dir"
        else
            open_in_new_tab "$inner_cmd"
            printf "forked from %s into new tab as '%s' in %s\n" "$session_id" "$fork_name" "$launch_dir"
        fi
        ;;
esac
