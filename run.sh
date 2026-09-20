#!/bin/bash

# Compile and run the integrated Mac Intelligence prototype
swiftc -o MacIntel \
      "Source/Models/AppState.swift" \
      "Source/Models/AppVersion.swift" \
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

if [ $? -eq 0 ]; then
    ./MacIntel
else
    echo "❌ Compilation failed."
fi
