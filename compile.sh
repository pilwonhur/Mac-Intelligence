#!/bin/bash
#
# Compiles the Mac Intelligence executable. Shared by build_app.sh and run.sh.
#
#     ./compile.sh <output-path>
#
# Builds against the default SDK first. If that fails, retries against every other
# macOS SDK installed alongside it, newest first. A Command Line Tools update can ship
# an SDK whose SwiftUI needs a macro plugin that only Xcode provides ("plugin for module
# 'SwiftUIMacros' not found"); an older SDK from the same install still builds fine.

OUTPUT="${1:?usage: compile.sh <output-path>}"
cd "$(dirname "$0")" || exit 1

SOURCES=(
    "Source/Models/AppState.swift"
    "Source/Models/AppVersion.swift"
    "Source/Models/ChatMessage.swift"
    "Source/Services/KeychainService.swift"
    "Source/Services/CLIBackend.swift"
    "Source/Services/LLMService.swift"
    "Source/Services/HotKeyService.swift"
    "Source/Services/CaptureService.swift"
    "Source/Core/GhostPanel.swift"
    "Source/Views/SettingsView.swift"
    "Source/Views/MainView.swift"
    "Source/Core/main.swift"
)

FIRST_ERRORS="$(mktemp)"
trap 'rm -f "$FIRST_ERRORS"' EXIT

if swiftc -o "$OUTPUT" "${SOURCES[@]}" 2>"$FIRST_ERRORS"; then
    cat "$FIRST_ERRORS" >&2   # warnings
    exit 0
fi

DEFAULT_SDK="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null)"
DEFAULT_SDK="$(cd "$DEFAULT_SDK" 2>/dev/null && pwd -P)"
DEV_DIR="$(xcode-select -p 2>/dev/null)"

# Real SDK directories only (the MacOSX.sdk / MacOSX27.sdk entries are symlinks),
# newest version first.
CANDIDATES="$(
    for SDK in "$DEV_DIR"/SDKs/MacOSX*.*.sdk \
               "$DEV_DIR"/Platforms/MacOSX.platform/Developer/SDKs/MacOSX*.*.sdk; do
        [ -d "$SDK" ] || continue
        VERSION="${SDK##*/MacOSX}"
        printf '%s\t%s\n' "${VERSION%.sdk}" "$SDK"
    done | sort -V -r | cut -f 2
)"

while IFS= read -r SDK; do
    [ -n "$SDK" ] || continue
    [ "$(cd "$SDK" && pwd -P)" = "$DEFAULT_SDK" ] && continue
    echo "↩️  The default SDK failed to build; retrying with $(basename "$SDK")..."
    if swiftc -sdk "$SDK" -o "$OUTPUT" "${SOURCES[@]}" 2>/dev/null; then
        echo "✅ Built with $(basename "$SDK")."
        exit 0
    fi
done <<< "$CANDIDATES"

# Nothing built: show the errors from the default SDK, which are the relevant ones.
cat "$FIRST_ERRORS" >&2
exit 1
