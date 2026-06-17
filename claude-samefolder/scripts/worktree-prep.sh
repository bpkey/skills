#!/usr/bin/env bash
# Shared helper for the claude-samefolder / claude-forkchat skills.
#
# Decides whether a NEW parallel Claude session should open in a dedicated git
# worktree (an isolated checkout) instead of the current folder, remembers that
# choice per-repository, and creates the worktree on request.
#
# Fully generic — no hardcoded paths or usernames. The git situation is derived
# at runtime; the per-repo preference is persisted under the shared BlueprintKey
# state root:  ~/.blueprintkey/parallel-sessions/prefs.conf
#
# Subcommands (all read the CURRENT working directory):
#   resolve [slug]   Decide what to do. Prints KEY=VALUE lines:
#                      NEED_ASK=0|1
#                      LAUNCH_DIR=<dir>      (when NEED_ASK=0)
#                      REASON=<why>          (when NEED_ASK=0)
#                      TOPLEVEL=<repo root>  (when NEED_ASK=1)
#                      SUGGESTED_SLUG=<slug> (when NEED_ASK=1)
#                      SUGGESTED_DIR=<path>  (when NEED_ASK=1)
#                    With a remembered "always" pref it creates the worktree
#                    itself and returns its LAUNCH_DIR.
#   create [slug]    Create `git worktree add <parent>/<repo>-<slug> -b <slug>`
#                    off the current HEAD (uniquifies a taken slug). Prints
#                    LAUNCH_DIR=<abs path>. A status note goes to stderr.
#   remember <always|never>
#                    Persist the choice for the current repo. Prints SAVED=<file>.

set -euo pipefail

PREF_DIR="$HOME/.blueprintkey/parallel-sessions"
PREF_FILE="$PREF_DIR/prefs.conf"

err() { printf '%s\n' "$*" >&2; }

# --- git situation ---------------------------------------------------------

in_work_tree() {
    [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null || echo false)" == "true" ]]
}

# True when the current dir is a LINKED worktree (already "activated" for
# parallel work), false when it is the repo's main checkout. A linked worktree's
# git dir (.git/worktrees/<name>) differs from the shared common dir (.git).
is_linked_worktree() {
    local gd cd
    gd="$(git rev-parse --absolute-git-dir 2>/dev/null || true)"
    cd="$(git rev-parse --git-common-dir 2>/dev/null || true)"
    [[ -z "$gd" || -z "$cd" ]] && return 1
    gd="$(cd "$gd" 2>/dev/null && pwd -P || printf '%s' "$gd")"
    cd="$(cd "$cd" 2>/dev/null && pwd -P || printf '%s' "$cd")"
    [[ "$gd" != "$cd" ]]
}

# --- preference store ------------------------------------------------------
# File format, one repo per line:  <always|never><TAB><git-toplevel-path>

saved_pref() {  # $1 = git toplevel -> echoes always|never|ask
    local top="$1" val
    [[ -f "$PREF_FILE" ]] || { echo ask; return; }
    val="$(awk -F'\t' -v p="$top" '$2==p {v=$1} END{if(v)print v}' "$PREF_FILE")"
    case "$val" in always|never) echo "$val" ;; *) echo ask ;; esac
}

# --- slug / worktree path --------------------------------------------------

slugify() {  # lower-case, collapse non-alnum to single hyphens, trim
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]' \
        | sed 's/[^a-z0-9]/-/g; s/-\{2,\}/-/g; s/^-//; s/-$//'
}

_slug_taken() {  # $1=slug $2=parent $3=primbase
    git show-ref --verify --quiet "refs/heads/$1" && return 0
    [[ -e "$2/$3-$1" ]] && return 0
    return 1
}

pick_slug() {  # $1=desired(maybe empty) $2=parent $3=primbase -> free slug
    local desired="$1" parent="$2" primbase="$3" base cand n
    base="$(slugify "$desired")"
    [[ -n "$base" ]] || base="parallel"
    cand="$base"; n=1
    # For the generic "parallel" base, start numbering immediately so the very
    # first auto worktree reads parallel-1 rather than a bare "parallel".
    if [[ "$base" == "parallel" ]]; then cand="parallel-1"; n=1; fi
    while _slug_taken "$cand" "$parent" "$primbase"; do
        n=$((n+1)); cand="${base}-${n}"
    done
    printf '%s' "$cand"
}

# --- subcommands -----------------------------------------------------------

cmd_create() {
    in_work_tree || { err "worktree-prep: not inside a git work tree"; exit 1; }
    local top parent primbase slug path out
    top="$(git rev-parse --show-toplevel)"
    parent="$(dirname "$top")"
    primbase="$(basename "$top")"
    slug="$(pick_slug "${1:-}" "$parent" "$primbase")"
    path="$parent/$primbase-$slug"
    if ! out="$(git worktree add "$path" -b "$slug" 2>&1)"; then
        err "worktree-prep: 'git worktree add' failed:"
        err "$out"
        exit 1
    fi
    err "created git worktree '$slug' (new branch $slug) at $path"
    printf 'LAUNCH_DIR=%s\n' "$path"
}

cmd_remember() {
    local val="${1:-}" top
    case "$val" in always|never) ;; *) err "worktree-prep: remember needs 'always' or 'never'"; exit 2 ;; esac
    in_work_tree || { err "worktree-prep: not inside a git work tree"; exit 1; }
    top="$(git rev-parse --show-toplevel)"
    mkdir -p "$PREF_DIR"
    if [[ -f "$PREF_FILE" ]]; then
        awk -F'\t' -v p="$top" '$2!=p' "$PREF_FILE" > "$PREF_FILE.tmp" && mv "$PREF_FILE.tmp" "$PREF_FILE"
    fi
    printf '%s\t%s\n' "$val" "$top" >> "$PREF_FILE"
    printf 'SAVED=%s\n' "$PREF_FILE"
}

cmd_resolve() {
    local desired="${1:-}"
    if ! in_work_tree; then
        printf 'NEED_ASK=0\nLAUNCH_DIR=%s\nREASON=not-a-git-repo\n' "$PWD"; return
    fi
    if is_linked_worktree; then
        printf 'NEED_ASK=0\nLAUNCH_DIR=%s\nREASON=already-in-worktree\n' "$PWD"; return
    fi
    local top pref parent primbase slug
    top="$(git rev-parse --show-toplevel)"
    pref="$(saved_pref "$top")"
    case "$pref" in
        never)
            printf 'NEED_ASK=0\nLAUNCH_DIR=%s\nREASON=pref-never\n' "$PWD" ;;
        always)
            cmd_create "$desired"            # emits LAUNCH_DIR=...
            printf 'NEED_ASK=0\nREASON=pref-always\n' ;;
        *)
            parent="$(dirname "$top")"; primbase="$(basename "$top")"
            slug="$(pick_slug "$desired" "$parent" "$primbase")"
            printf 'NEED_ASK=1\nTOPLEVEL=%s\nSUGGESTED_SLUG=%s\nSUGGESTED_DIR=%s\n' \
                "$top" "$slug" "$parent/$primbase-$slug" ;;
    esac
}

case "${1:-}" in
    resolve)  shift; cmd_resolve  "${1:-}" ;;
    create)   shift; cmd_create   "${1:-}" ;;
    remember) shift; cmd_remember "${1:-}" ;;
    *) err "usage: worktree-prep.sh {resolve [slug]|create [slug]|remember <always|never>}"; exit 2 ;;
esac
