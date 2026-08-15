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

    /// OAuth-capable providers come first — they are the intended default path.
    enum AIProvider: String, CaseIterable {
        case openai = "OpenAI"
        case anthropic = "Anthropic"
        case antigravity = "Antigravity"
        case gemini = "Gemini"

        /// The vendor CLI that owns this provider's OAuth session, if any.
        /// Signing in happens in that CLI; this app never handles tokens.
        var cliTool: CLIBackend.Tool? {
            switch self {
            case .openai: return .codex
            case .anthropic: return .claude
            case .antigravity: return .agy
            // Gemini's personal subscription CLI was retired (Code Assist for individuals
            // moved to Antigravity), so Gemini is an API-key-only provider here.
            case .gemini: return nil
            }
        }

        /// Antigravity is subscription-only — it has no public REST API to key into.
        var supportsAPIKey: Bool { self != .antigravity }

        var supportsOAuth: Bool { cliTool != nil }

        var defaultAuthMethod: AuthMethod { supportsOAuth ? .oauth : .apiKey }
    }

    enum AuthMethod: String, CaseIterable {
        case oauth = "OAuth"
        case apiKey = "API Key"
    }

    /// Models shipped by default for each provider. Users can add more in Settings.
    static let builtInModels: [AIProvider: [String]] = [
        .openai: ["gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna", "gpt-4o"],
        .anthropic: ["claude-fable-5", "claude-opus-5", "claude-sonnet-5", "claude-haiku-4-5"],
        // Antigravity uses its own model IDs with effort suffixes.
        .antigravity: ["gemini-3.6-flash-high", "gemini-3.6-flash-medium", "gemini-3.6-flash-low",
                       "gemini-3.1-pro-high", "gemini-3.1-pro-low",
                       "claude-sonnet-4-6", "claude-opus-4-6-thinking", "gpt-oss-120b-medium"],
        .gemini: ["gemini-3.6-flash", "gemini-3.1-pro-preview", "gemini-2.5-flash"],
    ]

    @Published var selectedProvider: AIProvider = .openai
    @Published var apiKeys: [AIProvider: String] = [:]
    @Published var authMethods: [AIProvider: AuthMethod] = [:]
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
        $authMethods
            .dropFirst()
            .sink { all in
                for (provider, method) in all {
                    UserDefaults.standard.set(method.rawValue, forKey: "auth_method_\(provider.rawValue)")
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

    // MARK: - Auth

    /// The auth method actually in effect, ignoring a stored choice the provider cannot honor.
    func authMethod(for provider: AIProvider) -> AuthMethod {
        let stored = authMethods[provider] ?? provider.defaultAuthMethod
        if stored == .oauth && !provider.supportsOAuth { return .apiKey }
        if stored == .apiKey && !provider.supportsAPIKey { return .oauth }
        return stored
    }

    /// Whether the selected auth method is actually usable right now.
    func isAuthReady(for provider: AIProvider) -> Bool {
        switch authMethod(for: provider) {
        case .oauth:
            guard let tool = provider.cliTool else { return false }
            return CLIDiscovery.locate(tool) != nil
        case .apiKey:
            return !apiKey(for: provider).isEmpty
        }
    }

    /// Short reason the provider cannot run, for the header badge and Settings.
    func authProblem(for provider: AIProvider) -> String? {
        guard !isAuthReady(for: provider) else { return nil }
        switch authMethod(for: provider) {
        case .oauth:
            guard let tool = provider.cliTool else { return "No OAuth path" }
            return "\(tool.displayName) not found"
        case .apiKey:
            return "No API key"
        }
    }

    // MARK: - Persistence

    private static func keychainKey(for provider: AIProvider) -> String {
        switch provider {
        case .openai: return "openai_api_key"
        case .gemini: return "gemini_api_key"
        case .anthropic: return "anthropic_api_key"
        case .antigravity: return "antigravity_api_key"   // unused; kept for symmetry
        }
    }

    func loadSettings() {
        for provider in AIProvider.allCases {
            apiKeys[provider] = KeychainService.shared.get(key: AppState.keychainKey(for: provider)) ?? ""
            customModels[provider] = UserDefaults.standard.stringArray(forKey: "custom_models_\(provider.rawValue)") ?? []
            if let model = UserDefaults.standard.string(forKey: "selected_model_\(provider.rawValue)") {
                selectedModels[provider] = model
            }
            if let raw = UserDefaults.standard.string(forKey: "auth_method_\(provider.rawValue)"),
               let method = AuthMethod(rawValue: raw) {
                authMethods[provider] = method
            } else {
                authMethods[provider] = provider.defaultAuthMethod
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
            UserDefaults.standard.set(authMethod(for: provider).rawValue, forKey: "auth_method_\(provider.rawValue)")
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
