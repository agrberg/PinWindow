#!/bin/bash
set -e
cd "$(dirname "$0")"

APP="PinWindow.app"
BINARY="$APP/Contents/MacOS/PinWindow"
SOURCE="pin.swift"

mkdir -p "$APP/Contents/MacOS"

if [ ! -f "$BINARY" ] || [ "$SOURCE" -nt "$BINARY" ]; then
    echo "Compiling..."
    swiftc "$SOURCE" \
        -o "$BINARY" \
        -framework Cocoa \
        -framework Carbon \
        -framework ScreenCaptureKit \
        -framework AVFoundation \
        -framework ApplicationServices

    echo "Signing..."
    codesign --force --deep --sign - "$APP"
    echo "Build complete."
else
    echo "No changes, skipping compile."
fi

# If run with arguments, pass them through to the binary
if [ $# -gt 0 ]; then
    "$BINARY" "$@"
else
    echo "Restarting PinWindow..."
    pkill -x PinWindow 2>/dev/null || true
    sleep 0.5
    open "$APP"
fi
