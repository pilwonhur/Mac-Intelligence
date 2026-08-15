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
- **🤖 Multi-Provider AI Support**: Choose between **OpenAI**, **Anthropic Claude**, **Antigravity**, or **Google Gemini**
- **🔑 OAuth by Default**: Uses your existing subscription sign-in through the vendor's own CLI (`codex`, `claude`, `agy`)—no API key needed. API keys remain available as a secondary path
- **🧩 Selectable & Custom Models**: Pick from built-in models per provider, or type any exact model ID to add it to your list permanently
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
- **One of the following**, for at least one provider:
  - A signed-in vendor CLI — [Codex](https://developers.openai.com/codex/cli) (`codex`), [Claude Code](https://claude.com/claude-code) (`claude`), or [Antigravity](https://antigravity.google/) (`agy`) — for the OAuth path, **or**
  - An **API key** for OpenAI, Anthropic, or Google Gemini

### Build from Source

1. **Clone the repository**
```bash
git clone https://github.com/pilwonhur/Mac-Intelligence.git
cd Mac-Intelligence
```

2. **Create a local signing certificate** (once per machine, recommended)
```bash
chmod +x make_signing_cert.sh
./make_signing_cert.sh
```
Without it the build falls back to ad-hoc signing, and macOS re-prompts for keychain access and Accessibility permission **after every rebuild** — see [Why a signing certificate](#why-a-signing-certificate) below.

3. **Build the application bundle**
```bash
chmod +x build_app.sh
./build_app.sh
```

4. **Move to Applications (optional)**
```bash
mv MacIntelligence.app /Applications/
```
> `build_app.sh` only rebuilds the copy inside the project folder—it does **not** update `/Applications` automatically. After every rebuild, reinstall manually:
> ```bash
> pkill MacIntelligence
> rm -rf /Applications/MacIntelligence.app
> cp -R MacIntelligence.app /Applications/
> ```

5. **Launch the app**
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

### Why a signing certificate

macOS binds keychain ACLs and Accessibility (TCC) permissions to an app's **designated requirement**. Ad-hoc signing (`codesign --sign -`) produces one built from the code hash:

```
designated => cdhash H"8c6a3164c0b7975ee710e1d6e90be0bbe85170c4"
```

That hash changes on every rebuild, so macOS sees a brand-new app each time: it re-asks for the login keychain password, and Accessibility access has to be granted again. **"Always Allow" never sticks.**

`make_signing_cert.sh` creates a self-signed certificate in your login keychain, and `build_app.sh` signs with it when present. The requirement becomes:

```
designated => identifier "com.pilwonhur.MacIntelligence" and certificate root = H"b419dab9..."
```

Both halves survive rebuilds, so permissions granted once stay granted.

The certificate is for local permission stability only. It is not from Apple, so it does nothing for Gatekeeper or for distributing the app to anyone else. No administrator password or trust-settings change is needed — `codesign` finds the identity in the keychain directly.

> **One-time transition:** the identity changes when you first adopt the certificate, so macOS asks once more for keychain access (click **Always Allow**) and Accessibility must be re-granted — remove the old entry in System Settings and re-add the rebuilt app. After that it is permanent.

### Setting Up Authentication & Models

1. Press `Cmd + Shift + K` to open Mac Intelligence
2. Click the **⚙️ Settings** icon
3. Under **Preferred AI**, pick the provider you want to query with
4. Under **Configure Provider**, select each provider you plan to use and choose an **Authentication** method:
   - **OAuth** (default): Settings shows whether the provider's CLI was detected and where. Sign-in happens in that CLI, not here
   - **API Key**: paste the key (a green checkmark confirms it's set)
   - Pick a model from the dropdown, or type an exact model ID into **Add Model**—once added, it stays selectable in future sessions
5. Click **Save and Close** (or the ❌ button—both save automatically)

Selections persist immediately, so your last-used provider and model are restored the next time you open the app—no need to re-save.

#### Authentication paths per provider

| Provider | OAuth (default) | API key | Notes |
|----------|-----------------|---------|-------|
| OpenAI | `codex` CLI | ✅ | Codex streams no partial text—the answer appears at once |
| Anthropic | `claude` CLI | ✅ | Streams token by token |
| Antigravity | `agy` CLI | ❌ | Subscription-only; no REST endpoint |
| Google Gemini | — | ✅ | The personal Gemini CLI subscription was retired; use Antigravity for a Google subscription |

**How OAuth works here:** the app spawns the vendor's own CLI in headless mode (`claude -p`, `codex exec`, `agy -p`) and streams its answer back. Mac Intelligence never sees a token, a client ID, or a credentials file—each CLI owns its own session.

Sign in once per CLI, in Terminal:

```bash
claude   # then follow the sign-in prompt
codex    # sign in with ChatGPT
agy      # sign in with your Google account
```

> **CLI not detected?** A GUI app launched from Finder cannot see your shell `PATH`, and `agy` is often a shell *function* that doesn't exist outside an interactive shell. The app resolves the usual install locations directly; if yours is elsewhere, paste an absolute path into **CLI path override** in Settings.

**Get API Keys:**
- OpenAI: [platform.openai.com](https://platform.openai.com)
- Gemini: [aistudio.google.com](https://aistudio.google.com)
- Anthropic: [console.anthropic.com](https://console.anthropic.com)

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

- **🌐 Web Search**: Enable real-time web search for current events and live data. Availability depends on the provider **and** its auth method:

| Provider | Auth | Web search |
|----------|------|------------|
| OpenAI | OAuth (`codex`) | ✅ via `tools.web_search` |
| Anthropic | OAuth (`claude`) | ✅ via the WebSearch tool |
| Google Gemini | API key | ✅ via `google_search` grounding |
| Antigravity | OAuth (`agy`) | ❌ headless runs auto-deny tool permissions |
| OpenAI / Anthropic | API key | ❌ not sent in this app's request body |

The toggle greys out with a short reason when the current combination cannot search.

### Built-in Models

| Provider | Built-in Models |
|----------|------------------|
| OpenAI | `gpt-5.6-sol`, `gpt-5.6-terra`, `gpt-5.6-luna`, `gpt-4o` |
| Anthropic | `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`, `claude-haiku-4-5` |
| Antigravity | `gemini-3.6-flash-high`, `gemini-3.6-flash-medium`, `gemini-3.6-flash-low`, `gemini-3.1-pro-high`, `gemini-3.1-pro-low`, `claude-sonnet-4-6`, `claude-opus-4-6-thinking`, `gpt-oss-120b-medium` |
| Gemini | `gemini-3.6-flash`, `gemini-3.1-pro-preview`, `gemini-2.5-flash` |

Type any other exact model ID into **Add Model** in Settings to add it to a provider's list.

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
│   ├── LLMService.swift     # Routes a query to the OAuth (CLI) or API-key (REST) path
│   ├── CLIBackend.swift     # Vendor CLI discovery + headless streaming (OAuth path)
│   └── KeychainService.swift# API key storage in the login keychain
├── Views/
│   ├── MainView.swift       # Primary chat interface
│   └── SettingsView.swift   # Configuration panel (providers, auth, models)
└── Models/
    ├── AppState.swift       # Global state, per-provider auth/keys/models, persistence
    └── ChatMessage.swift    # Chat message model
```

### Technology Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 6.0+ |
| UI Framework | SwiftUI |
| System Integration | AppKit (NSPanel, NSEvent) |
| Text Capture | Accessibility API, AppleScript |
| AI Providers | OpenAI, Anthropic Claude, Antigravity, Google Gemini (OAuth via vendor CLI, or API key) |
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

- **No token handling**: On the OAuth path the app never sees a token, client ID, or credentials file—it invokes the vendor CLI you already signed into, and that CLI owns its session
- **Stable code identity**: builds are signed with a local certificate (see `make_signing_cert.sh`) so keychain and Accessibility permissions survive rebuilds
- **Local-first**: API keys are stored in your login keychain (not uploaded anywhere). Keys written by earlier plain-text builds are migrated automatically on first read
- **No data retention**: Your text selections and conversations are not stored on any server
- **Direct calls**: Communication goes directly to the provider or through its official CLI—no intermediary servers

---

## 🚧 Roadmap

- [x] Claude (Anthropic) integration
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
- Powered by OpenAI, Anthropic Claude, Antigravity, and Google Gemini
- Inspired by the need for seamless AI integration into daily macOS workflows

---

<p align="center">
  <sub>Made with Swift for macOS 🍎</sub>
</p>
