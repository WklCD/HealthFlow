import Foundation
import SwiftUI
import SwiftData

@Observable
@MainActor
final class AIAssistantViewModel {
    var messages: [ChatMessage] = []
    var isStreaming = false
    private let modelContext: ModelContext
    private let aiService: AIServiceProtocol

    init(modelContext: ModelContext, aiService: AIServiceProtocol) {
        self.modelContext = modelContext
        self.aiService = aiService
        loadMessages()
    }

    func loadMessages() {
        let descriptor = FetchDescriptor<ChatMessage>(sortBy: [SortDescriptor(\.timestamp)])
        messages = (try? modelContext.fetch(descriptor)) ?? []
    }

    func sendMessage(_ text: String) async {
        let userMsg = ChatMessage(role: "user", content: text)
        modelContext.insert(userMsg)
        try? modelContext.save()
        loadMessages()

        let context = buildHealthContext()
        isStreaming = true

        let assistantMsg = ChatMessage(role: "assistant", content: "")
        modelContext.insert(assistantMsg)
        var fullContent = ""

        for await chunk in aiService.sendMessage(prompt: text, context: context) {
            fullContent += chunk
            assistantMsg.content = fullContent
            loadMessages()
        }

        assistantMsg.content = fullContent
        try? modelContext.save()
        isStreaming = false
        loadMessages()
    }

    func sendQuickPrompt(_ type: QuickPromptType) async {
        await sendMessage(type.promptText)
    }

    func clearConversation() {
        for msg in messages { modelContext.delete(msg) }
        try? modelContext.save()
        messages = []
    }

    private func buildHealthContext() -> HealthContext {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let activities = (try? modelContext.fetch(FetchDescriptor<DailyActivitySummary>())) ?? []
        let recentActivities = activities.filter { $0.date >= sevenDaysAgo }
        let totalSteps = recentActivities.reduce(0) { $0 + $1.steps }

        let workouts = (try? modelContext.fetch(FetchDescriptor<WorkoutRecord>())) ?? []
        let recentWorkouts = workouts.filter { $0.startTime >= sevenDaysAgo }

        let sleeps = (try? modelContext.fetch(FetchDescriptor<SleepRecord>())) ?? []
        let recentSleeps = sleeps.filter { $0.endTime >= sevenDaysAgo }
        let avgSleepHours = recentSleeps.isEmpty ? 0 : recentSleeps.reduce(0.0) { $0 + $1.duration } / Double(recentSleeps.count) / 3600.0
        let avgSleepQuality = recentSleeps.isEmpty ? 0 : Double(recentSleeps.reduce(0) { $0 + $1.quality }) / Double(recentSleeps.count)

        let diets = (try? modelContext.fetch(FetchDescriptor<DietRecord>())) ?? []
        let recentDiets = diets.filter { $0.timestamp >= sevenDaysAgo }
        let avgDietCalories = recentDiets.isEmpty ? 0 : recentDiets.reduce(0.0) { $0 + $1.totalCalories } / Double(recentDiets.count)

        let profile = (try? modelContext.fetch(FetchDescriptor<UserProfile>()).first)
        let currentWeight: Double? = profile?.targetWeight

        let metrics = (try? modelContext.fetch(FetchDescriptor<PhysiologicalMetric>())) ?? []
        let heartRates = metrics.filter { $0.metricType == "heartRate" }
        let avgHeartRate: Double? = heartRates.isEmpty ? nil : heartRates.reduce(0.0) { $0 + $1.value } / Double(heartRates.count)

        let bpMetrics = metrics.filter { $0.metricType == "bloodPressure" && $0.valueSystolic != nil }
        let bloodPressureSummary: String? = bpMetrics.isEmpty ? nil : bpMetrics.map { "\($0.valueSystolic ?? 0)/\($0.valueDiastolic ?? 0)" }.last

        return HealthContext(
            dateRange: "近7天",
            totalSteps: totalSteps,
            totalWorkouts: recentWorkouts.count,
            avgSleepHours: avgSleepHours,
            avgSleepQuality: avgSleepQuality,
            avgDietCalories: avgDietCalories,
            currentWeight: currentWeight,
            avgHeartRate: avgHeartRate,
            bloodPressureSummary: bloodPressureSummary
        )
    }
}