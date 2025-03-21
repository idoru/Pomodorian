#!/bin/bash

# Script to check if app icon is correctly added to the bundle

APP_BUNDLE="build/Pomodorian.app"
ICON_PATH="${APP_BUNDLE}/Contents/Resources/AppIcon.icns"

# First build the app
./build.sh

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
  echo "❌ ERROR: App bundle not found at $APP_BUNDLE"
  exit 1
fi

# Check if icon file exists in the right location
if [ ! -f "$ICON_PATH" ]; then
  echo "❌ ERROR: Icon file not found at $ICON_PATH"
  exit 1
fi

# Check if icon file has content (not empty)
if [ ! -s "$ICON_PATH" ]; then
  echo "❌ ERROR: Icon file exists but is empty"
  exit 1
fi

# Check file type to verify it's actually an icns file
FILE_TYPE=$(file -b "$ICON_PATH")
if [[ $FILE_TYPE != *"Mac OS X icon"* ]]; then
  echo "❌ ERROR: File at $ICON_PATH is not a valid Mac OS X icon"
  echo "File type: $FILE_TYPE"
  exit 1
fi

# Check if Info.plist references the icon
ICON_REFERENCE=$(plutil -p "${APP_BUNDLE}/Contents/Info.plist" | grep CFBundleIconFile)
if [[ -z "$ICON_REFERENCE" ]]; then
  echo "❌ ERROR: Info.plist doesn't reference any icon file"
  exit 1
fi

if [[ "$ICON_REFERENCE" != *"AppIcon"* ]]; then
  echo "❌ ERROR: Info.plist references wrong icon file"
  echo "Current reference: $ICON_REFERENCE"
  exit 1
fi

echo "✅ SUCCESS: App icon validated successfully!"
echo "Icon file present at: $ICON_PATH"
echo "Info.plist reference: $ICON_REFERENCE"
exit 0

