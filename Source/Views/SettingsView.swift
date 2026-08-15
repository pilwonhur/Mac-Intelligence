import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: AppState
    @State private var configProvider: AppState.AIProvider = .openai
    @State private var newModelName: String = ""
    @State private var cliPathText: String = ""
    /// Bumped whenever something that affects CLI detection changes, to force a re-check.
    @State private var detectionToken: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button(action: saveAndClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    preferredProviderSection
                    Divider()
                    configureProviderSection
                    authSection
                    modelSection
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }

            Divider()
            Button(action: saveAndClose) {
                Text("Save and Close")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .onAppear {
            configProvider = state.selectedProvider
            syncCLIPathField()
        }
    }

    // MARK: - Sections

    private var preferredProviderSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Preferred AI")
                .font(.caption)
                .fontWeight(.bold)
            Picker("", selection: $state.selectedProvider) {
                ForEach(AppState.AIProvider.allCases, id: \.self) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .labelsHidden()

            if let problem = state.authProblem(for: state.selectedProvider) {
                Text("⚠️ \(state.selectedProvider.rawValue): \(problem)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.orange)
            } else {
                Label("Ready via \(state.authMethod(for: state.selectedProvider).rawValue)",
                      systemImage: "checkmark.circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.green)
            }
        }
    }

    private var configureProviderSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Configure Provider")
                .font(.caption)
                .fontWeight(.bold)
            Picker("", selection: $configProvider) {
                ForEach(AppState.AIProvider.allCases, id: \.self) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .labelsHidden()
            .onChange(of: configProvider) { _ in syncCLIPathField() }
        }
    }

    private var authSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Authentication")
                .font(.caption)
                .fontWeight(.bold)

            Picker("", selection: authBinding) {
                ForEach(AppState.AuthMethod.allCases, id: \.self) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .disabled(!(configProvider.supportsOAuth && configProvider.supportsAPIKey))

            if !configProvider.supportsOAuth {
                Text("\(configProvider.rawValue) has no subscription CLI — API key only. "
                     + "For a Google subscription, use Antigravity.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else if !configProvider.supportsAPIKey {
                Text("\(configProvider.rawValue) is subscription-only — OAuth via its CLI.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            if state.authMethod(for: configProvider) == .oauth {
                oauthDetail
            } else {
                apiKeyDetail
            }
        }
    }

    @ViewBuilder
    private var oauthDetail: some View {
        if let tool = configProvider.cliTool {
            let resolved = detectedPath(for: tool)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: resolved != nil ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(resolved != nil ? .green : .orange)
                    Text(resolved != nil ? "\(tool.displayName) detected" : "\(tool.displayName) not found")
                        .fontWeight(.semibold)
                }
                .font(.caption)

                if let resolved = resolved {
                    Text(resolved)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                        .textSelection(.enabled)
                } else {
                    Text(tool.loginHint)
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("CLI path override")
                        .font(.system(size: 10, weight: .bold))
                    TextField("auto-detect", text: $cliPathText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 10, design: .monospaced))
                        .onSubmit(commitCLIPath)
                    Text("Leave empty to auto-detect. The app is launched from Finder, so it "
                         + "cannot see your shell PATH or shell functions.")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                Text("Signing in happens in \(tool.displayName) itself — this app never handles "
                     + "your tokens.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)

                if !tool.streamsDeltas {
                    Text("Note: \(tool.displayName) does not stream partial text, so the answer "
                         + "appears all at once when it finishes.")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var apiKeyDetail: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text("\(configProvider.rawValue) API Key")
                    .font(.caption)
                    .fontWeight(.bold)
                if (state.apiKeys[configProvider] ?? "").isEmpty {
                    Text("— not set")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            SecureField(keyPlaceholder, text: apiKeyBinding)
                .textFieldStyle(.roundedBorder)
            Text("Stored in your login keychain.")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Model")
                    .font(.caption)
                    .fontWeight(.bold)
                Picker("", selection: modelBinding) {
                    ForEach(state.models(for: configProvider), id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Add Model")
                    .font(.caption)
                    .fontWeight(.bold)
                HStack(spacing: 6) {
                    TextField(modelPlaceholder, text: $newModelName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addModel)
                    Button(action: addModel) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .disabled(newModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Text("Type the exact model ID. It stays selectable afterwards.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Bindings & helpers

    private var authBinding: Binding<AppState.AuthMethod> {
        Binding(
            get: { state.authMethod(for: configProvider) },
            set: { state.authMethods[configProvider] = $0 }
        )
    }

    private var apiKeyBinding: Binding<String> {
        Binding(
            get: { state.apiKeys[configProvider] ?? "" },
            set: { state.apiKeys[configProvider] = $0 }
        )
    }

    private var modelBinding: Binding<String> {
        Binding(
            get: { state.selectedModel(for: configProvider) },
            set: { state.selectedModels[configProvider] = $0 }
        )
    }

    /// `detectionToken` is read so SwiftUI re-runs this after a path override is committed.
    private func detectedPath(for tool: CLIBackend.Tool) -> String? {
        _ = detectionToken
        return CLIDiscovery.locate(tool)
    }

    private func syncCLIPathField() {
        cliPathText = configProvider.cliTool.flatMap { CLIDiscovery.override(for: $0) } ?? ""
    }

    private func commitCLIPath() {
        guard let tool = configProvider.cliTool else { return }
        CLIDiscovery.setOverride(cliPathText, for: tool)
        detectionToken += 1
    }

    private var keyPlaceholder: String {
        switch configProvider {
        case .openai: return "sk-..."
        case .gemini: return "Enter Gemini Key..."
        case .anthropic: return "sk-ant-..."
        case .antigravity: return "Not applicable"
        }
    }

    private var modelPlaceholder: String {
        switch configProvider {
        case .openai: return "e.g. gpt-4o-mini"
        case .gemini: return "e.g. gemini-2.5-pro"
        case .anthropic: return "e.g. claude-sonnet-5"
        case .antigravity: return "e.g. gemini-3.1-pro-high"
        }
    }

    private func addModel() {
        state.addModel(newModelName, for: configProvider)
        newModelName = ""
    }

    private func saveAndClose() {
        commitCLIPath()
        state.saveSettings()
        state.showSettings = false
    }
}
