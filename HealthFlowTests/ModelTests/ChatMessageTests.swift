import Testing
import Foundation
@testable import HealthFlow

struct ChatMessageTests {

    @Test("默认值为空")
    func testDefaults() {
        let msg = ChatMessage()
        #expect(msg.role == "")
        #expect(msg.content == "")
        #expect(msg.promptType == nil)
    }

    @Test("设置 role 为 user 和 assistant")
    func testRoleValues() {
        let userMsg = ChatMessage()
        userMsg.role = "user"
        #expect(userMsg.role == "user")

        let aiMsg = ChatMessage()
        aiMsg.role = "assistant"
        #expect(aiMsg.role == "assistant")
    }

    @Test("promptType 可设置")
    func testPromptType() {
        let msg = ChatMessage()
        msg.promptType = QuickPromptType.todaySummary.rawValue
        #expect(msg.promptType == "today_summary")
    }

    @Test("timestamp 在创建时自动设置")
    func testTimestampOnCreation() {
        let before = Date()
        let msg = ChatMessage()
        #expect(msg.timestamp >= before)
        #expect(msg.timestamp <= Date())
    }
}