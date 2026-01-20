import SwiftUI

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
                    Text(state.selectedProvider == .openai ? "GPT-4o" : "Gemini 2.5 Flash")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.blue.opacity(0.7))
                }
                Spacer()
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
                Text(message.role == .user ? "YOU" : (state.selectedProvider == .openai ? "GPT-4o" : "GEMINI 2.5 FLASH"))
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
                    .disabled(state.selectedProvider == .openai)
                    
                    if state.selectedProvider == .openai && state.useWebSearch {
                        Text("(Gemini only)")
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
    
    func submitQuery() {
        guard !userPrompt.isEmpty else { return }
        
        let prompt = userPrompt
        let context = state.capturedText
        let provider: LLMService.Provider = (state.selectedProvider == .openai) ? .openai : .gemini
        let apiKey = (provider == .openai) ? state.apiKey : state.geminiKey
        let useWebSearch = state.useWebSearch
        let history = state.messages
        
        // Add User Message
        state.messages.append(ChatMessage(role: .user, content: prompt))
        userPrompt = ""
        
        // Add Placeholder Assistant Message
        let aiMessageIndex = state.messages.count
        state.messages.append(ChatMessage(role: .assistant, content: ""))
        state.isProcessing = true
        
        if apiKey.isEmpty {
            state.messages[aiMessageIndex].content = "⚠️ Please set your \(provider == .openai ? "OpenAI" : "Gemini") API Key in Settings (⚙️)."
            state.isProcessing = false
            return
        }
        
        LLMService.shared.streamCompletion(
            provider: provider,
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
