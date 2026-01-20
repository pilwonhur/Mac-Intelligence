# Mac Intelligence

<p align="center">
  <strong>A Native macOS AI Assistant for System-Wide Text Intelligence</strong>
</p>

<p align="center">
  <em>By Pilwon Hur</em>
</p>

---

## 🌟 Overview

**Mac Intelligence** is a macOS-native productivity tool that brings AI-powered assistance to any application on your Mac. It allows you to instantly interact with selected text from any app—browsers, documents, PDFs, and more—through a lightweight, non-intrusive floating popup interface.

No more switching between apps. No more copy-pasting into a browser. Just select text, press a hotkey, and get instant AI-powered answers with full context awareness.

### ✨ Key Features

- **🎯 Universal Text Capture**: Works with virtually any application—Safari, Chrome, MS Word, TextEdit, MS Teams, Preview, and more
- **🤖 Dual AI Support**: Choose between **OpenAI GPT-4o** or **Google Gemini 2.5 Flash**
- **🌐 Live Web Search**: Enable real-time Google Search grounding for up-to-date information
- **💬 Conversational Memory**: Multi-turn chat that remembers previous context
- **🪟 Ghost Window**: Non-intrusive floating panel that doesn't steal focus from your work
- **⌨️ Global Hotkey**: Trigger from anywhere with `Cmd + Shift + K`
- **🎨 Premium UI**: Glassmorphic design with native dark/light mode support

---

## 📸 How It Works

1. **Select** any text in any application
2. **Press** `Cmd + Shift + K`
3. **Ask** a question about the selected text
4. **Get** an AI-powered response with full context

The assistant automatically captures:
- The selected text snippet
- Browser context (URL, page title) when applicable
- Full conversation history for follow-up questions

---

## 🛠️ Installation

### Prerequisites

- **macOS 13.0** (Ventura) or later
- **Swift 6.0+** (included with Xcode)
- **API Keys** for OpenAI and/or Google Gemini

### Build from Source

1. **Clone the repository**
```bash
git clone https://github.com/pilwonhur/mac-intelligence.git
cd mac-intelligence
```

2. **Build the application bundle**
```bash
chmod +x build_app.sh
./build_app.sh
```

3. **Move to Applications (optional)**
```bash
mv MacIntelligence.app /Applications/
```

4. **Launch the app**
```bash
open MacIntelligence.app
```
Or find "Mac Intelligence" in Spotlight.

### Development Mode

For active development, you can run directly without creating an app bundle:
```bash
chmod +x run.sh
./run.sh
```

---

## ⚙️ Configuration

### Granting Permissions

On first launch, macOS will prompt for the following permissions:

1. **Accessibility Access** (Required)
   - Go to **System Settings > Privacy & Security > Accessibility**
   - Enable **Mac Intelligence** (or Terminal if running in dev mode)

2. **Automation Access** (Required for browsers)
   - Allow control of Safari/Chrome when prompted

3. **Browser Settings** (For full context from browsers)
   - **Safari**: Safari > Settings > Advanced > "Show Develop menu" → Develop > "Allow JavaScript from Apple Events"
   - **Chrome**: View > Developer > "Allow JavaScript from Apple Events"

### Setting Up API Keys

1. Press `Cmd + Shift + K` to open Mac Intelligence
2. Click the **⚙️ Settings** icon
3. Select your preferred AI provider (OpenAI or Gemini)
4. Paste your API key
5. Click **Save and Close**

**Get API Keys:**
- OpenAI: [platform.openai.com](https://platform.openai.com)
- Gemini: [aistudio.google.com](https://aistudio.google.com)

---

## 🎮 Usage

### Basic Operations

| Action | Shortcut |
|--------|----------|
| Open Mac Intelligence | `Cmd + Shift + K` |
| Submit question | `Enter` |
| New line in input | `Shift + Enter` |
| Copy response | `Cmd + C` |
| Clear chat history | Click 🗑️ icon |
| Close window | Click ❌ or `Esc` |
| Quit application | Click ⏻ icon |

### Feature Toggles

- **🌐 Web Search**: Enable real-time web search for current events and live data (Gemini only)

### Tips

- Use the trash icon to clear chat and start fresh while keeping the selected context
- The AI maintains conversation history—ask follow-up questions naturally
- Browser context (URL/title) is automatically included when triggered from Safari or Chrome

---

## 🏗️ Architecture

Mac Intelligence follows a modular service-oriented architecture:

```
Source/
├── Core/
│   ├── main.swift           # Application entry point
│   └── GhostPanel.swift     # Non-activating floating window
├── Services/
│   ├── CaptureService.swift # Text capture engine (Accessibility + AppleScript)
│   ├── HotKeyService.swift  # Global keyboard shortcut handler
│   ├── LLMService.swift     # AI provider integration (OpenAI/Gemini)
│   └── KeychainService.swift# Secure API key storage
├── Views/
│   ├── MainView.swift       # Primary chat interface
│   └── SettingsView.swift   # Configuration panel
└── Models/
    ├── AppState.swift       # Global application state
    └── ChatMessage.swift    # Chat message model
```

### Technology Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 6.0+ |
| UI Framework | SwiftUI |
| System Integration | AppKit (NSPanel, NSEvent) |
| Text Capture | Accessibility API, AppleScript |
| AI Providers | OpenAI GPT-4o, Google Gemini 2.5 Flash |
| Concurrency | Swift Structured Concurrency (async/await) |

### Text Capture Strategy

Mac Intelligence employs a hybrid capture strategy for maximum compatibility:

1. **AppleScript** for browsers (Safari, Chrome) and MS Word
2. **Accessibility API** for native apps (TextEdit, Notes, Preview)
3. **Copy Fallback** (simulated `Cmd+C`) for Electron apps and others

---

## 📁 Project Structure

```
mac-intelligence/
├── Source/                    # Swift source code
├── MacIntelligence.app/       # Built application bundle
├── build_app.sh               # Production build script
├── run.sh                     # Development run script
├── PRD.md                     # Product Requirements Document
├── architecture.md            # Technical architecture
├── roadmap.md                 # Development roadmap
├── spikes.md                  # Technical experiments log
├── spike_*.swift              # Technical spike scripts
└── session_history_*.md       # Development session logs
```

---

## 🔒 Privacy & Security

- **Local-first**: API keys are stored locally using UserDefaults (not uploaded anywhere)
- **No data retention**: Your text selections and conversations are not stored on any server
- **Direct API calls**: Communication goes directly to OpenAI/Google—no intermediary servers

---

## 🚧 Roadmap

- [ ] Claude (Anthropic) integration
- [ ] Custom system prompts
- [ ] Conversation history persistence
- [ ] Menu bar icon with quick actions
- [ ] Image analysis support
- [ ] Customizable hotkey

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Pilwon Hur**

---

## 🙏 Acknowledgments

- Built with ❤️ using Swift and SwiftUI
- Powered by OpenAI and Google Gemini APIs
- Inspired by the need for seamless AI integration into daily macOS workflows

---

<p align="center">
  <sub>Made with Swift for macOS 🍎</sub>
</p>
