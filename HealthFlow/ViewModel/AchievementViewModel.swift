import Foundation
import SwiftData

@Observable
@MainActor
final class AchievementViewModel {
    var earnedBadges: [AchievementBadge] = []

    func checkAndAwardBadges(modelContext: ModelContext) {
        loadBadges(modelContext: modelContext)

        let calendar = Calendar.current
        let now = Date()

        let activities = (try? modelContext.fetch(FetchDescriptor<DailyActivitySummary>())) ?? []
        let sleeps = (try? modelContext.fetch(FetchDescriptor<SleepRecord>())) ?? []
        let diets = (try? modelContext.fetch(FetchDescriptor<DietRecord>())) ?? []
        let workouts = (try? modelContext.fetch(FetchDescriptor<WorkoutRecord>())) ?? []
        let profile = (try? modelContext.fetch(FetchDescriptor<UserProfile>()).first)

        for badge in BadgeDefinition.allCases {
            guard !badge.isEarned(badges: earnedBadges) else { continue }

            let shouldAward: Bool
            switch badge {
            case .streak7Days:
                shouldAward = computeStreakDays(records: activities, calendar: calendar, now: now) >= 7
            case .streak30Days:
                shouldAward = computeStreakDays(records: activities, calendar: calendar, now: now) >= 30
            case .steps10000:
                shouldAward = activities.contains { $0.steps >= 10000 }
            case .perfectSleep:
                shouldAward = sleeps.contains { $0.quality >= 5 }
            case .calorieGoalMet:
                let target = Double(profile?.targetCalories ?? 2000)
                shouldAward = diets.contains { abs($0.totalCalories - target) <= 100 }
            case .exercise5Times:
                let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
                let recentWorkouts = workouts.filter { $0.startTime >= weekAgo }
                shouldAward = recentWorkouts.count >= 5
            case .earlyBird:
                shouldAward = computeEarlyBirdCount(sleeps: sleeps, calendar: calendar, now: now) >= 3
            }

            if shouldAward {
                let newBadge = AchievementBadge(badgeType: badge.rawValue, title: badge.title)
                modelContext.insert(newBadge)
                earnedBadges.append(newBadge)
            }
        }

        try? modelContext.save()
    }

    func loadBadges(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<AchievementBadge>(sortBy: [SortDescriptor(\.earnedDate)])
        earnedBadges = (try? modelContext.fetch(descriptor)) ?? []
    }

    func allBadges() -> [(BadgeDefinition, Bool)] {
        BadgeDefinition.allCases.map { badge in
            (badge, badge.isEarned(badges: earnedBadges))
        }
    }

    private func computeStreakDays(records: [DailyActivitySummary], calendar: Calendar, now: Date) -> Int {
        let activeDates = Set(records.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var checkDate = calendar.startOfDay(for: now)
        while activeDates.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    private func computeEarlyBirdCount(sleeps: [SleepRecord], calendar: Calendar, now: Date) -> Int {
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now) ?? now
        let recentSleeps = sleeps.filter { $0.endTime >= threeDaysAgo }
        var count = 0
        for sleep in recentSleeps {
            let hour = calendar.component(.hour, from: sleep.endTime)
            if hour < 6 { count += 1 }
        }
        return count
    }
}