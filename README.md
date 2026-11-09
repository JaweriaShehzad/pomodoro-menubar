# Pomodoro for the Mac menu bar

A tiny Pomodoro timer that lives in your Mac's menu bar. Click ▶, study for 45 minutes, take a 15-minute break, and watch your daily session count go up.

```
▶ 45:00          ready, click to start
● 32:10  2/8     focus session (green)
☕︎ 09:41  3/8     break (red)
```

## Features

- **One-click start.** Click **▶ 45:00** in the menu bar and the 45-minute focus session begins.
- **Live countdown in the menu bar.** Green during focus, red during the break.
- **Automatic break.** When focus ends, a 15-minute break starts by itself. You get a notification and the timer **beeps for about 30 seconds**. Click the timer to silence it.
- **Your own alarm song (optional).** Add any audio file and it plays on repeat when focus ends, until you click the timer. See [Use your own alarm song](#use-your-own-alarm-song).
- **Break-over reminder.** A few beeps and a notification tell you when it's time to start again.
- **Daily session counter.** After each full 45-minute session the count goes up (`1/8`, `2/8`, …) toward a goal of 8 sessions (6 hours). The menu shows your total time studied today.
- **Late-night friendly.** A "study day" runs from 5 AM to 5 AM, so sessions after midnight still count toward the same day.
- **Survives restarts.** Your count and any running timer are saved, so quitting the app or restarting your Mac doesn't lose them.
- **Lightweight.** One Swift file, no Dock icon, no dependencies.

## Install

Requires macOS 12 or later.

### Option 1: Download the app (easiest)

1. Go to the [**Releases**](../../releases/latest) page and download `Pomodoro.zip`.
2. Unzip it and drag **Pomodoro.app** into your **Applications** folder.
3. The first time, **right-click Pomodoro.app → Open → Open**. The app isn't signed with an Apple Developer certificate, so macOS asks you to confirm once.
   - If macOS still blocks it, open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway**.
4. Look for **▶ 45:00** in your menu bar.

### Option 2: Build from source

You need the Xcode Command Line Tools (`xcode-select --install` if you don't have them).

```bash
git clone https://github.com/JaweriaShehzad/pomodoro-menubar.git
cd pomodoro-menubar
./install.sh
```

This builds the app, installs it to `~/Applications/Pomodoro.app` and launches it.

To also start it automatically every time you log in:

```bash
./install.sh --login
```

## How to use

| You want to… | Do this |
|---|---|
| Start a focus session | Click **▶ 45:00** |
| Silence the beeping | Click the timer |
| Skip straight to the break | Click the timer → **Skip to break** |
| Stop the timer | Click the timer → **■ Stop** |
| Start the next session early during a break | Click the timer → **▶ Start next focus now** |
| See today's total | Click the timer while it's running, or right-click it any time. The top line shows e.g. *Today: 3/8 sessions · 2h 15m studied* |
| Add a session you did without the timer | Right-click → **+1 session (add manually)** |
| Fix a wrong count | Right-click → **−1 session** or **Reset today's count** |
| Quit | Right-click → **Quit Pomodoro** |

**What counts as a session:** only focus sessions that run the full 45 minutes. Using **Skip to break** or **Stop** doesn't add to the count.

## Use your own alarm song

Instead of beeps, Pomodoro can play a song of your choice on repeat when a focus session ends. It keeps playing until you click the timer.

1. Open the alarm folder. Paste this into Terminal (it creates the folder if needed):
   ```bash
   mkdir -p ~/Library/Application\ Support/Pomodoro && open ~/Library/Application\ Support/Pomodoro
   ```
2. Put an audio file in that folder and name it **`alarm.mp3`**. You can also use `alarm.m4a`, `alarm.wav`, `alarm.aiff` or `alarm.aac`.
3. That's it. No restart needed: the app looks for the file each time a session ends.

**Got a video instead (`.mov` or `.mp4`)?** Convert it to audio with macOS's built-in tool:

```bash
avconvert --source ~/Downloads/your-video.mov --preset PresetAppleM4A \
  --output ~/Library/Application\ Support/Pomodoro/alarm.m4a
```

To go back to beeps, delete the `alarm` file. The end-of-break reminder always uses short beeps.

## Customize

Open `Pomodoro.swift` and change these lines near the top:

```swift
let FOCUS: TimeInterval = 45 * 60   // focus length in seconds
let BREAK: TimeInterval = 15 * 60   // break length in seconds
let DAILY_GOAL = 8                  // sessions per day
```

The beep sound is set in `startBeeping` (`"Glass"`). Any sound in `/System/Library/Sounds` works, for example `"Ping"`, `"Hero"` or `"Submarine"`. The start of the study day (5 AM) is set in `Tally.today`.

Then run `./install.sh` again to rebuild.

## Uninstall

```bash
./install.sh --uninstall
```

Or, if you installed from the download: quit Pomodoro from its menu and drag it from Applications to the Trash. To also remove the saved count:

```bash
defaults delete local.pomodoro.menubar
```

## How it works

- `Pomodoro.swift`: the whole app. It's an `NSStatusItem` (menu bar item) that updates every half second. It works out the time left from a saved end time, so it stays accurate even if your Mac sleeps.
- `Info.plist`: marks it as a menu-bar-only app (`LSUIElement`), so there's no Dock icon.
- `install.sh`: compiles with `swiftc`, bundles the `.app`, ad-hoc signs it and, with `--login`, adds a LaunchAgent so it opens at login.
- Settings are stored with `UserDefaults` under `local.pomodoro.menubar`.
- Notifications are sent with `osascript`, so no extra permissions are needed.

## License

MIT. See [LICENSE](LICENSE).
