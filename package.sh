#!/bin/bash
set -e
cd "$(dirname "$0")"

APP="PinWindow.app"
BINARY="$APP/Contents/MacOS/PinWindow"
SOURCE="pin.swift"
VERSION="1.0"
DMG_NAME="PinWindow-${VERSION}.dmg"
DIST_DIR="dist"

# Signing identity: set via env or default to ad-hoc
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
# Notarization profile (optional): set via env
# Create with: xcrun notarytool store-credentials "notary-profile" --apple-id ... --team-id ... --password ...
NOTARIZE_PROFILE="${NOTARIZE_PROFILE:-}"

echo "=== PinWindow Build & Package ==="
echo "Version:  $VERSION"
echo "Signing:  ${SIGN_IDENTITY:--  (ad-hoc)}"
echo ""

# --- Step 1: Compile ---
echo "[1/5] Compiling..."
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

swiftc "$SOURCE" \
    -o "$BINARY" \
    -O \
    -framework Cocoa \
    -framework Carbon \
    -framework ScreenCaptureKit \
    -framework AVFoundation \
    -framework ApplicationServices

echo "      Compiled."

# --- Step 2: Sign ---
echo "[2/5] Signing app..."
codesign --force --deep --sign "$SIGN_IDENTITY" \
    --options runtime \
    --entitlements /dev/stdin "$APP" <<'ENTITLEMENTS'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
ENTITLEMENTS
echo "      Signed."

# Verify
codesign --verify --deep --strict "$APP" 2>&1 && echo "      Signature valid." || echo "      [warn] Signature verification issue."

# --- Step 3: Create DMG ---
echo "[3/5] Creating DMG..."
mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR/$DMG_NAME"

# Create a temporary directory for DMG contents
DMG_STAGING=$(mktemp -d)
cp -R "$APP" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

# Create DMG
hdiutil create \
    -volname "PinWindow" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$DIST_DIR/$DMG_NAME" \
    -quiet

rm -rf "$DMG_STAGING"
echo "      Created: $DIST_DIR/$DMG_NAME"

# --- Step 4: Sign DMG ---
echo "[4/5] Signing DMG..."
codesign --force --sign "$SIGN_IDENTITY" "$DIST_DIR/$DMG_NAME"
echo "      DMG signed."

# --- Step 5: Notarize (if profile provided) ---
if [ -n "$NOTARIZE_PROFILE" ]; then
    echo "[5/5] Notarizing..."
    xcrun notarytool submit "$DIST_DIR/$DMG_NAME" \
        --keychain-profile "$NOTARIZE_PROFILE" \
        --wait
    echo "      Stapling..."
    xcrun stapler staple "$DIST_DIR/$DMG_NAME"
    echo "      Notarized and stapled."
else
    echo "[5/5] Skipping notarization (no NOTARIZE_PROFILE set)."
    echo ""
    echo "  To notarize, first create a keychain profile:"
    echo "    xcrun notarytool store-credentials \"pinwindow-notary\" \\"
    echo "      --apple-id YOUR_APPLE_ID \\"
    echo "      --team-id YOUR_TEAM_ID \\"
    echo "      --password APP_SPECIFIC_PASSWORD"
    echo ""
    echo "  Then run:"
    echo "    SIGN_IDENTITY=\"Developer ID Application: ...\" \\"
    echo "    NOTARIZE_PROFILE=\"pinwindow-notary\" \\"
    echo "    ./package.sh"
fi

echo ""
echo "=== Done ==="
DMG_SIZE=$(du -h "$DIST_DIR/$DMG_NAME" | cut -f1 | xargs)
echo "Output: $DIST_DIR/$DMG_NAME ($DMG_SIZE)"
