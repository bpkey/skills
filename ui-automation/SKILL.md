---
name: ui-automation
description: Drive an Android emulator, an iOS simulator, or a Chrome browser from the command line — reading the UI as structured text (accessibility tree or DOM) and acting on elements by name, instead of burning tokens on screenshots and guessing tap coordinates. Use this whenever the work involves controlling a phone, emulator, simulator, or browser — setting one up from scratch, tapping or typing into an app, filling a form, navigating a site, checking how a page renders on mobile, writing a UI test loop, or letting an agent click through a flow. Trigger it on requests like "test this on mobile", "open the app in the emulator", "set up an Android emulator", "run this in the iOS simulator", "click through the signup flow", "take a screenshot of the page on a phone", "automate the browser", or "why can't my agent see the page content". Also use it when an agent is already automating a UI and is stuck, looping on screenshots, or tapping coordinates that miss.
---

# UI automation — read the tree, not the pixels

Every platform here can hand you the interface as **structured text**: Android exposes the
accessibility node tree, iOS exposes the accessibility element tree, and Chrome exposes the
DOM. Each element arrives with a name, a role, and exact bounds. Screenshots are the fallback,
not the default.

This matters for two independent reasons, and the second one is the one people underestimate.

**Cost.** A phone screenshot resized to model limits runs roughly 1,000–1,600 tokens. The
filtered list of interactable elements on the same screen is usually 100–400. Over a
twenty-step flow that difference compounds into the majority of a context window.

**Correctness.** A screenshot tells you what something looks like, not where it is. Reading a
coordinate off an image means estimating, and estimates miss — controls shift by a few pixels
between renders, a banner appears and pushes everything down, a device has a different scale
factor. The tree carries the element's real bounds, so the tap lands where the element
actually is. You also get to *search* the tree, which you can't do with an image.

So: locate elements by their accessibility label, identifier, or text. Compute the tap point
from the element's own bounds. Reach for a screenshot when you specifically need to see
appearance.

## Pick the platform

Read the matching reference file before running anything — each one covers install-from-nothing
and the platform's specific traps.

| Target | Read | Control channel |
|---|---|---|
| Android phone/tablet emulator, or a real device over USB | `references/android.md` | `adb` + the accessibility node tree |
| iPhone/iPad simulator | `references/ios.md` | `xcrun simctl` for device state, `idb` for gestures and the element tree |
| Chrome on the desktop | `references/chrome.md` | Claude in Chrome extension, or the DevTools Protocol |
| A web page inside the Android emulator | `references/android.md` (DevTools section) | DevTools Protocol tunnelled over `adb` |

If the user hasn't said which platform, ask — the setups are large downloads and unrelated to
each other. "Test on mobile" most often means one specific platform they already care about.

## The loop

Whatever the platform, the shape is the same, and it's worth internalising because it's what
keeps a long automation from drifting:

1. **Observe** — dump the tree, filtered to interactable elements. Cheap, so do it often.
2. **Locate** — find the target by its label, identifier, or text. If nothing matches, the
   screen isn't what you assumed. Re-dump rather than tapping hopefully.
3. **Act** — tap, type, or send a key. The helper scripts derive coordinates from the matched
   element, so you never type a number.
4. **Verify** — dump again and confirm the state actually changed. This is the step that gets
   skipped, and skipping it is why automations fail silently ten steps later.

A useful habit for step 4 on long pages or lists: act, re-dump, and compare. If the tree is
byte-identical after a scroll or a tap, the action didn't take effect — a gesture landed on a
fixed header, a modal is swallowing input, or the page has genuinely reached its end. Treat "no
change" as information, not as success.

## When a screenshot is the right tool

Don't over-rotate — some questions are genuinely visual, and the tree cannot answer them:

- **Appearance** — does this look right, is the layout broken, is contrast bad, did the
  spacing regress. The tree describes structure, never rendering.
- **Content the tree can't see.** This is the sharpest limit and it differs per platform. On
  Android, web content inside a WebView is a single opaque node until an accessibility service
  is enabled (`references/android.md` explains the fix). On iOS, the element tree never
  enumerates WebKit page content at all, no matter what you enable — there's a documented
  workaround in `references/ios.md`.
- **Proof for a human** — when the user asked to *see* something, produce the image.
- **Debugging a stuck automation** — one screenshot to find out what's actually on screen
  beats five more blind tree dumps.

Both helper scripts include a screenshot command, so switching costs nothing.

## Helper scripts

`scripts/ui-android` and `scripts/ui-ios` implement the loop with a shared command vocabulary,
so the two platforms feel the same:

```
tree                 list interactable elements with labels and bounds
find <query>         show matching elements
tap <query>          tap the best match — no coordinates
type <text>          type into the focused field
key <name|code>      send a key (TAB, ENTER, BACK ...)
shot <file.png>      screenshot, when you need to see it
```

They're plain Python 3 with no third-party imports. Run them from the skill directory, or copy
them onto `PATH`. Each prints usage with `--help` and exits with a clear message when its
platform tooling is missing, rather than failing obscurely.

Query matching is a case-insensitive substring across every name-like attribute, so
`tap "sign in"` finds a button labelled "Sign In". Wrap the query in `/.../` for a regular
expression. When several elements match, the smallest wins — the real control rather than a
container that inherited the same label.

## Setting up from nothing

All three setups are free and need no paid tooling. They do involve multi-gigabyte downloads
(Android system images, the Xcode iOS runtime), so start them early and in the background, and
tell the user what's downloading. Each reference file has the exact command sequence, verified
end to end rather than recalled — but toolchains move, so if a command fails, read the tool's
own `--help` rather than retrying a remembered flag.

Two rules that save real time:

- **Verify by doing, not by asserting.** After setup, actually navigate somewhere and read the
  result back. A booted emulator proves nothing about whether you can drive it.
- **Never ask the user to type a password into a terminal.** If a step genuinely needs
  administrator rights on macOS, run it through the native authorisation dialog:
  `osascript -e 'do shell script "…" with administrator privileges'`. In practice none of these
  setups require root — if you find yourself reaching for `sudo`, re-read the reference file.

## Reference index

- `references/android.md` — install the SDK and create an emulator; drive it with `adb`; make
  web content visible to the tree; tunnel the DevTools Protocol; real devices over USB.
- `references/ios.md` — Xcode and simulator runtimes; what `simctl` can and cannot do; install
  and use `idb` for gestures and the element tree, including its install traps and a logging
  hazard worth knowing about.
- `references/chrome.md` — driving desktop Chrome; why an extension connection fails and how to
  diagnose it; reading pages as text instead of screenshots; the DevTools Protocol directly.
