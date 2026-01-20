# Product Requirements Document (PRD): Mac Intelligence AI Assistant

## 1. Project Overview
**Mac Intelligence** is a macOS-native productivity tool designed to bridge the gap between static content (web pages, documents, PDFs) and AI-driven insights. It allows users to instantly interact with any selected text on their Mac through a lightweight, non-intrusive popup interface, providing context-aware answers and general AI assistance.

## 2. Problem Statement
Users frequently encounter information while reading web pages or documents that requires further explanation, translation, or analysis. Switching between applications (e.g., copying text, opening a browser, navigating to an AI chat, pasting text) disrupts focus and creates friction. There is a need for a seamless, "system-wide" AI layer that understands current context.

## 3. Goals & Objectives
- **Seamless Integration:** Provide a native macOS experience via Services, Quick Actions, and Keyboard Shortcuts.
- **Contextual Understanding:** Leverage the surrounding text or document content to provide more accurate AI responses.
- **Minimal Friction:** Minimize the steps between "selecting text" and "getting an answer."
- **Versatility:** Support both text-specific queries and general AI chat.
- **Customizability:** Allow users to choose their preferred AI models and languages.

## 4. Target Audience
- Researchers and Students analyzing complex documents.
- Developers reading documentation.
- Professionals needing quick translations or summaries.
- General macOS power users looking to integrate AI into their daily workflow.

## 5. Functional Requirements

### 5.1 Trigger Mechanisms
- **Selection-Based Trigger:** User selects text and right-clicks or uses a shortcut to query the specific snippet.
- **Universal Trigger (No Selection):** User can trigger the popup at any time (via right-click on empty space or global keyboard shortcut) to start a fresh AI conversation.
- **Right-Click / Services Menu:** Integration into the system-wide context menu, appearing even when no text is highlighted.
- **Global Keyboard Shortcut:** A customizable hotkey (e.g., `Cmd + Shift + K`) that opens the popup regardless of current selection state.
- **Quick Action:** Appearance in the Touch Bar or Finder Quick Actions for easy access.

### 5.2 The "Intelligence" Popup Interface
- **Floating Window:** A lightweight, Draggable, and non-modal popup window that appears near the cursor or in a centered overlay.
- **Input Area:** A text field to type detailed questions about the selected text or separate queries.
- **Response Area:** Markdown-rendered AI responses with support for code highlights and formatted text.
- **Close Mechanism:** A close button (`X`) and the ability to close via the `Esc` key.
- **Non-Interference:** The window should be "always on top" but not block the user's ability to interact with the underlying document unless explicitly focused.

### 5.3 AI Capabilities
- **Automated Context Analysis:** Automatically includes selected text or page context (if available) in the AI's prompt.
- **Universal AI Chat:** When triggered without selection, the popup functions as a standalone AI assistant for any task or query.
- **Dynamic Context Detection:** 
    - *Web:* Attempt to scrape current browser tab content.
    - *System:* Use Accessibility APIs to read surrounding text in active applications.
- **Model Selection:** Dropdown menu to switch between models (e.g., GPT-4o, Claude 3.5 Sonnet, Gemini Pro).
- **Language Selection:** Option to set preferred response language (Korean, English, etc.).

### 5.4 Settings & Configuration
- **API Key Management:** Secure storage for user-provided API keys (OpenAI, Anthropic, Google).
- **Default Prompts:** Customizable system prompts for different actions (e.g., "Explain this," "Translate this").
- **Theme Support:** Native Dark/Light mode integration.

## 6. User Flows

### 6.1 Flow A: Contextual Query (With Selection)
1. **Highlight:** User highlights a paragraph in a Research Paper (PDF).
2. **Trigger:** User right-clicks and selects "Ask Mac Intelligence" or hits the shortcut.
3. **Popup:** The window appears with the highlighted text referenced as context.
4. **Input:** User types: "How does this concept relate to the Free Energy Principle?"
5. **AI Response:** Assistant provides a detailed contextual explanation.
6. **Dismiss:** User clicks the close button or hits `Esc` to return to work.

### 6.2 Flow B: General Assistance (Without Selection)
1. **Trigger:** User hits `Cmd + Shift + K` while browsing a website (without selecting text).
2. **Popup:** A blank assistance window appears.
3. **Input:** User types a general question: "What is the capital of France?" or "Create a Python script for a timer."
4. **AI Response:** Assistant provides the answer.
5. **Dismiss:** User closes the window and continues browsing.

## 7. Technical Considerations (High-Level)
- **Framework:** Swift / SwiftUI for a native macOS feel.
- **Permissions:** Will require MacOS Accessibility permissions to read selected text and screen content.
- **Browser Integration:** May require a companion browser extension to get full HTML context of web pages.
- **LLM Orchestration:** A backend or local relay to handle API requests to various LLM providers.

## 8. Non-Functional Requirements
- **Lateny:** Popup should appear in < 200ms. AI streaming should begin immediately.
- **UI/UX:** Must feel "Premium" and "Apple-like" (Glassmorphism, smooth animations).
- **Privacy:** User data/selections should not be stored permanently; local-first approach for API keys.

## 9. Success Metrics
- Reduction in time spent switching between apps for AI queries.
- User retention (frequency of use per day).
- Positive feedback on the "Context Awareness" accuracy.
