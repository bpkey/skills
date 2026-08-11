# Chrome — driving the desktop browser

Two independent ways in. Pick by what's available rather than by preference:

- **The Claude in Chrome extension**, exposing `mcp__claude-in-chrome__*` tools. Drives the
  user's real browser with their real sessions, so it can reach anything they're logged into.
  Needs the extension installed and paired, which is where nearly all the trouble lives.
- **The DevTools Protocol**, by starting Chrome with a debugging port. No extension, fully
  scriptable, but it runs in a separate browser instance with its own empty profile unless you
  point it at a real one.

## Contents

- [Reading pages cheaply](#reading-pages-cheaply)
- [Extension connection troubleshooting](#extension-connection-troubleshooting)
- [Chrome profiles and private content](#chrome-profiles-and-private-content)
- [The DevTools Protocol directly](#the-devtools-protocol-directly)
- [Gotchas](#gotchas)

## Reading pages cheaply

The DOM is the accessibility tree's equivalent here, and the same principle applies: read the
page as text and act on elements by selector or role, rather than screenshotting and clicking
coordinates.

With the extension, load the tools in **one** `ToolSearch` call rather than one per tool — the
select query takes a comma-separated list, and each extra call is a wasted round trip:

```
ToolSearch "select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__read_page,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__tabs_create_mcp"
```

Add task-specific tools to that same call when you already know you'll need them —
`get_page_text`, `find`, `form_input`, `read_console_messages`, `read_network_requests`,
`javascript_tool`, `gif_creator`.

Then prefer, in rough order of cost:

1. **`get_page_text`** — the page as plain text. Cheapest, and usually enough to answer "what
   does this page say" or "did the navigation work".
2. **`read_page`** — structured elements with the identifiers the click tools accept.
3. **`find`** — locate one element without pulling the whole page.
4. **`computer`** screenshots — only for appearance, or when the structure genuinely isn't
   telling you what's on screen.

`read_console_messages` accepts a `pattern` regular expression. Use it — console output is
frequently enormous, and filtering to the lines you care about is the difference between a
useful signal and a flooded context.

**Start every session with `tabs_context_mcp`.** It lists the user's current tabs, which tells
you what they're working on. Never reuse a tab ID from an earlier session — they don't persist.
Create a new tab with `tabs_create_mcp` unless the user asked you to work in an existing one.
If a tool reports an invalid tab, call `tabs_context_mcp` again for fresh IDs rather than
retrying.

## Extension connection troubleshooting

"Browser extension is not connected" is the common failure, and it's genuinely hard to debug
because **three unrelated causes produce that identical message**. Check them in this order.

**1. Account mismatch.** The CLI and the extension find each other through a cloud rendezvous
keyed to the signed-in account. If the extension is signed out, or signed into a *different*
account than the CLI session, you get the generic error no matter how healthy everything else
is. Check which account the CLI is using:

```bash
python3 -c "import json;print(json.load(open('$HOME/.claude.json'))['oauthAccount']['emailAddress'])"
```

Then open the extension in the Chrome profile being controlled and confirm it shows that same
account. This bites hardest when the user has several accounts and several Chrome profiles —
extension sign-in is per-profile and can lapse silently.

**2. Another app holding the native-messaging slot.** The extension keeps exactly one local
native-messaging connection, and it tries the Claude desktop app's host *before* the CLI's. The
desktop app's helper answers even when the app isn't running, so where both are installed the
desktop app deterministically wins and the CLI never gets the slot.

Check who currently holds it:

```bash
pgrep -lf chrome-native-host
ls "/tmp/claude-mcp-browser-bridge-$USER/" 2>/dev/null   # one socket per connected profile
```

A path inside the desktop app means it won. To hand the slot to the CLI, rename the desktop
app's manifest aside and restart Chrome fully:

```bash
mv "$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.anthropic.claude_browser_extension.json"{,.disabled}
```

Reversible — rename it back to restore the desktop app's own browser control. On Linux the
manifest lives under `~/.config/google-chrome/NativeMessagingHosts/`.

**3. Chrome hasn't actually restarted, or restarted into the wrong profile.** Manifest changes
need a full quit, not just closing windows:

```bash
osascript -e 'tell application "Google Chrome" to quit'   # then wait for the process to exit
open -a "Google Chrome" -n --args --profile-directory="Profile 1"
```

Verify with `tabs_context_mcp` — a successful tab list is the only proof. A previously seen
Claude tab group proves nothing, since tab groups persist across restarts.

## Chrome profiles and private content

When several Chrome profiles exist, **which profile a URL opens in decides whether the user can
see it at all**. A private resource — an internal site, a private repository, a company
document — renders as "not found" in a profile whose account lacks access. Many sites return a
404 for a private resource rather than a permission error, so the page looks deleted when it is
merely invisible to that account. Don't debug the URL; check the profile.

Map profile directories to accounts:

```bash
python3 -c "
import json,os
p=os.path.expanduser('~/Library/Application Support/Google/Chrome/Local State')
c=json.load(open(p))['profile']['info_cache']
[print(k,'->',v.get('user_name') or v.get('gaia_name') or '(none)') for k,v in c.items()]
"
```

Then open the URL in the profile that has access:

```bash
open -na "Google Chrome" --args --profile-directory="<Profile Dir>" "https://example.com/page"
```

Several URLs in one invocation open as several tabs.

### `--profile-directory` only works at cold start

**Chrome honors `--profile-directory` when it is launching, and ignores it when it is already
running.** A second Chrome process finds the running instance, hands over its command line, and
exits; the running instance then opens the URL in **whatever window was most recently active**,
in whatever profile that window belongs to. The flag is silently dropped.

This is a property of Chrome's single-instance model, not of any one command spelling. All of
these behave identically once Chrome is up — none of them targets a profile:

```bash
open -a "Google Chrome" --args --profile-directory="X" "<url>"          # flag ignored
open -na "Google Chrome" --args --profile-directory="X" "<url>"         # flag ignored
open -na "Google Chrome" --args --profile-directory="X" --new-window "<url>"  # flag ignored
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --profile-directory="X" "<url>"                                       # flag ignored
```

The failure is invisible, and worse, it is *intermittently correct*: when the intended profile
happens to own the active window, the URL lands right and the command looks like it worked.
Reaching for a different spelling after a miss is chasing a coincidence.

So do not assume placement — establish it:

- **Cold start is the one reliable path.** If the target profile has no window yet, launching it
  with the flag genuinely opens that profile. Quitting Chrome entirely first (`osascript -e 'tell
  application "Google Chrome" to quit'`, then wait for the process to exit) makes the next launch
  a cold start, at the cost of disrupting every other window.
- **With Chrome already running, verify where the tab landed** rather than trusting the flag. For
  a private URL the tell is the title: a "not found" page means it opened in a profile without
  access.
- **A router extension is the robust answer** if this matters routinely. Only code running inside
  Chrome can move a URL between profiles reliably; a command line cannot.

### Raise the window, or the user sees nothing

Opening a tab does not bring Chrome forward. The page loads in a window the user may not be
looking at, and to them the command did nothing — which reads as a failure and invites
re-running it, piling up duplicate tabs. After opening a URL the user asked to see, activate
Chrome and select the tab:

```bash
osascript <<'EOF'
tell application "Google Chrome"
  activate
  repeat with w in windows
    set i to 0
    repeat with t in tabs of w
      set i to i + 1
      if URL of t contains "URL_FRAGMENT" then
        set active tab index of w to i
        set index of w to 1
        return "raised"
      end if
    end repeat
  end repeat
  return "not found"
end tell
EOF
```

**The extension is paired to one profile at a time**, which is often the default one. If the
extension is bound to a profile without access, an MCP-driven `navigate` returns that same
misleading "not found" — the call succeeds and the page is empty. That's a profile mismatch,
not a broken link. The `open` command above needs no extension, but note the trade-off: only the
extension-controlled profile can be *read* by the browser tools, so a page opened that way is for
the user to look at, not for you to scrape.

## The DevTools Protocol directly

No extension needed. Start Chrome with a debugging port and a scratch profile:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-automation &

curl -s http://localhost:9222/json/version
curl -s http://localhost:9222/json          # open targets with their webSocketDebuggerUrl
```

Drive targets over the WebSocket with `Page.navigate`, `Runtime.evaluate`,
`DOM.querySelector`, `Input.dispatchMouseEvent`, and friends. `Accessibility.getFullAXTree`
gives the browser's own accessibility tree if you want the same shape as the mobile platforms.

`--user-data-dir` is what makes this a separate instance; without it Chrome may attach to a
running browser and ignore the port. Point it at the real profile directory only if the
automation genuinely needs the user's logged-in sessions, and say so first — it's their live
browser state.

For Chrome running inside an Android emulator, the same protocol is reachable over `adb` —
see `references/android.md`.

## Gotchas

- **Never trigger a JavaScript `alert`, `confirm`, or `prompt`.** A modal dialog blocks the
  event loop, and the extension stops receiving commands entirely — the session goes
  unresponsive until a human dismisses it. Avoid clicking things likely to confirm, warn the
  user first if you must, and use `console.log` plus `read_console_messages` for diagnostics
  instead of `alert`.
- **Site permissions are per-site.** The extension asks for access; a tool failing on one
  domain while working on another is usually permissions, not connectivity.
- **Stop after two or three failed attempts.** These failures cluster into a few known causes,
  and retrying the same call doesn't move through any of them. Report what was tried and what
  the error said, and ask — that's faster for everyone than another round of blind retries.
