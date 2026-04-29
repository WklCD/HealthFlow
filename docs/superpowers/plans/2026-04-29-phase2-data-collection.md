# 阶段二：健康数据采集 实现计划

> **面向开发者：** 请使用 superpowers:subagent-driven-development（推荐）按任务逐个实现。步骤使用 `- [ ]` 复选框跟踪进度。严格遵循 TDD（RED-GREEN-REFACTOR）流程。

**目标：** 实现健康数据的录入与管理（运动/睡眠/饮食/生理指标），HealthKit 集成与数据同步，食物营养数据库。

**技术栈：** SwiftUI, SwiftData, HealthKit

**测试覆盖率目标：** ≥91%（中等任务）

**前置依赖：** 阶段一已完成

---

## 任务 1：HealthKitProtocol 协议

**文件：** `HealthFlow/Service/HealthKitProtocol.swift`

- [ ] **步骤 1：编写协议定义（GREEN）**

```swift
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
```

- [ ] **步骤 2：编译验证**

```bash
xcodebuild build -project HealthFlow.xcodep -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16'
```

期望：**BUILD SUCCEEDED**

- [ ] **步骤 3：提交**

```bash
git add .
git commit -m "feat: 定义 HealthKitProtocol 协议"
```

---

## 任务 2：MockHealthKitManager（测试用）

**文件：** `HealthFlowTests/ServiceTests/MockHealthKitManager.swift`

- [ ] **步骤 1：编写 Mock 实现（GREEN）**

```swift
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

    func requestAuthorization() async throws -> Bool { isAuthorized }
    func fetchDailyActivity(from: Date, to: Date) async throws -> [DailyActivitySummary] { dailyActivities }
    func fetchWorkouts(from: Date, to: Date) async throws -> [WorkoutRecord] { workouts }
    func fetchSleep(from: Date, to: Date) async throws -> [SleepRecord] { sleepRecords }
    func fetchWeight(from: Date, to: Date) async throws -> [PhysiologicalMetric] { weightMetrics }
    func fetchHeartRate(from: Date, to: Date) async throws -> [PhysiologicalMetric] { heartRateMetrics }
    func fetchBloodOxygen(from: Date, to: Date) async throws -> [PhysiologicalMetric] { bloodOxygenMetrics }
    func fetchBodyTemperature(from: Date, to: Date) async throws -> [PhysiologicalMetric] { bodyTempMetrics }
    func fetchBloodPressure(from: Date, to: Date) async throws -> [PhysiologicalMetric] { bloodPressureMetrics }
    func fetchBloodGlucose(from: Date, to: Date) async throws -> [PhysiologicalMetric] { bloodGlucoseMetrics }
    func observeChanges() async -> AsyncStream<Void> { AsyncStream { $0.finish() } }
}
```

- [ ] **步骤 2：编译验证后提交**

```bash
xcodebuild build -project HealthFlow.xcodep -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16'
git add .
git commit -m "test: 添加 MockHealthKitManager 用于单元测试"
```

---

## 任务 3：SyncEngine + 去重逻辑

**文件：** `HealthFlow/Service/SyncEngine.swift`，`HealthFlowTests/ServiceTests/SyncEngineTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

创建 `HealthFlowTests/ServiceTests/SyncEngineTests.swift`：

```swift
import Testing
import SwiftData
import Foundation
@testable import HealthFlow

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
}
```

- [ ] **步骤 2：运行测试确认失败**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/SyncEngineTests
```

期望：**BUILD FAILED**（SyncEngine 不存在）

- [ ] **步骤 3：编写最小实现（GREEN）**

创建 `HealthFlow/Service/SyncEngine.swift`：

```swift
import Foundation
import SwiftData

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
}
```

- [ ] **步骤 4：运行测试确认通过（GREEN）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/SyncEngineTests
```

期望：**2 tests passed**

- [ ] **步骤 5：REFACTOR — 泛化去重方法**

```swift
extension SyncEngine {
    func upsertRecords<T: PersistentModel>(_ records: [T], uuidKey: KeyPath<T, String?>) async {
        let existing = (try? modelContext.fetch(FetchDescriptor<T>())) ?? []
        let existingUUIDs = Set(existing.compactMap { $0[keyPath: uuidKey] })

        for record in records {
            guard let uuid = record[keyPath: uuidKey], !existingUUIDs.contains(uuid) else { continue }
            modelContext.insert(record)
        }
        try? modelContext.save()
    }
}
```

- [ ] **步骤 6：补充完整 SyncEngine 方法**

添加 `syncAll(daysBack:)` 和 `syncMetric` 等方法（接收 `HealthKitProtocol` 依赖注入）。

- [ ] **步骤 7：提交**

```bash
git add .
git commit -m "feat: 添加 SyncEngine（HealthKit 去重 + 批量同步）及单元测试"
```

---

## 任务 4：HealthKitManager 实现

**文件：** `HealthFlow/Service/HealthKitManager.swift`

- [ ] **步骤 1：编写实现**

```swift
import HealthKit
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
    }

    func fetchDailyActivity(from start: Date, to end: Date) async throws -> [DailyActivitySummary] {
        // 使用 HKStatisticsCollectionQuery 按天聚合步数/卡路里/距离
        // 返回 [DailyActivitySummary]，每条含 healthKitUUID
        []
    }

    func fetchWorkouts(from start: Date, to end: Date) async throws -> [WorkoutRecord] {
        // 使用 HKSampleQuery for .workoutType()
        // 返回 [WorkoutRecord]，每条含 healthKitUUID
        []
    }

    // ... 其余 fetch 方法实现 HealthKit 查询
    // 血压合并 syst + dia 为一条 PhysiologicalMetric

    func observeChanges() async -> AsyncStream<Void> {
        AsyncStream { continuation in
            // HKObserverQuery 监听各类型数据变化
        }
    }
}

extension HealthKitManager {
    // 首次启动在 HealthFlowApp 中调用
    func syncToSwiftData(context: ModelContext, daysBack: Int = 7) async {
        let engine = SyncEngine(modelContext: context)
        await engine.syncAll(healthKit: self, daysBack: daysBack)
    }
}
```

> 注：具体 HealthKit 查询代码参照 Apple HealthKit 文档。核心模式是 HKSampleQuery + predicate + sortDescriptor，每条结果映射到对应 SwiftData 模型并携带 healthKitUUID。

- [ ] **步骤 2：编译验证**

```bash
xcodebuild build -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16'
git add .
git commit -m "feat: 实现 HealthKitManager（HealthKit 读写 + observeChanges）"
```

---

## 任务 5：HealthDataViewModel

**文件：** `HealthFlow/ViewModel/HealthDataViewModel.swift`，`HealthFlowTests/ViewModelTests/HealthDataViewModelTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

```swift
import Testing
import SwiftData
@testable import HealthFlow

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
}
```

- [ ] **步骤 2：运行测试 → BUILD FAILED**

- [ ] **步骤 3：编写实现（GREEN）**

```swift
import Foundation
import SwiftUI
import SwiftData

@Observable
final class HealthDataViewModel {
    var dailyActivities: [DailyActivitySummary] = []
    var workouts: [WorkoutRecord] = []
    var sleepRecords: [SleepRecord] = []
    var dietRecords: [DietRecord] = []
    var metrics: [PhysiologicalMetric] = []
    var medications: [MedicationRecord] = []

    private let modelContext: ModelContext
    private let healthKit: HealthKitProtocol

    init(modelContext: ModelContext, healthKit: HealthKitProtocol) {
        self.modelContext = modelContext
        self.healthKit = healthKit
    }

    func loadAllData() {
        // 从 SwiftData 查询各类数据
    }

    func addWorkout(_ workout: WorkoutRecord) {
        modelContext.insert(workout)
        try? modelContext.save()
        loadAllData()
    }

    func syncDailyActivity() async {
        guard let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else { return }
        do {
            let records = try await healthKit.fetchDailyActivity(from: start, to: Date())
            let engine = SyncEngine(modelContext: modelContext)
            await engine.upsertDailyActivity(records)
            loadAllData()
        } catch {
            print("同步失败: \(error)")
        }
    }

    // ... deleteRecord, addRecord 等通用方法
}
```

- [ ] **步骤 4：运行测试 → 2 passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 HealthDataViewModel（含 HealthKit 同步 + Mock 测试）"
```

---

## 任务 6：健康数据列表页

**文件：** 修改 `HealthFlow/View/HealthData/HealthDataListView.swift`

- [ ] **步骤 1：重写 HealthDataListView（替换占位页）**

```swift
import SwiftUI
import SwiftData

struct HealthDataListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HealthDataViewModel?

    var body: some View {
        NavigationStack {
            List {
                Section("运动") {
                    NavigationLink { ActivityDetailView() } label: {
                        HStack {
                            Image(systemName: "figure.walk").foregroundStyle(.orange)
                            Text("运动")
                            Spacer()
                            if let vm = viewModel {
                                Text("\(vm.workouts.count)次").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("睡眠") {
                    NavigationLink { SleepDetailView() } label: {
                        HStack {
                            Image(systemName: "moon.zzz.fill").foregroundStyle(.indigo)
                            Text("睡眠")
                        }
                    }
                }
                Section("饮食") {
                    NavigationLink { DietDetailView() } label: {
                        HStack {
                            Image(systemName: "fork.knife").foregroundStyle(.green)
                            Text("饮食")
                        }
                    }
                }
                Section("生理指标") {
                    NavigationLink { MetricDetailView() } label: {
                        HStack {
                            Image(systemName: "heart.text.square.fill").foregroundStyle(.red)
                            Text("生理指标")
                        }
                    }
                }
                Section("用药记录") {
                    NavigationLink { MedicationDetailView() } label: {
                        HStack {
                            Image(systemName: "pills.fill").foregroundStyle(.blue)
                            Text("用药记录")
                        }
                    }
                }
            }
            .navigationTitle("健康数据")
        }
        .tabItem { Label("健康数据", systemImage: "heart.text.clipboard.fill") }
        .onAppear {
            let vm = HealthDataViewModel(modelContext: modelContext, healthKit: HealthKitManager.shared)
            vm.loadAllData()
            viewModel = vm
        }
    }
}
```

- [ ] **步骤 2：编译验证后提交**

```bash
xcodebuild build -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16'
git add .
git commit -m "feat: 实现健康数据列表页（运动/睡眠/饮食/生理指标/用药入口）"
```

---

## 任务 7：运动详情页 + 手动录入

**文件：** `HealthFlow/View/HealthData/ActivityDetailView.swift`，`HealthFlow/View/HealthData/WorkoutDetailView.swift`

- [ ] **步骤 1：编写 ActivityDetailView** — 日历视图 + DailyActivitySummary 展示（步数/卡路里/距离）+ 下方 Workout 列表
- [ ] **步骤 2：编写 WorkoutDetailView** — 日历视图 + 记录列表 + 右上角「+」Sheet 表单（Picker 运动类型、DatePicker 起止时间、Stepper 时长、TextField 卡路里/步数/距离/备注）+ 保存按钮
- [ ] **步骤 3：保存逻辑**

```swift
Button("保存") {
    let workout = WorkoutRecord()
    workout.exerciseType = selectedType.rawValue
    workout.startTime = startTime
    workout.endTime = endTime
    workout.duration = endTime.timeIntervalSince(startTime)
    workout.calories = calories
    workout.steps = steps
    workout.distance = distance
    workout.source = "manual"
    workout.note = note
    viewModel.addWorkout(workout)
    dismiss()
}
```

- [ ] **步骤 4：编译验证后提交**

```bash
git add .
git commit -m "feat: 添加运动详情页（DailyActivitySummary + WorkoutRecord 录入）"
```

---

## 任务 8：睡眠详情页 + 手动录入

**文件：** `HealthFlow/View/HealthData/SleepDetailView.swift`

- [ ] **步骤 1：编写 SleepDetailView** — 日历视图 + 记录列表（入睡/起床时间、总时长、深睡/REM、质量评分 ★）+ 右上角「+」Sheet（DatePicker 起止时间、Stepper 质量 1-5、TextField 备注）
- [ ] **步骤 2：编译验证后提交**

```bash
git add .
git commit -m "feat: 添加睡眠详情页（记录列表 + 手动录入）"
```

---

## 任务 9：饮食详情页 + 食物搜索 + 食物数据库

**文件：**
- 创建：`HealthFlow/View/HealthData/DietDetailView.swift`
- 创建：`HealthFlow/View/HealthData/FoodSearchView.swift`
- 创建：`HealthFlow/Service/FoodDatabaseService.swift`
- 创建：`HealthFlow/Resource/FoodDatabase.json`
- 测试：`HealthFlowTests/ServiceTests/FoodDatabaseServiceTests.swift`

- [ ] **步骤 1：编写失败测试（RED）** — FoodDatabaseServiceTests

```swift
import Testing
@testable import HealthFlow

struct FoodDatabaseServiceTests {
    @Test("搜索'鸡蛋'返回结果")
    func testSearchEgg() {
        let service = FoodDatabaseService()
        let results = service.search(query: "鸡蛋")
        #expect(!results.isEmpty)
        #expect(results.first?.name.contains("鸡蛋") ?? false)
    }

    @Test("按类别查询返回正确分类")
    func testGetByCategory() {
        let service = FoodDatabaseService()
        let proteins = service.getCategory(category: "protein")
        #expect(proteins.contains { $0.name.contains("鸡胸") })
    }
}
```

- [ ] **步骤 2：运行测试 → BUILD FAILED**

- [ ] **步骤 3：创建 FoodDatabase.json**（200+ 中国食物），Format:

```json
[
  {
    "name": "鸡蛋（煮）",
    "category": "protein",
    "defaultUnit": "个",
    "defaultAmount": 1,
    "caloriesPerUnit": 78,
    "proteinPerUnit": 6.5,
    "carbsPerUnit": 0.6,
    "fatPerUnit": 5.3
  },
  ...
]
```

- [ ] **步骤 4：创建 FoodDatabaseService.swift（GREEN）**

```swift
struct FoodDefinition: Codable, Identifiable {
    let name: String
    let category: String
    let defaultUnit: String
    let defaultAmount: Double
    let caloriesPerUnit: Double
    let proteinPerUnit: Double
    let carbsPerUnit: Double
    let fatPerUnit: Double
    var id: String { name }
}

final class FoodDatabaseService {
    private var foods: [FoodDefinition] = []

    init() { loadFoods() }

    private func loadFoods() {
        guard let url = Bundle.main.url(forResource: "FoodDatabase", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([FoodDefinition].self, from: data)
        else { return }
        foods = decoded
    }

    func search(query: String) -> [FoodDefinition] {
        foods.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func getCategory(category: String) -> [FoodDefinition] {
        foods.filter { $0.category == category }
    }
}
```

- [ ] **步骤 5：运行测试 → 2 passed**

- [ ] **步骤 6：编写 FoodSearchView** — 搜索栏 + 分类筛选 + 结果列表 + 点击选中

- [ ] **步骤 7：编写 DietDetailView** — 按日期/餐次分组 + 食物清单 + @Transient 聚合营养 +「+」按钮 → 选择餐次类型 → FoodSearchView → 选份量 → 确认 → 保存到 SwiftData

- [ ] **步骤 8：提交**

```bash
git add .
git commit -m "feat: 添加饮食模块（食物数据库 + 搜索 + 详情录入）"
```

---

## 任务 10：生理指标详情页

**文件：** `HealthFlow/View/HealthData/MetricDetailView.swift`

- [ ] **步骤 1：编写 MetricDetailView** — SegmentedPicker 切换指标类型（体重/心率/血氧/体温/血压/血糖）+ 趋势图占位区 + 记录列表 + 右上角「+」Sheet（根据 metricType 显示不同表单字段，血压显示双值输入）
- [ ] **步骤 2：编译验证后提交**

```bash
git add .
git commit -m "feat: 添加生理指标详情页（含血压双值录入）"
```

---

## 任务 11：用药详情页

**文件：** `HealthFlow/View/HealthData/MedicationDetailView.swift`

- [ ] **步骤 1：编写 MedicationDetailView** — 用药列表（按 scheduledTime 排序，✅/⏳ 状态）+ 右上角「+」Sheet（药名、剂量、计划时间、备注）+ 点击标记已服
- [ ] **步骤 2：编译验证后提交**

```bash
git add .
git commit -m "feat: 添加用药记录页（录入 + 标记已服 + 提醒）"
```

---

## 任务 12：ImageStorageService

**文件：** `HealthFlow/Service/ImageStorageService.swift`，`HealthFlowTests/ServiceTests/ImageStorageServiceTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

```swift
import Testing
import UIKit
@testable import HealthFlow

struct ImageStorageServiceTests {
    @Test("保存后再加载得到相同图像")
    func testSaveAndLoad() throws {
        let service = ImageStorageService()
        let image = UIImage(systemName: "fork.knife")!
        let path = try service.saveImage(image)
        let loaded = service.loadImage(path: path)
        #expect(loaded != nil)
    }

    @Test("删除后加载返回 nil")
    func testDeleteRemovesImage() throws {
        let service = ImageStorageService()
        let image = UIImage(systemName: "fork.knife")!
        let path = try service.saveImage(image)
        try service.deleteImage(path: path)
        let loaded = service.loadImage(path: path)
        #expect(loaded == nil)
    }
}
```

- [ ] **步骤 2：运行测试 → BUILD FAILED**

- [ ] **步骤 3：编写实现（GREEN）**

```swift
import UIKit
import Foundation

struct ImageStorageService {
    private var directory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent(Constants.Storage.foodImagesDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func saveImage(_ image: UIImage) throws -> String {
        let resized = resizeImage(image, maxDimension: Constants.Storage.maxImageDimension)
        guard let data = resized.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageStorage", code: 1)
        }
        let filename = "\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(filename)
        try data.write(to: url)
        return filename
    }

    func loadImage(path: String) -> UIImage? {
        let url = directory.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func deleteImage(path: String) throws {
        let url = directory.appendingPathComponent(path)
        try FileManager.default.removeItem(at: url)
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
```

- [ ] **步骤 4：运行测试 → 2 passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 ImageStorageService（照片存文件系统 + 压缩）及测试"
```

---

## 任务 13：阶段二总体验证

- [ ] 运行全部测试：

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

- [ ] Simulator 验证：HealthKit 授权弹窗、运动/睡眠/生理指标从 HealthKit 填充、手动录入正常、食物搜索正常、照片保存正常
- [ ] 测试覆盖率确认 ≥91%

```bash
git add .
git commit -m "feat: 完成阶段二——健康数据采集、HealthKit 集成、食物数据库"
```
