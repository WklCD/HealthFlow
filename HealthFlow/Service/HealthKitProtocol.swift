import Foundation

protocol HealthKitProtocol {
    func requestAuthorization() async throws -> Bool
    func fetchDailyActivity(from: Date, to: Date) async throws -> [DailyActivitySummary]
    func fetchWorkouts(from: Date, to: Date) async throws -> [WorkoutRecord]
    func fetchSleep(from: Date, to: Date) async throws -> [SleepRecord]
    func fetchWeight(from: Date, to: Date) async throws -> [PhysiologicalMetric]
    func fetchHeartRate(from: Date, to: Date) async throws -> [PhysiologicalMetric]
    func fetchBloodOxygen(from: Date, to: Date) async throws -> [PhysiologicalMetric]
    func fetchBodyTemperature(from: Date, to: Date) async throws -> [PhysiologicalMetric]
    func fetchBloodPressure(from: Date, to: Date) async throws -> [PhysiologicalMetric]
    func fetchBloodGlucose(from: Date, to: Date) async throws -> [PhysiologicalMetric]
    func observeChanges() async -> AsyncStream<Void>
}