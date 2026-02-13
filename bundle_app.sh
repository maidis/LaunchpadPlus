#!/bin/bash

APP_NAME="LaunchpadPlus"
APP_BUNDLE="$APP_NAME.app"
BINARY_PATH=".build/release/$APP_NAME"
ICON_SOURCE="/Users/anilozbek/.gemini/antigravity/brain/03a60874-0d49-43e5-872e-dc001b4b1e2f/launchpad_miniature_icon_1770899582712.png"

# Create Bundle Structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy Binary
cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Create Icon
mkdir -p "$APP_BUNDLE/Contents/Resources/AppIcon.iconset"

# Resize and name correctly for iconutil (needs .png extension and specific names)
sips -z 16 16     -s format png "$ICON_SOURCE" --out "$APP_BUNDLE/Contents/Resources/AppIcon.iconset/icon_16x16.png"
sips -z 32 32     -s format png "$ICON_SOURCE" --out "$APP_BUNDLE/Contents/Resources/AppIcon.iconset/icon_16x16@2x.png"
sips -z 32 32     -s format png "$ICON_SOURCE" --out "$APP_BUNDLE/Contents/Resources/AppIcon.iconset/icon_32x32.png"
sips -z 64 64     -s format png "$ICON_SOURCE" --out "$APP_BUNDLE/Contents/Resources/AppIcon.iconset/icon_32x32@2x.png"
sips -z 128 128   -s format png "$ICON_SOURCE" --out "$APP_BUNDLE/Contents/Resources/AppIcon.iconset/icon_128x128.png"
sips -z 256 256   -s format png "$ICON_SOURCE" --out "$APP_BUNDLE/Contents/Resources/AppIcon.iconset/icon_128x128@2x.png"
sips -z 256 256   -s format png "$ICON_SOURCE" --out "$APP_BUNDLE/Contents/Resources/AppIcon.iconset/icon_256x256.png"
sips -z 512 512   -s format png "$ICON_SOURCE" --out "$APP_BUNDLE/Contents/Resources/AppIcon.iconset/icon_256x256@2x.png"
sips -z 512 512   -s format png "$ICON_SOURCE" --out "$APP_BUNDLE/Contents/Resources/AppIcon.iconset/icon_512x512.png"
sips -z 1024 1024 -s format png "$ICON_SOURCE" --out "$APP_BUNDLE/Contents/Resources/AppIcon.iconset/icon_512x512@2x.png"

# Convert iconset to icns
iconutil -c icns "$APP_BUNDLE/Contents/Resources/AppIcon.iconset" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
rm -rf "$APP_BUNDLE/Contents/Resources/AppIcon.iconset"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF


# Force Icon Refresh
touch "$APP_BUNDLE"

echo "App Bundle Created: $APP_BUNDLE"
