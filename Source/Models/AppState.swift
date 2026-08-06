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
        case anthropic = "Anthropic"
    }

    /// Models shipped by default for each provider. Users can add more in Settings.
    static let builtInModels: [AIProvider: [String]] = [
        .openai: ["gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna", "gpt-4o"],
        .gemini: ["gemini-3.6-flash", "gemini-3.1-pro-preview", "gemini-2.5-flash"],
        .anthropic: ["claude-fable-5", "claude-opus-5", "claude-sonnet-5", "claude-haiku-4-5"],
    ]

    @Published var selectedProvider: AIProvider = .openai
    @Published var apiKeys: [AIProvider: String] = [:]
    @Published var customModels: [AIProvider: [String]] = [:]
    @Published var selectedModels: [AIProvider: String] = [:]
    @Published var useWebSearch: Bool = false
    @Published var showSettings: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Persist model/provider selections immediately so they survive
        // however Settings is closed (Save button, ✕, or app quit).
        $selectedProvider
            .dropFirst()
            .sink { UserDefaults.standard.set($0.rawValue, forKey: "selected_provider") }
            .store(in: &cancellables)
        $selectedModels
            .dropFirst()
            .sink { selections in
                for (provider, model) in selections {
                    UserDefaults.standard.set(model, forKey: "selected_model_\(provider.rawValue)")
                }
            }
            .store(in: &cancellables)
        $customModels
            .dropFirst()
            .sink { all in
                for (provider, models) in all {
                    UserDefaults.standard.set(models, forKey: "custom_models_\(provider.rawValue)")
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Model / Key helpers

    func models(for provider: AIProvider) -> [String] {
        let builtIn = AppState.builtInModels[provider] ?? []
        let custom = (customModels[provider] ?? []).filter { !builtIn.contains($0) }
        return builtIn + custom
    }

    func selectedModel(for provider: AIProvider) -> String {
        if let model = selectedModels[provider], models(for: provider).contains(model) {
            return model
        }
        return models(for: provider).first ?? ""
    }

    /// Adds a user-typed model to the provider's list and selects it.
    func addModel(_ model: String, for provider: AIProvider) {
        let trimmed = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !models(for: provider).contains(trimmed) {
            customModels[provider, default: []].append(trimmed)
        }
        selectedModels[provider] = trimmed
    }

    func removeModel(_ model: String, for provider: AIProvider) {
        customModels[provider]?.removeAll { $0 == model }
        if selectedModels[provider] == model {
            selectedModels[provider] = models(for: provider).first
        }
    }

    func apiKey(for provider: AIProvider) -> String {
        return apiKeys[provider] ?? ""
    }

    // MARK: - Persistence

    private static func keychainKey(for provider: AIProvider) -> String {
        switch provider {
        case .openai: return "openai_api_key"
        case .gemini: return "gemini_api_key"
        case .anthropic: return "anthropic_api_key"
        }
    }

    func loadSettings() {
        for provider in AIProvider.allCases {
            apiKeys[provider] = KeychainService.shared.get(key: AppState.keychainKey(for: provider)) ?? ""
            customModels[provider] = UserDefaults.standard.stringArray(forKey: "custom_models_\(provider.rawValue)") ?? []
            if let model = UserDefaults.standard.string(forKey: "selected_model_\(provider.rawValue)") {
                selectedModels[provider] = model
            }
        }
        if let savedProvider = UserDefaults.standard.string(forKey: "selected_provider"),
           let provider = AIProvider(rawValue: savedProvider) {
            selectedProvider = provider
        }
    }

    func saveSettings() {
        for provider in AIProvider.allCases {
            KeychainService.shared.save(key: AppState.keychainKey(for: provider), value: apiKeys[provider] ?? "")
            UserDefaults.standard.set(customModels[provider] ?? [], forKey: "custom_models_\(provider.rawValue)")
            UserDefaults.standard.set(selectedModel(for: provider), forKey: "selected_model_\(provider.rawValue)")
        }
        UserDefaults.standard.set(selectedProvider.rawValue, forKey: "selected_provider")
    }

    func reset() {
        capturedText = ""
        sourceTitle = nil
        sourceURL = nil
        appName = ""
        messages = []
        isProcessing = false
        // Persistently stored settings like API keys, models, and selectedProvider are NOT reset
    }
}
