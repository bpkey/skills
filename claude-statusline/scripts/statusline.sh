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

# Where the session is, said once. Three names for one place — the folder,
# the branch, and the worktree — read as three different things and are often
# near-copies of each other, so only the one that identifies the work is
# shown, each behind a letter that says what it is:
#
#   f:<folder>              outside a repo — the last folder of the path
#   b:<branch>              in a repo
#   b:<branch> w:<worktree> in a linked worktree of one
#
# The branch isn't in the status-line JSON, so it's read from git in the
# session's own directory rather than wherever this script happens to run. A
# detached HEAD has no branch to name, so it falls back to the folder.
folder() {
  local p="$1"
  [ -z "$p" ] && return
  [ "$p" = "$HOME" ] && { printf '~'; return; }
  [ "${p##*/}" = "" ] && { printf '%s' "$p"; return; }   # p is "/"
  printf '%s' "${p##*/}"
}

branch=""
[ -n "$cwd" ] && branch=$(git -C "$cwd" branch --show-current 2>/dev/null)

place=""
if [ -n "$branch" ]; then
  place="b:$branch"
  [ -n "$worktree" ] && place="$place w:$worktree"
else
  folder=$(folder "$cwd")
  [ -n "$folder" ] && place="f:$folder"
fi

# `Opus 5 (1M context)` is most of a status line by itself. Keep the family
# name and the context-window marker, drop the rest: `opus|1M`.
model_family() {
  local name="$1"
  [ -z "$name" ] && return
  case "$name" in
    *[Oo]pus*)   printf 'opus' ;;
    *[Ss]onnet*) printf 'sonnet' ;;
    *[Hh]aiku*)  printf 'haiku' ;;
    *[Ff]able*)  printf 'fable' ;;
    *) printf '%s' "${name%% *}" | tr '[:upper:]' '[:lower:]' ;;
  esac
}
short_model() {
  local name="$1" suffix
  [ -z "$name" ] && return
  case "$name" in
    *1M*) suffix="|1M" ;;
    *)    suffix="" ;;
  esac
  printf '%s%s' "$(model_family "$name")" "$suffix"
}
family=$(model_family "$model")
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

# The weekly window of the model this session is on — what `/usage` draws as
# "Current week (Fable)". The status-line JSON carries only the account-wide
# five-hour and seven-day windows: Claude Code keeps the per-model buckets on
# an object it doesn't pipe here (its internal schema calls them
# `rate_limits.model_scoped`). So fetch them ourselves from the same endpoint
# `/usage` reads, and cache them.
#
# The render never waits on the network. A cache younger than the TTL is used
# as it stands; an older one is still used, and a refresh runs detached for
# the next turn to pick up. No cache means no segment — never a stall, never
# an error on the line.
usage_cache="$HOME/.claude/cache/oauth-usage.json"
usage_ttl=60

# A directory is the lock: `mkdir` is atomic, so of the several sessions
# rendering at once exactly one refreshes. A lock older than two minutes
# outlived its refresh and is cleared.
refresh_usage() {
  local lock="$usage_cache.lock" tmp
  mkdir -p "${usage_cache%/*}" 2>/dev/null
  if [ -d "$lock" ]; then
    [ -z "$(find "$lock" -maxdepth 0 -mmin +2 2>/dev/null)" ] && return
    rmdir "$lock" 2>/dev/null
  fi
  mkdir "$lock" 2>/dev/null || return
  (
    # The OAuth token stays out of argv and out of every process listing:
    # curl reads the header from a config on stdin, and nothing echoes it.
    # macOS keeps it in the login Keychain, Linux in a credentials file.
    tok=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null |
      jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    if [ -z "$tok" ] && [ -r "$HOME/.claude/.credentials.json" ]; then
      tok=$(jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json" 2>/dev/null)
    fi
    if [ -n "$tok" ]; then
      tmp="$usage_cache.$$"
      if printf 'url = "https://api.anthropic.com/api/oauth/usage"\nheader = "Authorization: Bearer %s"\nheader = "Content-Type: application/json"\n' "$tok" |
        curl -s -m 10 -K - -o "$tmp" && jq -e '.limits' "$tmp" >/dev/null 2>&1; then
        mv -f "$tmp" "$usage_cache"
      else
        rm -f "$tmp"
      fi
    fi
    rmdir "$lock" 2>/dev/null
  ) >/dev/null 2>&1 &
  disown 2>/dev/null
}

age=$(stat -f %m "$usage_cache" 2>/dev/null)
if [ -z "$age" ] || [ $(($(date +%s) - age)) -ge "$usage_ttl" ]; then
  refresh_usage
fi

# The weekly bucket whose model matches this session's, if the account has
# one — how much of it is spent, and when it resets. Matching on the server's
# own display name keeps this generic: a bucket the server later emits for
# another family works with no change here. The reset time is an ISO
# timestamp with a fraction and a numeric offset, which `fromdateiso8601`
# refuses, so the fraction and the (always UTC) offset are trimmed first.
model_pct=""
model_reset=""
if [ -n "$family" ] && [ -r "$usage_cache" ]; then
  IFS=' ' read -r model_pct model_reset < <(jq -r --arg fam "$family" '
    def epoch: try (sub("\\.[0-9]+"; "") | sub("(\\+00:00|Z)$"; "") + "Z" | fromdateiso8601) catch empty;
    [ .limits[]?
      | select(.kind == "weekly_scoped")
      | select((.scope.model.display_name // "") | ascii_downcase | startswith($fam)) ][0]
    | select(. != null)
    | "\(.percent | floor) \((.resets_at // "" | epoch) // "")"' "$usage_cache" 2>/dev/null)
fi

# Hours until that window resets, rounded up so a window still open never
# reads as 0. Under an hour says so rather than claiming a whole one.
model_left=""
if [ -n "$model_reset" ]; then
  secs=$((model_reset - $(date +%s)))
  if [ "$secs" -gt 3600 ]; then
    model_left="..$(((secs + 3599) / 3600))hr"
  elif [ "$secs" -gt 0 ]; then
    model_left="..<1hr"
  fi
fi

# Shown against the model name — `fable(78%..19hr)` — because it is that
# model's limit and moving off the model moves off the limit. Orange from
# 75%, red from 90%: the weekly window is the one that ends a day's work.
if [ -n "$model_pct" ] && [ -n "$model" ]; then
  if [ "$model_pct" -ge 90 ]; then
    model="$model"$'\033[38;5;196m'"($model_pct%$model_left)"$'\033[0m'
  elif [ "$model_pct" -ge 75 ]; then
    model="$model"$'\033[38;5;208m'"($model_pct%$model_left)"$'\033[0m'
  else
    model="$model($model_pct%$model_left)"
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
append "$place" "  "

printf '%s' "$out"
