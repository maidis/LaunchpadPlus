#!/bin/bash

APP_NAME="LaunchpadPlus"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"
TEMP_DMG_DIR="temp_dmg_dist"

# Clean up any existing artifacts
rm -rf "$TEMP_DMG_DIR"
rm -f "$DMG_NAME"

echo "Creating DMG structure..."
mkdir -p "$TEMP_DMG_DIR"

# Copy the app bundle
cp -R "$APP_BUNDLE" "$TEMP_DMG_DIR/"

# Create a symlink to Applications
ln -s /Applications "$TEMP_DMG_DIR/Applications"

echo "Generating DMG..."
hdiutil create -volname "$APP_NAME" -srcfolder "$TEMP_DMG_DIR" -ov -format UDZO "$DMG_NAME"

# Clean up
rm -rf "$TEMP_DMG_DIR"

echo "DMG Created: $DMG_NAME"
