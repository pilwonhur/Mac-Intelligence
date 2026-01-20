import Foundation

/// Service for interacting with LLM providers (OpenAI, Claude, etc.).
class LLMService: NSObject, URLSessionDataDelegate {
    static let shared = LLMService()
    
    enum Provider {
        case openai
        case gemini
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
    
    func streamCompletion(provider: Provider, prompt: String, context: String?, history: [ChatMessage] = [], apiKey: String, useWebSearch: Bool = false, onUpdate: @escaping (String) -> Void, onComplete: @escaping () -> Void) {
        self.onUpdate = onUpdate
        self.onComplete = onComplete
        self.buffer = Data()
        self.currentProvider = provider
        
        let url: URL
        var request: URLRequest
        
        let systemPrompt = "You are Mac Intelligence, a helpful macOS AI assistant. Provide extremely concise, high-quality answers. Use Markdown for formatting."
        
        if provider == .openai {
            url = URL(string: "https://api.openai.com/v1/chat/completions")!
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            var messages: [[String: Any]] = [["role": "system", "content": systemPrompt]]
            
            // Add History
            for msg in history {
                messages.append([
                    "role": msg.role == .user ? "user" : "assistant",
                    "content": msg.content
                ])
            }
            
            // Add Current Context & Prompt
            let currentPayload = context != nil && !context!.isEmpty ? "Context: \(context!)\n\nQuestion: \(prompt)" : prompt
            messages.append(["role": "user", "content": currentPayload])
            
            let body: [String: Any] = [
                "model": "gpt-4o",
                "messages": messages,
                "stream": true
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        } else {
            // Gemini
            let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent?alt=sse&key=\(key)")!
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            var contents: [[String: Any]] = []
            
            // Add History to Gemini contents
            // Gemini expects "user" and "model" roles
            for msg in history {
                contents.append([
                    "role": msg.role == .user ? "user" : "model",
                    "parts": [["text": msg.content]]
                ])
            }
            
            // Add Current Context & Prompt
            let currentPayload = context != nil && !context!.isEmpty ? "\(systemPrompt)\n\nContext: \(context!)\n\nQuestion: \(prompt)" : "\(systemPrompt)\n\n\(prompt)"
            contents.append([
                "role": "user",
                "parts": [["text": currentPayload]]
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
            print("📡 \(currentProvider == .openai ? "OpenAI" : "Gemini") API Status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                onUpdate?("❌ Connection Error (\(httpResponse.statusCode)). Check your key and limits.")
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
                
                if currentProvider == .openai {
                    if let choices = json["choices"] as? [[String: Any]],
                       let delta = choices.first?["delta"] as? [String: Any],
                       let content = delta["content"] as? String {
                        onUpdate?(content)
                    }
                } else {
                    // Gemini parsing
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
