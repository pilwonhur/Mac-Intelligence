import Foundation
import Combine

/// Manages the global state and logic of the Mac Intelligence application.
class AppState: ObservableObject {
    @Published var capturedText: String = ""
    @Published var sourceTitle: String? = nil
    @Published var sourceURL: String? = nil
    @Published var appName: String = ""
    
    @Published var isPanelVisible: Bool = false
    @Published var isProcessing: Bool = false
    @Published var messages: [ChatMessage] = []
    
    enum AIProvider: String, CaseIterable {
        case openai = "OpenAI"
        case gemini = "Gemini"
    }
    
    @Published var selectedProvider: AIProvider = .openai
    @Published var apiKey: String = "" // OpenAI Key
    @Published var geminiKey: String = ""
    @Published var useWebSearch: Bool = false
    @Published var showSettings: Bool = false
    
    func reset() {
        capturedText = ""
        sourceTitle = nil
        sourceURL = nil
        appName = ""
        messages = []
        isProcessing = false
        // Persistently stored settings like apiKey, geminiKey, and selectedProvider are NOT reset
    }
}
