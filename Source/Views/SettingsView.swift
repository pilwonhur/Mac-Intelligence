import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: AppState
    @State private var configProvider: AppState.AIProvider = .openai
    @State private var newModelName: String = ""

    var body: some View {
        VStack(spacing: 16) {
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

            // Preferred provider (used for queries)
            VStack(alignment: .leading, spacing: 4) {
                Text("Preferred AI")
                    .font(.caption)
                    .fontWeight(.bold)
                Picker("", selection: $state.selectedProvider) {
                    ForEach(AppState.AIProvider.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if !providersMissingKeys.isEmpty {
                    Text("⚠️ No API key entered for: \(providersMissingKeys.map { $0.rawValue }.joined(separator: ", "))")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.orange)
                }
            }

            Divider()

            // Per-provider configuration
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Configure Provider")
                        .font(.caption)
                        .fontWeight(.bold)
                    Picker("", selection: $configProvider) {
                        ForEach(AppState.AIProvider.allCases, id: \.self) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

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
                }

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

                Text("Keys and models are stored locally on your Mac.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Button(action: saveAndClose) {
                Text("Save and Close")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .onAppear {
            configProvider = state.selectedProvider
        }
    }

    private var providersMissingKeys: [AppState.AIProvider] {
        AppState.AIProvider.allCases.filter { (state.apiKeys[$0] ?? "").isEmpty }
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

    private var keyPlaceholder: String {
        switch configProvider {
        case .openai: return "sk-..."
        case .gemini: return "Enter Gemini Key..."
        case .anthropic: return "sk-ant-..."
        }
    }

    private var modelPlaceholder: String {
        switch configProvider {
        case .openai: return "e.g. gpt-4o-mini"
        case .gemini: return "e.g. gemini-2.5-pro"
        case .anthropic: return "e.g. claude-sonnet-5"
        }
    }

    private func addModel() {
        state.addModel(newModelName, for: configProvider)
        newModelName = ""
    }

    private func saveAndClose() {
        state.saveSettings()
        state.showSettings = false
    }
}
