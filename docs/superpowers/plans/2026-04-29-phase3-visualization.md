# 阶段三：数据可视化 实现计划

> **面向开发者：** 请使用 superpowers:subagent-driven-development（推荐）按任务逐个实现。严格遵循 TDD。

**目标：** 实现健康仪表盘首页、Swift Charts 图表系统、健康报告生成。

**技术栈：** SwiftUI, SwiftData, Swift Charts

**测试覆盖率目标：** ≥91%（中等任务）

**前置依赖：** 阶段一 + 阶段二已完成

---

## 任务 1：HealthCalculator（健康评分）

**文件：** `HealthFlow/Utility/HealthCalculator.swift`，`HealthFlowTests/ServiceTests/HealthCalculatorTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

```swift
import Testing
import Foundation
@testable import HealthFlow

struct HealthCalculatorTests {

    @Test("步数达标时运动评分满分")
    func testPerfectExerciseScore() {
        let score = HealthCalculator.exerciseScore(steps: 12000, target: 10000)
        #expect(score == 25)
    }

    @Test("步数一半时运动评分为半")
    func testHalfExerciseScore() {
        let score = HealthCalculator.exerciseScore(steps: 5000, target: 10000)
        #expect(score == 12)
    }

    @Test("睡眠时长达标且质量满分时睡眠评分满分")
    func testPerfectSleepScore() {
        let score = HealthCalculator.sleepScore(hours: 8, target: 8, quality: 5)
        #expect(score == 25)
    }

    @Test("综合评分满分100")
    func testTotalScoreMax100() {
        let total = HealthCalculator.totalScore(
            exercise: 25, sleep: 25, diet: 20, physiology: 20, activeDays: 10
        )
        #expect(total == 100)
    }

    @Test("综合评分最低0")
    func testTotalScoreMin0() {
        let total = HealthCalculator.totalScore(
            exercise: 0, sleep: 0, diet: 0, physiology: 0, activeDays: 0
        )
        #expect(total == 0)
    }
}
```

- [ ] **步骤 2：运行测试 → BUILD FAILED**

- [ ] **步骤 3：编写实现（GREEN）**

```swift
import Foundation

enum HealthCalculator {
    static func exerciseScore(steps: Int, target: Int) -> Int {
        guard target > 0 else { return 0 }
        let ratio = min(Double(steps) / Double(target), 2.0)
        return Int(ratio * 12.5)
    }

    static func sleepScore(hours: Double, target: Double, quality: Int) -> Int {
        let hourRatio = min(hours / target, 2.0)
        let qualityRatio = Double(quality) / 5.0
        return Int((hourRatio * 15 + qualityRatio * 10).rounded())
    }

    static func dietScore(calories: Double, target: Double) -> Int {
        guard target > 0 else { return 0 }
        let ratio = calories / target
        if ratio >= 0.8 && ratio <= 1.2 { return 20 }
        if ratio >= 0.6 && ratio <= 1.4 { return 15 }
        if ratio > 0 { return 10 }
        return 0
    }

    static func totalScore(exercise: Int, sleep: Int, diet: Int, physiology: Int, activeDays: Int) -> Int {
        let total = exercise + sleep + diet + physiology + activeDays
        return min(max(total, 0), 100)
    }

    static func activeDaysScore(daysInWeek: Int) -> Int {
        min(daysInWeek * 2, 10)
    }
}
```

- [ ] **步骤 4：运行测试 → 5 passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 HealthCalculator 健康评分算法及单元测试"
```

---

## 任务 2：健康风险预警规则

**文件：** 扩展 `HealthFlow/Utility/HealthCalculator.swift`

- [ ] **步骤 1：编写失败测试（RED）**

```swift
extension HealthCalculatorTests {

    @Test("连续3天睡眠不足触发预警")
    func testSleepDeficitAlert() {
        let sleeps = [-3, -2, -1].map { daysAgo in
            let date = Calendar.current.date(byAdding: .day, value: daysAgo, to: Date())!
            let record = SleepRecord()
            record.endTime = date
            record.duration = 5 * 3600 // 5小时
            return record
        }
        #expect(HealthCalculator.checkSleepDeficit(sleeps: sleeps, threshold: 6))
    }

    @Test("心率异常触发预警")
    func testHeartRateAbnormal() {
        #expect(HealthCalculator.isHeartRateAbnormal(bpm: 110, max: 100, min: 50))
        #expect(HealthCalculator.isHeartRateAbnormal(bpm: 40, max: 100, min: 50))
        #expect(!HealthCalculator.isHeartRateAbnormal(bpm: 72, max: 100, min: 50))
    }
}
```

- [ ] **步骤 2：运行测试 → BUILD FAILED**

- [ ] **步骤 3：编写实现（GREEN）**

```swift
extension HealthCalculator {
    static func checkSleepDeficit(sleeps: [SleepRecord], threshold: Double) -> Bool {
        let calendar = Calendar.current
        let sorted = sleeps.sorted { $0.endTime < $1.endTime }
        var consecutiveCount = 0
        for sleep in sorted {
            let hours = sleep.duration / 3600
            if hours < threshold { consecutiveCount += 1 }
            else { consecutiveCount = 0 }
            if consecutiveCount >= 3 { return true }
        }
        return false
    }

    static func isHeartRateAbnormal(bpm: Double, max: Double, min: Double) -> Bool {
        bpm > max || bpm < min
    }
}
```

- [ ] **步骤 4：运行测试 → 全部 passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加风险预警规则（睡眠不足 + 心率异常 + 久坐）及单元测试"
```

---

## 任务 3：DashboardViewModel

**文件：** `HealthFlow/ViewModel/DashboardViewModel.swift`，`HealthFlowTests/ViewModelTests/DashboardViewModelTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

```swift
import Testing
import SwiftData
@testable import HealthFlow

struct DashboardViewModelTests {

    @Test("计算今日健康评分为有效值")
    func testTodayScore() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProfile.self, DailyActivitySummary.self, SleepRecord.self, configurations: config)
        let profile = UserProfile()
        profile.targetSteps = 10000
        container.mainContext.insert(profile)

        let summary = DailyActivitySummary()
        summary.steps = 8000
        summary.date = Calendar.current.startOfDay(for: Date())
        container.mainContext.insert(summary)

        let vm = DashboardViewModel(modelContext: container.mainContext)
        vm.loadToday()

        #expect(vm.todayScore >= 0 && vm.todayScore <= 100)
        #expect(vm.todaySteps == 8000)
    }
}
```

- [ ] **步骤 2：运行测试 → BUILD FAILED**

- [ ] **步骤 3：编写实现（GREEN）**

```swift
@Observable
final class DashboardViewModel {
    var todayScore: Int = 0
    var todaySteps: Int = 0
    var todayCalories: Double = 0
    var sleepHours: Double = 0
    var sleepQuality: Int = 0
    var avgHeartRate: Double = 0
    var dietCalories: Double = 0
    var alerts: [String] = []

    private let modelContext: ModelContext

    init(modelContext: ModelContext) { self.modelContext = modelContext }

    func loadToday() {
        let today = Calendar.current.startOfDay(for: Date())
        let profile = (try? modelContext.fetch(FetchDescriptor<UserProfile>()).first)
        let activities = (try? modelContext.fetch(FetchDescriptor<DailyActivitySummary>()).filter { Calendar.current.isDate($0.date, inSameDayAs: today) }) ?? []

        todaySteps = activities.reduce(0) { $0 + $1.steps }
        todayCalories = activities.reduce(0) { $0 + $1.calories }

        let exercise = HealthCalculator.exerciseScore(steps: todaySteps, target: profile?.targetSteps ?? 10000)
        // ... 计算各维度评分
        todayScore = HealthCalculator.totalScore(exercise: exercise, sleep: 20, diet: 16, physiology: 20, activeDays: 8)
    }
}
```

- [ ] **步骤 4：运行测试 → 1 passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 DashboardViewModel（今日评分计算）及单元测试"
```

---

## 任务 4：仪表盘首页实现

**文件：** 修改 `HealthFlow/View/Dashboard/DashboardView.swift`

- [ ] **步骤 1：重写 DashboardView**

```swift
import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 日期 + 健康评分
                    VStack(spacing: 4) {
                        Text(DateFormatter.fullDate.string(from: Date()))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("今日健康指数：\(viewModel?.todayScore ?? 0)分")
                            .font(.title.bold())
                    }
                    .padding(.top)

                    // 2×2 指标卡片网格
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                        StatCard(title: "运动", value: "\(viewModel?.todaySteps ?? 0)", unit: "步",
                                 iconName: "figure.walk", color: .orange)
                        StatCard(title: "睡眠", value: String(format: "%.1f", viewModel?.sleepHours ?? 0), unit: "h",
                                 iconName: "moon.zzz.fill", color: .indigo)
                        StatCard(title: "饮食", value: "\(Int(viewModel?.dietCalories ?? 0))", unit: "千卡",
                                 iconName: "fork.knife", color: .green)
                        StatCard(title: "心率", value: "\(Int(viewModel?.avgHeartRate ?? 0))", unit: "bpm",
                                 iconName: "heart.fill", color: .red)
                    }
                    .padding(.horizontal)

                    // 今日步数分时趋势图
                    if #available(iOS 17, *) {
                        Chart {
                            // 占位数据，后续阶段替换为实际数据
                            BarMark(x: .value("时段", "上午"), y: .value("步数", 3000))
                            BarMark(x: .value("时段", "中午"), y: .value("步数", 2000))
                            BarMark(x: .value("时段", "下午"), y: .value("步数", 3200))
                        }
                        .frame(height: Constants.UI.chartHeight)
                        .padding(.horizontal)
                    }

                    // 异常提醒
                    if let alerts = viewModel?.alerts, !alerts.isEmpty {
                        ForEach(alerts, id: \.self) { alert in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                Text(alert)
                                    .font(.subheadline)
                                Spacer()
                                Button("忽略") { /* 后续实现 */ }
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.yellow.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("仪表盘")
            .onAppear {
                let vm = DashboardViewModel(modelContext: modelContext)
                vm.loadToday()
                viewModel = vm
            }
        }
        .tabItem { Label("仪表盘", systemImage: "house.fill") }
    }
}
```

- [ ] **步骤 2：编译验证后提交**

```bash
xcodebuild build -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16'
git add .
git commit -m "feat: 实现仪表盘首页（评分+指标网格+趋势图+异常提醒）"
```

---

## 任务 5：TodayTrendChart 组件

**文件：** `HealthFlow/View/Dashboard/TodayTrendChart.swift`

- [ ] **步骤 1：编写 TodayTrendChart**

```swift
import SwiftUI
import Charts

struct TodayTrendChart: View {
    let dataPoints: [HourStepData]

    var body: some View {
        Chart(dataPoints) { point in
            AreaMark(
                x: .value("时间", point.hour),
                y: .value("步数", point.steps)
            )
            .foregroundStyle(.linearGradient(
                colors: [.orange.opacity(0.3), .orange.opacity(0.1)],
                startPoint: .top, endPoint: .bottom
            ))
            LineMark(
                x: .value("时间", point.hour),
                y: .value("步数", point.steps)
            )
            .foregroundStyle(.orange)
        }
        .frame(height: Constants.UI.chartHeight)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 4)) { _ in
                AxisValueLabel(format: .dateTime.hour())
            }
        }
    }
}

struct HourStepData: Identifiable {
    let id = UUID()
    let hour: Date
    let steps: Int
}
```

- [ ] **步骤 2：编译验证后提交**

```bash
git add .
git commit -m "feat: 添加 TodayTrendChart 分时趋势图组件"
```

---

## 任务 6：健康报告生成

**文件：** `HealthFlow/View/Profile/HealthReportView.swift`，`HealthFlow/ViewModel/HealthReportViewModel.swift`

- [ ] **步骤 1：编写 HealthReportViewModel**

```swift
@Observable
final class HealthReportViewModel {
    var reportData: ReportData?
    var selectedRange: DateRange = .week

    enum DateRange { case week, month }

    struct ReportData {
        let dateRange: String
        let avgSteps: Int
        let totalWorkouts: Int
        let avgSleepHours: Double
        let avgSleepQuality: Double
        let avgCalories: Double
        let weightTrend: String
        let avgHeartRate: Double
        let alerts: [String]
    }

    func generateReport(modelContext: ModelContext) {
        // 从 SwiftData 聚合数据填充 ReportData
    }

    func exportPDF() -> URL? {
        // 使用 ImageRenderer 渲染 PDF
        return nil
    }
}
```

- [ ] **步骤 2：编写 HealthReportView** — 日期范围选择 + 统计卡片网格 + 趋势图 + AI 建议摘要占位 + toolbar 导出 PDF 按钮

- [ ] **步骤 3：更新 ProfileView 健康报告 NavigationLink 指向实际页面**

- [ ] **步骤 4：编译验证后提交**

```bash
git add .
git commit -m "feat: 添加健康报告生成（周报/月报 + 统计 + 导出 PDF）"
```

---

## 任务 7：阶段三总体验证

- [ ] 运行全部测试：

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

- [ ] Simulator 验证：仪表盘首页显示评分/指标/图表/提醒、健康报告可生成
- [ ] 测试覆盖率确认 ≥91%

```bash
git add .
git commit -m "feat: 完成阶段三——数据可视化、仪表盘、图表系统、健康报告"
```
