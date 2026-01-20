# Comprehensive Development Chronicle: Mac Intelligence
**Date:** December 27, 2024
**Authors:** Pilwon Hur (Lead Developer) & Antigravity (AI Co-Pilot)

---

## 🏗 Project Vision: "The Invisible AI Layer"
Mac Intelligence is a premium, non-intrusive AI companion for macOS. It live "above" the OS, triggered by a global hotkey, capturing context from any application (Safari, Chrome, Word, Acrobat, etc.) and allowing the user to interact with that context through a beautiful, glassmorphic chat interface.

---

## � Interaction & Iteration Ledger
*This section documents the collaborative evolution of the app during this session, tracking how specific user requests led to technical breakthroughs.*

| Step | User Request | Implementation Strategy (Co-Pilot) | Result |
| :--- | :--- | :--- | :--- |
| **01** | *Initial State* | Setup basic text capture and single-response UI. | Functional but static prototype. |
| **02** | "Show the model name as well." | Added dynamic badges in the header showing "GPT-4o" or "Gemini 2.5 Flash" based on state. | Improved transparency for the user. |
| **03** | "For Gemini, I want to use Gemini 2.5 Flash." | Updated API endpoint to `gemini-2.5-flash` and updated UI labels. | Leveraged the latest experimental models. |
| **04** | "I want the enter key to work for submission." | Initially added `.onSubmit` to the `TextField`. | Faster interaction loop. |
| **05** | "Is it possible to do Internet search?" | Integrated Gemini's `google_search` grounding tool with a UI toggle. | Added real-time research capabilities. |
| **06** | "I want to keep previous answers (history)." | Introduced `ChatMessage` model and converted UI to a ScrollView with threading. | Enabled multi-turn conversations. |
| **07** | "Enable shortcuts (Cmd+C/V) and text selection." | Implemented a programmatic `Edit` menu in `AppDelegate` and added `.textSelection(.enabled)`. | Professional-grade text management. |
| **08** | "Add a button to delete chat history." | Added a 🗑️ Trash button that wipes the message array but preserves context. | Easy session reset. |
| **09** | "Change title, make window resizable, and allow multi-line input." | Updated title, added `NSPanel` constraints, and swapped `TextField` for a custom `NSTextView`. | UI became elastic and pro-user friendly. |
| **10** | "Shift+Enter should result in a newline, not submission." | Refined `NSTextView` bridge to intercept `insertNewline` and check for modifier flags. | Perfected the desktop typing experience. |
| **11** | "Bypass repetitive Keychain security popups." | Migrated sensitive keys to a custom `UserDefaults` layer for local development. | Frictionless developer workflow. |

---

## 🛠 Technical Achievements & Architecture

### 1. The Context Capture Engine
A hybrid system for reliable extraction across the OS:
- **Browser Protocol:** AppleScript extraction (URL + Title + Selection).
- **Native Protocol:** Accessibility API traversal for apps like Word/Acrobat.
- **Fallback Protocol:** "Safe Copy" routine with clipboard restoration.

### 2. Multi-Provider Intelligence Hub
- **OpenAI & Gemini Parallelism:** A unified `LLMService` that formats payloads differently for each provider while maintaining a single streaming interface for the UI.
- **SSE Streaming Parser:** A custom buffer-based parser that handles the unpredictable data chunks characteristic of LLM streaming.

### 3. The Custom Text Engine (`CustomTextView`)
Standard SwiftUI controls were too limited. We built a bridge to AppKit:
- **NSTextView Wrapper:** Allows for raw key event interception.
- **Modifier Detection:** Logic that distinguishes between `Return` (Command) and `Shift+Return` (Data Entry).
- **Dynamic Growth:** The field expands up to 5 lines of vertical height before scrolling.

### 4. Windowing & Aesthetics
- **GhostPanel:** An `NSPanel` configuration that is "non-activating" (doesn't hide the background app).
- **HUD Material:** Uses `visualEffect.material = .hudWindow` for a dark, translucent, premium feel.
- **ScrollViewReader:** Ensures that as the AI "types", the window scrolls in real-time to track the last word.

---

## 💻 Technical Stack Recap
| Component | Technology |
| :--- | :--- |
| **Language** | Swift 6.0 |
| **UI Framework** | SwiftUI & AppKit Hybrid |
| **Communication** | URLSession (SSE) |
| **Persistence** | UserDefaults (Secure Named) |
| **OS Bridges** | AppleScript, Accessibility API, Carbon |
| **AI Brains** | GPT-4o, Gemini 2.5 Flash |

---

## 📂 File Architecture
- `Source/Models/ChatMessage.swift`: Session history model.
- `Source/Services/LLMService.swift`: Multi-provider network manager.
- `Source/Views/MainView.swift`: The responsive chat surface.
- `Source/Core/GhostPanel.swift`: The elastic window container.

---

**Current Status:** Alpha Prototype v2.6 ("The Power Session")
**Project:** Mac Intelligence by Pilwon Hur
