# Development Roadmap: Mac Intelligence

This roadmap outlines the phased development of the Mac Intelligence AI Assistant, focusing on macOS system integration, premium UI, and contextual AI capabilities.

## Phase 1: Technical Spikes & Feasibility
*Goal: Validate core macOS integration capabilities.*
- [ ] **Accessibility API Research:** Investigate `AXUIElement` for retrieving selected text from other apps without copy/paste.
- [ ] **Global Hotkey Implementation:** Research and implement a system-wide hotkey (e.g., `Cmd + Shift + K`).
- [ ] **Services Menu Integration:** Register the app as a macOS Service in `Info.plist`.
- [ ] **Window Behavior:** Prototype an `NSPanel` that stays on top without taking focus from the active app.

## Phase 2: Design & UI Mockups
*Goal: Define the "Premium" look and feel.*
- [ ] **Visual Identity:** Design glassmorphic UI elements (vibrancy, blur, thin borders).
- [ ] **Interaction Design:** Prototype window appearance/dismissal animations.
- [ ] **Mockups:** Create high-fidelity mockups for:
    - Contextual query window.
    - General AI chat window.
    - Model/Language selection dropdowns.

## Phase 3: MVP Development (Core Engine)
*Goal: Build a working prototype of the core experience.*
- [ ] **Project Setup:** Initialize SwiftUI-based macOS project.
- [ ] **Floating Window Implementation:** Build the draggable, non-modal overlay.
- [ ] **Text Capture Engine:** Implement logic to grab selection on trigger.
- [ ] **Basic Chat UI:** Input field and response area.

## Phase 4: AI & Services Integration
*Goal: Connect the engine to LLM providers.*
- [ ] **LLM Orchestration:** Implement API connectors for OpenAI, Anthropic, and Google.
- [ ] **Streaming Support:** Visualizing real-time AI responses.
- [ ] **Markdown Rendering:** Proper formatting for code blocks and rich text in responses.
- [ ] **Settings Panel:** API key management and default configuration.

## Phase 5: Advanced Context & Polishing
*Goal: Enhance intelligence and user experience.*
- [ ] **Browser Integration:** Use AppleScript or extensions for full-page context scraping.
- [ ] **Context Awareness 2.0:** Support for surrounding text detection via Accessibility APIs.
- [ ] **Multi-language Support:** Native Korean/English switching logic.
- [ ] **Performance Optimization:** Ensure < 200ms popup latency.
