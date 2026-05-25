#!/usr/bin/env bash
# Claude Code status line renderer.
#
# Layout:  <cwd> [<branch>] [<worktree>]  <model>  <effort>  <context%>
#
# Claude Code pipes the status-line JSON to this script on stdin on every
# turn; see https://docs.claude.com/en/docs/claude-code/statusline for the
# full schema. We read only the fields we render and silently drop any that
# aren't present yet (outside a repo, before the first model response, on a
# model with no effort knob, etc.) so the line never shows blanks or errors.

input=$(cat)

# Without jq we can't parse the JSON. Rather than print nothing, fall back to
# a bare current-directory path so the status line is still informative.
if ! command -v jq >/dev/null 2>&1; then
  printf '%s' "${PWD/#$HOME/~}"
  exit 0
fi

# Pull every field in one jq pass, joined by US (0x1f). A non-whitespace
# separator matters: with a whitespace IFS, `read` collapses consecutive
# empty fields, so a missing effort+worktree would shift the percentage into
# the wrong slot. The percentage is floored to a whole number in jq (and
# emptied when null, early in the session) so it arrives as a clean integer.
IFS=$'\x1f' read -r cwd model effort worktree pct < <(printf '%s' "$input" | jq -r '
  [ (.workspace.current_dir // .cwd // ""),
    (.model.display_name // ""),
    (.effort.level // ""),
    (.workspace.git_worktree // .worktree.name // ""),
    (.context_window.used_percentage | if type == "number" then (floor | tostring) else "" end)
  ] | join("")')

# Collapse $HOME → ~ for a shorter, readable path.
[ -n "$cwd" ] && cwd="${cwd/#$HOME/~}"

# The branch name isn't in the status-line JSON, so read it from git in the
# session's own directory (not wherever this script happens to run).
branch=""
if [ -n "$cwd" ]; then
  dir="${cwd/#\~/$HOME}"
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
fi

# Color the context% to flag when it climbs: 10–14% orange, 15%+ red, under
# 10% no color. ANSI escapes (orange via 256-color 208, red via 196) with a
# reset after; Claude Code renders these in the status line.
pct_segment=""
if [ -n "$pct" ]; then
  if [ "$pct" -ge 15 ]; then
    pct_segment=$'\033[38;5;196m'"$pct%"$'\033[0m'
  elif [ "$pct" -ge 10 ]; then
    pct_segment=$'\033[38;5;208m'"$pct%"$'\033[0m'
  else
    pct_segment="$pct%"
  fi
fi

# Assemble left to right, dropping any segment we couldn't resolve.
out="$cwd"
[ -n "$branch" ]      && out="$out [$branch]"
[ -n "$worktree" ]    && out="$out [$worktree]"
[ -n "$model" ]       && out="$out  $model"
[ -n "$effort" ]      && out="$out  $effort"
[ -n "$pct_segment" ] && out="$out  $pct_segment"

printf '%s' "$out"
