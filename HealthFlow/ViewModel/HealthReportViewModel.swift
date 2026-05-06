import SwiftUI
import SwiftData

@Observable
@MainActor
final class HealthReportViewModel {
    var reportData: ReportData?
    var selectedRange: DateRange = .week

    enum DateRange {
        case week, month
    }

    struct ReportData {
        let dateRange: String
        let avgSteps: Int
        let totalWorkouts: Int
        let avgSleepHours: Double
        let avgSleepQuality: Double
        let avgCalories: Double
        let weightTrend: String
        let avgHeartRate: Double
        let alerts: [String]
    }

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func generateReport() {
        let calendar = Calendar.current
        let daysBack = selectedRange == .week ? 7 : 30
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: Date()) else { return }

        let activities = ((try? modelContext.fetch(FetchDescriptor<DailyActivitySummary>())) ?? [])
            .filter { $0.date >= startDate }
        let workouts = ((try? modelContext.fetch(FetchDescriptor<WorkoutRecord>())) ?? [])
            .filter { $0.startTime >= startDate }
        let sleeps = ((try? modelContext.fetch(FetchDescriptor<SleepRecord>())) ?? [])
            .filter { $0.endTime >= startDate }
        let metrics = ((try? modelContext.fetch(FetchDescriptor<PhysiologicalMetric>())) ?? [])
            .filter { $0.timestamp >= startDate }
        let diets = ((try? modelContext.fetch(FetchDescriptor<DietRecord>())) ?? [])
            .filter { $0.timestamp >= startDate }

        let avgSteps = activities.isEmpty ? 0 : activities.reduce(0) { $0 + $1.steps } / activities.count
        let totalWorkouts = workouts.count
        let groupedByDay = Dictionary(grouping: sleeps) { calendar.startOfDay(for: $0.endTime) }
        let dailySleepHours = groupedByDay.values.map { dayRecords in
            dayRecords.reduce(0.0) { $0 + $1.duration } / 3600.0
        }
        let avgSleepHours = dailySleepHours.isEmpty ? 0 : dailySleepHours.reduce(0, +) / Double(dailySleepHours.count)
        let avgSleepQuality = sleeps.isEmpty ? 0 : Double(sleeps.reduce(0) { $0 + $1.quality }) / Double(sleeps.count)
        let avgCalories = diets.isEmpty ? 0 : diets.reduce(0.0) { $0 + $1.totalCalories } / Double(diets.count)

        let heartRates = metrics.filter { $0.metricType == "heartRate" }
        let avgHeartRate = heartRates.isEmpty ? 0 : heartRates.reduce(0.0) { $0 + $1.value } / Double(heartRates.count)

        let weights = metrics.filter { $0.metricType == "weight" }.sorted { $0.timestamp < $1.timestamp }
        let weightTrend: String
        if weights.count >= 2,
           let first = weights.first?.value,
           let last = weights.last?.value {
            let diff = last - first
            if diff > 0.5 { weightTrend = "上升" }
            else if diff < -0.5 { weightTrend = "下降" }
            else { weightTrend = "稳定" }
        } else {
            weightTrend = "数据不足"
        }

        var alerts: [String] = []
        if HealthCalculator.checkSleepDeficit(sleeps: sleeps, threshold: Constants.Alert.defaultSleepMinimumHours) {
            alerts.append("存在睡眠不足预警")
        }
        if HealthCalculator.checkSedentary(workouts: workouts, daysBack: daysBack) {
            alerts.append("运动不足")
        }

        let dateFormatter = DateFormatter.monthDay
        let rangeString = "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: Date()))"

        reportData = ReportData(
            dateRange: rangeString,
            avgSteps: avgSteps,
            totalWorkouts: totalWorkouts,
            avgSleepHours: avgSleepHours,
            avgSleepQuality: avgSleepQuality,
            avgCalories: avgCalories,
            weightTrend: weightTrend,
            avgHeartRate: avgHeartRate,
            alerts: alerts
        )
    }

    func exportPDF() -> URL? {
        return nil
    }
}