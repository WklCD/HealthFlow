# HealthFlow Design Specification

**项目名称**：HealthFlow（个人健康数据管理与可视化软件）

**日期**：2026-04-29（v2 — 审查修复版）

**平台**：iOS 17+，macOS + Xcode 开发

**架构模式**：MVVM（Model-View-ViewModel）

**技术栈**：Swift + SwiftUI + SwiftData + Swift Charts + HealthKit + 国产大模型 API

---

## 一、项目概述与目标

从零开发一个运行在 iOS 移动端的个人健康数据管理与可视化软件。纯本地存储，不上传云端，确保数据隐私。支持 HealthKit 自动读取 + 手动录入混合模式。

### 核心原则

- 所有数据存储在设备本地（SwiftData），无服务端
- 无登录注册机制，直接进入 App
- 以 HealthKit 自动采集为主，手动录入为辅
- 采用 MVVM 架构，ViewModel 与 View 分离，便于测试
- 严格遵循 TDD（RED-GREEN-REFACTOR）开发流程
- 测试覆盖率：简单任务 ≥85%，中等任务 ≥91%，复杂任务 ≥94%

---

## 二、阶段划分

| 阶段 | 子项目 | 核心内容 |
|------|--------|----------|
| **第一阶段** | 基础框架 + 用户中心 | 项目脚手架、MVVM 架构搭建、数据模型定义、个人档案管理、设置页面、食物营养数据库骨架 |
| **第二阶段** | 健康数据采集 | 运动、睡眠、饮食、生理指标的数据录入与管理，HealthKit 集成与数据同步 |
| **第三阶段** | 数据可视化 | 健康仪表盘首页、图表系统（Swift Charts）、健康报告生成 |
| **第四阶段** | 智能分析 | 健康评分系统、风险预警、AI 健康建议（国产大模型） |
| **第五阶段** | 数据安全与精修 | 隐私锁（Face ID/Touch ID）、数据导出、成就徽章、UI/UX 精修 |

> 每个阶段完成后需经过规格合规性审查和代码质量审查后方可进入下一阶段。

---

## 三、导航结构

**模式**：TabBar（4 个标签）+ 每 Tab 内 NavigationStack 层级导航

| Tab | 名称 | 功能 |
|-----|------|------|
| 1 | **仪表盘** | 今日概览、健康评分数、关键指标卡片网格、分时趋势图、异常提醒 |
| 2 | **健康数据** | 按类别浏览（运动/睡眠/饮食/生理指标/用药），每页右上角「+」添加按钮进入详情与录入 |
| 3 | **AI 助手** | 对话式 AI 交互，基于用户健康数据给出智能建议，快捷提问入口 |
| 4 | **我的** | 个人档案、健康报告、数据导出、成就徽章、设置（隐私锁/API 配置/主题/备份） |

---

## 四、SwiftData 数据模型

### 1. UserProfile（用户档案 — 全局单例）

```swift
@Model
final class UserProfile {
    var name: String = ""
    var gender: String = "unset"      // "unset" / "male" / "female" / "other"
    var birthDate: Date = Date()      // 出生日期，年龄动态计算
    var height: Double = 0            // 身高（cm）
    var targetWeight: Double?         // 目标体重（kg）
    var targetSteps: Int?             // 每日步数目标
    var targetSleepHours: Double?     // 每日睡眠时长目标（小时）
    var targetCalories: Int?          // 每日卡路里目标（kcal）
    var createdAt: Date = Date()
}
```

**单例创建策略**：

UserProfile 在 App 中全局唯一。创建和读取策略如下：

- 在 `HealthFlowApp` 的 `ModelContainer` 初始化回调中，自动检查是否存在 UserProfile 记录
- 如果不存在，自动创建一条默认记录（name=""，gender="unset"，其余为默认值）
- 如果已存在，直接使用
- 使用 `@Attribute(.unique)` 不适用此场景（单条记录无需唯一约束），而是通过 ViewModel 层的 `fetchFirst()` 方法确保唯一性
- 用户误删场景：在 ProfileViewModel 中同样检测空数据时自动重建默认记录

```swift
// ModelContainer 配置示例
let container = try ModelContainer(for: UserProfile.self, ...)
let context = container.mainContext
if context.fetch(FetchDescriptor<UserProfile>().first == nil) {
    context.insert(UserProfile())
}
```

### 2. DailyActivitySummary（每日活动聚合）

> 修复说明：原 ExerciseRecord 同时存储「每日累计步数」和「单次运动会话」，语义冲突。现拆分为两个独立模型。

```swift
@Model
final class DailyActivitySummary {
    var date: Date = Date()               // 当天日期（精确到日）
    var steps: Int = 0                    // 总步数
    var calories: Double = 0              // 总消耗卡路里（kcal）
    var distance: Double = 0              // 总行走/跑步距离（米）
    var standHours: Int?                  // 站立小时数（Apple Watch）
    var source: String = "healthkit"      // "healthkit" / "manual"
    @Attribute(.unique) var healthKitUUID: String?  // HealthKit 唯一标识，用于去重
    var note: String?
}
```

> 说明：DailyActivitySummary 由 HealthKit 的 `.stepCount`、`.activeEnergyBurned`、`.distanceWalkingRunning` 等按天聚合统计值映射。手动录入时用于补充修正某天的总步数/卡路里。

### 3. WorkoutRecord（单次运动会话）

```swift
@Model
final class WorkoutRecord {
    var exerciseType: String = ""         // "walking" / "running" / "cycling" / "swimming" / "other"
    var startTime: Date = Date()
    var endTime: Date = Date()
    var duration: TimeInterval = 0        // 运动时长（秒）
    var calories: Double = 0              // 本次消耗卡路里（kcal）
    var steps: Int?                       // 本次步数
    var distance: Double?                 // 本次距离（米）
    var heartRateAvg: Double?             // 平均心率（bpm）
    var heartRateMax: Double?             // 最大心率（bpm）
    var source: String = "manual"         // "healthkit" / "manual"
    @Attribute(.unique) var healthKitUUID: String?  // HealthKit 唯一标识，用于去重
    var note: String?
}
```

> 说明：WorkoutRecord 由 HealthKit 的 `.workoutType()` 映射，每条对应一次独立运动。手动录入时记录用户自行添加的运动会话。

### 4. SleepRecord（睡眠记录）

```swift
@Model
final class SleepRecord {
    var startTime: Date = Date()
    var endTime: Date = Date()
    var duration: TimeInterval = 0        // 总睡眠时长（秒）
    var deepSleep: TimeInterval?          // 深睡时长（秒）
    var remSleep: TimeInterval?           // REM 睡眠时长（秒）
    var quality: Int = 0                  // 睡眠质量评分 1-5
    var source: String = "manual"         // "healthkit" / "manual"
    @Attribute(.unique) var healthKitUUID: String?  // HealthKit 唯一标识，用于去重
    var note: String?
}
```

### 5. DietRecord（饮食记录）+ FoodItem（食物条目）

> 修复说明：(1) 移除冗余汇总字段（totalCalories 等），改用 @Transient 计算属性动态聚合，消除数据不一致风险；(2) imageData 改为 imagePath 文件路径引用，避免 SwiftData 数据库膨胀。

```swift
@Model
final class DietRecord {
    var mealType: String = ""             // "breakfast" / "lunch" / "dinner" / "snack"
    var timestamp: Date = Date()
    var imagePath: String?                // 食物照片文件路径（存于 App Documents 目录）
    var source: String = "manual"
    @Relationship(deleteRule: .cascade) var foodItems: [FoodItem]? = []

    @Transient
    var totalCalories: Double {
        foodItems?.reduce(0) { $0 + $1.calories } ?? 0
    }

    @Transient
    var totalProtein: Double {
        foodItems?.reduce(0) { $0 + $1.protein } ?? 0
    }

    @Transient
    var totalCarbs: Double {
        foodItems?.reduce(0) { $0 + $1.carbs } ?? 0
    }

    @Transient
    var totalFat: Double {
        foodItems?.reduce(0) { $0 + $1.fat } ?? 0
    }
}

@Model
final class FoodItem {
    var name: String = ""
    var amount: Double = 0                // 份量数值
    var unit: String = "份"              // 份/克/毫升
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
}
```

**照片存储策略**：

- 饮食照片存入 App Documents 目录下的 `FoodImages/` 子目录
- ⚠️ **SwiftData 懒加载注意**：`@Transient` 计算属性（totalCalories 等）依赖 `@Relationship` 的 `foodItems`。SwiftData 默认懒加载 Relationship，在访问计算属性前必须确保 `foodItems` 已加载。在 ViewModel 层查询 DietRecord 时，应使用 `FetchDescriptor` 的 `relationshipPath` 配置或在访问前显式访问 `foodItems` 属性触发加载。
- 文件名使用 `UUID().uuidString.jpg`，确保唯一性
- DietRecord 中只存 `imagePath: String?`（文件路径引用）
- 删除 DietRecord 时，同步删除对应照片文件（在 ViewModel 层处理）
- 照片在存储前压缩至最大 1024×1024 像素，降低存储空间占用

### 6. PhysiologicalMetric（生理指标）

> 修复说明：(1) 血压不再拆成两条记录，改为在同一条记录中存储收缩压和舒张压，确保关联性；(2) 添加 `measurementGroupID` 字段，用于将同一次测量的多个不同类型指标（如同时测的体温+心率）关联起来；(3) 添加 `healthKitUUID` 唯一标识。

```swift
@Model
final class PhysiologicalMetric {
    var metricType: String = ""           // "weight" / "heartRate" / "bloodOxygen" /
                                          // "bodyTemperature" / "bloodPressure" /
                                          // "bloodGlucose" / ...
    var value: Double = 0                 // 单值指标：体重、心率、血氧、体温、血糖等
    var valueSystolic: Double?            // 血压收缩压（mmHg），仅 metricType == "bloodPressure" 时有效
    var valueDiastolic: Double?           // 血压舒张压（mmHg），仅 metricType == "bloodPressure" 时有效
    var unit: String = ""                 // "kg" / "bpm" / "%" / "°C" / "mmHg" / "mmol/L"
    var timestamp: Date = Date()
    var source: String = "manual"         // "healthkit" / "manual"
    @Attribute(.unique) var healthKitUUID: String?  // HealthKit 唯一标识，用于去重
    var measurementGroupID: String?       // 同一次测量的关联标识（如同时测血压+心率）
    var note: String?
}
```

**血压存储规则**：

- 当 `metricType == "bloodPressure"` 时，必须同时填写 `valueSystolic` 和 `valueDiastolic`
- `value` 字段在血压场景下存储收缩压（与 `valueSystolic` 相同），便于按单一字段排序和查询
- 其他指标类型只使用 `value` 字段，`valueSystolic`/`valueDiastolic` 为 nil

**measurementGroupID 规则**：

- 每次测量会话生成一个 `UUID().uuidString` 作为 groupID
- 同一次体检或测量中产生的多个指标（如同时量了体温、心率、血压）共享同一个 groupID
- 单独录入的指标 groupID 为 nil
- HealthKit 同步的数据，根据采样时间窗口（±5 分钟内相同类型）自动生成 groupID

### 7. AchievementBadge（成就徽章）+ BadgeDefinition（徽章定义）

> 修复说明：增加 BadgeDefinition 枚举定义所有可能的徽章类型和获取条件，UI 层合并定义列表和已获得列表来展示完整徽章页（已获得 ✅ + 未获得 🔒）。

```swift
@Model
final class AchievementBadge {
    var badgeType: String = ""            // 对应 BadgeDefinition 的 rawValue
    var title: String = ""
    var earnedDate: Date = Date()
}
```

```swift
enum BadgeDefinition: String, CaseIterable {
    case streak7Days = "streak_7days"         // 连续打卡 7 天
    case streak30Days = "streak_30days"       // 连续打卡 30 天
    case steps10000 = "steps_10000"           // 单日万步
    case perfectSleep = "perfect_sleep"       // 睡眠质量 5 分
    case calorieGoalMet = "calorie_goal_met"  // 达成卡路里目标
    case exercise5Times = "exercise_5times"   // 本周运动 5 次
    case earlyBird = "early_bird"             // 连续 3 天 6:00 前起床

    var title: String {
        switch self {
        case .streak7Days: return "坚持不懈"
        case .streak30Days: return "习惯养成"
        case .steps10000: return "万步达人"
        case .perfectSleep: return "完美睡眠"
        case .calorieGoalMet: return "目标达成"
        case .exercise5Times: return "运动健将"
        case .earlyBird: return "早起之星"
        }
    }

    var description: String {
        switch self {
        case .streak7Days: return "连续7天记录健康数据"
        case .streak30Days: return "连续30天记录健康数据"
        case .steps10000: return "单日步数达到10,000步"
        case .perfectSleep: return "睡眠质量评分达到5分"
        case .calorieGoalMet: return "达成每日卡路里目标"
        case .exercise5Times: return "本周完成5次运动"
        case .earlyBird: return "连续3天在6:00前起床"
        }
    }

    var iconName: String {
        switch self {
        case .streak7Days: return "flame.fill"
        case .streak30Days: return "medal.fill"
        case .steps10000: return "figure.walk"
        case .perfectSleep: return "moon.stars.fill"
        case .calorieGoalMet: return "flame.circle.fill"
        case .exercise5Times: return "dumbbell.fill"
        case .earlyBird: return "sunrise.fill"
        }
    }

    func isEarned(badges: [AchievementBadge]) -> Bool {
        badges.contains { $0.badgeType == self.rawValue }
    }
}
```

> BadgeDefinition 是纯 Swift enum（非 SwiftData 模型），作为配置定义。UI 层遍历 `BadgeDefinition.allCases`，对每个定义检查是否在已获得列表中，渲染已获得/未获得状态。

### 8. MedicationRecord（用药记录）

> 修复说明：补充 `source` 和 `note` 字段，保持与其他模型的一致性。

```swift
@Model
final class MedicationRecord {
    var name: String = ""
    var dosage: String = ""
    var scheduledTime: Date = Date()
    var takenAt: Date?
    var source: String = "manual"         // 保持一致性（未来可能接入 HealthKit 用药数据）
    var note: String?                     // 备注（如"饭后服用""与上次间隔8小时"）
}
```

### 9. ChatMessage（AI 对话消息 — 持久化）

> 修复说明：新增 SwiftData 模型持久化对话历史，确保 App 重启后对话不丢失。

```swift
@Model
final class ChatMessage {
    var role: String = ""                 // "user" / "assistant"
    var content: String = ""
    var timestamp: Date = Date()
    var promptType: String?               // QuickPromptType rawValue（仅 assistant 消息标记）
}
```

### 模型关系图

```
UserProfile (全局唯一单例)
  │ 各记录模型不持有 Profile 外键，
  │ 通过 SwiftData Query 按日期范围关联查询
  │
  ├── DailyActivitySummary   ← 每日聚合统计（步数/卡路里/距离）
  ├── WorkoutRecord          ← 单次运动会话
  ├── SleepRecord
  ├── DietRecord ──→ FoodItem (1:N, cascade delete)
  ├── PhysiologicalMetric    ← 含血压双值、measurementGroupID
  ├── AchievementBadge       ← 配合 BadgeDefinition 枚举使用
  ├── MedicationRecord
  └── ChatMessage            ← AI 对话历史持久化
```

> 说明：(1) 由于只有一位本地用户，各记录模型无需显式外键关联 UserProfile；(2) DailyActivitySummary 与 WorkoutRecord 是不同粒度的运动数据，前者按天聚合，后者按次记录；(3) PhysiologicalMetric 的 measurementGroupID 用于关联同一次测量的多个指标；(4) BadgeDefinition 是纯 enum，不持久化。

### SwiftData 关键使用规范

| 要点 | 说明 |
|------|------|
| `@Model` 宏 | 自动持久化，生成 PersistentModel 协议实现 |
| `@Attribute(.unique)` | 所有 HealthKit 同步的模型必须有 `healthKitUUID` 字段并标记 `.unique`，用于去重 |
| `@Relationship(deleteRule: .cascade)` | 删除父记录时级联删除子记录（DietRecord → FoodItem） |
| `@Transient` | 标记不持久化的计算属性（如 DietRecord 的 totalCalories） |
| `ModelContainer` | 全局容器，在 App 入口 `modelContainer(for:)` 注入，启动时确保 UserProfile 单例存在 |
| `ModelContext` | 通过 `@Environment(\.modelContext)` 获取，用于 CRUD 操作 |
| `#Predicate` 宏 | 类型安全查询，如 `#Predicate<WorkoutRecord> { $0.exerciseType == "running" }` |
| Enum 存储 | SwiftData 不支持 Swift enum，统一用 String rawValue 映射 |
| 照片存储 | 大二进制数据（照片）存文件系统，Model 中只存路径引用 |

---

## 五、各模块页面设计

### 5.1 仪表盘 Tab（首页）

```
┌─────────────────────────────────┐
│  📅 2026年4月29日 周二           │
│       今日健康指数：85分          │
│  ┌─────────────────────────────┐ │
│  │ 🏃 运动        睡眠 💤      │ │
│  │ 8,200步/万步   7h 23m       │ │
│  │ 320千卡       质量 ★★★★☆  │ │
│  │ 🔥 饮食        心率 ❤️      │ │
│  │ 1850/2000千卡  72 bpm       │ │
│  │ 蛋白65g碳水200g脂50g       │ │
│  └─────────────────────────────┘ │
│  ┌─ 今日趋势 ─────────────────┐  │
│  │  步数折线图（今日分时）    │  │
│  │  📈 ──────────────         │  │
│  └────────────────────────────┘  │
│  ┌─ 异常提醒 ─────────────────┐  │
│  │ ⚠️ 昨日睡眠仅5.2h,低于目标 │  │
│  │       [忽略此提醒]          │  │
│  └────────────────────────────┘  │
└─────────────────────────────────┘
```

**功能要点**：
- 顶部日期 + 今日健康评分
- 2×2 卡片网格展示四个核心指标摘要（运动取 DailyActivitySummary，心率取 PhysiologicalMetric）
- 今日分时趋势图（Swift Charts 折线图）
- 异常提醒卡片（如未达标指标），每条提醒支持「忽略此提醒」操作
- 向下滑动可查看昨日摘要

### 5.2 健康数据 Tab

```
┌─────────────────────────────────┐
│  健康数据                        │
│  ┌─ 运动 ─────────────────────┐  │
│  │ 📊 本周：5次 | 32,500步    │  │
│  └────────────────────────────┘  │
│  ┌─ 睡眠 ─────────────────────┐  │
│  │ 📊 本周均：7.1h | 质量4.0  │  │
│  └────────────────────────────┘  │
│  ┌─ 饮食 ─────────────────────┐  │
│  │ 📊 今日：1850千卡          │  │
│  └────────────────────────────┘  │
│  ┌─ 生理指标 ─────────────────┐  │
│  │ 📊 体重72kg | 心率72bpm    │  │
│  └────────────────────────────┘  │
│  ┌─ 用药记录 ─────────────────┐  │
│  │ 📊 今日1次 | 已提醒 ✅     │  │
│  └────────────────────────────┘  │
└─────────────────────────────────┘
```

**功能要点**：
- 按类别分组列表，显示本周/今日摘要
- 点击进入详情页（日历视图 + 记录列表）
- 详情页右上角「+」按钮添加新记录
- 支持按日/周/月/年筛选
- 运动详情页展示两层：每日聚合（DailyActivitySummary）+ 单次运动列表（WorkoutRecord）
- 睡眠详情展示入睡/起床时间、深睡/REM 分布、备注
- 饮食详情展示每餐的食物清单和营养成分（从 FoodItem 动态聚合计算）
- 饮食录入支持从食物营养数据库搜索选择
- 生理指标详情展示各指标的趋势图和记录列表，血压展示双值
- 用药详情展示用药历史和提醒管理

### 5.3 AI 助手 Tab

```
┌─────────────────────────────────┐
│  🤖 AI 健康助手                  │
│  ┌─────────────────────────────┐ │
│  │ 💬 你本周运动趋势怎么样？   │ │
│  │   - 用户                    │ │
│  │ 💬 本周你共运动4次，步数    │ │
│  │   累计28,500步，比上周少了  │ │
│  │   8%。建议周末增加一次有氧  │ │
│  │   运动来追上周目标。        │ │
│  │   - AI助手                  │ │
│  └─────────────────────────────┘ │
│  ┌─────────────────────────────┐ │
│  │ 💡 快捷提问：              │  │
│  │ [今日总结] [本周趋势]       │  │
│  │ [饮食建议] [运动计划]       │  │
│  └─────────────────────────────┘ │
│  ┌─────────────────────────────┐ │
│  │ 输入问题...            📎  📤│ │
│  └─────────────────────────────┘ │
└─────────────────────────────────┘
```

**功能要点**：
- 对话式聊天界面，历史消息持久化（ChatMessage SwiftData 模型）
- 快捷提问按钮：今日总结、本周趋势、饮食建议、运动计划
- 每次提问自动注入近 7 天健康数据摘要作为 AI 上下文
- AI 返回基于用户真实数据的个性化建议
- 支持流式输出（打字机效果），国产大模型 API
- API Key 在「我的 → 设置 → API 配置」中配置，存入 Keychain
- 支持清除对话历史

### 5.4 我的 Tab

```
┌─────────────────────────────────┐
│  我的                            │
│  ┌─ 👤 个人档案 ──────────────┐ │
│  └─ 📊 健康报告 ──────────────┐ │
│  ┌─ 📤 数据导出 ──────────────┐ │
│  └─ 🏆 成就徽章 ──────────────┐ │
│  ┌─ ⚙️  设置 ──────────────────┐ │
│  │   🔒 隐私锁                 │ │
│  │   🔑 API配置               │ │
│  │   🌙 深色模式               │ │
│  │   🔄 数据备份/恢复         │ │
│  │   ℹ️  关于                  │ │
│  └─────────────────────────────┘ │
└─────────────────────────────────┘
```

**子页面说明**：
- **个人档案**：编辑姓名、性别、出生日期、身高、健康目标
- **健康报告**：选择日期范围生成周报/月报，包含指标汇总、图表、AI 建议摘要，可导出为 PDF
- **数据导出**：选择数据类型和日期范围，导出 CSV 或 JSON，通过系统分享面板发送
- **成就徽章**：展示完整徽章页（已获得 ✅ + 未获得 🔒），基于 BadgeDefinition.allCases 和 AchievementBadge 记录合并渲染
- **隐私锁**：开关 Face ID / Touch ID 验证，含截图防护说明
- **API 配置**：配置大模型 API Key、Endpoint
- **深色模式**：跟随系统 / 浅色 / 深色 三种选项
- **数据备份/恢复**：手动备份 SwiftData 存储到文件，从文件恢复

---

## 六、食物营养数据库设计

> 修复说明：饮食是唯一不走 HealthKit 自动采集的数据类别，手动录入体验至关重要。需要本地食物营养数据库支持快速搜索和选择。

### 架构

```
FoodDatabaseService
├── search(query: String) → [FoodDefinition]
├── getCategory(category: FoodCategory) → [FoodDefinition]
├── getFavorites() → [FoodDefinition]
├── addFavorite(food: FoodDefinition)
└── removeFavorite(food: FoodDefinition)

FoodDefinition（非 SwiftData 模型，纯数据结构）
├── name: String              // "鸡蛋" / "牛奶" / ...
├── category: FoodCategory    // "protein" / "grain" / "vegetable" / ...
├── defaultUnit: String       // "个" / "杯" / "克"
├── defaultAmount: Double     // 1个 / 1杯 / 100克
├── caloriesPerUnit: Double
├── proteinPerUnit: Double
├── carbsPerUnit: Double
├── fatPerUnit: Double
```

### 数据来源

- 内置 200+ 常见中国食物的基础营养信息（JSON 文件打包在 App Bundle 中）
- 食物按类别分组：主食、蛋白质、蔬菜、水果、奶制品、零食、饮品
- 支持搜索和按类别浏览
- 用户可收藏常用食物（收藏列表存 UserDefaults 或单独 SwiftData 模型）
- 选择食物后自动填充营养数据到 FoodItem，用户可修改份量

### FavoriteFood（收藏食物）

```swift
@Model
final class FavoriteFood {
    var foodName: String = ""
    var category: String = ""
    var defaultUnit: String = ""
    var caloriesPerUnit: Double = 0
    var proteinPerUnit: Double = 0
    var carbsPerUnit: Double = 0
    var fatPerUnit: Double = 0
    var addedAt: Date = Date()
}
```

---

## 七、HealthKit 集成设计

### 架构

```
HealthKitManager（单例，实现 HealthKitProtocol）
├── requestAuthorization() async throws -> Bool
├── fetchDailyActivity(from: Date, to: Date) async throws -> [DailyActivitySummary]
├── fetchWorkouts(from: Date, to: Date) async throws -> [WorkoutRecord]
├── fetchSleep(from: Date, to: Date) async throws -> [SleepRecord]
├── fetchWeight(from: Date, to: Date) async throws -> [PhysiologicalMetric]
├── fetchHeartRate(from: Date, to: Date) async throws -> [PhysiologicalMetric]
├── fetchBloodOxygen(from: Date, to: Date) async throws -> [PhysiologicalMetric]
├── fetchBodyTemperature(from: Date, to: Date) async throws -> [PhysiologicalMetric]
├── fetchBloodPressure(from: Date, to: Date) async throws -> [PhysiologicalMetric]
├── fetchBloodGlucose(from: Date, to: Date) async throws -> [PhysiologicalMetric]
└── observeChanges() → 监听 HKObserverQuery 回调

SyncEngine
├── syncAll(daysBack: Int) → 后台同步历史数据
├── deduplicateHealthKitRecords<T>(existing: [T], newUUIDs: Set<String>) → 去重逻辑
└── scheduleBackgroundRefresh() → 注册后台任务
```

### 读取的 HealthKit 数据类型

| 类型 | HKQuantityType | 映射模型 |
|------|----------------|----------|
| 步数 | `.stepCount` | DailyActivitySummary |
| 运动能量 | `.activeEnergyBurned` | DailyActivitySummary |
| 运动距离 | `.distanceWalkingRunning` | DailyActivitySummary |
| 运动 | `.workoutType()` | WorkoutRecord |
| 睡眠分析 | `.categoryType(forIdentifier: .sleepAnalysis)` | SleepRecord |
| 体重 | `.bodyMass` | PhysiologicalMetric |
| 心率 | `.heartRate` | PhysiologicalMetric |
| 血氧 | `.oxygenSaturation` | PhysiologicalMetric |
| 体温 | `.bodyTemperature` | PhysiologicalMetric |
| 血压 | `.bloodPressureSystolic` + `.bloodPressureDiastolic` | PhysiologicalMetric (metricType="bloodPressure") |
| 血糖 | `.bloodGlucose` | PhysiologicalMetric |

> 修复说明：(1) 步数/卡路里/距离不再映射到 WorkoutRecord，改为映射到 DailyActivitySummary；(2) 血压合并为一条 PhysiologicalMetric 记录，同时包含收缩压和舒张压。

### 测试抽象

`HealthKitManager` 需实现 `HealthKitProtocol` 协议，便于在 ViewModel 和 Service 测试中注入 Mock 实现：

```swift
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
}
```

### 同步策略

1. **首次启动**：请求所有类型授权 → 静默拉取 7 天历史数据 → 存入 SwiftData
2. **运行时**：通过 `HKObserverQuery` 监听 HealthKit 数据变化，增量同步
3. **去重**：所有 HealthKit 同步的模型必须有 `healthKitUUID` 字段（`@Attribute(.unique)`），在插入前检查是否已存在相同 UUID 的记录，存在则跳过；手动记录 `source = "manual"`，healthKitUUID 为 nil
4. **后台更新**：通过 `HKAnchoredObjectQuery` 获取增量数据

### 权限请求

- 分批请求而非一次性全部弹出，减少用户拒绝概率
- 请求前展示说明页面解释各权限用途
- 如果用户拒绝，在健康数据页面提供「重新授权」入口

---

## 八、AI 助手集成设计

### 架构

```
AIService（实现 AIServiceProtocol）
├── configure(apiKey: String, endpoint: String)
├── sendMessage(prompt: String, context: HealthContext) → AsyncStream<String>
├── generateQuickPrompt(type: QuickPromptType) → String
└── clearHistory()

AIAssistantViewModel
├── messages: [ChatMessage]          ← 从 SwiftData Query 获取
├── sendMessage(_ text: String)
├── sendQuickPrompt(_ type: QuickPromptType)
└── clearConversation()              ← 删除 SwiftData 中所有 ChatMessage
```

### 上下文注入

每次发送消息时，自动构建健康上下文注入到 System Prompt：

```
你是一位专业的健康顾问。以下是用户近7天的健康数据摘要：

运动：共4次运动，总步数28,500步，消耗1,200千卡
睡眠：平均7.1小时/晚，平均质量4.0/5
饮食：平均每日摄入1,950千卡
体重：72kg（稳定）
心率：静息68bpm

请基于以上数据回答问题。
```

### 流式输出

- 使用 `AsyncStream<String>` 逐 token 接收 AI 响应
- SwiftUI 中逐字追加到 ChatMessage，呈现打字机效果
- 支持中途取消（用户点击停止按钮）
- 完整响应完成后，将最终内容写入 ChatMessage SwiftData 模型持久化

### 快捷提问类型

```swift
enum QuickPromptType: String {
    case todaySummary = "today_summary"       // 今日总结
    case weeklyTrend = "weekly_trend"         // 本周趋势
    case dietAdvice = "diet_advice"           // 饮食建议
    case exercisePlan = "exercise_plan"       // 运动计划
    case sleepAnalysis = "sleep_analysis"     // 睡眠分析
    case healthWarning = "health_warning"     // 风险预警
}
```

### AIServiceProtocol（测试抽象）

```swift
protocol AIServiceProtocol {
    func configure(apiKey: String, endpoint: String)
    func sendMessage(prompt: String, context: HealthContext) -> AsyncStream<String>
    func generateQuickPrompt(type: QuickPromptType) -> String
}
```

### 数据安全

- API Key 存储在 iOS Keychain 中，不落盘明文
- 只发送聚合摘要数据，不发送原始记录
- 所有 AI 请求在用户设备上发起，数据不上传其他服务

---

## 九、隐私锁设计

### 流程

```
App 启动
  └→ PrivacyLockView（全屏覆盖）
       ├── 检查隐私锁是否启用
       │   ├── 未启用 → 直接进入 MainTabView
       │   └── 已启用 → 触发生物识别
       ├── Face ID / Touch ID 验证
       │   ├── 成功 → 进入 MainTabView
       │   └── 失败 → 重试（最多3次）→ fallback 设备密码
       └── App 进入后台 → 隐藏内容，显示纯色 + Logo → 返回前台重新验证
```

> 修复说明：App 进入后台时不仅覆盖模糊层，而是将内容完全替换为纯色背景 + App Logo，防止 iOS 截图和多任务切换界面的内容泄露。

### 技术实现

- 使用 `LocalAuthentication` 框架的 `LAContext`
- `evaluatePolicy(.deviceOwnerAuthentication)` 触发 Face ID / Touch ID
- `Info.plist` 配置 `NSFaceIDUsageDescription` 权限描述
- App 生命周期监听 `scenePhase` 变化：
  - 进入 `.inactive`/`.background` 时，替换界面为纯色背景 + App Logo（非模糊覆盖）
  - 返回 `.active` 时，如果隐私锁启用，重新触发生物识别验证
- 设置中开关隐私锁，修改 UserDefaults 标志位
- 截图防护：界面替换为纯色而非模糊层，确保截图和多任务卡片中不显示任何数据

---

## 十、数据导出设计

### CSV 导出

- 选择数据类型（运动/睡眠/饮食/生理指标）
- 选择日期范围
- 将 SwiftData 记录序列化为 CSV 行
- 通过 `ShareLink` 或 `UIActivityViewController` 分享文件

### PDF 健康报告

```
健康报告结构：
1. 封面：姓名、日期范围、生成时间
2. 基本信息：年龄、性别、身高、体重
3. 运动数据：统计表格 + 趋势折线图（含 DailyActivitySummary + WorkoutRecord）
4. 睡眠数据：统计表格 + 趋势折线图
5. 饮食数据：统计表格 + 营养分布饼图（动态聚合 FoodItem）
6. 生理指标：统计表格 + 趋势图（血压展示双值）
7. AI 健康建议摘要
```

### 技术实现

- PDF：使用 `ImageRenderer` 将 SwiftUI 报告视图渲染为 PDF
- CSV：`Codable` + 枚举字段头，手动拼接或使用 CSV 编码工具
- 文件临时写入 `NSTemporaryDirectory()`，通过系统分享面板发送
- 饮食照片导出：如果 DietRecord 有 imagePath，导出 CSV 中包含照片文件路径引用

---

## 十一、健康评分系统设计

### 评分维度（满分 100 分）

| 维度 | 权重 | 数据来源 |
|------|------|----------|
| 运动达成率 | 25% | 今日 DailyActivitySummary 步数 / 目标步数 |
| 睡眠质量 | 25% | 睡眠时长 / 目标时长 + 质量评分 |
| 饮食达标率 | 20% | 卡路里摄入是否在目标范围内（DietRecord 动态聚合） |
| 生理指标正常度 | 20% | 心率、血压、体重等是否在正常范围 |
| 活跃天数 | 10% | 近 7 天有记录的活跃天数 |

### 风险预警规则

> 修复说明：增加「忽略提醒」功能和自定义阈值设置，避免频繁误报导致用户忽略所有提醒。

**预警触发条件**：

- 连续 3 天睡眠 < 6 小时 → 触发睡眠不足预警
- 心率静息 > 100 或 < 50 → 触发心率异常预警
- 体重月变化 > 5% → 触发体重异常预警
- 近 7 天无运动记录 → 触发久坐预警
- 血压超出正常范围 → 触发血压预警

**预警交互规则**：

- 每条预警支持「忽略此提醒」操作，忽略后该条不再弹出，但保留在预警历史列表中
- 预警历史列表在「我的 → 设置 → 预警管理」中可查看
- 预警阈值可在设置中自定义（如将睡眠不足阈值从 6h 调整为 5h）
- 同一类型预警 7 天内只触发一次，避免重复提醒

```swift
@Model
final class IgnoredAlert {
    var alertType: String = ""         // "sleep_deficit" / "heart_rate_abnormal" / ...
    var triggeredDate: Date = Date()
    var ignoredDate: Date = Date()
}
```

---

## 十二、测试策略

### 测试框架

- **Swift Testing**（iOS 17+ 主框架）用于新测试
- **XCTest** 用于需要与 XCTest 生态兼容的测试（如 UI 测试）

### 覆盖率目标

| 复杂度 | 目标 | 示例 |
|--------|------|------|
| 简单 | ≥85% | 数据模型初始化验证、工具函数、格式化扩展、BadgeDefinition 枚举 |
| 中等 | ≥91% | HealthKit Service、数据同步去重、ViewModel 业务逻辑、食物数据库搜索 |
| 复杂 | ≥94% | AI 会话管理（Mock）、健康评分算法、报告生成、血压双值处理 |

### 分层测试

| 层 | 测试方式 | 工具 |
|-----|----------|------|
| Model | 纯单元测试，验证初始化、计算属性（如 DietRecord.totalCalories） | Swift Testing |
| ViewModel | 注入 Mock Service（HealthKitProtocol/AIServiceProtocol），验证状态变化和数据转换 | Swift Testing |
| Service | Protocol 抽象 + Mock 实现，验证业务逻辑 | Swift Testing |
| View | 有限 UI 测试，验证关键用户流程 | XCTest UI Tests |

### TDD 流程

每个功能严格遵循 RED → GREEN → REFACTOR：
1. **RED**：先写失败的测试
2. **GREEN**：写最小实现让测试通过
3. **REFACTOR**：重构代码，保持测试绿色

---

## 十三、项目文件结构

```
HealthFlow/
├── HealthFlowApp.swift              # @main App 入口，注入 ModelContainer，确保 UserProfile 单例
├── Model/
│   ├── UserProfile.swift
│   ├── DailyActivitySummary.swift
│   ├── WorkoutRecord.swift
│   ├── SleepRecord.swift
│   ├── DietRecord.swift
│   ├── FoodItem.swift
│   ├── PhysiologicalMetric.swift
│   ├── AchievementBadge.swift
│   ├── MedicationRecord.swift
│   ├── ChatMessage.swift
│   ├── FavoriteFood.swift
│   └── IgnoredAlert.swift
├── Definition/
│   ├── BadgeDefinition.swift        # 枚举：徽章类型和获取条件
│   ├── MetricType.swift             # 枚举：生理指标类型和单位映射
│   ├── ExerciseType.swift           # 枚举：运动类型
│   ├── MealType.swift               # 枚举：餐次类型
│   └── QuickPromptType.swift        # 枚举：AI 快捷提问类型
├── View/
│   ├── MainTabView.swift            # TabBar 容器
│   ├── Dashboard/
│   │   ├── DashboardView.swift      # 仪表盘首页
│   │   ├── HealthScoreCard.swift    # 健康评分卡片
│   │   ├── MetricGridCard.swift     # 指标网格
│   │   └── TodayTrendChart.swift    # 今日分时趋势图
│   │   └── AlertCard.swift          # 异常提醒卡片（含忽略按钮）
│   ├── HealthData/
│   │   ├── HealthDataListView.swift # 健康数据列表
│   │   ├── ActivityDetailView.swift # 每日活动聚合详情
│   │   ├── WorkoutDetailView.swift  # 单次运动详情
│   │   ├── SleepDetailView.swift    # 睡眠详情
│   │   ├── DietDetailView.swift     # 饮食详情（含食物搜索）
│   │   ├── MetricDetailView.swift   # 生理指标详情（含血压双值）
│   │   ├── MedicationDetailView.swift # 用药详情
│   │   └── FoodSearchView.swift     # 食物搜索选择页
│   ├── AIAssistant/
│   │   ├── AIAssistantView.swift    # AI 对话界面
│   │   ├── ChatBubbleView.swift     # 聊天气泡
│   │   └── QuickPromptView.swift    # 快捷提问栏
│   ├── Profile/
│   │   ├── ProfileView.swift        # 我的主页
│   │   ├── HealthReportView.swift   # 健康报告
│   │   ├── ExportView.swift         # 数据导出
│   │   ├── AchievementView.swift    # 成就徽章（合并 BadgeDefinition + AchievementBadge）
│   │   ├── AlertHistoryView.swift   # 预警历史管理
│   │   ├── SettingsView.swift       # 设置页
│   │   └── PersonalInfoView.swift   # 个人档案编辑
│   ├── Privacy/
│   │   └── PrivacyLockView.swift    # 隐私锁覆盖层（纯色 + Logo，非模糊）
│   └── Component/
│       ├── StatCard.swift           # 通用指标卡片
│       ├── DateRangePicker.swift    # 日期范围选择器
│       ├── MetricRow.swift          # 指标行组件
│       ├── EmptyStateView.swift     # 空状态占位
│       └── BloodPressureCard.swift  # 血压双值展示组件
├── ViewModel/
│   ├── DashboardViewModel.swift
│   ├── HealthDataViewModel.swift
│   ├── AIAssistantViewModel.swift
│   ├── ProfileViewModel.swift
│   ├── HealthReportViewModel.swift
│   ├── ExportViewModel.swift
│   ├── PrivacyLockViewModel.swift
│   └── FoodSearchViewModel.swift
├── Service/
│   ├── HealthKitManager.swift       # HealthKit 读写与监听（实现 HealthKitProtocol）
│   ├── HealthKitProtocol.swift      # HealthKit 协议抽象（便于 Mock）
│   ├── AIService.swift              # 国产大模型 API 调用（实现 AIServiceProtocol）
│   ├── AIServiceProtocol.swift      # AI 服务协议抽象（便于 Mock）
│   ├── FoodDatabaseService.swift    # 食物营养数据库查询
│   ├── ExportService.swift          # CSV/PDF 生成
│   ├── KeychainService.swift        # Keychain 安全存储
│   └── ImageStorageService.swift    # 食物照片文件管理
├── Resource/
│   ├── FoodDatabase.json            # 内置食物营养数据（200+ 常见中国食物）
│   └── Assets.xcassets              # App 图标、徽章图标等
├── Utility/
│   ├── DateFormatter+Extensions.swift
│   ├── HealthCalculator.swift       # 健康评分计算、风险预警规则
│   ├── CSVEncoder.swift             # CSV 编码工具
│   ├── Constants.swift              # 全局常量（预警阈值默认值等）
│   └── ImageCompressor.swift        # 照片压缩工具
└── HealthFlowTests/
    ├── ModelTests/
    │   ├── UserProfileTests.swift
    │   ├── DailyActivitySummaryTests.swift
    │   ├── WorkoutRecordTests.swift
    │   ├── PhysiologicalMetricTests.swift
    │   ├── DietRecordTests.swift     # 包含 totalCalories @Transient 计算属性测试
    │   ├── ChatMessageTests.swift
    │   └── BadgeDefinitionTests.swift
    ├── ViewModelTests/
    │   ├── DashboardViewModelTests.swift
    │   ├── HealthDataViewModelTests.swift
    │   ├── AIAssistantViewModelTests.swift
    │   └── FoodSearchViewModelTests.swift
    ├── ServiceTests/
    │   ├── HealthKitManagerTests.swift
    │   ├── ExportServiceTests.swift
    │   ├── HealthCalculatorTests.swift
    │   └── FoodDatabaseServiceTests.swift
    │   ├── ImageStorageServiceTests.swift
    └── DefinitionTests/
        ├── MetricTypeTests.swift
        └── ExerciseTypeTests.swift
```

---

## 十四、阶段一详细范围

第一阶段将完成以下内容：

1. Xcode 项目创建与基础配置（iOS 17+ 最低版本、Info.plist 权限描述）
2. SwiftData ModelContainer 配置，所有核心数据模型定义（含 UserProfile 单例创建策略）
3. MainTabView 骨架（4 个 Tab 占位页 + NavigationStack）
4. 用户个人档案的 CRUD（ProfileView + PersonalInfoView + ProfileViewModel）
5. 设置页面骨架（SettingsView）
6. 基础通用组件（StatCard、EmptyStateView、BloodPressureCard 等）
7. Definition 枚举定义（BadgeDefinition、MetricType、ExerciseType、MealType、QuickPromptType）
8. 食物营养数据库 JSON 数据 + FoodDatabaseService 骨架
9. ImageStorageService 照片管理骨架
10. 对应单元测试覆盖

---

## 十五、技术依赖

| 技术 | 版本要求 | 用途 |
|------|----------|------|
| Swift | 5.9+ | 编程语言 |
| SwiftUI | iOS 17+ | UI 框架 |
| SwiftData | iOS 17+ | 本地持久化 |
| Swift Charts | iOS 17+ | 图表绘制 |
| HealthKit | iOS 17+ | 健康数据读写 |
| LocalAuthentication | iOS 17+ | Face ID / Touch ID |
| Keychain Services | iOS 17+ | API Key 安全存储 |
| UniformTypeIdentifiers | iOS 17+ | 文件导出类型标识 |

---

## 十六、审查修复记录

本节记录 v2 版本相对于 v1 的所有修复，便于追溯：

| 编号 | 优先级 | 修复内容 |
|------|--------|----------|
| 1 | 🔴 P0 | ExerciseRecord 拆分为 DailyActivitySummary + WorkoutRecord，消除数据粒度冲突 |
| 2 | 🔴 P0 | PhysiologicalMetric 血压改为双值字段（valueSystolic + valueDiastolic），添加 measurementGroupID 关联同一次测量 |
| 3 | 🔴 P0 | DietRecord 移除冗余汇总字段，改用 @Transient 计算属性动态聚合；imageData 改为 imagePath 文件引用 |
| 4 | 🔴 P0 | UserProfile 单例创建策略明确：App 启动时检查并自动创建默认记录 |
| 5 | 🔴 P0 | MedicationRecord 补充 source 和 note 字段 |
| 8 | 🟡 P1 | 所有 HealthKit 同步模型添加 healthKitUUID 字段（@Attribute(.unique)） |
| 9 | 🟡 P1 | imageData → imagePath + ImageStorageService 照片管理 + 照片压缩策略 |
| 10 | 🟡 P1 | 新增食物营养数据库设计（FoodDatabaseService + FoodDefinition + FavoriteFood） |
| 7 | 🟡 P1 | 新增 ChatMessage SwiftData 模型持久化 AI 对话历史 |
| 6 | 🟡 P1 | 新增 BadgeDefinition 枚举定义所有徽章类型和获取条件 |
| 11 | 🟢 P2 | UserProfile gender 默认值从 "" 改为 "unset" |
| 12 | 🟢 P2 | SleepRecord 添加 note 字段 |
| 13 | 🟢 P2 | 隐私锁从模糊覆盖改为纯色+Logo，防止截图和多任务泄露 |
| 14 | 🟢 P2 | 风险预警增加忽略功能、7天重复抑制、自定义阈值、IgnoredAlert 模型 |
| 15 | 🟢 P2 | 阶段一范围措辞改为「所有核心数据模型」，不硬编码数量 |