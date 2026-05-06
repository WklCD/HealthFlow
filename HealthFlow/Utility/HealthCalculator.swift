import Foundation

enum HealthCalculator {
    static func exerciseScore(steps: Int, target: Int) -> Int {
        guard target > 0 else { return 0 }
        let ratio = Double(steps) / Double(target)
        if ratio >= 1.0 { return 25 }
        return Int((ratio * 25).rounded())
    }

    static func sleepScore(hours: Double, target: Double, quality: Int) -> Int {
        guard target > 0 else { return 0 }
        let hourRatio = min(hours / target, 2.0)
        let qualityRatio = Double(quality) / 5.0
        return Int((hourRatio * 15 + qualityRatio * 10).rounded())
    }

    static func dietScore(calories: Double, target: Double) -> Int {
        guard target > 0 else { return 0 }
        let ratio = calories / target
        if ratio >= 0.8 && ratio <= 1.2 { return 20 }
        if calories > 0 { return 10 }
        return 0
    }

    static func totalScore(exercise: Int, sleep: Int, diet: Int, physiology: Int, activeDays: Int) -> Int {
        let total = exercise + sleep + diet + physiology + activeDays
        return min(max(total, 0), 100)
    }

    static func activeDaysScore(daysInWeek: Int) -> Int {
        min(daysInWeek * 2, 10)
    }

    static func checkSleepDeficit(sleeps: [SleepRecord], threshold: Double) -> Bool {
        let calendar = Calendar.current
        let groupedByDay = Dictionary(grouping: sleeps) { calendar.startOfDay(for: $0.endTime) }
        let dailyHours = groupedByDay.values
            .map { $0.reduce(0.0) { $0 + $1.duration } / 3600.0 }
            .sorted()
        var consecutiveCount = 0
        for hours in dailyHours {
            if hours < threshold { consecutiveCount += 1 }
            else { consecutiveCount = 0 }
            if consecutiveCount >= 3 { return true }
        }
        return false
    }

    static func isHeartRateAbnormal(bpm: Double, max: Double, min: Double) -> Bool {
        bpm > max || bpm < min
    }

    static func checkSedentary(workouts: [WorkoutRecord], daysBack: Int) -> Bool {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -daysBack, to: Date()) else { return true }
        let recentWorkouts = workouts.filter { $0.startTime >= startDate }
        return recentWorkouts.isEmpty
    }
}