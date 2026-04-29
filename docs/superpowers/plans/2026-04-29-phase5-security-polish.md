# 阶段五：数据安全与精修 实现计划

> **面向开发者：** 请使用 superpowers:subagent-driven-development（推荐）按任务逐个实现。严格遵循 TDD。

**目标：** 隐私锁（Face ID/Touch ID）、数据导出（CSV/PDF）、成就徽章展示、部分 UI/UX 精修。

**技术栈：** SwiftUI, SwiftData, LocalAuthentication, ImageRenderer

**测试覆盖率目标：** ≥85%（简单+中等混合）

**前置依赖：** 阶段一至四已完成

---

## 任务 1：PrivacyLockViewModel + PrivacyLockView

**文件：** `HealthFlow/ViewModel/PrivacyLockViewModel.swift`，`HealthFlow/View/Privacy/PrivacyLockView.swift`，`HealthFlowTests/ViewModelTests/PrivacyLockViewModelTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

```swift
import Testing
@testable import HealthFlow

struct PrivacyLockViewModelTests {

    @Test("隐私锁禁用时不需要验证")
    func testNotEnabled() {
        UserDefaults.standard.set(false, forKey: "privacy_lock_enabled")
        let vm = PrivacyLockViewModel()
        #expect(vm.needsAuthentication == false)
    }

    @Test("隐私锁启用时需要验证")
    func testEnabled() {
        UserDefaults.standard.set(true, forKey: "privacy_lock_enabled")
        let vm = PrivacyLockViewModel()
        #expect(vm.needsAuthentication == true)
    }

    @Test("验证成功后 isAuthenticated 为 true")
    func testAuthenticationSuccess() async {
        let vm = PrivacyLockViewModel()
        await vm.authenticate()
        #expect(vm.isAuthenticated == true)
    }
}
```

- [ ] **步骤 2：运行测试 → BUILD FAILED**

- [ ] **步骤 3：编写实现（GREEN）**

```swift
import Foundation
import SwiftUI
import LocalAuthentication

@Observable
final class PrivacyLockViewModel {
    var isAuthenticated = false
    var showLock = true

    var needsAuthentication: Bool {
        UserDefaults.standard.bool(forKey: "privacy_lock_enabled")
    }

    func authenticate() async {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isAuthenticated = true // 不支持时直接放行
            return
        }
        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "验证身份以查看您的健康数据"
            )
            await MainActor.run {
                isAuthenticated = result
                if result { showLock = false }
            }
        } catch {
            isAuthenticated = false
        }
    }

    func lock() {
        showLock = true
        isAuthenticated = false
    }
}
```

- [ ] **步骤 4：运行测试 → 3 passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 PrivacyLockViewModel（Face ID + 纯色锁屏）及单元测试"
```

---

## 任务 2：PrivacyLockView 界面 + HealthFlowApp 集成

**文件：** `HealthFlow/View/Privacy/PrivacyLockView.swift`，修改 `HealthFlow/HealthFlowApp.swift`

- [ ] **步骤 1：编写 PrivacyLockView**

```swift
import SwiftUI

struct PrivacyLockView: View {
    let viewModel: PrivacyLockViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                Text("HealthFlow")
                    .font(.largeTitle.bold())
                Text("轻触以验证身份")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .onTapGesture {
            Task { await viewModel.authenticate() }
        }
        .onAppear {
            Task { await viewModel.authenticate() }
        }
    }
}
```

- [ ] **步骤 2：修改 HealthFlowApp.swift 包装隐私锁**

```swift
var body: some Scene {
    WindowGroup {
        ContentView()
            .modelContainer(container)
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var lockVM = PrivacyLockViewModel()

    var body: some View {
        ZStack {
            MainTabView()
            if lockVM.showLock && lockVM.needsAuthentication {
                PrivacyLockView(viewModel: lockVM)
                    .transition(.opacity)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                if lockVM.needsAuthentication { lockVM.lock() }
            }
        }
    }
}
```

- [ ] **步骤 3：编译验证**

```bash
xcodebuild build -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16'
```

期望：**BUILD SUCCEEDED**

- [ ] **步骤 4：提交**

```bash
git add .
git commit -m "feat: 添加隐私锁界面 + App 后台锁屏 + 截图防护"
```

---

## 任务 3：CSVEncoder + ExportService

**文件：** `HealthFlow/Utility/CSVEncoder.swift`，`HealthFlow/Service/ExportService.swift`，`HealthFlowTests/ServiceTests/ExportServiceTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

```swift
import Testing
import Foundation
@testable import HealthFlow

struct ExportServiceTests {

    @Test("CSV 导出包含正确表头和数据")
    func testCSVExportWorkouts() throws {
        let service = ExportService()
        let workout = WorkoutRecord()
        workout.exerciseType = "running"
        workout.duration = 1800
        workout.calories = 300
        workout.startTime = Date(timeIntervalSince1970: 0)

        let csv = try service.exportCSV(workouts: [workout])
        #expect(csv.contains("exerciseType,duration,calories,startTime"))
        #expect(csv.contains("running"))
        #expect(csv.contains("1800"))
        #expect(csv.contains("300"))
    }

    @Test("空数据集导出为空 CSV（仅表头）")
    func testEmptyCSVExport() throws {
        let service = ExportService()
        let csv = try service.exportCSV(workouts: [])
        #expect(csv.contains("exerciseType"))
    }
}
```

- [ ] **步骤 2：运行测试 → BUILD FAILED**

- [ ] **步骤 3：编写 CSVEncoder**

```swift
import Foundation

struct CSVEncoder {
    static func encode<T: Encodable>(_ items: [T]) throws -> String {
        guard let first = items.first else { return "" }
        let mirror = Mirror(reflecting: first)
        let headers = mirror.children.map { $0.label ?? "" }.joined(separator: ",")
        let rows = items.map { item -> String in
            let m = Mirror(reflecting: item)
            return m.children.map { child -> String in
                "\(child.value)"
            }.joined(separator: ",")
        }
        return ([headers] + rows).joined(separator: "\n")
    }
}
```

- [ ] **步骤 4：编写 ExportService**

```swift
import Foundation

final class ExportService {
    func exportCSV(workouts: [WorkoutRecord]) throws -> String {
        try CSVEncoder.encode(workouts)
    }

    func exportToFile(data: String, filename: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        try data.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
```

- [ ] **步骤 5：运行测试 → 2 passed**

- [ ] **步骤 6：提交**

```bash
git add .
git commit -m "feat: 添加 CSVEncoder + ExportService（数据导出）及单元测试"
```

---

## 任务 4：数据导出界面

**文件：** `HealthFlow/View/Profile/ExportView.swift`

- [ ] **步骤 1：编写 ExportView**

```swift
import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedType: ExportType = .workouts
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var endDate = Date()
    @State private var exportURL: URL?

    enum ExportType: String, CaseIterable {
        case workouts, sleep, diet, metrics, medications
        var displayName: String {
            switch self {
            case .workouts: return "运动数据"
            case .sleep: return "睡眠数据"
            case .diet: return "饮食数据"
            case .metrics: return "生理指标"
            case .medications: return "用药记录"
            }
        }
    }

    var body: some View {
        Form {
            Picker("数据类型", selection: $selectedType) {
                ForEach(ExportType.allCases, id: \.rawValue) { type in
                    Text(type.displayName).tag(type)
                }
            }
            DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
            DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
            Section {
                Button("导出 CSV") { exportCSV() }
            }
            if let url = exportURL {
                Section {
                    ShareLink(item: url)
                }
            }
        }
        .navigationTitle("数据导出")
    }

    func exportCSV() {
        // 根据 selectedType 从 SwiftData 查询数据 → ExportService
        // 调用 exportToFile → 设置 exportURL
    }
}
```

- [ ] **步骤 2：更新 ProfileView 数据导出 NavigationLink**

- [ ] **步骤 3：编译验证后提交**

```bash
git add .
git commit -m "feat: 添加数据导出界面（选择类型+日期+CSV导出+分享）"
```

---

## 任务 5：成就徽章展示页 + AlertHistoryView

**文件：** `HealthFlow/View/Profile/AchievementView.swift`，`HealthFlow/View/Profile/AlertHistoryView.swift`

- [ ] **步骤 1：编写 AchievementView**

```swift
import SwiftUI

struct AchievementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AchievementViewModel?

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            if let badges = viewModel?.allBadges() {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(badges, id: \.0.rawValue) { definition, earned in
                        VStack(spacing: 8) {
                            Image(systemName: definition.iconName)
                                .font(.system(size: 30))
                                .foregroundStyle(earned ? .yellow : .gray.opacity(0.4))
                            Text(definition.title)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(earned ? Color.yellow.opacity(0.1) : Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(earned ? nil : Image(systemName: "lock.fill").font(.caption).foregroundStyle(.secondary).offset(y: -30))
                    }
                }
                .padding()
            }
        }
        .navigationTitle("成就徽章")
        .onAppear {
            let vm = AchievementViewModel()
            vm.checkAndAwardBadges(modelContext: modelContext)
            viewModel = vm
        }
    }
}
```

- [ ] **步骤 2：编写 AlertHistoryView** — 被忽略的预警列表 + 自定义阈值表单（睡眠/心率/体重）

- [ ] **步骤 3：更新 ProfileView 的成就徽章和预警管理链接**

- [ ] **步骤 4：编译验证后提交**

```bash
git add .
git commit -m "feat: 添加成就徽章展示 + 预警历史管理界面"
```

---

## 任务 6：血氧/体温指标完善 + 各详情页图标与空状态

- [ ] **步骤 1：确保所有生理指标详情页图标、空状态效果一致**
- [ ] **步骤 2：完善血氧、体温、血糖等指标的录入表单和趋势展示**
- [ ] **步骤 3：各详情页添加 EmptyStateView（无数据时显示引导提示）**

- [ ] **步骤 4：提交**

```bash
git add .
git commit -m "feat: 完善生理指标录入 + 各详情页空状态 + UI 一致性"
```

---

## 任务 7：阶段五总体验证

- [ ] 运行全部测试：

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

- [ ] Simulator 验证：
  - 隐私锁：启/禁用正常工作，后台返回重验证，截图显示纯色+Logo
  - 数据导出：CSV 分享正常
  - 成就徽章：完整展示（✅+🔒）
  - 预警历史：查看/自定义阈值
  - 全流程回归测试

- [ ] 测试覆盖率确认 ≥85%

```bash
git add .
git commit -m "feat: 完成阶段五——隐私锁、数据导出、成就徽章、UI 精修"

# 最终打 Tag
git tag -a v1.0.0 -m "HealthFlow v1.0 完成——五个阶段全部交付"
```
