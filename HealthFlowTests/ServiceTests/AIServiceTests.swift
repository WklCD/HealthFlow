import Testing
import Foundation
@testable import HealthFlow

struct AIServiceTests {

    @Test("配置 endpoint、apiKey 和 modelId 后 isConfigured 为 true")
    func testConfigure() {
        let service = AIService()
        service.configure(apiKey: "test-key", endpoint: "https://api.example.com/v1", modelId: "deepseek-chat")
        #expect(service.isConfigured)
    }

    @Test("未配置时调用返回空流")
    func testNotConfiguredReturnsEmptyStream() async {
        let service = AIService()
        let context = HealthContext(dateRange: "", totalSteps: 0, totalWorkouts: 0,
            avgSleepHours: 0, avgSleepQuality: 0, avgDietCalories: 0,
            currentWeight: nil, avgHeartRate: nil, bloodPressureSummary: nil)
        let stream = service.sendMessage(prompt: "测试", context: context)
        var results: [String] = []
        for await chunk in stream { results.append(chunk) }
        #expect(results.isEmpty)
    }

    @Test("快捷提问内容非空")
    func testQuickPromptsNotEmpty() {
        for type in QuickPromptType.allCases {
            let text = AIService.generateQuickPrompt(type: type)
            #expect(!text.isEmpty)
        }
    }

    @Test("缺少 modelId 时 isConfigured 为 false")
    func testConfigureWithoutModelId() {
        let service = AIService()
        service.configure(apiKey: "test-key", endpoint: "https://api.example.com/v1", modelId: "")
        #expect(!service.isConfigured)
    }
}