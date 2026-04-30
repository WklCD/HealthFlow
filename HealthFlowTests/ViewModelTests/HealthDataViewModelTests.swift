import Testing
import SwiftData
import Foundation
@testable import HealthFlow

@MainActor
struct HealthDataViewModelTests {

    @Test("手动添加运动记录后数据更新")
    func testAddWorkout() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: WorkoutRecord.self, configurations: config)
        let mockHK = MockHealthKitManager()
        let vm = HealthDataViewModel(modelContext: container.mainContext, healthKit: mockHK)

        let workout = WorkoutRecord()
        workout.exerciseType = "running"
        workout.duration = 1800
        vm.addWorkout(workout)

        #expect(vm.workouts.count == 1)
        #expect(vm.workouts.first?.exerciseType == "running")
    }

    @Test("从 HealthKit 同步后合并数据")
    func testSyncFromHealthKit() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DailyActivitySummary.self, configurations: config)
        let mockHK = MockHealthKitManager()
        let summary = DailyActivitySummary()
        summary.steps = 8000
        summary.healthKitUUID = "hk-test-123"
        mockHK.dailyActivities = [summary]

        let vm = HealthDataViewModel(modelContext: container.mainContext, healthKit: mockHK)
        await vm.syncDailyActivity()

        #expect(vm.dailyActivities.count == 1)
    }

    @Test("添加睡眠记录后数据更新")
    func testAddSleepRecord() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SleepRecord.self, configurations: config)
        let mockHK = MockHealthKitManager()
        let vm = HealthDataViewModel(modelContext: container.mainContext, healthKit: mockHK)

        let sleep = SleepRecord()
        sleep.quality = 4
        sleep.duration = 28800
        vm.addSleepRecord(sleep)

        #expect(vm.sleepRecords.count == 1)
        #expect(vm.sleepRecords.first?.quality == 4)
    }

    @Test("添加饮食记录后数据更新")
    func testAddDietRecord() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DietRecord.self, FoodItem.self, configurations: config)
        let mockHK = MockHealthKitManager()
        let vm = HealthDataViewModel(modelContext: container.mainContext, healthKit: mockHK)

        let diet = DietRecord()
        diet.mealType = "breakfast"
        vm.addDietRecord(diet)

        #expect(vm.dietRecords.count == 1)
    }

    @Test("添加生理指标后数据更新")
    func testAddMetric() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PhysiologicalMetric.self, configurations: config)
        let mockHK = MockHealthKitManager()
        let vm = HealthDataViewModel(modelContext: container.mainContext, healthKit: mockHK)

        let metric = PhysiologicalMetric()
        metric.metricType = "weight"
        metric.value = 70.5
        vm.addPhysiologicalMetric(metric)

        #expect(vm.metrics.count == 1)
        #expect(vm.metrics.first?.metricType == "weight")
    }

    @Test("添加用药记录后数据更新")
    func testAddMedication() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: MedicationRecord.self, configurations: config)
        let mockHK = MockHealthKitManager()
        let vm = HealthDataViewModel(modelContext: container.mainContext, healthKit: mockHK)

        let med = MedicationRecord()
        med.name = "阿司匹林"
        med.dosage = "100mg"
        vm.addMedicationRecord(med)

        #expect(vm.medications.count == 1)
        #expect(vm.medications.first?.name == "阿司匹林")
    }

    @Test("删除运动记录后数据更新")
    func testDeleteWorkout() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: WorkoutRecord.self, configurations: config)
        let mockHK = MockHealthKitManager()
        let vm = HealthDataViewModel(modelContext: container.mainContext, healthKit: mockHK)

        let workout = WorkoutRecord()
        workout.exerciseType = "cycling"
        vm.addWorkout(workout)
        #expect(vm.workouts.count == 1)

        vm.deleteWorkout(workout)
        #expect(vm.workouts.isEmpty)
    }

    @Test("标记用药已服后状态更新")
    func testMarkMedicationTaken() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: MedicationRecord.self, configurations: config)
        let mockHK = MockHealthKitManager()
        let vm = HealthDataViewModel(modelContext: container.mainContext, healthKit: mockHK)

        let med = MedicationRecord()
        med.name = "布洛芬"
        vm.addMedicationRecord(med)
        #expect(vm.medications.first?.takenAt == nil)

        vm.markMedicationTaken(med)
        #expect(vm.medications.first?.takenAt != nil)
    }
}