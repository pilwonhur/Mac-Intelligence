# Technical Spikes: Mac Intelligence

This document tracks focused technical experiments ("Spikes") designed to validate high-risk features and macOS system integrations.

## Spike #1: Accessibility Text Capture (Highest Priority)
*   **Goal:** Verify if we can programmatically retrieve highlighted text from Safari, Word, or Chrome without the user pressing `Cmd+C`.
*   **Key Question:** Does the Accessibility API (`AXUIElement`) provide reliable access to the `AXSelectedText` attribute across different third-party applications?
*   **Status:** ✅ Completed
*   **Outcome:** Successfully captured text using an "Ultimate Hybrid" approach:
    - **Native Apps (TextEdit, etc.):** Accessibility API (`AXUIElement`) works reliably.
    - **Microsoft Word:** Specialized AppleScript required.
    - **Browsers (Safari, Chrome):** AppleScript with JavaScript injection required.
    - **Electron/Proprietary (Teams, Hancom):** Global Copy Fallback (`Cmd+C`) with clipboard restoration.
    - **Adobe Acrobat:** Deep hierarchy crawl + micro-delayed keyboard simulation.
    - **Security Settings Required:** 
        - **Safari:** Develop > Allow JavaScript from Apple Events.
        - **Chrome:** View > Developer > Allow JavaScript from Apple Events.

## Spike #2: The "Ghost" Window (Interaction Design)
*   **Goal:** Create a SwiftUI window that stays "always on top" but doesn't steal focus from the app the user is currently typing in (maintaining a non-intrusive experience).
*   **Key Question:** Can `NSPanel` be configured to allow interaction while the underlying application remains active?
*   **Status:** ✅ Completed
*   **Outcome:** Successfully created an `NSPanel` subclass with `.nonactivatingPanel` style mask. This allows the window to float and be clicked while the parent app (e.g., Terminal/Safari) remains the "Key" focused application.

## Spike #3: Universal Hotkey (Trigger Mechanism)
*   **Goal:** Register a listener for a global hotkey (e.g., `Cmd+Shift+K`) that works even when the app is minimized or hidden.
*   **Key Question:** Should we use `NSEvent` monitors or the lower-level `Carbon` framework for the most reliable performance?
*   **Status:** ✅ Completed
*   **Outcome:** Successfully registered a global hotkey using the `Carbon` framework. The event handler triggers even when the process is not the active application.

## Spike #4: Browser Context Scraping (Advanced IQ)
*   **Goal:** Extract the full HTML or page title from the active browser tab to provide deeper context to the AI.
*   **Key Question:** Can this be achieved via AppleScript without requiring a dedicated browser extension?
*   **Status:** ✅ Completed
*   **Outcome:** Successfully extracted Page Title, URL, and full `innerText` from Safari and Chrome using direct AppleScript/JavaScript injection. This confirms we can provide full-page context to the AI without a browser extension.
