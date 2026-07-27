# Android — emulator setup and accessibility-driven control

Everything here is first-party Android tooling. No third-party automation framework is needed
for the core loop, which matters for durability — `uiautomator` and `adb` are supported
interfaces, not reverse-engineered ones.

## Contents

- [Setup from nothing](#setup-from-nothing)
- [Controlling the device](#controlling-the-device)
- [Making web content visible to the tree](#making-web-content-visible-to-the-tree)
- [Chrome DevTools Protocol over adb](#chrome-devtools-protocol-over-adb)
- [Reaching a dev server on the host](#reaching-a-dev-server-on-the-host)
- [Real devices](#real-devices)
- [Gotchas](#gotchas)

## Setup from nothing

Check what already exists before installing — `adb` may be present from another toolchain:

```bash
which adb && adb version
ls "$HOME/Library/Android/sdk" 2>/dev/null || echo "no SDK in the default location"
```

On macOS with Homebrew. On Linux, install the command-line tools from the Android developer
site and the rest is identical.

**1. A JDK.** `sdkmanager` and `avdmanager` are Java programs and will not run without one.
Prefer a Homebrew formula over a `.pkg` cask — the formula installs into the Homebrew prefix
with no administrator prompt, while casks that ship a system installer need one.

```bash
brew install openjdk@21
```

Java 21 is a long-term-support release and is well exercised by Android tooling. Very new JDKs
occasionally break these tools.

**2. The command-line tools.**

```bash
brew install --cask android-commandlinetools
```

Note the SDK root it reports — Homebrew's is `$(brew --prefix)/share/android-commandlinetools`.
Everything below assumes `ANDROID_HOME` points there.

**3. Platform tools, emulator, and a system image.** Accept the licences first, or the install
silently declines.

```bash
export JAVA_HOME="$(brew --prefix)/opt/openjdk@21"
export ANDROID_HOME="$(brew --prefix)/share/android-commandlinetools"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

yes | sdkmanager --licenses > /dev/null
sdkmanager --install "platform-tools" "emulator" "platforms;android-36" \
                     "system-images;android-36;google_apis_playstore;arm64-v8a"
```

Pick the ABI matching the host CPU — `arm64-v8a` on Apple Silicon and ARM Linux, `x86_64` on
Intel. A mismatched image boots through slow emulation or not at all. List what's actually
offered rather than guessing an API level:

```bash
sdkmanager --list | grep "system-images;android-3[0-9];google_apis"
```

**Which image variant.** Both include Google Play *services*; the difference is narrower than
it sounds and is worth getting right up front, because changing it later means re-creating the
device:

- `google_apis_playstore` — ships the Play Store app so you can install real apps. It's a
  production build, so `adb root` is permanently refused.
- `google_apis` — no Play Store, but `adb root` and `adb remount` work. The one thing this
  actually buys you is writing a certificate into the *system* trust store, which since
  Android 7 is the only way a proxy can decrypt HTTPS traffic.

Root is **not** needed for automation. Tapping, swiping, typing, reading the tree, and taking
screenshots are all unprivileged. Choose `google_apis` only if you intend to inspect encrypted
network traffic; otherwise take the Play Store image.

**4. Create the virtual device.** Any profile from `avdmanager list device` works; the Pixel
profiles are the safest default.

```bash
echo "no" | avdmanager create avd -n Pixel_9_API_36 \
  -k "system-images;android-36;google_apis_playstore;arm64-v8a" -d pixel_9
```

Then adjust two settings in the AVD's `config.ini` (under `$HOME/.android/avd/<name>.avd/`):

- `PlayStore.enabled=yes` — `avdmanager` writes `no` even on a Play Store image, and the Play
  Store app is absent until you flip it.
- `hw.keyboard=yes` — lets the host keyboard type into the device, which makes text entry and
  TAB navigation work naturally.

**5. Persist the environment.** Append the four `export` lines from step 3 to the shell profile
(`~/.zshrc`, `~/.bashrc`) so `adb` and `emulator` resolve in new terminals. Setting `JAVA_HOME`
globally pins the JDK for everything on the machine — worth mentioning to the user if they do
other Java work.

**6. Boot and confirm.**

```bash
emulator -avd Pixel_9_API_36 &          # add -no-window to run headless
adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do sleep 2; done
adb devices -l
```

## Controlling the device

`adb shell uiautomator dump` **is** the accessibility tree — it serialises `AccessibilityNodeInfo`
straight to XML. Each node carries `text`, `content-desc` (the accessibility label),
`resource-id` (the developer-assigned test identifier), `hint`, `class`, `bounds`, and the state
flags `clickable`, `focusable`, `focused`, `scrollable`, `checkable`, `checked`, `enabled`,
`password`.

`resource-id` is the most stable handle when it's present — it comes from the app's source and
survives copy changes and translation. Prefer it over visible text for anything repeated.

Use `scripts/ui-android` for the loop:

```bash
ui-android tree                  # interactable elements with labels and bounds
ui-android find "sign in"        # preview matches before acting
ui-android tap "sign in"         # tap the tightest match
ui-android type "hello world"
ui-android key TAB               # TAB / ENTER / BACK / HOME / DPAD_DOWN ...
ui-android focus                 # which element has focus right now
ui-android shot screen.png
```

The underlying commands, when you need something the script doesn't wrap:

```bash
adb shell am start -a android.intent.action.VIEW -d "https://example.com"
adb shell am start -n com.example/.MainActivity
adb shell input tap 540 1200
adb shell input swipe 540 1600 540 600 300      # last arg is duration in ms
adb shell input text "hello%sworld"             # %s encodes a space
adb shell input keyevent KEYCODE_ENTER
adb exec-out screencap -p > shot.png
adb shell screenrecord /sdcard/v.mp4            # Ctrl-C, then adb pull
adb install -r app.apk
adb shell pm list packages
adb logcat -s MyTag
```

**Keyboard navigation works and is worth using.** `KEYCODE_TAB` moves focus through the page
and into browser chrome; the focused element is readable from the tree via `focused="true"`;
`KEYCODE_ENTER` activates it. That gives a fully keyboard-driven loop — `key TAB` → `focus` →
`key ENTER` — with no coordinates at all, which is the most robust form of this automation
when the app supports focus traversal.

## Making web content visible to the tree

**This is the single biggest gotcha on Android.** By default a `WebView` appears in the tree as
one opaque node — `content-desc="Web View"` with no children. Nothing inside a web page is
reachable, so `tap "sign in"` finds nothing on any web content, and it looks as though the tree
is broken.

It isn't. Building an accessibility tree for a page costs real work, so the browser engine
skips it until something signals that a user needs semantic content. `uiautomator` attaches as
its own privileged client and does not raise that signal. Enabling any accessibility service
does:

```bash
ui-android enable-a11y     # or the raw form below
adb shell settings put secure enabled_accessibility_services \
  com.android.systemui.accessibility.accessibilitymenu/.AccessibilityMenuService
adb shell settings put secure accessibility_enabled 1
```

After this, page elements appear as ordinary nodes with their own text and bounds.

**Use the Accessibility Menu service, not TalkBack.** TalkBack is the obvious candidate and it
does work for exposing the tree, but it also takes over touch handling — a single tap becomes
explore-by-touch and activation requires a double-tap. That silently breaks every `input tap`
you still rely on. The Accessibility Menu service reads the tree without owning input.

The setting is stored in the device's user data and survives reboots, but is lost if the device
is wiped. `enable-a11y` is idempotent, so re-running it costs nothing.

## Chrome DevTools Protocol over adb

For web content specifically, the DevTools Protocol is richer than the accessibility tree — the
real DOM, CSS selectors, JavaScript evaluation, and network activity. Chrome on Android exposes
it over a local abstract socket:

```bash
adb forward tcp:9222 localabstract:chrome_devtools_remote
curl -s http://localhost:9222/json/version     # browser and protocol version
curl -s http://localhost:9222/json             # open tabs, titles, URLs
```

Each target's `webSocketDebuggerUrl` accepts standard DevTools Protocol commands
(`Runtime.evaluate`, `DOM.querySelector`, `Page.navigate`, …). Reading the current URL this way
is a cheap and reliable way to confirm a navigation actually happened — far better than
screenshotting and reading the address bar.

Use the accessibility tree for native and system UI, and the DevTools Protocol for web content.

## Reaching a dev server on the host

The emulator is a virtual machine with its own loopback, so `localhost` inside it is not the
host's `localhost`. Two ways across:

```bash
adb reverse tcp:3000 tcp:3000    # device's localhost:3000 -> host's :3000
```

or use the special alias `10.0.2.2`, which the emulator maps to the host, with no setup at all:
`http://10.0.2.2:3000`. `adb reverse` is better when the app or a cookie is hard-coded to
`localhost`.

## Real devices

Everything above works unchanged on a physical device over USB, except the emulator commands.
Enable Developer Options (tap Build Number seven times), turn on USB debugging, connect, and
accept the RSA prompt on the device. `adb devices` shows `unauthorized` until that prompt is
accepted — a common few minutes of confusion.

With more than one device attached, every command needs a target: `adb -s <serial> …`, and the
helper script takes `-s <serial>` for the same reason.

## Gotchas

- **First-run screens intercept the first launch.** A freshly installed Chrome shows sign-in
  and notification prompts before it will load a URL. Tap through them once by label; they
  don't come back unless the app's data is cleared. Any app can do this — if a launch seems to
  ignore your intent, dump the tree and look at what's actually on screen.
- **Fixed banners eat gestures.** Cookie banners and bottom toolbars sit above the content, so
  a swipe starting inside them scrolls nothing. Dismiss the banner first, then scroll.
- **A tap fired too early lands on nothing.** Cookie banners in particular render after page
  load. Confirm the element is in the tree before tapping rather than sleeping and hoping.
- **`input text` splits on spaces.** Encode them as `%s`, which the helper script does for you.
- **`adb root` is refused on Play Store images** with `adbd cannot run as root in production
  builds`. That's expected, not a fault — see the image-variant discussion above.
- **The tree is a snapshot.** It reflects the moment it was dumped. After any action that
  animates, re-dump before locating the next element.
