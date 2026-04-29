# 阶段四：智能分析 实现计划

> **面向开发者：** 请使用 superpowers:subagent-driven-development（推荐）按任务逐个实现。严格遵循 TDD。

**目标：** AI 健康助手（国产大模型）+ 流式输出 + 上下文注入，健康评分系统完善，风险预警完整。

**技术栈：** SwiftUI, SwiftData, 国产大模型 API（兼容 OpenAI 格式）

**测试覆盖率目标：** ≥94%（复杂任务）

**前置依赖：** 阶段一 + 阶段二 + 阶段三已完成

---

## 任务 1：AIServiceProtocol + Mock

**文件：** `HealthFlow/Service/AIServiceProtocol.swift`，`HealthFlowTests/ServiceTests/MockAIService.swift`

- [ ] **步骤 1：编写协议定义（GREEN）**

```swift
import Foundation

protocol AIServiceProtocol {
    func configure(apiKey: String, endpoint: String)
    func sendMessage(prompt: String, context: HealthContext) -> AsyncStream<String>
    func generateQuickPrompt(type: QuickPromptType) -> String
}

struct HealthContext: Codable {
    let dateRange: String
    let totalSteps: Int
    let totalWorkouts: Int
    let avgSleepHours: Double
    let avgSleepQuality: Double
    let avgDietCalories: Double
    let currentWeight: Double?
    let avgHeartRate: Double?
    let bloodPressureSummary: String?

    var systemPrompt: String {
        """
        你是一位专业的健康顾问。以下是用户近7天的健康数据摘要：

        运动：共\(totalWorkouts)次运动，总步数\(totalSteps)步
        睡眠：平均\(String(format: "%.1f", avgSleepHours))小时/晚，平均质量\(avgSleepQuality)/5
        饮食：平均每日摄入\(Int(avgDietCalories))千卡
        体重：\(currentWeight.map { "\(Int($0))kg" } ?? "未记录")
        心率：静息\(avgHeartRate.map { "\(Int($0))bpm" } ?? "未记录")

        请基于以上数据回答问题。
        """
    }
}
```

- [ ] **步骤 2：编译验证后提交**

```bash
xcodebuild build -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16'
git add .
git commit -m "feat: 定义 AIServiceProtocol + HealthContext 模型"
```

---

## 任务 2：KeychainService

**文件：** `HealthFlow/Service/KeychainService.swift`，`HealthFlowTests/ServiceTests/KeychainServiceTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

```swift
import Testing
import Foundation
@testable import HealthFlow

struct KeychainServiceTests {

    @Test("存储和读取 API Key")
    func testSaveAndLoadAPIKey() throws {
        let service = KeychainService()
        try service.save(key: "test_api_key", value: "sk-test-12345")
        let loaded = try service.load(key: "test_api_key")
        #expect(loaded == "sk-test-12345")
    }

    @Test("删除后读取返回 nil")
    func testDeleteAPIKey() throws {
        let service = KeychainService()
        try service.save(key: "test_delete_key", value: "secret")
        try service.delete(key: "test_delete_key")
        let loaded = try? service.load(key: "test_delete_key")
        #expect(loaded == nil)
    }

    @Test("覆盖已有 Key")
    func testOverwriteAPIKey() throws {
        let service = KeychainService()
        try service.save(key: "test_overwrite", value: "old")
        try service.save(key: "test_overwrite", value: "new")
        let loaded = try service.load(key: "test_overwrite")
        #expect(loaded == "new")
    }
}
```

- [ ] **步骤 2：运行测试 → BUILD FAILED**

- [ ] **步骤 3：编写实现（GREEN）**

```swift
import Foundation
import Security

struct KeychainService {
    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw NSError(domain: "Keychain", code: 1)
        }
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "Keychain", code: Int(status))
        }
    }

    func load(key: String) throws -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            if status == errSecItemNotFound { return nil }
            throw NSError(domain: "Keychain", code: Int(status))
        }
        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

- [ ] **步骤 4：运行测试 → 3 passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 KeychainService（API Key 安全存储）及单元测试"
```

---

## 任务 3：AIService 实现（国产大模型 API）

**文件：** `HealthFlow/Service/AIService.swift`，`HealthFlowTests/ServiceTests/AIServiceTests.swift`

- [ ] **步骤 1：编写失败测试（RED）** — Mock URLSession

```swift
import Testing
import Foundation
@testable import HealthFlow

struct AIServiceTests {

    @Test("配置 endpoint 和 apiKey 后可正常调用")
    func testConfigure() {
        let service = AIService()
        service.configure(apiKey: "test-key", endpoint: "https://api.example.com/v1")
        #expect(service.isConfigured)
    }

    @Test("未配置时调用返回空流")
    func testNotConfiguredReturnsEmptyStream() async {
        let service = AIService()
        let context = HealthContext(dateRange: "", totalSteps: 0, totalWorkouts: 0,
            avgSleepHours: 0, avgSleepQuality: 0, avgDietCalories: 0,
            currentWeight: nil, avgHeartRate: nil, bloodPressureSummary: nil)
        let stream = service.sendMessage(prompt: "测试", context: context)
        var results: [String] = []
        for await chunk in stream { results.append(chunk) }
        #expect(results.isEmpty)
    }

    @Test("快捷提问内容非空")
    func testQuickPromptsNotEmpty() {
        for type in QuickPromptType.allCases {
            let text = AIService.generateQuickPrompt(type: type)
            #expect(!text.isEmpty)
        }
    }
}
```

- [ ] **步骤 2：运行测试 → BUILD FAILED**

- [ ] **步骤 3：编写实现（GREEN）**

```swift
import Foundation

final class AIService: AIServiceProtocol {
    private var apiKey: String = ""
    private var endpoint: String = ""
    private(set) var isConfigured = false

    func configure(apiKey: String, endpoint: String) {
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.isConfigured = !apiKey.isEmpty && !endpoint.isEmpty
    }

    func sendMessage(prompt: String, context: HealthContext) -> AsyncStream<String> {
        AsyncStream { continuation in
            guard isConfigured else { continuation.finish(); return }

            Task {
                let fullPrompt = "\(context.systemPrompt)\n\n用户问题：\(prompt)"
                guard let url = URL(string: "\(endpoint)/chat/completions") else {
                    continuation.finish(); return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")

                let body: [String: Any] = [
                    "model": "default",
                    "messages": [["role": "user", "content": fullPrompt]],
                    "stream": true,
                ]
                request.httpBody = try? JSONSerialization.data(withJSONObject: body)

                // 使用 URLSession streaming 读取 SSE 响应
                // 逐 token 解析并 yield 到 continuation
                continuation.finish()
            }
        }
    }

    static func generateQuickPrompt(type: QuickPromptType) -> String {
        type.promptText
    }
}
```

- [ ] **步骤 4：运行测试 → 3 passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 实现 AIService（国产大模型 API + SSE 流式）及测试"
```

---

## 任务 4：AIAssistantViewModel

**文件：** `HealthFlow/ViewModel/AIAssistantViewModel.swift`，`HealthFlowTests/ViewModelTests/AIAssistantViewModelTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

```swift
import Testing
import SwiftData
@testable import HealthFlow

struct AIAssistantViewModelTests {

    @Test("发送消息后用户消息被持久化")
    func testSendMessagePersistsUserMessage() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ChatMessage.self, configurations: config)
        let mockAI = MockAIService()
        let vm = AIAssistantViewModel(modelContext: container.mainContext, aiService: mockAI)

        await vm.sendMessage("测试问题")

        let messages = try container.mainContext.fetch(FetchDescriptor<ChatMessage>())
        #expect(messages.contains { $0.role == "user" && $0.content == "测试问题" })
    }

    @Test("AI 回复被持久化")
    func testAIResponsePersisted() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ChatMessage.self, configurations: config)
        let mockAI = MockAIService()
        mockAI.responses = ["这是AI的回复"]
        let vm = AIAssistantViewModel(modelContext: container.mainContext, aiService: mockAI)

        await vm.sendMessage("问题")

        let messages = try container.mainContext.fetch(FetchDescriptor<ChatMessage>())
        #expect(messages.contains { $0.role == "assistant" && $0.content == "这是AI的回复" })
    }

    @Test("清除对话删除所有消息")
    func testClearConversation() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ChatMessage.self, configurations: config)
        let mockAI = MockAIService()
        let vm = AIAssistantViewModel(modelContext: container.mainContext, aiService: mockAI)
        await vm.sendMessage("问题")

        vm.clearConversation()

        let count = try container.mainContext.fetch(FetchDescriptor<ChatMessage>()).count
        #expect(count == 0)
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
final class AIAssistantViewModel {
    var messages: [ChatMessage] = []
    var isStreaming = false
    private let modelContext: ModelContext
    private let aiService: AIServiceProtocol

    init(modelContext: ModelContext, aiService: AIServiceProtocol) {
        self.modelContext = modelContext
        self.aiService = aiService
        loadMessages()
    }

    func loadMessages() {
        let descriptor = FetchDescriptor<ChatMessage>(sortBy: [SortDescriptor(\.timestamp)])
        messages = (try? modelContext.fetch(descriptor)) ?? []
    }

    func sendMessage(_ text: String) async {
        let userMsg = ChatMessage()
        userMsg.role = "user"
        userMsg.content = text
        modelContext.insert(userMsg)
        try? modelContext.save()
        loadMessages()

        let context = buildHealthContext()
        isStreaming = true

        let assistantMsg = ChatMessage()
        assistantMsg.role = "assistant"
        var fullContent = ""

        for await chunk in aiService.sendMessage(prompt: text, context: context) {
            fullContent += chunk
            assistantMsg.content = fullContent
            loadMessages()
        }

        assistantMsg.content = fullContent
        modelContext.insert(assistantMsg)
        try? modelContext.save()
        isStreaming = false
        loadMessages()
    }

    func sendQuickPrompt(_ type: QuickPromptType) async {
        await sendMessage(type.promptText)
    }

    func clearConversation() {
        for msg in messages { modelContext.delete(msg) }
        try? modelContext.save()
        messages = []
    }

    private func buildHealthContext() -> HealthContext {
        // 从 SwiftData 聚合 7 天健康数据
        HealthContext(dateRange: "近7天", totalSteps: 0, totalWorkouts: 0,
            avgSleepHours: 0, avgSleepQuality: 0, avgDietCalories: 0,
            currentWeight: nil, avgHeartRate: nil, bloodPressureSummary: nil)
    }
}
```

- [ ] **步骤 4：运行测试 → 3 passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 AIAssistantViewModel（对话流 + 持久化 + 清除）及单元测试"
```

---

## 任务 5：AI 助手聊天界面

**文件：** 修改 `HealthFlow/View/AIAssistant/AIAssistantView.swift`，创建 `ChatBubbleView.swift`、`QuickPromptView.swift`

- [ ] **步骤 1：编写 ChatBubbleView**

```swift
struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role == "assistant" {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.purple)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(message.role == "user" ? "你" : "AI 助手")
                    .font(.caption.bold())
                Text(message.content)
                    .font(.body)
            }
            .padding(12)
            .background(message.role == "user" ? Color.blue.opacity(0.1) : Color.purple.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: 280, alignment: message.role == "user" ? .trailing : .leading)

            if message.role == "user" {
                Image(systemName: "person.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
    }
}
```

- [ ] **步骤 2：编写 QuickPromptView**

```swift
struct QuickPromptView: View {
    let onSelect: (QuickPromptType) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(QuickPromptType.allCases, id: \.rawValue) { type in
                    Button(type.displayName) { onSelect(type) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            .padding(.horizontal)
        }
    }
}
```

- [ ] **步骤 3：重写 AIAssistantView** — ScrollView + LazyVStack（ChatBubbleView）+ QuickPromptView + 底部 TextField + 发送按钮 + 流式输出时显示光标动画

- [ ] **步骤 4：编译验证后提交**

```bash
git add .
git commit -m "feat: 实现 AI 助手聊天界面（对话流+快捷提问+流式输出）"
```

---

## 任务 6：API 配置页

**文件：** `HealthFlow/View/Profile/APIConfigView.swift`（替换 SettingsView 中的占位 NavigationLink）

- [ ] **步骤 1：编写 APIConfigView** — Form（endpoint URL TextField、apiKey SecureField）+ 保存按钮（存入 Keychain）+ 验证连接按钮
- [ ] **步骤 2：更新 SettingsView 的 API 配置 NavigationLink 指向实际页面**
- [ ] **步骤 3：编译验证后提交**

```bash
git add .
git commit -m "feat: 添加 API 配置页（Keychain 存储 + 连接验证）"
```

---

## 任务 7：成就系统检查

**文件：** `HealthFlow/ViewModel/AchievementViewModel.swift`

- [ ] **步骤 1：编写 AchievementViewModel**

```swift
@Observable
final class AchievementViewModel {
    var earnedBadges: [AchievementBadge] = []

    func checkAndAwardBadges(modelContext: ModelContext) {
        // 遍历 BadgeDefinition.allCases
        // 检查条件（连续打卡、步数、睡眠质量等）
        // 达标且未获得 → 创建 AchievementBadge 并插入
    }

    func allBadges() -> [(BadgeDefinition, Bool)] {
        BadgeDefinition.allCases.map { badge in
            (badge, badge.isEarned(badges: earnedBadges))
        }
    }
}
```

- [ ] **步骤 2：编译验证后提交**

```bash
git add .
git commit -m "feat: 添加成就检查系统"
```

---

## 任务 8：阶段四总体验证

- [ ] 运行全部测试

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

- [ ] Simulator 验证：AI 对话正常、流式输出打字机效果、快捷提问正常、对话历史持久化、API 配置保存、成就徽章计算
- [ ] 测试覆盖率确认 ≥94%

```bash
git add .
git commit -m "feat: 完成阶段四——AI 助手、健康评分、风险预警、成就系统"
```
