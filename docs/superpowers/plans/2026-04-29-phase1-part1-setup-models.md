# 阶段一（1/3）：项目创建 + Definition 枚举 + UserProfile

> **面向开发者：** 严格遵循 TDD（RED-GREEN-REFACTOR）。步骤使用 `- [ ]` 复选框跟踪进度。

**目标：** 创建 Xcode 项目，定义 5 个枚举，创建 UserProfile / BadgeDefinition 配套 AchievementBadge 模型。

**测试覆盖率目标：** ≥85%

**接续：** 完成后继续 → `phase1-part2-models.md` → `phase1-part3-app-views.md`

---

## 任务 1：创建 Xcode 项目与基础配置

**文件：**
- 创建：Xcode 项目 `HealthFlow`

- [ ] **步骤 1：在 Xcode 中创建项目**

打开 Xcode → File → New → Project → iOS → App
- Product Name: `HealthFlow`
- Interface: `SwiftUI`
- Language: `Swift`
- Minimum Deployment: `iOS 17.0`
- 勾选 `Include Tests`
- 保存到 `/Users/linchengda/Desktop/HealthFlow/`

- [ ] **步骤 2：配置 Info.plist 权限描述**

在项目的 `Info.plist` 中添加以下键值：

```xml
<key>NSHealthShareUsageDescription</key>
<string>HealthFlow 需要读取您的健康数据以展示运动、睡眠和生理指标信息</string>
<key>NSHealthUpdateUsageDescription</key>
<string>HealthFlow 需要写入权限以记录您手动录入的健康数据</string>
<key>NSFaceIDUsageDescription</key>
<string>HealthFlow 使用面容识别保护您的健康数据隐私</string>
```

- [ ] **步骤 3：配置构建设置**

Build Settings 中确认：
- `Swift Language Version` = `Swift 5.9`
- 确认 `Assets.xcassets` 包含 AppIcon（默认即可）

- [ ] **步骤 4：构建空项目确认编译通过**

```bash
xcodebuild -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' build
```

期望：**BUILD SUCCEEDED**

- [ ] **步骤 5：初始化 Git 仓库并提交**

```bash
cd /Users/linchengda/Desktop/HealthFlow
git init
git add .
git commit -m "chore: 创建 HealthFlow Xcode 项目，配置 Info.plist 权限描述"
```

---

## 任务 2：定义 BadgeDefinition 枚举 + AchievementBadge 模型

**文件：**
- 创建：`HealthFlow/Definition/BadgeDefinition.swift`
- 创建：`HealthFlow/Model/AchievementBadge.swift`
- 测试：`HealthFlowTests/DefinitionTests/BadgeDefinitionTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

创建 `HealthFlowTests/DefinitionTests/BadgeDefinitionTests.swift`：

```swift
import Testing
@testable import HealthFlow

struct BadgeDefinitionTests {

    @Test("所有徽章定义都有非空标题")
    func allBadgeDefinitionsHaveNonEmptyTitle() {
        for badge in BadgeDefinition.allCases {
            #expect(!badge.title.isEmpty)
        }
    }

    @Test("所有徽章定义都有非空描述")
    func allBadgeDefinitionsHaveNonEmptyDescription() {
        for badge in BadgeDefinition.allCases {
            #expect(!badge.description.isEmpty)
        }
    }

    @Test("所有徽章定义都有非空图标名")
    func allBadgeDefinitionsHaveNonEmptyIconName() {
        for badge in BadgeDefinition.allCases {
            #expect(!badge.iconName.isEmpty)
        }
    }

    @Test("已获得的徽章 isEarned 返回 true")
    func isEarnedReturnsTrueWhenBadgeExists() {
        let badge = AchievementBadge()
        badge.badgeType = BadgeDefinition.steps10000.rawValue
        let result = BadgeDefinition.steps10000.isEarned(badges: [badge])
        #expect(result == true)
    }

    @Test("未获得的徽章 isEarned 返回 false")
    func isEarnedReturnsFalseWhenBadgeMissing() {
        let result = BadgeDefinition.steps10000.isEarned(badges: [])
        #expect(result == false)
    }
}
```

- [ ] **步骤 2：运行测试确认失败（RED）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/BadgeDefinitionTests
```

期望：**BUILD FAILED**（`BadgeDefinition` 不存在）

- [ ] **步骤 3：编写最小实现（GREEN）**

创建 `HealthFlow/Definition/BadgeDefinition.swift`：

```swift
import Foundation

enum BadgeDefinition: String, CaseIterable {
    case streak7Days = "streak_7days"
    case streak30Days = "streak_30days"
    case steps10000 = "steps_10000"
    case perfectSleep = "perfect_sleep"
    case calorieGoalMet = "calorie_goal_met"
    case exercise5Times = "exercise_5times"
    case earlyBird = "early_bird"

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

创建 `HealthFlow/Model/AchievementBadge.swift`（BadgeDefinition 的 isEarned 依赖此模型）：

```swift
import Foundation
import SwiftData

@Model
final class AchievementBadge {
    var badgeType: String = ""
    var title: String = ""
    var earnedDate: Date = Date()
}
```

- [ ] **步骤 4：运行测试确认通过（GREEN）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/BadgeDefinitionTests
```

期望：**5 tests passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 BadgeDefinition 枚举、AchievementBadge 模型及单元测试"
```

---

## 任务 3：定义 MetricType 枚举

**文件：**
- 创建：`HealthFlow/Definition/MetricType.swift`
- 测试：`HealthFlowTests/DefinitionTests/MetricTypeTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

创建 `HealthFlowTests/DefinitionTests/MetricTypeTests.swift`：

```swift
import Testing
@testable import HealthFlow

struct MetricTypeTests {

    @Test("所有指标类型都有正确的单位")
    func allMetricTypesHaveCorrectUnit() {
        #expect(MetricType.weight.unit == "kg")
        #expect(MetricType.heartRate.unit == "bpm")
        #expect(MetricType.bloodOxygen.unit == "%")
        #expect(MetricType.bodyTemperature.unit == "°C")
        #expect(MetricType.bloodPressure.unit == "mmHg")
        #expect(MetricType.bloodGlucose.unit == "mmol/L")
    }

    @Test("血压类型需要双值")
    func bloodPressureRequiresDualValues() {
        #expect(MetricType.bloodPressure.requiresDualValues == true)
        #expect(MetricType.weight.requiresDualValues == false)
    }

    @Test("所有 displayName 非空")
    func displayNameIsNotEmptyForAllCases() {
        for type in MetricType.allCases {
            #expect(!type.displayName.isEmpty)
        }
    }

    @Test("所有 normalRangeDescription 非空")
    func normalRangeDescriptionIsNotEmptyForAllCases() {
        for type in MetricType.allCases {
            #expect(!type.normalRangeDescription.isEmpty)
        }
    }
}
```

- [ ] **步骤 2：运行测试确认失败（RED）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/MetricTypeTests
```

期望：**BUILD FAILED**（`MetricType` 不存在）

- [ ] **步骤 3：编写最小实现（GREEN）**

创建 `HealthFlow/Definition/MetricType.swift`：

```swift
import Foundation

enum MetricType: String, CaseIterable {
    case weight = "weight"
    case heartRate = "heartRate"
    case bloodOxygen = "bloodOxygen"
    case bodyTemperature = "bodyTemperature"
    case bloodPressure = "bloodPressure"
    case bloodGlucose = "bloodGlucose"

    var displayName: String {
        switch self {
        case .weight: return "体重"
        case .heartRate: return "心率"
        case .bloodOxygen: return "血氧"
        case .bodyTemperature: return "体温"
        case .bloodPressure: return "血压"
        case .bloodGlucose: return "血糖"
        }
    }

    var unit: String {
        switch self {
        case .weight: return "kg"
        case .heartRate: return "bpm"
        case .bloodOxygen: return "%"
        case .bodyTemperature: return "°C"
        case .bloodPressure: return "mmHg"
        case .bloodGlucose: return "mmol/L"
        }
    }

    var requiresDualValues: Bool { self == .bloodPressure }

    var normalRangeDescription: String {
        switch self {
        case .weight: return "因人而异"
        case .heartRate: return "60-100 bpm（静息）"
        case .bloodOxygen: return "95-100%"
        case .bodyTemperature: return "36.0-37.3°C"
        case .bloodPressure: return "90-139 / 60-89 mmHg"
        case .bloodGlucose: return "3.9-6.1 mmol/L（空腹）"
        }
    }
}
```

- [ ] **步骤 4：运行测试确认通过（GREEN）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/MetricTypeTests
```

期望：**4 tests passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 MetricType 枚举及单元测试"
```

---

## 任务 4：定义 ExerciseType 枚举

**文件：**
- 创建：`HealthFlow/Definition/ExerciseType.swift`
- 测试：`HealthFlowTests/DefinitionTests/ExerciseTypeTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

创建 `HealthFlowTests/DefinitionTests/ExerciseTypeTests.swift`：

```swift
import Testing
@testable import HealthFlow

struct ExerciseTypeTests {

    @Test("所有运动类型都有非空展示名称")
    func allExerciseTypesHaveDisplayName() {
        for type in ExerciseType.allCases {
            #expect(!type.displayName.isEmpty)
        }
    }

    @Test("所有运动类型都有非空图标名")
    func allExerciseTypesHaveIconName() {
        for type in ExerciseType.allCases {
            #expect(!type.iconName.isEmpty)
        }
    }

    @Test("其他类型没有默认卡路里消耗率")
    func otherTypeHasNoCalorieRate() {
        #expect(ExerciseType.other.caloriesPerMinute == nil)
    }

    @Test("跑步每分卡路里消耗率大于走路")
    func runningBurnsMoreThanWalking() {
        let walk = ExerciseType.walking.caloriesPerMinute ?? 0
        let run = ExerciseType.running.caloriesPerMinute ?? 0
        #expect(run > walk)
    }

    @Test("步行有卡路里消耗率")
    func walkingHasCalorieRate() {
        #expect(ExerciseType.walking.caloriesPerMinute != nil)
    }
}
```

- [ ] **步骤 2：运行测试确认失败（RED）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/ExerciseTypeTests
```

期望：**BUILD FAILED**

- [ ] **步骤 3：编写最小实现（GREEN）**

创建 `HealthFlow/Definition/ExerciseType.swift`：

```swift
import Foundation

enum ExerciseType: String, CaseIterable {
    case walking = "walking"
    case running = "running"
    case cycling = "cycling"
    case swimming = "swimming"
    case yoga = "yoga"
    case hiit = "hiit"
    case strength = "strength_training"
    case other = "other"

    var displayName: String {
        switch self {
        case .walking: return "步行"
        case .running: return "跑步"
        case .cycling: return "骑行"
        case .swimming: return "游泳"
        case .yoga: return "瑜伽"
        case .hiit: return "HIIT"
        case .strength: return "力量训练"
        case .other: return "其他"
        }
    }

    var iconName: String {
        switch self {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.mind.and.body"
        case .hiit: return "flame.circle.fill"
        case .strength: return "dumbbell.fill"
        case .other: return "figure.mixed.cardio"
        }
    }

    var caloriesPerMinute: Double? {
        switch self {
        case .walking: return 4.0
        case .running: return 10.0
        case .cycling: return 7.0
        case .swimming: return 8.0
        case .yoga: return 3.0
        case .hiit: return 12.0
        case .strength: return 6.0
        case .other: return nil
        }
    }
}
```

- [ ] **步骤 4：运行测试确认通过（GREEN）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/ExerciseTypeTests
```

期望：**5 tests passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 ExerciseType 枚举及单元测试"
```

---

## 任务 5：定义 MealType 枚举

**文件：**
- 创建：`HealthFlow/Definition/MealType.swift`

- [ ] **步骤 1：编写实现**

创建 `HealthFlow/Definition/MealType.swift`：

```swift
import Foundation

enum MealType: String, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"

    var displayName: String {
        switch self {
        case .breakfast: return "早餐"
        case .lunch: return "午餐"
        case .dinner: return "晚餐"
        case .snack: return "加餐"
        }
    }

    var iconName: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "cup.and.saucer.fill"
        }
    }
}
```

- [ ] **步骤 2：编译验证**

```bash
xcodebuild build -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16'
```

期望：**BUILD SUCCEEDED**

- [ ] **步骤 3：提交**

```bash
git add .
git commit -m "feat: 添加 MealType 枚举"
```

---

## 任务 6：定义 QuickPromptType 枚举

**文件：**
- 创建：`HealthFlow/Definition/QuickPromptType.swift`

- [ ] **步骤 1：编写实现**

创建 `HealthFlow/Definition/QuickPromptType.swift`：

```swift
import Foundation

enum QuickPromptType: String, CaseIterable {
    case todaySummary = "today_summary"
    case weeklyTrend = "weekly_trend"
    case dietAdvice = "diet_advice"
    case exercisePlan = "exercise_plan"
    case sleepAnalysis = "sleep_analysis"
    case healthWarning = "health_warning"

    var displayName: String {
        switch self {
        case .todaySummary: return "今日总结"
        case .weeklyTrend: return "本周趋势"
        case .dietAdvice: return "饮食建议"
        case .exercisePlan: return "运动计划"
        case .sleepAnalysis: return "睡眠分析"
        case .healthWarning: return "风险预警"
        }
    }

    var promptText: String {
        switch self {
        case .todaySummary: return "请帮我总结今天的健康数据"
        case .weeklyTrend: return "请分析我本周的健康趋势"
        case .dietAdvice: return "请根据我的数据给出饮食建议"
        case .exercisePlan: return "请为我的下周运动计划给出建议"
        case .sleepAnalysis: return "请分析我的睡眠质量"
        case .healthWarning: return "请检查我的数据是否有异常"
        }
    }
}
```

- [ ] **步骤 2：编译验证后提交**

```bash
xcodebuild build -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16'
git add .
git commit -m "feat: 添加 QuickPromptType 枚举"
```

---

## 任务 7：创建 UserProfile 模型

**文件：**
- 创建：`HealthFlow/Model/UserProfile.swift`
- 测试：`HealthFlowTests/ModelTests/UserProfileTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

创建 `HealthFlowTests/ModelTests/UserProfileTests.swift`：

```swift
import Testing
import Foundation
@testable import HealthFlow

struct UserProfileTests {

    @Test("UserProfile 初始化具有正确的默认值")
    func testDefaultInitialization() {
        let profile = UserProfile()
        #expect(profile.name == "")
        #expect(profile.gender == "unset")
        #expect(profile.height == 0)
        #expect(profile.targetWeight == nil)
        #expect(profile.targetSteps == nil)
        #expect(profile.targetSleepHours == nil)
        #expect(profile.targetCalories == nil)
    }

    @Test("birthDate 默认在今天之前")
    func testBirthDateDefaultsToPast() {
        let profile = UserProfile()
        #expect(profile.birthDate <= Date())
    }

    @Test("createdAt 在创建时自动设置")
    func testCreatedAtSetOnCreation() {
        let before = Date()
        let profile = UserProfile()
        #expect(profile.createdAt >= before)
        #expect(profile.createdAt <= Date())
    }
}
```

- [ ] **步骤 2：运行测试确认失败（RED）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/UserProfileTests
```

期望：**BUILD FAILED**

- [ ] **步骤 3：编写最小实现（GREEN）**

创建 `HealthFlow/Model/UserProfile.swift`：

```swift
import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String = ""
    var gender: String = "unset"
    var birthDate: Date = Date()
    var height: Double = 0
    var targetWeight: Double?
    var targetSteps: Int?
    var targetSleepHours: Double?
    var targetCalories: Int?
    var createdAt: Date = Date()

    init(name: String = "",
         gender: String = "unset",
         birthDate: Date = Date(),
         height: Double = 0,
         targetWeight: Double? = nil,
         targetSteps: Int? = nil,
         targetSleepHours: Double? = nil,
         targetCalories: Int? = nil) {
        self.name = name
        self.gender = gender
        self.birthDate = birthDate
        self.height = height
        self.targetWeight = targetWeight
        self.targetSteps = targetSteps
        self.targetSleepHours = targetSleepHours
        self.targetCalories = targetCalories
        self.createdAt = Date()
    }
}
```

- [ ] **步骤 4：运行测试确认通过（GREEN）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/UserProfileTests
```

期望：**3 tests passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 UserProfile 模型及单元测试"
```

---

## 第一部分完成

已创建文件：
- Xcode 项目 + Info.plist 权限配置
- `HealthFlow/Definition/` 下 5 个枚举定义文件
- `HealthFlow/Model/AchievementBadge.swift`
- `HealthFlow/Model/UserProfile.swift`
- 对应 4 个测试文件（BadgeDefinitionTests, MetricTypeTests, ExerciseTypeTests, UserProfileTests）

继续 → **`phase1-part2-models.md`**（其余 10 个 SwiftData 模型）
