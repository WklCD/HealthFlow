import Testing
import Foundation
import SwiftData
@testable import HealthFlow

@MainActor
struct DashboardViewModelTests {

    @Test("计算今日健康评分为有效值")
    func testTodayScore() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProfile.self, DailyActivitySummary.self, SleepRecord.self, PhysiologicalMetric.self, DietRecord.self, WorkoutRecord.self, configurations: config)
        let profile = UserProfile()
        profile.targetSteps = 10000
        profile.targetSleepHours = 8
        profile.targetCalories = 2000
        container.mainContext.insert(profile)

        let summary = DailyActivitySummary()
        summary.steps = 8000
        summary.date = Calendar.current.startOfDay(for: Date())
        container.mainContext.insert(summary)

        let vm = DashboardViewModel(modelContext: container.mainContext)
        vm.loadToday()

        #expect(vm.todayScore >= 0 && vm.todayScore <= 100)
        #expect(vm.todaySteps == 8000)
    }

    @Test("无数据时评分为活跃天数分数")
    func testEmptyData() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProfile.self, DailyActivitySummary.self, SleepRecord.self, PhysiologicalMetric.self, DietRecord.self, WorkoutRecord.self, configurations: config)
        let profile = UserProfile()
        container.mainContext.insert(profile)

        let vm = DashboardViewModel(modelContext: container.mainContext)
        vm.loadToday()

        #expect(vm.todayScore >= 0)
        #expect(vm.todaySteps == 0)
    }

    @Test("睡眠不足预警触发")
    func testSleepAlertTriggered() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProfile.self, DailyActivitySummary.self, SleepRecord.self, PhysiologicalMetric.self, DietRecord.self, WorkoutRecord.self, configurations: config)
        let profile = UserProfile()
        container.mainContext.insert(profile)

        for daysAgo in 0..<3 {
            let record = SleepRecord()
            record.endTime = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            record.duration = 5 * 3600
            container.mainContext.insert(record)
        }

        let vm = DashboardViewModel(modelContext: container.mainContext)
        vm.loadToday()

        #expect(vm.alerts.contains { $0.contains("睡眠不足") })
    }
}