#!/usr/bin/env bash
# Install the claude-statusline renderer and point Claude Code at it.
#
# Safe to re-run: it backs up settings.json and *merges* the .statusLine key
# rather than rewriting the file, so existing hooks/plugins/permissions are
# left intact.
set -uo pipefail

err() { printf '%s\n' "$*" >&2; }

# --- This skill only means something inside Claude Code -------------------
# It writes ~/.claude/settings.json's .statusLine key, which only Claude Code
# reads and renders. In any other AI tool there's nothing to install into, so
# detect the host tool and bow out with an explanation rather than silently
# editing a file that tool will never read.
detect_tool() {
  if   [ -n "${CLAUDECODE:-}" ] || [ -n "${CLAUDE_CODE_ENTRYPOINT:-}" ]; then echo claude-code
  elif [ -n "${CURSOR_TRACE_ID:-}" ] || [ -n "${CURSOR_AGENT:-}" ];      then echo cursor
  elif [ -n "${WINDSURF_USER:-}" ] || [ -n "${WINDSURF_SESSION:-}" ];    then echo windsurf
  else echo "unknown tool"; fi
}
tool=$(detect_tool)
if [ "$tool" != "claude-code" ]; then
  err "claude-statusline is a Claude Code-only skill, but it's running in: $tool."
  err "It installs a status line by writing ~/.claude/settings.json's .statusLine"
  err "key — a setting only Claude Code reads and renders. There's nothing for"
  err "$tool to do with it, so run it from inside Claude Code instead."
  exit 1
fi

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$SKILL_DIR/scripts/statusline.sh"
DEST="$HOME/.claude/statusline.sh"
SETTINGS="$HOME/.claude/settings.json"

[ -f "$SRC" ] || { err "claude-statusline: renderer not found at $SRC"; exit 1; }

# --- 1. Install the renderer at a stable, skill-independent path ----------
# Copying to ~/.claude/ (rather than pointing settings at the skill folder)
# keeps the status line working even if the skill is later moved or removed.
mkdir -p "$HOME/.claude"
cp "$SRC" "$DEST"
chmod +x "$DEST"
printf 'Installed renderer  → %s\n' "$DEST"

# --- 2. Point settings.json at it (merge, with backup) --------------------
if ! command -v jq >/dev/null 2>&1; then
  err "jq not found — finish by adding this key to $SETTINGS yourself:"
  err '  "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }'
  exit 1
fi

if [ -f "$SETTINGS" ]; then
  if ! jq empty "$SETTINGS" 2>/dev/null; then
    err "claude-statusline: $SETTINGS isn't valid JSON — leaving it untouched."
    err 'Add this key yourself: "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }'
    exit 1
  fi
  backup="$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
  cp "$SETTINGS" "$backup"
  existing=$(cat "$SETTINGS")
  printf 'Backed up settings  → %s\n' "$backup"
else
  existing='{}'
fi

printf '%s' "$existing" \
  | jq '.statusLine = {"type":"command","command":"~/.claude/statusline.sh"}' \
  > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
printf 'Updated settings    → %s (.statusLine)\n' "$SETTINGS"

printf '\nDone. The status line appears on your next message:\n'
printf '  <cwd> [branch] [worktree]  <model>  <effort>  <context%%>\n'
