import Testing
import SwiftData
@testable import HealthFlow

@MainActor
struct AIAssistantViewModelTests {

    @Test("发送消息后用户消息被持久化")
    func testSendMessagePersistsUserMessage() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ChatMessage.self, configurations: config)
        let mockAI = MockAIService()
        let vm = AIAssistantViewModel(modelContext: container.mainContext, aiService: mockAI)

        await vm.sendMessage("测试问题")

        let messages = try container.mainContext.fetch(FetchDescriptor<ChatMessage>())
        #expect(messages.contains { $0.role == "user" && $0.content == "测试问题" })
    }

    @Test("AI 回复被持久化")
    func testAIResponsePersisted() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ChatMessage.self, configurations: config)
        let mockAI = MockAIService()
        mockAI.responses = ["这是AI的回复"]
        let vm = AIAssistantViewModel(modelContext: container.mainContext, aiService: mockAI)

        await vm.sendMessage("问题")

        let messages = try container.mainContext.fetch(FetchDescriptor<ChatMessage>())
        #expect(messages.contains { $0.role == "assistant" && $0.content == "这是AI的回复" })
    }

    @Test("清除对话删除所有消息")
    func testClearConversation() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ChatMessage.self, configurations: config)
        let mockAI = MockAIService()
        let vm = AIAssistantViewModel(modelContext: container.mainContext, aiService: mockAI)
        await vm.sendMessage("问题")

        vm.clearConversation()

        let count = try container.mainContext.fetch(FetchDescriptor<ChatMessage>()).count
        #expect(count == 0)
    }
}