import Foundation

protocol AIServiceProtocol {
    var isConfigured: Bool { get }
    func configure(apiKey: String, endpoint: String, modelId: String)
    func sendMessage(prompt: String, context: HealthContext) -> AsyncStream<String>
    func generateQuickPrompt(type: QuickPromptType) -> String
}

struct HealthContext: Codable {
    let dateRange: String
    let totalSteps: Int
    let totalWorkouts: Int
    let avgSleepHours: Double
    let avgSleepQuality: Double
    let avgDietCalories: Double
    let currentWeight: Double?
    let avgHeartRate: Double?
    let bloodPressureSummary: String?

    var systemPrompt: String {
        """
        你是一位专业的健康顾问。以下是用户近7天的健康数据摘要：

        运动：共\(totalWorkouts)次运动，总步数\(totalSteps)步
        睡眠：平均\(String(format: "%.1f", avgSleepHours))小时/晚，平均质量\(avgSleepQuality)/5
        饮食：平均每日摄入\(Int(avgDietCalories))千卡
        体重：\(currentWeight.map { "\(Int($0))kg" } ?? "未记录")
        心率：静息\(avgHeartRate.map { "\(Int($0))bpm" } ?? "未记录")

        请基于以上数据回答问题。
        """
    }
}