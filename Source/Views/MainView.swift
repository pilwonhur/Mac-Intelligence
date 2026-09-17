import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @ObservedObject var state: AppState
    @State private var userPrompt: String = ""
    
    var body: some View {
        ZStack {
            if state.showSettings {
                SettingsView(state: state)
                    .transition(.move(edge: .trailing))
            } else {
                content
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.spring(), value: state.showSettings)
    }
    
    var content: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Mac Intelligence by Pilwon Hur")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    HStack(spacing: 4) {
                        Text("\(state.selectedProvider.rawValue) · \(state.selectedModel(for: state.selectedProvider))")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.blue.opacity(0.7))
                        Text(state.authMethod(for: state.selectedProvider).rawValue)
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.18))
                            .cornerRadius(3)
                            .foregroundColor(.blue.opacity(0.9))
                        if let problem = state.authProblem(for: state.selectedProvider) {
                            Text("⚠️ \(problem)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.orange)
                        }
                    }
                }
                Spacer()
                Button(action: exportChat) {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Save chat as Markdown")
                .disabled(state.messages.isEmpty)
                .opacity(state.messages.isEmpty ? 0.4 : 1)

                Button(action: {
                    state.messages = []
                    state.isProcessing = false
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear Chat history")
                
                Button(action: { state.showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Settings")
                .padding(.trailing, 4)

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Image(systemName: "power")
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Quit Mac Intelligence")
            }
            .padding()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !state.capturedText.isEmpty {
                            sourceSection
                            selectedTextSection
                        }
                        
                        ForEach(state.messages) { message in
                            chatBubble(for: message)
                                .id(message.id)
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: state.messages.last?.content) { _ in
                    if let lastId = state.messages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Input Area
            inputArea
        }
    }
    
    func chatBubble(for message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer() }
                        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.role == .user ? "YOU" : state.selectedModel(for: state.selectedProvider).uppercased())
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(message.role == .user ? .secondary : .blue)
                
                Text(message.content)
                    .font(.system(size: 13))
                    .padding(10)
                    .background(message.role == .user ? Color.blue.opacity(0.15) : Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
            .padding(.trailing, message.role == .assistant ? 40 : 0)
            .padding(.leading, message.role == .user ? 40 : 0)
            
            if message.role == .assistant { Spacer() }
        }
        .padding(.horizontal)
    }
    
    var sourceSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: state.sourceURL != nil ? "safari" : "app.badge")
                Text(state.appName)
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .foregroundColor(.blue)
            
            if let title = state.sourceTitle {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal)
    }
    
    var selectedTextSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CONTEXT")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.secondary)
            
            Text(state.capturedText)
                .font(.system(size: 12, design: .serif))
                .italic()
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.03))
                .cornerRadius(8)
                .textSelection(.enabled)
        }
        .padding(.horizontal)
    }
    
    var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 12) {
                    CustomTextView(text: $userPrompt, onCommit: submitQuery)
                        .frame(minHeight: 36)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(2)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    
                    Button(action: submitQuery) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(userPrompt.isEmpty ? .secondary : .blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(userPrompt.isEmpty)
                }
                
                HStack {
                    Toggle(isOn: $state.useWebSearch) {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                            Text("Web Search")
                        }
                        .font(.system(size: 10, weight: .bold))
                    }
                    .toggleStyle(.checkbox)
                    .disabled(!state.supportsWebSearch(for: state.selectedProvider))

                    if !state.supportsWebSearch(for: state.selectedProvider) {
                        Text(webSearchUnavailableReason)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .padding()
        }
        .background(Color.black.opacity(0.1))
    }
    
    /// Why the toggle is greyed out for the current provider + auth combination.
    private var webSearchUnavailableReason: String {
        let provider = state.selectedProvider
        if provider == .antigravity { return "(not available via Antigravity)" }
        if state.authMethod(for: provider) == .apiKey && provider != .gemini {
            return "(switch \(provider.rawValue) to OAuth, or use Gemini)"
        }
        return "(not available here)"
    }

    func exportChat() {
        // Snapshot first — the hotkey can reset the conversation while the save panel is open.
        let markdown = state.transcriptMarkdown()

        let stamp = DateFormatter()
        stamp.dateFormat = "yyyy-MM-dd_HHmmss"

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        savePanel.nameFieldStringValue = "MacIntelligence_Chat_\(stamp.string(from: Date())).md"
        savePanel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        savePanel.canCreateDirectories = true

        // The ghost panel never activates the app, and without that the save panel cannot
        // take keyboard input. runModal also lifts it above the floating panel's level.
        NSApp.activate(ignoringOtherApps: true)
        guard savePanel.runModal() == .OK, let url = savePanel.url else { return }

        do {
            try markdown.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    func submitQuery() {
        guard !userPrompt.isEmpty else { return }

        let prompt = userPrompt
        let context = state.capturedText
        let provider = state.selectedProvider
        let authMethod = state.authMethod(for: provider)
        let model = state.selectedModel(for: provider)
        // First keychain touch happens here, not at launch — and only on the API-key path.
        if authMethod == .apiKey { state.ensureAPIKeyLoaded(for: provider) }
        let apiKey = state.apiKey(for: provider)
        let useWebSearch = state.useWebSearch
        let history = state.messages

        // Add User Message
        state.messages.append(ChatMessage(role: .user, content: prompt))
        userPrompt = ""

        // Add Placeholder Assistant Message
        let aiMessageIndex = state.messages.count
        state.messages.append(ChatMessage(role: .assistant, content: ""))
        state.isProcessing = true

        if let problem = state.authProblem(for: provider) {
            let fix = authMethod == .oauth
                ? "\(provider.cliTool?.loginHint ?? "") You can also set its path, or switch to an API key, in Settings (⚙️)."
                : "Set your \(provider.rawValue) API key in Settings (⚙️)."
            state.messages[aiMessageIndex].content = "⚠️ \(provider.rawValue) — \(problem). \(fix)"
            state.isProcessing = false
            return
        }

        LLMService.shared.send(
            provider: provider,
            authMethod: authMethod,
            model: model,
            prompt: prompt,
            context: context,
            history: history,
            apiKey: apiKey,
            useWebSearch: useWebSearch,
            onUpdate: { chunk in
                state.messages[aiMessageIndex].content += chunk
            },
            onComplete: {
                state.isProcessing = false
            }
        )
    }
}

// MARK: - Custom TextView for proper Multi-line / Enter handling
struct CustomTextView: NSViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.font = .systemFont(ofSize: 13)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 8, height: 8)
        
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            if textView.string != text {
                textView.string = text
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CustomTextView

        init(_ parent: CustomTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                parent.text = textView.string
            }
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                let event = NSApp.currentEvent
                // If Shift or Option is pressed, insert actual newline
                if event?.modifierFlags.contains(.shift) == true || event?.modifierFlags.contains(.option) == true {
                    return false // Let standard handling insert newline
                } else {
                    // Just Enter: Submit
                    parent.onCommit()
                    return true
                }
            }
            return false
        }
    }
}
