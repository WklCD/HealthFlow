import Foundation
@testable import HealthFlow

final class MockAIService: AIServiceProtocol {
    var isConfigured = false
    var responses: [String] = []

    func configure(apiKey: String, endpoint: String, modelId: String) {
        isConfigured = !apiKey.isEmpty && !endpoint.isEmpty && !modelId.isEmpty
    }

    func sendMessage(prompt: String, context: HealthContext) -> AsyncStream<String> {
        AsyncStream { continuation in
            for chunk in responses {
                continuation.yield(chunk)
            }
            continuation.finish()
        }
    }

    func generateQuickPrompt(type: QuickPromptType) -> String {
        type.promptText
    }
}