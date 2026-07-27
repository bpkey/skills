# iOS — simulator setup and accessibility-driven control

iOS splits across two tools, and knowing which does what saves a lot of wasted searching:
Apple's `simctl` drives **device state**, and a third-party bridge drives **gestures and the
element tree**. Apple ships no command-line access to the accessibility tree at all.

## Contents

- [Setup from nothing](#setup-from-nothing)
- [What simctl does](#what-simctl-does)
- [What simctl cannot do](#what-simctl-cannot-do)
- [Installing idb](#installing-idb)
- [Controlling the device](#controlling-the-device)
- [The WebKit blind spot](#the-webkit-blind-spot)
- [A logging hazard worth knowing about](#a-logging-hazard-worth-knowing-about)
- [Reliability](#reliability)
- [Gotchas](#gotchas)

Everything below is macOS-only. There is no iOS simulator on Linux or Windows — if that's the
host, the honest answer is a cloud device farm or a real device, not a workaround.

## Setup from nothing

**Check first — this may be a no-op.** Any machine with Xcode installed usually already has
simulators ready, and the download is very large, so never start it speculatively:

```bash
xcode-select -p                     # expect a path inside Xcode.app
xcrun simctl list devices available # expect an "-- iOS NN.N --" section with devices
xcrun simctl list runtimes          # a runtime marked "not downloaded" is the thing to fix
```

**Xcode.** Required — the simulator ships inside it. The Command Line Tools package alone is
not enough, which is a common dead end. Install from the App Store, or with the `xcodes` CLI
for a scriptable path. It is free but very large; tell the user before starting.

**A runtime**, if `simctl list runtimes` shows none downloaded:

```bash
xcodebuild -downloadPlatform iOS
```

Multi-gigabyte — run it in the background and report progress.

**First launch.** A never-run Xcode may need its licence accepted and components installed.
Check before escalating, because usually neither is needed:

```bash
xcodebuild -checkFirstLaunchStatus   # exit 0 means nothing to do
```

If it does need root, use the native macOS authorisation dialog rather than asking the user to
type a password into a terminal:

```bash
osascript -e 'do shell script "xcodebuild -runFirstLaunch" with administrator privileges'
```

**Boot a device.** Reuse an existing one from `simctl list devices` rather than creating a
duplicate:

```bash
xcrun simctl boot "iPhone 17 Pro"
xcrun simctl bootstatus "iPhone 17 Pro"   # blocks until the boot completes
open -a Simulator                          # show the window; headless works without this
```

## What simctl does

Any `<device>` slot accepts a UDID, the device name, or the literal `booted`. With more than
one simulator running, `booted` picks one arbitrarily — pass an explicit UDID in scripts.

```bash
# lifecycle
xcrun simctl list devices available
xcrun simctl list -j devices                  # JSON, for scripting
xcrun simctl shutdown "iPhone 17 Pro"         # or: shutdown all
xcrun simctl erase "iPhone 17 Pro"            # factory reset; device must be shut down first
xcrun simctl create "MyPhone" "iPhone 17 Pro" "com.apple.CoreSimulator.SimRuntime.iOS-26-5"
xcrun simctl delete "MyPhone"                 # or: delete unavailable

# apps
xcrun simctl install booted /path/to/MyApp.app
xcrun simctl launch --console booted com.example.MyApp    # streams stdout/stderr
xcrun simctl terminate booted com.example.MyApp
xcrun simctl listapps booted                              # installed bundle identifiers
xcrun simctl get_app_container booted com.example.MyApp data

# state and I/O
xcrun simctl openurl booted https://example.com           # also custom schemes
xcrun simctl io booted screenshot shot.png
xcrun simctl io booted recordVideo --codec=h264 out.mp4   # SIGINT finalises the file
xcrun simctl push booted com.example.MyApp payload.json   # needs an "aps" key, under 4 KB
xcrun simctl location booted set 37.3349,-122.0090
xcrun simctl ui booted appearance dark                    # light | dark
xcrun simctl ui booted content_size accessibility-large   # dynamic type
xcrun simctl status_bar booted override --time 9:41 --cellularBars 4 --batteryState charged
echo "text" | xcrun simctl pbcopy booted                  # host -> device clipboard
xcrun simctl pbpaste booted
xcrun simctl addmedia booted photo.jpg                    # photos, videos, vCards
xcrun simctl privacy booted grant photos com.example.MyApp
xcrun simctl keychain booted add-root-cert myCA.pem       # trust a CA for HTTPS inspection
```

Environment variables reach a launched app via a `SIMCTL_CHILD_` prefix on the host —
`SIMCTL_CHILD_API_URL=… xcrun simctl launch booted com.example.MyApp`.

## What simctl cannot do

**There is no tap, swipe, or type.** This surprises everyone, so state it plainly rather than
searching for a hidden subcommand — there isn't one. `simctl ui` covers only appearance,
contrast, and dynamic type. Nor is there any accessibility-tree access: not in `simctl`, not in
`devicectl` (which targets real devices and offers no UI automation), and Accessibility
Inspector is GUI-only with no scripting interface.

Two ways to close the gap:

- **`idb`** — Meta's iOS Development Bridge. Lightweight, genuinely command-line, gives both
  gestures and the element tree. Covered below. Free and open source.
- **XCUITest** — Apple's official path. Robust and supported, but it means writing a UI test
  target in Swift and running it through `xcodebuild test`, which is a poor fit for ad-hoc
  agent-driven automation.

Use `idb` for interactive work; reach for XCUITest when the automation must be durable and
owned, or if `idb` breaks. Read the [reliability](#reliability) section before building
anything load-bearing.

## Installing idb

Two steps, and both have a trap that produces a confusing error.

```bash
brew tap facebook/fb
brew trust facebook/fb          # newer Homebrew refuses to load formulae from untrusted taps
brew install idb-companion
```

Without `brew trust`, the install fails with `Refusing to load formula … from untrusted tap`.

```bash
brew install pipx
pipx install --python python3.12 fb-idb
```

**Pin the Python version.** The client is old code that calls `asyncio.get_event_loop()`, whose
implicit-loop behaviour was removed in Python 3.14. On a newer interpreter every invocation
dies with `RuntimeError: There is no current event loop in thread 'MainThread'`. If a future
Homebrew upgrade relinks `pipx` to a newer Python, reinstall with the same pin.

Confirm it can see the simulator:

```bash
idb list-targets
```

## Controlling the device

`scripts/ui-ios` wraps `idb` with the same vocabulary as the Android helper and starts
`idb_companion` on demand, so there's no daemon to remember:

```bash
ui-ios tree                      # accessibility elements of the foreground app
ui-ios find "Continue"
ui-ios tap "Continue"            # tap the matched element's centre
ui-ios type "hello"
ui-ios key 40                    # HID keycodes: 40 Return, 41 Esc, 42 Backspace, 43 Tab
ui-ios button HOME               # HOME | LOCK | SIDE_BUTTON | SIRI
ui-ios swipe 200 700 200 200
ui-ios probe 200 400             # describe whatever is under a point
ui-ios scan                      # grid-probe the screen — recovers web content
ui-ios shot screen.png
```

Elements expose `AXLabel`, `AXValue`, an identifier, a type (`Button`, `Link`, `TextField`, …),
and a frame. Native apps often set stable identifiers — those are the best handle, exactly like
`resource-id` on Android.

Raw equivalents, with `idb_companion --udid <UDID>` running:
`idb ui describe-all|describe-point|tap|text|key|button|swipe --udid <UDID>`.

**Swipes need `--delta`.** Without it the gesture is delivered as a single jump, which the
system does not interpret as a drag, so the view silently doesn't scroll. Supply intermediate
touch points and a duration:

```bash
idb ui swipe --udid "$UDID" --duration 0.25 --delta 12 200 760 200 150
```

This is a genuinely confusing failure — the command succeeds, returns nothing, and the screen
is unchanged. If scrolling seems not to work, this is almost always why.

## The WebKit blind spot

`idb ui describe-all` enumerates only the foreground app's own in-process elements. **Web page
content inside Safari or a web view is invisible to it** — a full page of content returns a
handful of browser chrome elements and nothing else. Neither flat nor `--nested` output helps,
and no setting changes it. This is the counterpart to Android's WebView problem, but unlike
Android there is no switch to flip.

Two ways through:

- **`describe-point` does reach web content.** Probing a coordinate returns the element there,
  so a grid scan recovers the page. `ui-ios scan` does this; it costs roughly 10–15 seconds per
  screen, which is a real cost but still cheaper and more precise than reasoning over an image.
- **Safari remote debugging** for heavy web work — the same idea as the Android DevTools
  Protocol section, driving the page directly instead of through the accessibility layer.

For native app automation this limit never bites. It only matters when the target is a web page.

## A logging hazard worth knowing about

`idb_companion` writes **its entire process environment into its log at startup, at every log
level**. Started from an ordinary interactive shell, that means every exported API key, token,
and secret is written to disk in plaintext.

`scripts/ui-ios` launches the companion with a deliberately minimal environment (`PATH`, `HOME`,
`USER`, `LANG`, `TMPDIR`, `SHELL`, `DEVELOPER_DIR`) and a mode-`0600` log file, so secrets in
the parent shell never reach it.

If you start `idb_companion` by hand from a normal shell, it will leak. Either use the script,
or start it with a scrubbed environment yourself (`env -i PATH="$PATH" HOME="$HOME" …`). If it
has already run unscrubbed, the logs are worth finding and deleting — and any secret that was
in that environment should be treated as exposed and rotated.

## Reliability

Be straight with the user about this rather than discovering it later.

`idb` works, but it is effectively unmaintained — the last substantive release was 2022, and it
depends on Apple private frameworks. A future Xcode can break it with no upstream fix coming,
and its Python client has already broken once on a newer interpreter. Latency is good (roughly
0.2 s per command once the companion is warm, about 1.3 s cold). It needs no root, and nothing
in it is paid or trial-limited.

That's an acceptable trade for interactive and exploratory automation. For a test suite that
has to keep working unattended, prefer **Appium with the XCUITest driver** — heavier (a Node
server plus WebDriverAgent) but actively maintained, and it drives by accessibility identifier
and exposes the tree through `mobile: source`. Note this recommendation is on reputation, not
because it was verified here.

## Gotchas

- **`erase` fails on a booted device.** Shut it down first.
- **`booted` is ambiguous** when several simulators are running. Use an explicit UDID.
- **There is no "press home" in `simctl`.** Use `ui-ios button HOME`, or terminate the
  foreground app by bundle identifier.
- **`recordVideo` finalises only on SIGINT.** Ctrl-C or `kill -INT`; a `kill -9` leaves a
  corrupt file. It prints `Recording started` to *stderr* once the first frame lands, which is
  the reliable signal to wait for.
- **Dark mode may not look dark.** `ui appearance dark` sets the system appearance, but Safari
  tints its chrome to the loaded page, so a page without dark-mode styling still renders light.
  Verify with `xcrun simctl ui booted appearance` or screenshot a system surface, not a page.
- **`push` only sends ordinary remote notifications.** VoIP, complication, and File Provider
  types are unsupported, the payload needs a top-level `aps` key and must stay under 4 KB, and
  the target app must already be installed.
- **`objc` duplicate-class warnings** appear on most `idb` invocations. Harmless noise.
