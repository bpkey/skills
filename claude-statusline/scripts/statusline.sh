#!/usr/bin/env bash
# Claude Code status line renderer.
#
# Layout:
#   <context%> <$cost> <@account_5h%_7d%> <model> <effort>  <cwd> ⑂ <branch> ⧉ <worktree>
#
# The branch and worktree are prefixed with a glyph rather than wrapped in
# brackets, so the two can't be mistaken for each other: ⑂ (U+2442 OCR FORK)
# for the branch, ⧉ (U+29C9 TWO JOINED SQUARES — "a second checkout") for the
# worktree. Most monospace fonts (SF Mono, Menlo) lack one or both, but system
# symbol fonts carry them — Apple Symbols on macOS — so font fallback renders
# them. The cwd stays unprefixed; a path is already self-evident.
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
# the wrong slot. Percentages are floored to whole numbers in jq (and emptied
# when null, early in the session) so they arrive as clean integers.
IFS=$'\x1f' read -r cwd model effort worktree pct cost five_h seven_d < <(printf '%s' "$input" | jq -r '
  def whole: if type == "number" then (floor | tostring) else "" end;
  [ (.workspace.current_dir // .cwd // ""),
    (.model.display_name // ""),
    (.effort.level // ""),
    (.workspace.git_worktree // .worktree.name // ""),
    (.context_window.used_percentage | whole),
    (.cost.total_cost_usd | if type == "number" then (. * 100 | round / 100 | tostring) else "" end),
    (.rate_limits.five_hour.used_percentage | whole),
    (.rate_limits.seven_day.used_percentage | whole)
  ] | join("\u001f")')

# The full path eats most of the line's width, so show only the last two
# components — enough to identify the project (and which worktree of it)
# without pushing everything else off the edge. $HOME renders as ~.
short_path() {
  local p="$1" base parent
  [ -z "$p" ] && return
  [ "$p" = "$HOME" ] && { printf '~'; return; }
  base="${p##*/}"
  [ -z "$base" ] && { printf '%s' "$p"; return; }   # p is "/"
  parent="${p%/*}"
  parent="${parent##*/}"
  [ -z "$parent" ] && { printf '/%s' "$base"; return; }  # p is a top-level dir
  printf '%s/%s' "$parent" "$base"
}

# The branch name isn't in the status-line JSON, so read it from git in the
# session's own directory (not wherever this script happens to run) — using
# the full path, before it gets shortened for display.
branch=""
[ -n "$cwd" ] && branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
cwd=$(short_path "$cwd")

# `Opus 5 (1M context)` is most of a status line by itself. Keep the family
# name and the context-window marker, drop the rest: `opus|1M`.
short_model() {
  local name="$1" family suffix
  [ -z "$name" ] && return
  case "$name" in
    *[Oo]pus*)   family=opus ;;
    *[Ss]onnet*) family=sonnet ;;
    *[Hh]aiku*)  family=haiku ;;
    *[Ff]able*)  family=fable ;;
    *) family=$(printf '%s' "${name%% *}" | tr '[:upper:]' '[:lower:]') ;;
  esac
  case "$name" in
    *1M*) suffix="|1M" ;;
    *)    suffix="" ;;
  esac
  printf '%s%s' "$family" "$suffix"
}
model=$(short_model "$model")

# Color the context% to flag when it climbs: 25–34% orange, 35%+ red, under
# 25% no color. ANSI escapes (orange via 256-color 208, red via 196) with a
# reset after; Claude Code renders these in the status line.
pct_segment=""
if [ -n "$pct" ]; then
  if [ "$pct" -ge 35 ]; then
    pct_segment=$'\033[38;5;196m'"$pct%"$'\033[0m'
  elif [ "$pct" -ge 25 ]; then
    pct_segment=$'\033[38;5;208m'"$pct%"$'\033[0m'
  else
    pct_segment="$pct%"
  fi
fi

# Which Anthropic account this session is logged into. It isn't in the
# status-line JSON, so read it from the CLI's own config; only the domain's
# first label is shown (@blueprintkey, not @blueprintkey.com), which is what
# distinguishes one account from another at a glance.
account=""
if [ -r "$HOME/.claude.json" ]; then
  email=$(jq -r '.oauthAccount.emailAddress // empty' "$HOME/.claude.json" 2>/dev/null)
  if [ -n "$email" ]; then
    domain="${email#*@}"
    account="@${domain%%.*}"
  fi
fi

# Account + usage against the two plan limits, joined into one compact
# underscore-separated token: @blueprintkey_30%_36% (5h then 7d).
acct_usage="$account"
[ -n "$five_h" ]  && acct_usage="${acct_usage}_$five_h%"
[ -n "$seven_d" ] && acct_usage="${acct_usage}_$seven_d%"

# Assemble left to right, dropping any segment we couldn't resolve. `append`
# adds its separator only once the line is non-empty, so the line never starts
# or ends with stray spaces no matter which segments are present (e.g. before
# the first response sets context%, cost leads instead).
out=""
append() { # $1 = text, $2 = separator to use when the line already has content
  [ -z "$1" ] && return
  if [ -z "$out" ]; then out="$1"; else out="$out$2$1"; fi
}

append "$pct_segment" "  "
[ -n "$cost" ] && append "\$$cost" " "
append "$acct_usage" " "
append "$model" " "
append "$effort" " "
append "$cwd" "  "
[ -n "$branch" ]   && append "⑂ $branch" " "
[ -n "$worktree" ] && append "⧉ $worktree" " "

printf '%s' "$out"
