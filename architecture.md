# System Architecture: Mac Intelligence

This document outlines the technical design, module structure, and data flow of the Mac Intelligence macOS assistant.

## 1. Technology Stack
*   **Language:** Swift 6.0+
*   **UI Framework:** SwiftUI for modern, glassmorphic interfaces.
*   **Core Systems:** 
    *   `AppKit` for low-level system interaction (`NSPanel`, `NSEvent`).
    *   `Accessibility API` (Application Services) for text capture.
    *   `Keychain` for secure API key storage.
*   **Concurrency:** Structured Concurrency (Swift Actors/Async-Await).
*   **LLM Orchestration:** Direct HTTPS requests to OpenAI, Anthropic, and Google Vertex AI endpoints.

## 2. High-Level Architecture
The app follows a **Modular Service-Oriented** architecture to decouple system integration from AI logic.

### 2.1 Core Modules
1.  **Hotkey Manager:** 
    *   Monitors system-wide key events.
    *   Triggers the Overlay Manager.
2.  **Context Capture Engine:**
    *   Uses Accessibility APIs to detect currently focused windows and selected text safely.
    *   (Future) AppleScript bridge for browser-specific tab content.
3.  **Overlay Manager (`NSPanel` controller):**
    *   Manages a non-activating floating window.
    *   Handles "Always on Top" logic and cursor-relative positioning.
4.  **AI Service Layer:**
    *   Handles prompt assembly (Context + User Input).
    *   Manages streaming completions from multiple LLM providers.
5.  **Persistence Layer:**
    *   Stores user preferences (Language, Model) and secure credentials (API Keys).

## 3. Data Flow
1.  **Trigger:** User presses `Cmd + Shift + K`.
2.  **Capture:** `Hotkey Manager` signals `Context Capture Engine`. It retrieves "Focused App" + "Selected Text".
3.  **UI Display:** `Overlay Manager` appears at the cursor location with the captured text pre-loaded.
4.  **Request:** User types a question. `AI Service` sends an authenticated request to the selected LLM provider.
5.  **Response:** LLM streams data back; `SwiftUI View` renders Markdown in real-time.

## 4. Security & Permissions
*   **Accessibility:** Users must manually grant `Accessibility Permissions` in System Settings for selection capture to function.
*   **API Keys:** Never stored in plain text; always encrypted using the **macOS Keychain**.
*   **Privacy:** Content is sent to LLM providers for processing but is not stored on a central "Mac Intelligence" server.

## 5. UI Architecture (Design System)
*   **Theming:** Dynamic Light/Dark mode.
*   **Vibrancy:** Extensive use of `.background(.ultraThinMaterial)` for a premium glassmorphic feel.
*   **Responsiveness:** Use of `Grid` and `Flexible Containers` to ensure the popup looks good with varying text lengths.
