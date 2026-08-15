#!/bin/bash

# Define App Name and Paths
APP_NAME="Mac Intelligence"
BUNDLE_NAME="MacIntelligence.app"
CONTENTS_DIR="$BUNDLE_NAME/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🔨 Building $BUNDLE_NAME..."

# 1. Create directory structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 2. Compile the Swift executable
# Note: We name the executable "MacIntelligence" inside the bundle
swiftc -o "$MACOS_DIR/MacIntelligence" \
      "Source/Models/AppState.swift" \
      "Source/Models/ChatMessage.swift" \
      "Source/Services/KeychainService.swift" \
      "Source/Services/CLIBackend.swift" \
      "Source/Services/LLMService.swift" \
      "Source/Services/HotKeyService.swift" \
      "Source/Services/CaptureService.swift" \
      "Source/Core/GhostPanel.swift" \
      "Source/Views/SettingsView.swift" \
      "Source/Views/MainView.swift" \
      "Source/Core/main.swift"

if [ $? -ne 0 ]; then
    echo "❌ Compilation failed."
    exit 1
fi

# 3. Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacIntelligence</string>
    <key>CFBundleIdentifier</key>
    <string>com.pilwonhur.MacIntelligence</string>
    <key>CFBundleName</key>
    <string>Mac Intelligence</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <string>1</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAccessibilityUsageDescription</key>
    <string>Mac Intelligence needs accessibility access to capture selected text from your active applications.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Mac Intelligence needs to control your browser to capture URLs and page titles from Safari and Chrome.</string>
</dict>
</plist>
EOF

# 4. Ad-hoc sign the app (Crucial for macOS security)
echo "🔐 Signing $BUNDLE_NAME..."
codesign --force --deep --sign - "$BUNDLE_NAME"

echo "✅ $BUNDLE_NAME created successfully!"
echo "🚀 You can now move it to /Applications or open it with 'open $BUNDLE_NAME'"
