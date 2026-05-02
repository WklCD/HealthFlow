import Foundation
import SwiftUI
import SwiftData

@Observable
@MainActor
final class HealthDataViewModel {
    var dailyActivities: [DailyActivitySummary] = []
    var workouts: [WorkoutRecord] = []
    var sleepRecords: [SleepRecord] = []
    var dietRecords: [DietRecord] = []
    var metrics: [PhysiologicalMetric] = []
    var medications: [MedicationRecord] = []
    var isHealthKitAuthorized = false
    var isSyncing = false

    private let modelContext: ModelContext
    private let healthKit: HealthKitProtocol

    init(modelContext: ModelContext, healthKit: HealthKitProtocol) {
        self.modelContext = modelContext
        self.healthKit = healthKit
    }

    func loadAllData() {
        dailyActivities = (try? modelContext.fetch(FetchDescriptor<DailyActivitySummary>())) ?? []
        workouts = (try? modelContext.fetch(FetchDescriptor<WorkoutRecord>())) ?? []
        sleepRecords = (try? modelContext.fetch(FetchDescriptor<SleepRecord>())) ?? []
        dietRecords = (try? modelContext.fetch(FetchDescriptor<DietRecord>())) ?? []
        metrics = (try? modelContext.fetch(FetchDescriptor<PhysiologicalMetric>())) ?? []
        medications = (try? modelContext.fetch(FetchDescriptor<MedicationRecord>())) ?? []
        migrateLegacyData()
    }

    private func migrateLegacyData() {
        var needsSave = false

        for metric in metrics {
            if metric.metricType == "bloodOxygen" && metric.value <= 1.0 && metric.value > 0 {
                metric.value *= 100.0
                needsSave = true
            }
        }

        for record in sleepRecords {
            if record.sleepStage.isEmpty || record.sleepStage == "" {
                if let deepSleep = record.deepSleep, deepSleep > 0 {
                    record.sleepStage = "deep"
                    needsSave = true
                } else if let remSleep = record.remSleep, remSleep > 0 {
                    record.sleepStage = "rem"
                    needsSave = true
                } else if record.source == "healthkit" {
                    record.sleepStage = "core"
                    needsSave = true
                }
            }
        }

        if needsSave {
            try? modelContext.save()
        }
    }

    func addWorkout(_ workout: WorkoutRecord) {
        modelContext.insert(workout)
        try? modelContext.save()
        loadAllData()
    }

    func addSleepRecord(_ record: SleepRecord) {
        modelContext.insert(record)
        try? modelContext.save()
        loadAllData()
    }

    func addDietRecord(_ record: DietRecord) {
        modelContext.insert(record)
        try? modelContext.save()
        loadAllData()
    }

    func addPhysiologicalMetric(_ metric: PhysiologicalMetric) {
        modelContext.insert(metric)
        try? modelContext.save()
        loadAllData()
    }

    func addMedicationRecord(_ medication: MedicationRecord) {
        modelContext.insert(medication)
        try? modelContext.save()
        loadAllData()
    }

    func deleteWorkout(_ workout: WorkoutRecord) {
        modelContext.delete(workout)
        try? modelContext.save()
        loadAllData()
    }

    func deleteSleepRecord(_ record: SleepRecord) {
        modelContext.delete(record)
        try? modelContext.save()
        loadAllData()
    }

    func deleteDietRecord(_ record: DietRecord) {
        modelContext.delete(record)
        try? modelContext.save()
        loadAllData()
    }

    func deletePhysiologicalMetric(_ metric: PhysiologicalMetric) {
        modelContext.delete(metric)
        try? modelContext.save()
        loadAllData()
    }

    func deleteMedicationRecord(_ medication: MedicationRecord) {
        modelContext.delete(medication)
        try? modelContext.save()
        loadAllData()
    }

    func markMedicationTaken(_ medication: MedicationRecord) {
        medication.takenAt = Date()
        try? modelContext.save()
        loadAllData()
    }

    func requestAuthorizationAndSync() async {
        isSyncing = true
        do {
            let authorized = try await healthKit.requestAuthorization()
            isHealthKitAuthorized = authorized
            if authorized {
                await syncAllFromHealthKit()
            }
        } catch {
            print("HealthKit 授权失败: \(error)")
            isHealthKitAuthorized = false
        }
        isSyncing = false
    }

    func syncDailyActivity() async {
        guard let start = Calendar.current.date(byAdding: .day, value: -Constants.HealthKit.syncDaysBack, to: Date()) else { return }
        do {
            let records = try await healthKit.fetchDailyActivity(from: start, to: Date())
            let engine = SyncEngine(modelContext: modelContext)
            await engine.upsertDailyActivity(records)
            loadAllData()
        } catch {
            print("同步失败: \(error)")
        }
    }

    func syncAllFromHealthKit() async {
        let engine = SyncEngine(modelContext: modelContext)
        await engine.syncAll(healthKit: healthKit)
        loadAllData()
    }
}