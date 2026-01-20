import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: AppState
    @State private var tempOpenAIKey: String = ""
    @State private var tempGeminiKey: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button(action: { state.showSettings = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 5)
            
            // Provider Selection
            Picker("Preferred AI", selection: $state.selectedProvider) {
                ForEach(AppState.AIProvider.allCases, id: \.self) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading, spacing: 12) {
                // OpenAI Section
                VStack(alignment: .leading, spacing: 4) {
                    Text("OpenAI API Key")
                        .font(.caption)
                        .fontWeight(.bold)
                    SecureField("sk-...", text: $tempOpenAIKey)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Gemini Section
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gemini API Key")
                        .font(.caption)
                        .fontWeight(.bold)
                    SecureField("Enter Gemini Key...", text: $tempGeminiKey)
                        .textFieldStyle(.roundedBorder)
                }
                
                Text("Keys are stored locally on your Mac.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Button(action: saveKeys) {
                Text("Save and Close")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .onAppear {
            tempOpenAIKey = KeychainService.shared.get(key: "openai_api_key") ?? ""
            tempGeminiKey = KeychainService.shared.get(key: "gemini_api_key") ?? ""
        }
    }
    
    func saveKeys() {
        KeychainService.shared.save(key: "openai_api_key", value: tempOpenAIKey)
        KeychainService.shared.save(key: "gemini_api_key", value: tempGeminiKey)
        state.apiKey = tempOpenAIKey
        state.geminiKey = tempGeminiKey
        
        // Save preferred provider to defaults for next launch
        UserDefaults.standard.set(state.selectedProvider.rawValue, forKey: "selected_provider")
        
        state.showSettings = false
    }
}
