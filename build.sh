#!/bin/bash

# Set the current directory to the script directory
cd "$(dirname "$0")"

# Configuration
APP_NAME="PomodoroMenuBar"
BUNDLE_NAME="${APP_NAME}.app"
OUTPUT_DIR="build"
CONTENTS_DIR="${OUTPUT_DIR}/${BUNDLE_NAME}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# Create app bundle structure
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy and create app icon (if possible)
if command -v sips &> /dev/null && command -v iconutil &> /dev/null; then
    # Create iconset directory
    ICONSET_DIR="${OUTPUT_DIR}/AppIcon.iconset"
    mkdir -p "${ICONSET_DIR}"
    
    # Convert SVG to PNG using sips
    if [ -f "tomato.svg" ]; then
        TMP_PNG="${OUTPUT_DIR}/tomato.png"
        sips -s format png tomato.svg --out "${TMP_PNG}" &> /dev/null
        
        # Create iconset images
        sips -z 16 16 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_16x16.png" &> /dev/null
        sips -z 32 32 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_16x16@2x.png" &> /dev/null
        sips -z 32 32 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_32x32.png" &> /dev/null
        sips -z 64 64 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_32x32@2x.png" &> /dev/null
        sips -z 128 128 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_128x128.png" &> /dev/null
        sips -z 256 256 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_128x128@2x.png" &> /dev/null
        sips -z 256 256 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_256x256.png" &> /dev/null
        sips -z 512 512 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_256x256@2x.png" &> /dev/null
        sips -z 512 512 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_512x512.png" &> /dev/null
        sips -z 1024 1024 "${TMP_PNG}" --out "${ICONSET_DIR}/icon_512x512@2x.png" &> /dev/null
        
        # Convert iconset to icns
        iconutil -c icns "${ICONSET_DIR}" -o "${RESOURCES_DIR}/AppIcon.icns" &> /dev/null
        
        # Clean up
        rm -f "${TMP_PNG}"
        rm -rf "${ICONSET_DIR}"
    fi
fi

# Create Info.plist
cat > "${CONTENTS_DIR}/Info.plist" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.example.pomodoromenubar</string>
    <key>CFBundleName</key>
    <string>PomodoroMenuBar</string>
    <key>CFBundleExecutable</key>
    <string>PomodoroMenuBar</string>
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

# Compile macOS app
echo "Building ${APP_NAME} for macOS..."
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
    echo "Build completed successfully!"
    echo "App bundle created at: $(pwd)/${OUTPUT_DIR}/${BUNDLE_NAME}"
    echo ""
    echo "To run the app, use this command:"
    echo "open $(pwd)/${OUTPUT_DIR}/${BUNDLE_NAME}"
    
    # Make the binary executable
    chmod +x "${MACOS_DIR}/${APP_NAME}"
else
    echo "Build failed."
fi