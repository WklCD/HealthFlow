import Foundation

final class AIService: AIServiceProtocol {
    private var apiKey: String = ""
    private var endpoint: String = ""
    private var modelId: String = ""
    private(set) var isConfigured = false

    func configure(apiKey: String, endpoint: String, modelId: String) {
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.modelId = modelId
        self.isConfigured = !apiKey.isEmpty && !endpoint.isEmpty && !modelId.isEmpty
    }

    func sendMessage(prompt: String, context: HealthContext) -> AsyncStream<String> {
        AsyncStream { continuation in
            guard self.isConfigured else {
                continuation.finish()
                return
            }

            let fullPrompt = "\(context.systemPrompt)\n\n用户问题：\(prompt)"
            guard let url = URL(string: "\(self.endpoint)/chat/completions") else {
                continuation.finish()
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "model": self.modelId,
                "messages": [["role": "user", "content": fullPrompt]],
                "stream": true,
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        continuation.finish()
                        return
                    }
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            if jsonString == "[DONE]" { break }
                            if let data = jsonString.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let choices = json["choices"] as? [[String: Any]],
                               let delta = choices.first?["delta"] as? [String: Any],
                               let content = delta["content"] as? String {
                                continuation.yield(content)
                            }
                        }
                    }
                } catch {
                    continuation.finish()
                    return
                }
                continuation.finish()
            }
        }
    }

    func generateQuickPrompt(type: QuickPromptType) -> String {
        Self.generateQuickPrompt(type: type)
    }

    static func generateQuickPrompt(type: QuickPromptType) -> String {
        type.promptText
    }
}