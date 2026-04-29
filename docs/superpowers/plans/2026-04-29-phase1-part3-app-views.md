# 阶段一（3/3）：App 入口、Views、ViewModel、总体验证

> **面向开发者：** 严格遵循 TDD。步骤使用 `- [ ]` 复选框。

**目标：** 创建工具类、App 入口与 ModelContainer、MainTabView 骨架、ProfileViewModel、ProfileView/PersonalInfoView/SettingsView、通用组件，最终验证全量测试通过。

**前置：** `phase1-part1-setup-models.md` 和 `phase1-part2-models.md` 已完成

**完成后：** 阶段一交付，可进入阶段二

---

## 任务 1：创建 Constants + DateFormatter 工具类

**文件：**
- 创建：`HealthFlow/Utility/Constants.swift`
- 创建：`HealthFlow/Utility/DateFormatter+Extensions.swift`

- [ ] **步骤 1：编写 Constants.swift**

创建 `HealthFlow/Utility/Constants.swift`：

```swift
import Foundation

enum Constants {
    enum HealthKit {
        static let syncDaysBack = 7
    }

    enum Alert {
        static let defaultSleepMinimumHours: Double = 6
        static let defaultHeartRateMin: Double = 50
        static let defaultHeartRateMax: Double = 100
        static let defaultWeightChangePercentThreshold: Double = 5
        static let defaultSedentaryDays: Int = 7
        static let alertRepeatWindowDays: Int = 7
    }

    enum UI {
        static let statCardHeight: CGFloat = 80
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
        static let chartHeight: CGFloat = 200
    }

    enum Storage {
        static let foodImagesDirectory = "FoodImages"
        static let maxImageDimension: CGFloat = 1024
    }
}
```

- [ ] **步骤 2：编写 DateFormatter 扩展**

创建 `HealthFlow/Utility/DateFormatter+Extensions.swift`：

```swift
import Foundation

extension DateFormatter {
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

extension Calendar {
    func dayBoundary(daysBack: Int, from date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: date)
        guard let start = calendar.date(byAdding: .day, value: -daysBack, to: end) else {
            return (end, end)
        }
        return (start, end)
    }
}
```

- [ ] **步骤 3：编译验证并提交**

```bash
xcodebuild build -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16'
git add .
git commit -m "feat: 添加 Constants + DateFormatter 扩展工具类"
```

---

## 任务 2：配置 HealthFlowApp 入口与 ModelContainer

**文件：**
- 修改：`HealthFlow/HealthFlowApp.swift`

- [ ] **步骤 1：修改 HealthFlowApp.swift**

替换原有 `HealthFlowApp.swift`（Xcode 生成的 ContentView）为：

```swift
import SwiftUI
import SwiftData

@main
struct HealthFlowApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                UserProfile.self,
                DailyActivitySummary.self,
                WorkoutRecord.self,
                SleepRecord.self,
                DietRecord.self,
                FoodItem.self,
                PhysiologicalMetric.self,
                AchievementBadge.self,
                MedicationRecord.self,
                ChatMessage.self,
                FavoriteFood.self,
                IgnoredAlert.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            ensureUserProfileExists()
        } catch {
            fatalError("无法初始化 ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }

    private func ensureUserProfileExists() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            let profiles = try context.fetch(descriptor)
            if profiles.isEmpty {
                let defaultProfile = UserProfile()
                context.insert(defaultProfile)
                try context.save()
            }
        } catch {
            print("检查 UserProfile 时出错: \(error)")
        }
    }
}
```

- [ ] **步骤 2：编译验证**

```bash
xcodebuild build -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16'
```

期望：**BUILD FAILED**（MainTabView 尚未创建，预期行为）

- [ ] **步骤 3：提交**

```bash
git add .
git commit -m "feat: 配置 HealthFlowApp 入口，注入 ModelContainer 并确保 UserProfile 单例"
```

---

## 任务 3：创建 MainTabView 与 3 个占位页

**文件：**
- 创建：`HealthFlow/View/MainTabView.swift`
- 创建：`HealthFlow/View/Dashboard/DashboardView.swift`
- 创建：`HealthFlow/View/HealthData/HealthDataListView.swift`
- 创建：`HealthFlow/View/AIAssistant/AIAssistantView.swift`

- [ ] **步骤 1：编写占位页**

创建 `HealthFlow/View/Dashboard/DashboardView.swift`：

```swift
import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                Text("仪表盘")
                    .font(.title)
                Text("即将在第三阶段实现")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("仪表盘")
        }
        .tabItem {
            Label("仪表盘", systemImage: "house.fill")
        }
    }
}
```

创建 `HealthFlow/View/HealthData/HealthDataListView.swift`：

```swift
import SwiftUI

struct HealthDataListView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "list.clipboard.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                Text("健康数据")
                    .font(.title)
                Text("即将在第二阶段实现")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("健康数据")
        }
        .tabItem {
            Label("健康数据", systemImage: "heart.text.clipboard.fill")
        }
    }
}
```

创建 `HealthFlow/View/AIAssistant/AIAssistantView.swift`：

```swift
import SwiftUI

struct AIAssistantView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple)
                Text("AI 助手")
                    .font(.title)
                Text("即将在第四阶段实现")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("AI 助手")
        }
        .tabItem {
            Label("AI 助手", systemImage: "brain")
        }
    }
}
```

- [ ] **步骤 2：创建 MainTabView**

创建 `HealthFlow/View/MainTabView.swift`：

```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
            HealthDataListView()
            AIAssistantView()
            ProfileView()
        }
    }
}
```

- [ ] **步骤 3：编译验证**

```bash
xcodebuild build -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16'
```

期望：**BUILD FAILED**（ProfileView 尚未创建，预期行为）

- [ ] **步骤 4：提交**

```bash
git add .
git commit -m "feat: 添加 MainTabView 骨架与 3 个占位页"
```

---

## 任务 4：创建 ProfileViewModel

**文件：**
- 创建：`HealthFlow/ViewModel/ProfileViewModel.swift`
- 测试：`HealthFlowTests/ViewModelTests/ProfileViewModelTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

创建 `HealthFlowTests/ViewModelTests/ProfileViewModelTests.swift`：

```swift
import Testing
import SwiftData
@testable import HealthFlow

struct ProfileViewModelTests {

    @Test("加载时无 UserProfile 则自动创建")
    func testAutoCreateWhenEmpty() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProfile.self, configurations: config)
        let viewModel = ProfileViewModel(modelContext: container.mainContext)

        viewModel.loadProfile()

        #expect(viewModel.profile != nil)
        #expect(viewModel.profile?.gender == "unset")
    }

    @Test("更新后保存生效")
    func testSaveUpdatesProfile() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProfile.self, configurations: config)
        let viewModel = ProfileViewModel(modelContext: container.mainContext)
        viewModel.loadProfile()

        viewModel.saveProfile(
            name: "测试用户",
            gender: "male",
            birthDate: Calendar.current.date(byAdding: .year, value: -25, to: Date())!,
            height: 175,
            targetWeight: 70,
            targetSteps: 10000,
            targetSleepHours: 8,
            targetCalories: 2000
        )

        #expect(viewModel.profile?.name == "测试用户")
        #expect(viewModel.profile?.gender == "male")
        #expect(viewModel.profile?.height == 175)
        #expect(viewModel.profile?.targetSteps == 10000)
    }

    @Test("加载已有 UserProfile 时不重复创建")
    func testLoadExistingDoesNotDuplicate() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProfile.self, configurations: config)
        let viewModel = ProfileViewModel(modelContext: container.mainContext)
        viewModel.loadProfile()
        let firstCount = try container.mainContext.fetch(FetchDescriptor<UserProfile>()).count
        #expect(firstCount == 1)

        viewModel.loadProfile()
        let secondCount = try container.mainContext.fetch(FetchDescriptor<UserProfile>()).count
        #expect(secondCount == 1)
    }
}
```

- [ ] **步骤 2：运行测试确认失败（RED）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/ProfileViewModelTests
```

期望：**BUILD FAILED**

- [ ] **步骤 3：编写最小实现（GREEN）**

创建 `HealthFlow/ViewModel/ProfileViewModel.swift`：

```swift
import Foundation
import SwiftUI
import SwiftData

@Observable
final class ProfileViewModel {
    var profile: UserProfile?
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            let profiles = try modelContext.fetch(descriptor)
            if let existing = profiles.first {
                profile = existing
            } else {
                let newProfile = UserProfile()
                modelContext.insert(newProfile)
                try modelContext.save()
                profile = newProfile
            }
        } catch {
            print("加载 UserProfile 失败: \(error)")
        }
    }

    func saveProfile(
        name: String,
        gender: String,
        birthDate: Date,
        height: Double,
        targetWeight: Double? = nil,
        targetSteps: Int? = nil,
        targetSleepHours: Double? = nil,
        targetCalories: Int? = nil
    ) {
        guard let p = profile else { return }
        p.name = name
        p.gender = gender
        p.birthDate = birthDate
        p.height = height
        p.targetWeight = targetWeight
        p.targetSteps = targetSteps
        p.targetSleepHours = targetSleepHours
        p.targetCalories = targetCalories
        do {
            try modelContext.save()
        } catch {
            print("保存 UserProfile 失败: \(error)")
        }
    }
}
```

- [ ] **步骤 4：运行测试确认通过（GREEN）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/ProfileViewModelTests
```

期望：**3 tests passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 ProfileViewModel 及单元测试"
```

---

## 任务 5：创建 ProfileView + PersonalInfoView + SettingsView

**文件：**
- 创建：`HealthFlow/View/Profile/ProfileView.swift`
- 创建：`HealthFlow/View/Profile/PersonalInfoView.swift`
- 创建：`HealthFlow/View/Profile/SettingsView.swift`

- [ ] **步骤 1：编写 ProfileView.swift**

创建 `HealthFlow/View/Profile/ProfileView.swift`：

```swift
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ProfileViewModel?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        if let vm = viewModel {
                            PersonalInfoView(viewModel: vm)
                        }
                    } label: {
                        Label("个人档案", systemImage: "person.fill")
                    }
                }

                Section {
                    NavigationLink(destination: EmptyView()) {
                        Label("健康报告", systemImage: "doc.text.fill")
                    }
                    NavigationLink(destination: EmptyView()) {
                        Label("数据导出", systemImage: "square.and.arrow.up.fill")
                    }
                    NavigationLink(destination: EmptyView()) {
                        Label("成就徽章", systemImage: "medal.fill")
                    }
                }

                Section {
                    NavigationLink(destination: SettingsView()) {
                        Label("设置", systemImage: "gearshape.fill")
                    }
                }
            }
            .navigationTitle("我的")
        }
        .tabItem {
            Label("我的", systemImage: "person.circle.fill")
        }
        .onAppear {
            let vm = ProfileViewModel(modelContext: modelContext)
            vm.loadProfile()
            viewModel = vm
        }
    }
}
```

- [ ] **步骤 2：编写 PersonalInfoView.swift**

创建 `HealthFlow/View/Profile/PersonalInfoView.swift`：

```swift
import SwiftUI

struct PersonalInfoView: View {
    let viewModel: ProfileViewModel

    @State private var name: String = ""
    @State private var gender: String = "unset"
    @State private var birthDate: Date = Date()
    @State private var height: Double = 170
    @State private var targetWeight: Double?
    @State private var targetSteps: Int?
    @State private var targetSleepHours: Double?
    @State private var targetCalories: Int?

    let genderOptions: [(String, String)] = [
        ("unset", "未设置"),
        ("male", "男"),
        ("female", "女"),
        ("other", "其他"),
    ]

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("姓名", text: $name)
                Picker("性别", selection: $gender) {
                    ForEach(genderOptions, id: \.0) { value, label in
                        Text(label).tag(value)
                    }
                }
                DatePicker("出生日期", selection: $birthDate, displayedComponents: .date)
                HStack {
                    Text("身高")
                    Spacer()
                    Text("\(Int(height)) cm")
                        .foregroundStyle(.secondary)
                    Stepper("", value: $height, in: 100...250, step: 1)
                        .labelsHidden()
                }
            }

            Section("健康目标") {
                HStack {
                    Text("每日步数")
                    Spacer()
                    TextField("目标步数", value: $targetSteps, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("每日睡眠")
                    Spacer()
                    TextField("小时", value: $targetSleepHours, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("每日卡路里")
                    Spacer()
                    TextField("千卡", value: $targetCalories, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("目标体重")
                    Spacer()
                    TextField("kg", value: $targetWeight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .navigationTitle("个人档案")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") {
                    viewModel.saveProfile(
                        name: name,
                        gender: gender,
                        birthDate: birthDate,
                        height: height,
                        targetWeight: targetWeight,
                        targetSteps: targetSteps,
                        targetSleepHours: targetSleepHours,
                        targetCalories: targetCalories
                    )
                }
            }
        }
        .onAppear {
            loadProfileData()
        }
    }

    private func loadProfileData() {
        guard let profile = viewModel.profile else { return }
        name = profile.name
        gender = profile.gender
        birthDate = profile.birthDate
        height = profile.height
        targetWeight = profile.targetWeight
        targetSteps = profile.targetSteps
        targetSleepHours = profile.targetSleepHours
        targetCalories = profile.targetCalories
    }
}
```

- [ ] **步骤 3：编写 SettingsView.swift**

创建 `HealthFlow/View/Profile/SettingsView.swift`：

```swift
import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var darkModeSelection: String = "system"

    var body: some View {
        Form {
            Section("隐私与安全") {
                HStack {
                    Label("隐私锁", systemImage: "lock.fill")
                    Spacer()
                    Toggle("", isOn: .constant(false))
                        .disabled(true)
                }
            }

            Section("AI 配置") {
                NavigationLink(destination: EmptyView()) {
                    Label("API 配置", systemImage: "key.fill")
                }
            }

            Section("外观") {
                Picker(selection: $darkModeSelection) {
                    Text("跟随系统").tag("system")
                    Text("浅色模式").tag("light")
                    Text("深色模式").tag("dark")
                } label: {
                    Label("深色模式", systemImage: "moon.fill")
                }
            }

            Section("数据管理") {
                Button {} label: {
                    Label("数据备份", systemImage: "arrow.triangle.2.circlepath")
                }
            }

            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("设置")
    }
}
```

- [ ] **步骤 4：编译验证**

```bash
xcodebuild build -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16'
```

期望：**BUILD SUCCEEDED**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 ProfileView + PersonalInfoView + SettingsView"
```

---

## 任务 6：创建通用组件

**文件：**
- 创建：`HealthFlow/View/Component/StatCard.swift`
- 创建：`HealthFlow/View/Component/EmptyStateView.swift`

- [ ] **步骤 1：编写 StatCard.swift**

创建 `HealthFlow/View/Component/StatCard.swift`：

```swift
import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let iconName: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

- [ ] **步骤 2：编写 EmptyStateView.swift**

创建 `HealthFlow/View/Component/EmptyStateView.swift`：

```swift
import SwiftUI

struct EmptyStateView: View {
    let iconName: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
```

- [ ] **步骤 3：编译验证并提交**

```bash
xcodebuild build -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16'
git add .
git commit -m "feat: 添加 StatCard + EmptyStateView 通用组件"
```

---

## 任务 7：阶段一总体验证

- [ ] **步骤 1：运行全部测试**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16'
```

期望：**全部测试通过**（DefinitionTests + ModelTests + ViewModelTests 合计 40+ tests）

- [ ] **步骤 2：Simulator 运行验证**

在 Xcode Simulator 中：
- 4 个 Tab 正常切换显示
- 进入「我的」Tab → 个人档案 → 填写信息 → 点击保存
- 返回再进入，确认信息已保存
- 进入「设置」页确认各项显示正常
- 仪表盘/健康数据/AI 助手 Tab 显示占位内容

- [ ] **步骤 3：最终提交**

```bash
git add .
git commit -m "feat: 完成阶段一——基础框架、数据模型、个人档案、设置页骨架及单元测试"
```

---

## 阶段一完成标准

以下条件全部满足方可进入阶段二：

- [ ] Xcode 项目可编译运行
- [ ] 12 个 SwiftData 模型全部定义并测试通过
- [ ] 5 个 Definition 枚举定义并测试通过
- [ ] MainTabView 四 Tab 导航正常
- [ ] ProfileView → PersonalInfoView 个人档案 CRUD 可用
- [ ] SettingsView 骨架页面显示（深色模式 Picker 可切换）
- [ ] StatCard + EmptyStateView 通用组件可渲染
- [ ] 单元测试覆盖率 ≥85%
- [ ] 所有测试绿色

---

## 第三部分完成

完整文件清单（Part 1+2+3 合计）：

| 目录 | 文件数 | 说明 |
|------|--------|------|
| `HealthFlow/` | 1 | HealthFlowApp.swift |
| `Model/` | 12 | 全部 SwiftData 模型 |
| `Definition/` | 5 | BadgeDefinition, MetricType, ExerciseType, MealType, QuickPromptType |
| `View/` | 8 | MainTabView, DashboardView, HealthDataListView, AIAssistantView, ProfileView, PersonalInfoView, SettingsView, StatCard, EmptyStateView |
| `ViewModel/` | 1 | ProfileViewModel |
| `Utility/` | 2 | Constants, DateFormatter+Extensions |
| `HealthFlowTests/` | ~13 | 对应测试文件 |

阶段一共 23 个任务，分为 3 个计划子文件执行。
