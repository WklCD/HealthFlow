import Testing
import SwiftData
import Foundation
@testable import HealthFlow

@MainActor
struct SyncEngineTests {

    @Test("去重：已存在的 healthKitUUID 不会重复插入")
    func testDeduplicationSkipsExistingUUIDs() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DailyActivitySummary.self, configurations: config)
        let context = container.mainContext

        let existing = DailyActivitySummary()
        existing.healthKitUUID = "hk-uuid-001"
        existing.steps = 5000
        context.insert(existing)
        try context.save()

        let newData = DailyActivitySummary()
        newData.healthKitUUID = "hk-uuid-001"
        newData.steps = 8000

        let engine = SyncEngine(modelContext: context)
        await engine.upsertDailyActivity([newData])

        let count = try context.fetch(FetchDescriptor<DailyActivitySummary>()).count
        #expect(count == 1)
    }

    @Test("去重：新 UUID 正常插入")
    func testNewUUIDInsertsNormally() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DailyActivitySummary.self, configurations: config)
        let context = container.mainContext

        let newData = DailyActivitySummary()
        newData.healthKitUUID = "hk-uuid-002"
        newData.steps = 8000

        let engine = SyncEngine(modelContext: context)
        await engine.upsertDailyActivity([newData])

        let count = try context.fetch(FetchDescriptor<DailyActivitySummary>()).count
        #expect(count == 1)
    }

    @Test("去重：混合新旧 UUID 正确插入")
    func testMixedUUIDs() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DailyActivitySummary.self, configurations: config)
        let context = container.mainContext

        let existing = DailyActivitySummary()
        existing.healthKitUUID = "hk-uuid-001"
        existing.steps = 5000
        context.insert(existing)
        try context.save()

        let newRecord = DailyActivitySummary()
        newRecord.healthKitUUID = "hk-uuid-002"
        newRecord.steps = 8000

        let duplicate = DailyActivitySummary()
        duplicate.healthKitUUID = "hk-uuid-001"
        duplicate.steps = 9000

        let engine = SyncEngine(modelContext: context)
        await engine.upsertDailyActivity([newRecord, duplicate])

        let results = try context.fetch(FetchDescriptor<DailyActivitySummary>())
        #expect(results.count == 2)
    }

    @Test("泛化去重：WorkoutRecord 去重")
    func testUpsertRecordsWorkoutDedup() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: WorkoutRecord.self, configurations: config)
        let context = container.mainContext

        let existing = WorkoutRecord()
        existing.healthKitUUID = "wk-uuid-001"
        existing.exerciseType = "running"
        context.insert(existing)
        try context.save()

        let duplicate = WorkoutRecord()
        duplicate.healthKitUUID = "wk-uuid-001"
        duplicate.exerciseType = "walking"

        let engine = SyncEngine(modelContext: context)
        await engine.upsertRecords([duplicate], uuidKey: \WorkoutRecord.healthKitUUID)

        let count = try context.fetch(FetchDescriptor<WorkoutRecord>()).count
        #expect(count == 1)
    }

    @Test("syncAll 调用所有 fetch 方法")
    func testSyncAllCallsAllFetchMethods() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DailyActivitySummary.self, WorkoutRecord.self, SleepRecord.self, PhysiologicalMetric.self, configurations: config)
        let context = container.mainContext

        let mockHK = MockHealthKitManager()
        let summary = DailyActivitySummary()
        summary.healthKitUUID = "hk-sync-001"
        summary.steps = 10000
        mockHK.dailyActivities = [summary]

        let engine = SyncEngine(modelContext: context)
        await engine.syncAll(healthKit: mockHK, daysBack: 7)

        let activities = try context.fetch(FetchDescriptor<DailyActivitySummary>())
        #expect(activities.count == 1)
        #expect(activities.first?.steps == 10000)
    }
}