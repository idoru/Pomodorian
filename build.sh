#!/bin/bash

# Set the current directory to the script directory
cd "$(dirname "$0")"

# Configuration
APP_NAME="Pomodorian"
BUNDLE_NAME="${APP_NAME}.app"
OUTPUT_DIR="build"
CONTENTS_DIR="${OUTPUT_DIR}/${BUNDLE_NAME}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# Create app bundle structure
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# We'll create Info.plist and the icon after the full build

# Compile macOS app
echo "Building ${APP_NAME} for macOS..."

# Clean up any existing build if present
rm -rf "${OUTPUT_DIR}/${BUNDLE_NAME}"

# Recreate directories after cleanup
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Create a backup of the app icon if it exists
if [ -f "${RESOURCES_DIR}/AppIcon.icns" ]; then
    echo "Backing up existing app icon..."
    cp "${RESOURCES_DIR}/AppIcon.icns" "${OUTPUT_DIR}/AppIcon.icns.bak"
fi
swiftc -o "${MACOS_DIR}/${APP_NAME}" \
    -sdk $(xcrun --show-sdk-path --sdk macosx) \
    -target x86_64-apple-macosx11.0 \
    -swift-version 5 \
    MenuBarApp.swift \
    PomodoroTimer.swift \
    StatusBarView.swift \
    MenuBarContentView.swift

# Check if build was successful
if [ $? -eq 0 ]; then
    # Make the binary executable
    chmod +x "${MACOS_DIR}/${APP_NAME}"
    
    # Recreate Info.plist (it got deleted during the build)
    echo "Creating Info.plist..."
    cat > "${CONTENTS_DIR}/Info.plist" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.example.pomodorian</string>
    <key>CFBundleName</key>
    <string>Pomodorian</string>
    <key>CFBundleExecutable</key>
    <string>Pomodorian</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOL
    
    # Create app icon from PomodorianIcon.png
    echo "Creating app icon..."
    ICONSET_DIR="${OUTPUT_DIR}/AppIcon.iconset"
    mkdir -p "${ICONSET_DIR}"
    
    # Use PomodorianIcon.png as the source for app icon
    if [ -f "PomodorianIcon.png" ]; then
        # Create iconset images
        echo "Using PomodorianIcon.png as icon source"
        sips -z 16 16 "PomodorianIcon.png" --out "${ICONSET_DIR}/icon_16x16.png"
        sips -z 32 32 "PomodorianIcon.png" --out "${ICONSET_DIR}/icon_16x16@2x.png"
        sips -z 32 32 "PomodorianIcon.png" --out "${ICONSET_DIR}/icon_32x32.png"
        sips -z 64 64 "PomodorianIcon.png" --out "${ICONSET_DIR}/icon_32x32@2x.png"
        sips -z 128 128 "PomodorianIcon.png" --out "${ICONSET_DIR}/icon_128x128.png"
        sips -z 256 256 "PomodorianIcon.png" --out "${ICONSET_DIR}/icon_128x128@2x.png"
        sips -z 256 256 "PomodorianIcon.png" --out "${ICONSET_DIR}/icon_256x256.png"
        sips -z 512 512 "PomodorianIcon.png" --out "${ICONSET_DIR}/icon_256x256@2x.png"
        sips -z 512 512 "PomodorianIcon.png" --out "${ICONSET_DIR}/icon_512x512.png"
        sips -z 1024 1024 "PomodorianIcon.png" --out "${ICONSET_DIR}/icon_512x512@2x.png"
    else
        echo "PomodorianIcon.png not found, falling back to tomato.svg"
        # Fall back to tomato.svg
        TMP_PNG="${OUTPUT_DIR}/tomato.png"
        sips -s format png tomato.svg --out "${TMP_PNG}"
        
        # Create iconset images
        sips -z 16 16 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_16x16.png"
        sips -z 32 32 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_16x16@2x.png"
        sips -z 32 32 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_32x32.png"
        sips -z 64 64 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_32x32@2x.png"
        sips -z 128 128 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_128x128.png"
        sips -z 256 256 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_128x128@2x.png"
        sips -z 256 256 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_256x256.png"
        sips -z 512 512 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_256x256@2x.png"
        sips -z 512 512 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_512x512.png"
        sips -z 1024 1024 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_512x512@2x.png"
    fi
    
    # Convert iconset to icns
    echo "Converting iconset to icns file..."
    iconutil -c icns "${ICONSET_DIR}" -o "${RESOURCES_DIR}/AppIcon.icns"
    
    # Clean up
    echo "Cleaning up temporary files..."
    if [ -f "${OUTPUT_DIR}/tomato.png" ]; then
        rm -f "${OUTPUT_DIR}/tomato.png"
    fi
    rm -rf "${ICONSET_DIR}"
    
    echo "Build completed successfully!"
    echo "App bundle created at: $(pwd)/${OUTPUT_DIR}/${BUNDLE_NAME}"
    echo ""
    echo "To run the app, use this command:"
    echo "open $(pwd)/${OUTPUT_DIR}/${BUNDLE_NAME}"
else
    echo "Build failed."
fi