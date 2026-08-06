import Foundation

/// Service for interacting with LLM providers (OpenAI, Gemini, Anthropic).
class LLMService: NSObject, URLSessionDataDelegate {
    static let shared = LLMService()

    enum Provider {
        case openai
        case gemini
        case anthropic
    }

    private var session: URLSession!
    private var onUpdate: ((String) -> Void)?
    private var onComplete: (() -> Void)?
    private var buffer = Data()
    private var currentProvider: Provider = .openai

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }

    func streamCompletion(provider: Provider, model: String, prompt: String, context: String?, history: [ChatMessage] = [], apiKey: String, useWebSearch: Bool = false, onUpdate: @escaping (String) -> Void, onComplete: @escaping () -> Void) {
        self.onUpdate = onUpdate
        self.onComplete = onComplete
        self.buffer = Data()
        self.currentProvider = provider

        let url: URL
        var request: URLRequest
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        let systemPrompt = "You are Mac Intelligence, a helpful macOS AI assistant. Provide extremely concise, high-quality answers. Use Markdown for formatting."
        let currentPayload = context != nil && !context!.isEmpty ? "Context: \(context!)\n\nQuestion: \(prompt)" : prompt

        switch provider {
        case .openai:
            url = URL(string: "https://api.openai.com/v1/chat/completions")!
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            var messages: [[String: Any]] = [["role": "system", "content": systemPrompt]]
            for msg in history {
                messages.append([
                    "role": msg.role == .user ? "user" : "assistant",
                    "content": msg.content
                ])
            }
            messages.append(["role": "user", "content": currentPayload])

            let body: [String: Any] = [
                "model": model,
                "messages": messages,
                "stream": true
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        case .anthropic:
            url = URL(string: "https://api.anthropic.com/v1/messages")!
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue(key, forHTTPHeaderField: "x-api-key")
            request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            var messages: [[String: Any]] = []
            for msg in history {
                messages.append([
                    "role": msg.role == .user ? "user" : "assistant",
                    "content": msg.content
                ])
            }
            messages.append(["role": "user", "content": currentPayload])

            let body: [String: Any] = [
                "model": model,
                "max_tokens": 8192,
                "system": systemPrompt,
                "messages": messages,
                "stream": true
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        case .gemini:
            url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):streamGenerateContent?alt=sse&key=\(key)")!
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            var contents: [[String: Any]] = []
            // Gemini expects "user" and "model" roles
            for msg in history {
                contents.append([
                    "role": msg.role == .user ? "user" : "model",
                    "parts": [["text": msg.content]]
                ])
            }
            let geminiPayload = context != nil && !context!.isEmpty ? "\(systemPrompt)\n\nContext: \(context!)\n\nQuestion: \(prompt)" : "\(systemPrompt)\n\n\(prompt)"
            contents.append([
                "role": "user",
                "parts": [["text": geminiPayload]]
            ])

            var body: [String: Any] = ["contents": contents]
            if useWebSearch {
                body["tools"] = [
                    ["google_search": [String: Any]()]
                ]
            }
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        let task = session.dataTask(with: request)
        task.resume()
    }

    // MARK: - URLSessionDataDelegate

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 API Status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                onUpdate?("❌ Connection Error (\(httpResponse.statusCode)). Check your key, model name, and limits.")
            }
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)

        while let newlineIndex = buffer.firstIndex(of: 10) {
            let lineData = buffer.prefix(upTo: newlineIndex)
            buffer.removeSubrange(0...newlineIndex)

            guard let line = String(data: lineData, encoding: .utf8)?.trimmingCharacters(in: .whitespaces),
                  line.hasPrefix("data: ") else { continue }

            let jsonString = line.dropFirst(6)
            if jsonString == "[DONE]" {
                onComplete?()
                return
            }

            if let jsonData = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {

                switch currentProvider {
                case .openai:
                    if let choices = json["choices"] as? [[String: Any]],
                       let delta = choices.first?["delta"] as? [String: Any],
                       let content = delta["content"] as? String {
                        onUpdate?(content)
                    }
                case .anthropic:
                    if let type = json["type"] as? String {
                        if type == "content_block_delta",
                           let delta = json["delta"] as? [String: Any],
                           let text = delta["text"] as? String {
                            onUpdate?(text)
                        } else if type == "message_stop" {
                            onComplete?()
                            return
                        } else if type == "error",
                                  let error = json["error"] as? [String: Any],
                                  let message = error["message"] as? String {
                            onUpdate?("\n\n❌ API Error: \(message)")
                        }
                    }
                case .gemini:
                    if let candidates = json["candidates"] as? [[String: Any]],
                       let firstCandidate = candidates.first,
                       let content = firstCandidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let text = parts.first?["text"] as? String {
                        onUpdate?(text)
                    }
                }
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            onUpdate?("\n\n❌ Network Error: \(error.localizedDescription)")
        }
        onComplete?()
    }
}
