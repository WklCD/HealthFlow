import Foundation
import SwiftData

@Observable
@MainActor
final class DashboardViewModel {
    var todayScore: Int = 0
    var todaySteps: Int = 0
    var todayCalories: Double = 0
    var sleepHours: Double = 0
    var sleepQuality: Int = 0
    var avgHeartRate: Double = 0
    var dietCalories: Double = 0
    var alerts: [String] = []

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadToday() {
        let today = Calendar.current.startOfDay(for: Date())
        let profile = (try? modelContext.fetch(FetchDescriptor<UserProfile>()).first)

        let activities = (try? modelContext.fetch(FetchDescriptor<DailyActivitySummary>())) ?? []
        let todayActivities = activities.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        todaySteps = todayActivities.reduce(0) { $0 + $1.steps }
        todayCalories = todayActivities.reduce(0) { $0 + $1.calories }

        let sleeps = (try? modelContext.fetch(FetchDescriptor<SleepRecord>())) ?? []
        let todaySleeps = sleeps.filter { Calendar.current.isDate($0.endTime, inSameDayAs: today) }
        let totalSleepSeconds = todaySleeps.reduce(0.0) { $0 + $1.duration }
        sleepHours = totalSleepSeconds / 3600.0
        if !todaySleeps.isEmpty {
            sleepQuality = Int(todaySleeps.reduce(0) { $0 + $1.quality } / todaySleeps.count)
        }

        let metrics = (try? modelContext.fetch(FetchDescriptor<PhysiologicalMetric>())) ?? []
        let heartRates = metrics.filter { $0.metricType == "heartRate" }
        if !heartRates.isEmpty {
            avgHeartRate = heartRates.reduce(0) { $0 + $1.value } / Double(heartRates.count)
        }

        let diets = (try? modelContext.fetch(FetchDescriptor<DietRecord>())) ?? []
        let todayDiets = diets.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }
        dietCalories = todayDiets.reduce(0) { $0 + $1.totalCalories }

        let exerciseScore = HealthCalculator.exerciseScore(steps: todaySteps, target: profile?.targetSteps ?? 10000)
        let sleepScore = HealthCalculator.sleepScore(hours: sleepHours, target: profile?.targetSleepHours ?? 8, quality: sleepQuality)
        let dietScoreValue = HealthCalculator.dietScore(calories: dietCalories, target: Double(profile?.targetCalories ?? 2000))
        let physiologyScore = computePhysiologyScore(metrics: metrics, heartRates: heartRates)
        let activeDays = computeActiveDays(activities: activities)

        todayScore = HealthCalculator.totalScore(
            exercise: exerciseScore,
            sleep: sleepScore,
            diet: dietScoreValue,
            physiology: physiologyScore,
            activeDays: activeDays
        )

        checkAlerts(sleeps: sleeps, heartRates: heartRates, workouts: (try? modelContext.fetch(FetchDescriptor<WorkoutRecord>())) ?? [])
    }

    private func computePhysiologyScore(metrics: [PhysiologicalMetric], heartRates: [PhysiologicalMetric]) -> Int {
        guard !metrics.isEmpty else { return 10 }
        var normalCount = 0
        for m in metrics {
            switch m.metricType {
            case "heartRate":
                if !HealthCalculator.isHeartRateAbnormal(bpm: m.value, max: Constants.Alert.defaultHeartRateMax, min: Constants.Alert.defaultHeartRateMin) {
                    normalCount += 1
                }
            case "bloodPressure":
                if let sys = m.valueSystolic, let dia = m.valueDiastolic {
                    if sys >= 90 && sys <= 140 && dia >= 60 && dia <= 90 {
                        normalCount += 1
                    }
                }
            default:
                normalCount += 1
            }
        }
        let ratio = Double(normalCount) / Double(metrics.count)
        return Int(ratio * 20)
    }

    private func computeActiveDays(activities: [DailyActivitySummary]) -> Int {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentActivities = activities.filter { $0.date >= sevenDaysAgo }
        let uniqueDays = Set(recentActivities.map { calendar.startOfDay(for: $0.date) })
        return HealthCalculator.activeDaysScore(daysInWeek: uniqueDays.count)
    }

    private func checkAlerts(sleeps: [SleepRecord], heartRates: [PhysiologicalMetric], workouts: [WorkoutRecord]) {
        alerts = []
        if HealthCalculator.checkSleepDeficit(sleeps: sleeps, threshold: Constants.Alert.defaultSleepMinimumHours) {
            alerts.append("近3天睡眠不足\(Int(Constants.Alert.defaultSleepMinimumHours))小时")
        }
        if let latestHR = heartRates.max(by: { $0.timestamp < $1.timestamp }) {
            if HealthCalculator.isHeartRateAbnormal(bpm: latestHR.value, max: Constants.Alert.defaultHeartRateMax, min: Constants.Alert.defaultHeartRateMin) {
                alerts.append("心率异常：\(Int(latestHR.value)) bpm")
            }
        }
        if HealthCalculator.checkSedentary(workouts: workouts, daysBack: Constants.Alert.defaultSedentaryDays) {
            alerts.append("近\(Constants.Alert.defaultSedentaryDays)天无运动记录")
        }
    }
}