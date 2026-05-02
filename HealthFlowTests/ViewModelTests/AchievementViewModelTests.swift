import Testing
import SwiftData
@testable import HealthFlow

@MainActor
struct AchievementViewModelTests {

    @Test("步数达标时获得万步达人徽章")
    func testStepsBadgeAwarded() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DailyActivitySummary.self, AchievementBadge.self, configurations: config)
        let vm = AchievementViewModel()

        let activity = DailyActivitySummary(steps: 12000)
        container.mainContext.insert(activity)
        try container.mainContext.save()

        vm.checkAndAwardBadges(modelContext: container.mainContext)
        #expect(vm.earnedBadges.contains { $0.badgeType == "steps_10000" })
    }

    @Test("完美睡眠徽章在质量评分为5时获得")
    func testPerfectSleepBadgeAwarded() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SleepRecord.self, AchievementBadge.self, configurations: config)
        let vm = AchievementViewModel()

        let sleep = SleepRecord(quality: 5)
        container.mainContext.insert(sleep)
        try container.mainContext.save()

        vm.checkAndAwardBadges(modelContext: container.mainContext)
        #expect(vm.earnedBadges.contains { $0.badgeType == "perfect_sleep" })
    }

    @Test("allBadges 返回所有徽章及状态")
    func testAllBadgesReturnsCorrectCount() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: AchievementBadge.self, configurations: config)
        let vm = AchievementViewModel()
        vm.loadBadges(modelContext: container.mainContext)

        let result = vm.allBadges()
        #expect(result.count == BadgeDefinition.allCases.count)
    }
}