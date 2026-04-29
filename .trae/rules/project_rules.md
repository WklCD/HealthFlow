# HealthFlow 项目规则

## Swift 并发安全规则（必读）

### 规则 1：测试类访问 `container.mainContext` 必须标注 `@MainActor`

SwiftData 的 `ModelContainer.mainContext` 是 `@MainActor` 隔离的。在测试中访问它时，必须将整个测试 struct 标注为 `@MainActor`，否则会触发 `unsafeForcedSync` 警告。

```swift
// ✅ 正确
@MainActor
struct ProfileViewModelTests {
    func testSave() async throws {
        let container = try ModelContainer(for: UserProfile.self, configurations: config)
        let vm = ProfileViewModel(modelContext: container.mainContext)
        vm.loadProfile()
    }
}

// ❌ 错误 — 会产生 "unsafeForcedSync called from Swift Concurrent context"
struct ProfileViewModelTests {
    func testSave() async throws {
        let vm = ProfileViewModel(modelContext: container.mainContext) // ⚠️
    }
}
```

**适用于所有测试文件**：`SyncEngineTests`、`HealthDataViewModelTests`、`DashboardViewModelTests`、`AIAssistantViewModelTests` 等。

---

### 规则 2：ViewModel 中操作 `ModelContext` 的方法必须标注 `@MainActor`

任何读写 `modelContext` 的方法（如 `loadProfile()`、`loadMessages()`、`loadAllData()`）必须在主线程执行。将整个 ViewModel 类标注 `@MainActor`，或将相关方法标注 `@MainActor`。

```swift
// ✅ 正确 — 整个类标注 @MainActor
@Observable
@MainActor
final class HealthDataViewModel {
    private let modelContext: ModelContext
    func loadAllData() { ... }  // 自动在主线程
}

// ✅ 也可以 — 仅方法标注（但整个类标注更安全）
@Observable
final class AIAssistantViewModel {
    @MainActor
    func loadMessages() {
        messages = (try? modelContext.fetch(descriptor)) ?? []
    }
}

// ❌ 错误 — 不标注会导致并发警告
final class HealthDataViewModel {
    func loadAllData() {  // ⚠️ 在非主线程可能调用
        let results = try? modelContext.fetch(FetchDescriptor<...>())
    }
}
```

---

### 规则 3：View 中用 `.task {}` 替代 `.onAppear {}` 初始化 ViewModel

`.onAppear` 是同步的，在其中创建 ViewModel 并调用 ModelContext 操作会触发并发警告。用 `.task {}` 异步执行。

```swift
// ✅ 正确
var body: some View {
    MainTabView()
        .task {
            await ensureUserProfileExists()
        }
}

// ✅ 正确 — ViewModel 初始化也在 .task 中
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?

    var body: some View {
        List { ... }
        .task {
            let vm = DashboardViewModel(modelContext: modelContext)
            await vm.loadToday()
            viewModel = vm
        }
    }
}

// ❌ 错误 — 同步调用触发 unsafeForcedSync
struct DashboardView: View {
    var body: some View {
        List { ... }
        .onAppear {
            let vm = DashboardViewModel(modelContext: modelContext)
            vm.loadToday()  // ⚠️ 同步调用 ModelContext 操作
        }
    }
}
```

---

## SwiftData 模型规则

### 规则 4：SwiftData `@Model` 类必须提供显式 `init`

SwiftData 会为 `@Model` 属性生成默认值，但为了测试和可用性，每个模型必须提供带默认参数的 `init`。

```swift
// ✅ 正确
@Model
final class UserProfile {
    var name: String = ""
    var height: Double = 0

    init(name: String = "", height: Double = 0) {
        self.name = name
        self.height = height
    }
}

// ❌ 错误 — 省略 init 可能导致编译或测试问题
@Model
final class UserProfile {
    var name: String = ""
    var height: Double = 0
    // 没有 init
}
```

---

### 规则 5：SwiftData 存储路径必须显式指定

不要使用默认存储路径，必须用 `URL.applicationSupportDirectory` 显式指定，避免首次启动时目录不存在的错误。

```swift
// ✅ 正确
let storeURL = URL.applicationSupportDirectory.appendingPathComponent("HealthFlow.sqlite")
let config = ModelConfiguration(schema: schema, url: storeURL)
let container = try ModelContainer(for: schema, configurations: [config])

// ❌ 错误 — 可能导致 "Failed to create file; code = 2"
let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
let container = try ModelContainer(for: schema, configurations: [config])
```

---

## Bundle Identifier 规则

### 规则 6：使用反向域名格式的唯一 Bundle ID

不要使用通用域名如 `com.healthflow.app`，必须使用你的个人/团队标识符。

```
# ✅ 正确
com.linchengda.HealthFlow

# ❌ 错误 — 可能与其他开发者冲突
com.healthflow.app
```

---

## 代码风格规则

### 规则 7：不添加注释（除非用户要求）

遵循项目统一风格，代码本身应该足够清晰，不写多余注释。

### 规则 8：TDD 流程

每个功能模块严格遵循 RED-GREEN-REFACTOR：
1. **RED**：先写失败测试
2. **GREEN**：写最小实现使测试通过
3. **REFACTOR**：重构代码（可选）

### 规则 9：每次提交前运行完整测试

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

确保所有测试通过后再提交。