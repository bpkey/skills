---
name: knock-knock-neo
description: Play the cinematic Matrix "Wake up, Neo..." wake-up sequence on the user's machine — digital rain, slow ghost-typed messages ("Wake up, Neo...", "The Matrix has you...", "Follow the white rabbit.", "Knock, knock, Neo."), audible knocks, a timed macOS notification from "Unknown", and a white-rabbit keypress ending on "There is no spoon." Use whenever the user invokes /knock-knock-neo, or asks for "the Matrix experience", "wake up Neo", "knock knock Neo", "digital rain / Matrix rain in my terminal", "make my terminal look like the Matrix", "follow the white rabbit", or wants a Matrix-style terminal surprise or easter egg — even if they don't name the skill. Purely local and harmless; nothing leaves the machine.
---

# Knock, Knock, Neo

Recreate the opening scene of The Matrix for the user, as if they were Neo: their screen gets taken over by a green-on-black terminal window that plays digital rain, then slowly ghost-types the iconic messages, knocks audibly, and pings a macOS notification from "Unknown" timed to the knock.

The full sequence lives in `scripts/neo.py` (Python 3 + curses, no dependencies). Do not rewrite it — run it.

## How to run (macOS, the full experience)

1. **Launch the script in its own dedicated Terminal window** so it takes over visually. Use the built-in "Homebrew" profile (green on black):

   ```bash
   osascript <<'EOF'
   tell application "Terminal"
     activate
     set w to do script "clear; python3 '<absolute-path-to>/scripts/neo.py'; exit"
     try
       set current settings of w to settings set "Homebrew"
     end try
     set bounds of front window to {0, 0, 1600, 1000}
   end tell
   EOF
   ```

   Resolve `<absolute-path-to>` from this skill's own directory. The `try` block matters — if the user renamed or removed the Homebrew profile, the show still goes on in their default theme.

2. **Schedule the out-of-band knock** — a macOS notification that arrives roughly when the on-screen knock scene plays (~40 s in). Run it as a background task so it doesn't block:

   ```bash
   (sleep 40 && osascript -e 'display notification "Knock, knock, Neo." with title "Unknown" sound name "Bottle"') &
   ```

   This is the touch that reaches *outside* the terminal — keep it unless the user asks for a silent run.

3. **Tell the user what's happening** only AFTER launching — the surprise is part of the experience. Then briefly narrate the sequence: rain fades in → three ghost-typed messages that dissolve → two knocks + "Knock, knock, Neo." → white rabbit waits for a keypress → rain swallows the screen → "There is no spoon."

## Sequence timing (for reference, not for editing)

The script is self-contained: ~1.5 s of black silence, ~7 s of rain fading in, each message types at 90–220 ms per character with a blinking block cursor, dissolves character-by-character, knocks play via `afplay` on the system `Bottle.aiff` sound, and the finale waits for any keypress.

## Fallbacks

- **Non-macOS / no Apple Terminal** (Linux, SSH, iTerm-only setups): run `python3 scripts/neo.py` directly in the current terminal. Curses works anywhere; the script degrades gracefully — `afplay` and the notification simply don't fire. Skip step 2.
- **No audio hardware or `afplay` missing**: the script ignores sound failures; nothing to do.
- **User asks to make it permanent**: offer to install a small wrapper command on their PATH or a scheduled job that knocks at a random evening moment — but only build that if they ask.

## Safety

Everything is local: one curses script, system sounds, one notification. It writes no files, reads no user data, and touches no network. Never extend it to do otherwise.
