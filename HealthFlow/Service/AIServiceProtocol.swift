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
        你是专业的健康顾问，回答简洁直接，控制在3-5句话。
        只有当用户明确询问健康数据分析、趋势或建议时，才引用以下数据：
        近7天：运动\(totalWorkouts)次，步数\(totalSteps)，睡眠\(String(format: "%.1f", avgSleepHours))h/晚（质量\(avgSleepQuality)/5），饮食\(Int(avgDietCalories))千卡/日，体重\(currentWeight.map { "\(Int($0))kg" } ?? "未记")，静息心率\(avgHeartRate.map { "\(Int($0))bpm" } ?? "未记")。
        用户未问数据时不要主动列出，直接回答问题即可。
        """
    }
}