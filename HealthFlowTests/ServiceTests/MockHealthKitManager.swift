@testable import HealthFlow
import Foundation

final class MockHealthKitManager: HealthKitProtocol {
    var isAuthorized = true
    var dailyActivities: [DailyActivitySummary] = []
    var workouts: [WorkoutRecord] = []
    var sleepRecords: [SleepRecord] = []
    var weightMetrics: [PhysiologicalMetric] = []
    var heartRateMetrics: [PhysiologicalMetric] = []
    var bloodOxygenMetrics: [PhysiologicalMetric] = []
    var bodyTempMetrics: [PhysiologicalMetric] = []
    var bloodPressureMetrics: [PhysiologicalMetric] = []
    var bloodGlucoseMetrics: [PhysiologicalMetric] = []
    var shouldThrow = false

    func requestAuthorization() async throws -> Bool {
        if shouldThrow { throw NSError(domain: "MockHealthKit", code: 1) }
        return isAuthorized
    }

    func fetchDailyActivity(from: Date, to: Date) async throws -> [DailyActivitySummary] {
        if shouldThrow { throw NSError(domain: "MockHealthKit", code: 1) }
        return dailyActivities
    }

    func fetchWorkouts(from: Date, to: Date) async throws -> [WorkoutRecord] {
        if shouldThrow { throw NSError(domain: "MockHealthKit", code: 1) }
        return workouts
    }

    func fetchSleep(from: Date, to: Date) async throws -> [SleepRecord] {
        if shouldThrow { throw NSError(domain: "MockHealthKit", code: 1) }
        return sleepRecords
    }

    func fetchWeight(from: Date, to: Date) async throws -> [PhysiologicalMetric] {
        if shouldThrow { throw NSError(domain: "MockHealthKit", code: 1) }
        return weightMetrics
    }

    func fetchHeartRate(from: Date, to: Date) async throws -> [PhysiologicalMetric] {
        if shouldThrow { throw NSError(domain: "MockHealthKit", code: 1) }
        return heartRateMetrics
    }

    func fetchBloodOxygen(from: Date, to: Date) async throws -> [PhysiologicalMetric] {
        if shouldThrow { throw NSError(domain: "MockHealthKit", code: 1) }
        return bloodOxygenMetrics
    }

    func fetchBodyTemperature(from: Date, to: Date) async throws -> [PhysiologicalMetric] {
        if shouldThrow { throw NSError(domain: "MockHealthKit", code: 1) }
        return bodyTempMetrics
    }

    func fetchBloodPressure(from: Date, to: Date) async throws -> [PhysiologicalMetric] {
        if shouldThrow { throw NSError(domain: "MockHealthKit", code: 1) }
        return bloodPressureMetrics
    }

    func fetchBloodGlucose(from: Date, to: Date) async throws -> [PhysiologicalMetric] {
        if shouldThrow { throw NSError(domain: "MockHealthKit", code: 1) }
        return bloodGlucoseMetrics
    }

    func observeChanges() async -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}