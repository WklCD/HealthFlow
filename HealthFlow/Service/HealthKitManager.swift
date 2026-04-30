import HealthKit
import SwiftData
import Foundation

final class HealthKitManager: HealthKitProtocol {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKWorkoutType.workoutType(),
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.bodyMass),
            HKQuantityType(.heartRate),
            HKQuantityType(.oxygenSaturation),
            HKQuantityType(.bodyTemperature),
            HKQuantityType(.bloodPressureSystolic),
            HKQuantityType(.bloodPressureDiastolic),
            HKQuantityType(.bloodGlucose),
        ]
    }

    func requestAuthorization() async throws -> Bool {
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        return HKHealthStore.isHealthDataAvailable()
    }

    func fetchDailyActivity(from start: Date, to end: Date) async throws -> [DailyActivitySummary] {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        let calendar = Calendar.current
        var results: [DailyActivitySummary] = []
        let stepSamples = try await fetchQuantitySamples(.stepCount, from: start, to: end)
        let calorieSamples = try await fetchQuantitySamples(.activeEnergyBurned, from: start, to: end)
        let distanceSamples = try await fetchQuantitySamples(.distanceWalkingRunning, from: start, to: end)

        var day = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        while day <= endDay {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: day)!
            let daySteps = stepSamples.filter { $0.startDate >= day && $0.startDate < dayEnd }
                .reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.count()) }
            let dayCalories = calorieSamples.filter { $0.startDate >= day && $0.startDate < dayEnd }
                .reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.kilocalorie()) }
            let dayDistance = distanceSamples.filter { $0.startDate >= day && $0.startDate < dayEnd }
                .reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.meter()) }

            if daySteps > 0 || dayCalories > 0 || dayDistance > 0 {
                let summary = DailyActivitySummary()
                summary.date = day
                summary.steps = Int(daySteps)
                summary.calories = dayCalories
                summary.distance = dayDistance
                summary.source = "healthkit"
                summary.healthKitUUID = "daily-\(Int(day.timeIntervalSince1970))"
                results.append(summary)
            }
            day = dayEnd
        }
        return results
    }

    func fetchWorkouts(from start: Date, to end: Date) async throws -> [WorkoutRecord] {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let samples = try await executeQuery(
            sampleType: HKWorkoutType.workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        )
        return samples.compactMap { $0 as? HKWorkout }.map { workout in
            let record = WorkoutRecord()
            record.exerciseType = "\(workout.workoutActivityType.rawValue)"
            record.startTime = workout.startDate
            record.endTime = workout.endDate
            record.duration = workout.duration
            record.calories = workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
            record.distance = workout.totalDistance?.doubleValue(for: HKUnit.meter())
            record.source = "healthkit"
            record.healthKitUUID = workout.uuid.uuidString
            return record
        }
    }

    func fetchSleep(from start: Date, to end: Date) async throws -> [SleepRecord] {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let samples = try await executeQuery(
            sampleType: HKCategoryType(.sleepAnalysis),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        )
        let categorySamples = samples.compactMap { $0 as? HKCategorySample }
        return categorySamples.map { sample in
            let record = SleepRecord()
            record.startTime = sample.startDate
            record.endTime = sample.endDate
            record.duration = sample.endDate.timeIntervalSince(sample.startDate)
            if sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue {
                record.deepSleep = record.duration
            } else if sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                record.remSleep = record.duration
            }
            record.source = "healthkit"
            record.healthKitUUID = sample.uuid.uuidString
            return record
        }
    }

    func fetchWeight(from start: Date, to end: Date) async throws -> [PhysiologicalMetric] {
        try await fetchQuantityMetric(.bodyMass, unit: HKUnit.gramUnit(with: .kilo), metricType: "weight", from: start, to: end)
    }

    func fetchHeartRate(from start: Date, to end: Date) async throws -> [PhysiologicalMetric] {
        try await fetchQuantityMetric(.heartRate, unit: HKUnit.count().unitDivided(by: HKUnit.minute()), metricType: "heartRate", from: start, to: end)
    }

    func fetchBloodOxygen(from start: Date, to end: Date) async throws -> [PhysiologicalMetric] {
        try await fetchQuantityMetric(.oxygenSaturation, unit: HKUnit.percent(), metricType: "bloodOxygen", from: start, to: end)
    }

    func fetchBodyTemperature(from start: Date, to end: Date) async throws -> [PhysiologicalMetric] {
        try await fetchQuantityMetric(.bodyTemperature, unit: HKUnit.degreeCelsius(), metricType: "bodyTemperature", from: start, to: end)
    }

    func fetchBloodPressure(from start: Date, to end: Date) async throws -> [PhysiologicalMetric] {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        let systolic = try await fetchQuantityMetric(.bloodPressureSystolic, unit: HKUnit.millimeterOfMercury(), metricType: "bloodPressure", from: start, to: end)
        let diastolicSamples = try await fetchRawQuantitySamples(.bloodPressureDiastolic, from: start, to: end)

        var diastolicByGroupID: [String: Double] = [:]
        for sample in diastolicSamples {
            diastolicByGroupID[sample.uuid.uuidString] = sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
        }

        var results: [PhysiologicalMetric] = []
        for metric in systolic {
            if let groupID = metric.measurementGroupID, let diastolicValue = diastolicByGroupID[groupID] {
                metric.valueSystolic = metric.value
                metric.valueDiastolic = diastolicValue
            }
            results.append(metric)
        }
        return results
    }

    func fetchBloodGlucose(from start: Date, to end: Date) async throws -> [PhysiologicalMetric] {
        try await fetchQuantityMetric(.bloodGlucose, unit: HKUnit(from: "mmol*L^-1"), metricType: "bloodGlucose", from: start, to: end)
    }

    func observeChanges() async -> AsyncStream<Void> {
        AsyncStream { continuation in
            let types: [HKSampleType] = [
                HKQuantityType(.stepCount),
                HKQuantityType(.heartRate),
                HKQuantityType(.bodyMass),
                HKWorkoutType.workoutType(),
                HKCategoryType(.sleepAnalysis),
            ]
            for type in types {
                let query = HKObserverQuery(sampleType: type, predicate: nil) { _, _, _ in
                    continuation.yield(())
                }
                self.healthStore.execute(query)
            }
            continuation.onTermination = { _ in }
        }
    }

    @MainActor
    func syncToSwiftData(context: ModelContext, daysBack: Int = Constants.HealthKit.syncDaysBack) async {
        let engine = SyncEngine(modelContext: context)
        await engine.syncAll(healthKit: self, daysBack: daysBack)
    }

    private func fetchQuantitySamples(_ typeIdentifier: HKQuantityTypeIdentifier, from start: Date, to end: Date) async throws -> [HKQuantitySample] {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let samples = try await executeQuery(
            sampleType: HKQuantityType(typeIdentifier),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        )
        return samples.compactMap { $0 as? HKQuantitySample }
    }

    private func executeQuery(sampleType: HKSampleType, predicate: NSPredicate?, limit: Int, sortDescriptors: [NSSortDescriptor]?) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptors,
                resultsHandler: { _, samples, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: samples ?? [])
                    }
                }
            )
            self.healthStore.execute(query)
        }
    }

    private func fetchQuantityMetric(_ typeIdentifier: HKQuantityTypeIdentifier, unit: HKUnit, metricType: String, from start: Date, to end: Date) async throws -> [PhysiologicalMetric] {
        let samples = try await fetchQuantitySamples(typeIdentifier, from: start, to: end)
        return samples.map { sample in
            let metric = PhysiologicalMetric()
            metric.metricType = metricType
            metric.value = sample.quantity.doubleValue(for: unit)
            metric.unit = unit.unitString
            metric.timestamp = sample.startDate
            metric.source = "healthkit"
            metric.healthKitUUID = sample.uuid.uuidString
            metric.measurementGroupID = sample.uuid.uuidString
            return metric
        }
    }

    private func fetchRawQuantitySamples(_ typeIdentifier: HKQuantityTypeIdentifier, from start: Date, to end: Date) async throws -> [HKQuantitySample] {
        try await fetchQuantitySamples(typeIdentifier, from: start, to: end)
    }
}