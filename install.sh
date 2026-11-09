#!/bin/zsh
# Builds Pomodoro from source and installs it to ~/Applications.
# Usage:  ./install.sh            install and launch
#         ./install.sh --login    also start it automatically at login
#         ./install.sh --uninstall
set -e
cd "$(dirname "$0")"

APP="$HOME/Applications/Pomodoro.app"
AGENT="$HOME/Library/LaunchAgents/local.pomodoro.menubar.plist"

if [[ "$1" == "--uninstall" ]]; then
  pkill -f "Pomodoro.app/Contents/MacOS/Pomodoro" 2>/dev/null || true
  rm -f "$AGENT"
  rm -rf "$APP"
  echo "Pomodoro removed."
  exit 0
fi

if ! command -v swiftc >/dev/null; then
  echo "Swift compiler not found. Install the Xcode Command Line Tools first:"
  echo "  xcode-select --install"
  exit 1
fi

echo "Building Pomodoro…"
mkdir -p "$APP/Contents/MacOS"
swiftc -swift-version 5 -O Pomodoro.swift -o "$APP/Contents/MacOS/Pomodoro"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force -s - "$APP" >/dev/null 2>&1 || true

if [[ "$1" == "--login" ]]; then
  mkdir -p "$HOME/Library/LaunchAgents"
  cat > "$AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>local.pomodoro.menubar</string>
<key>ProgramArguments</key><array><string>/usr/bin/open</string><string>$APP</string></array>
<key>RunAtLoad</key><true/>
</dict></plist>
EOF
  echo "Pomodoro will start automatically at login."
fi

pkill -f "Pomodoro.app/Contents/MacOS/Pomodoro" 2>/dev/null || true
sleep 1
open "$APP"
echo "Installed to $APP — look for ▶ 45:00 in your menu bar."
