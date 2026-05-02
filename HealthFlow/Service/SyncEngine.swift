import Foundation
import SwiftData

@MainActor
final class SyncEngine {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func upsertDailyActivity(_ summaries: [DailyActivitySummary]) async {
        let existingUUIDs = Set((try? modelContext.fetch(FetchDescriptor<DailyActivitySummary>()).compactMap { $0.healthKitUUID }) ?? [])
        for summary in summaries {
            guard let uuid = summary.healthKitUUID, !existingUUIDs.contains(uuid) else { continue }
            modelContext.insert(summary)
        }
        try? modelContext.save()
    }

    func upsertRecords<T: PersistentModel>(_ records: [T], uuidKey: KeyPath<T, String?>) async {
        let existing = (try? modelContext.fetch(FetchDescriptor<T>())) ?? []
        let existingUUIDs = Set(existing.compactMap { $0[keyPath: uuidKey] })
        for record in records {
            guard let uuid = record[keyPath: uuidKey], !existingUUIDs.contains(uuid) else { continue }
            modelContext.insert(record)
        }
        try? modelContext.save()
    }

    func upsertSleepRecords(_ records: [SleepRecord]) async {
        let existing = (try? modelContext.fetch(FetchDescriptor<SleepRecord>())) ?? []
        let existingByUUID = Dictionary(uniqueKeysWithValues: existing.compactMap { ($0.healthKitUUID, $0) })

        for record in records {
            guard let uuid = record.healthKitUUID else { continue }
            if let existingRecord = existingByUUID[uuid] {
                if existingRecord.sleepStage.isEmpty {
                    existingRecord.sleepStage = record.sleepStage
                }
                if existingRecord.deepSleep == nil, let deepSleep = record.deepSleep {
                    existingRecord.deepSleep = deepSleep
                }
                if existingRecord.remSleep == nil, let remSleep = record.remSleep {
                    existingRecord.remSleep = remSleep
                }
            } else {
                modelContext.insert(record)
            }
        }
        try? modelContext.save()
    }

    func upsertPhysiologicalMetrics(_ metrics: [PhysiologicalMetric]) async {
        let existing = (try? modelContext.fetch(FetchDescriptor<PhysiologicalMetric>())) ?? []
        let existingByUUID = Dictionary(uniqueKeysWithValues: existing.compactMap { ($0.healthKitUUID, $0) })

        for metric in metrics {
            guard let uuid = metric.healthKitUUID else { continue }
            if let existingMetric = existingByUUID[uuid] {
                if metric.metricType == "bloodOxygen" && existingMetric.value <= 1.0 {
                    existingMetric.value = metric.value
                }
            } else {
                modelContext.insert(metric)
            }
        }
        try? modelContext.save()
    }

    func syncAll(healthKit: HealthKitProtocol, daysBack: Int = Constants.HealthKit.syncDaysBack) async {
        guard let startDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) else { return }
        let endDate = Date()

        do {
            let activities = try await healthKit.fetchDailyActivity(from: startDate, to: endDate)
            await upsertDailyActivity(activities)

            let workouts = try await healthKit.fetchWorkouts(from: startDate, to: endDate)
            await upsertRecords(workouts, uuidKey: \WorkoutRecord.healthKitUUID)

            let sleepRecords = try await healthKit.fetchSleep(from: startDate, to: endDate)
            await upsertSleepRecords(sleepRecords)

            let weightMetrics = try await healthKit.fetchWeight(from: startDate, to: endDate)
            await upsertRecords(weightMetrics, uuidKey: \PhysiologicalMetric.healthKitUUID)

            let heartRateMetrics = try await healthKit.fetchHeartRate(from: startDate, to: endDate)
            await upsertRecords(heartRateMetrics, uuidKey: \PhysiologicalMetric.healthKitUUID)

            let bloodOxygenMetrics = try await healthKit.fetchBloodOxygen(from: startDate, to: endDate)
            await upsertPhysiologicalMetrics(bloodOxygenMetrics)

            let bodyTempMetrics = try await healthKit.fetchBodyTemperature(from: startDate, to: endDate)
            await upsertRecords(bodyTempMetrics, uuidKey: \PhysiologicalMetric.healthKitUUID)

            let bloodPressureMetrics = try await healthKit.fetchBloodPressure(from: startDate, to: endDate)
            await upsertRecords(bloodPressureMetrics, uuidKey: \PhysiologicalMetric.healthKitUUID)

            let bloodGlucoseMetrics = try await healthKit.fetchBloodGlucose(from: startDate, to: endDate)
            await upsertRecords(bloodGlucoseMetrics, uuidKey: \PhysiologicalMetric.healthKitUUID)
        } catch {
            print("HealthKit 同步失败: \(error)")
        }
    }
}