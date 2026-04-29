# 阶段一（2/3）：全部数据模型定义（TDD）

> **面向开发者：** 每个模型严格 RED（先写测试→失败）→ GREEN（最小实现→通过）。步骤使用 `- [ ]` 复选框。

**目标：** 创建剩余 10 个 SwiftData 模型及单元测试。

**前置：** `phase1-part1-setup-models.md` 已完成（UserProfile、AchievementBadge 已创建，Definition 枚举已定义）

**接续：** 完成后继续 → `phase1-part3-app-views.md`

---

## 任务 1：DailyActivitySummary 模型

**文件：**
- 创建：`HealthFlow/Model/DailyActivitySummary.swift`
- 测试：`HealthFlowTests/ModelTests/DailyActivitySummaryTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

创建 `HealthFlowTests/ModelTests/DailyActivitySummaryTests.swift`：

```swift
import Testing
import Foundation
@testable import HealthFlow

struct DailyActivitySummaryTests {

    @Test("默认 source 为 healthkit")
    func testDefaultSource() {
        let summary = DailyActivitySummary()
        #expect(summary.source == "healthkit")
    }

    @Test("healthKitUUID 默认为 nil")
    func testHealthKitUUIDDefaultsToNil() {
        let summary = DailyActivitySummary()
        #expect(summary.healthKitUUID == nil)
    }

    @Test("所有数值字段默认值为 0")
    func testNumericDefaults() {
        let summary = DailyActivitySummary()
        #expect(summary.steps == 0)
        #expect(summary.calories == 0)
        #expect(summary.distance == 0)
    }

    @Test("standHours 默认为 nil")
    func testStandHoursDefaultsToNil() {
        let summary = DailyActivitySummary()
        #expect(summary.standHours == nil)
    }
}
```

- [ ] **步骤 2：运行测试确认失败**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/DailyActivitySummaryTests
```

期望：**BUILD FAILED**

- [ ] **步骤 3：编写实现（GREEN）**

创建 `HealthFlow/Model/DailyActivitySummary.swift`：

```swift
import Foundation
import SwiftData

@Model
final class DailyActivitySummary {
    var date: Date = Date()
    var steps: Int = 0
    var calories: Double = 0
    var distance: Double = 0
    var standHours: Int?
    var source: String = "healthkit"
    @Attribute(.unique) var healthKitUUID: String?
    var note: String?
}
```

- [ ] **步骤 4：运行测试确认通过（GREEN）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/DailyActivitySummaryTests
```

期望：**4 tests passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 DailyActivitySummary 模型及单元测试"
```

---

## 任务 2：WorkoutRecord 模型

**文件：**
- 创建：`HealthFlow/Model/WorkoutRecord.swift`
- 测试：`HealthFlowTests/ModelTests/WorkoutRecordTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

创建 `HealthFlowTests/ModelTests/WorkoutRecordTests.swift`：

```swift
import Testing
import Foundation
@testable import HealthFlow

struct WorkoutRecordTests {

    @Test("默认 source 为 manual")
    func testDefaultSource() {
        let record = WorkoutRecord()
        #expect(record.source == "manual")
    }

    @Test("duration 默认值为 0")
    func testDefaultDuration() {
        let record = WorkoutRecord()
        #expect(record.duration == 0)
    }

    @Test("可选字段默认为 nil")
    func testOptionalDefaults() {
        let record = WorkoutRecord()
        #expect(record.healthKitUUID == nil)
        #expect(record.steps == nil)
        #expect(record.distance == nil)
        #expect(record.heartRateAvg == nil)
        #expect(record.heartRateMax == nil)
        #expect(record.note == nil)
    }
}
```

- [ ] **步骤 2：运行测试确认失败**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/WorkoutRecordTests
```

期望：**BUILD FAILED**

- [ ] **步骤 3：编写实现（GREEN）**

创建 `HealthFlow/Model/WorkoutRecord.swift`：

```swift
import Foundation
import SwiftData

@Model
final class WorkoutRecord {
    var exerciseType: String = ""
    var startTime: Date = Date()
    var endTime: Date = Date()
    var duration: TimeInterval = 0
    var calories: Double = 0
    var steps: Int?
    var distance: Double?
    var heartRateAvg: Double?
    var heartRateMax: Double?
    var source: String = "manual"
    @Attribute(.unique) var healthKitUUID: String?
    var note: String?
}
```

- [ ] **步骤 4：运行测试确认通过（GREEN）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/WorkoutRecordTests
```

期望：**3 tests passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 WorkoutRecord 模型及单元测试"
```

---

## 任务 3：SleepRecord 模型

**文件：**
- 创建：`HealthFlow/Model/SleepRecord.swift`
- 测试：`HealthFlowTests/ModelTests/SleepRecordTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

创建 `HealthFlowTests/ModelTests/SleepRecordTests.swift`：

```swift
import Testing
import Foundation
@testable import HealthFlow

struct SleepRecordTests {

    @Test("默认值正确")
    func testDefaults() {
        let record = SleepRecord()
        #expect(record.quality == 0)
        #expect(record.duration == 0)
        #expect(record.source == "manual")
        #expect(record.note == nil)
        #expect(record.healthKitUUID == nil)
        #expect(record.deepSleep == nil)
        #expect(record.remSleep == nil)
    }
}
```

- [ ] **步骤 2：运行测试确认失败**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/SleepRecordTests
```

期望：**BUILD FAILED**

- [ ] **步骤 3：编写实现（GREEN）**

创建 `HealthFlow/Model/SleepRecord.swift`：

```swift
import Foundation
import SwiftData

@Model
final class SleepRecord {
    var startTime: Date = Date()
    var endTime: Date = Date()
    var duration: TimeInterval = 0
    var deepSleep: TimeInterval?
    var remSleep: TimeInterval?
    var quality: Int = 0
    var source: String = "manual"
    @Attribute(.unique) var healthKitUUID: String?
    var note: String?
}
```

- [ ] **步骤 4：运行测试确认通过（GREEN）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/SleepRecordTests
```

期望：**1 test passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 SleepRecord 模型及单元测试"
```

---

## 任务 4：FoodItem + DietRecord 模型

**文件：**
- 创建：`HealthFlow/Model/FoodItem.swift`
- 创建：`HealthFlow/Model/DietRecord.swift`
- 测试：`HealthFlowTests/ModelTests/FoodItemTests.swift`
- 测试：`HealthFlowTests/ModelTests/DietRecordTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

创建 `HealthFlowTests/ModelTests/FoodItemTests.swift`：

```swift
import Testing
import Foundation
@testable import HealthFlow

struct FoodItemTests {

    @Test("默认单位是'份'")
    func testDefaultUnit() {
        let item = FoodItem()
        #expect(item.unit == "份")
    }

    @Test("所有营养值默认为 0")
    func testNutrientDefaults() {
        let item = FoodItem()
        #expect(item.calories == 0)
        #expect(item.protein == 0)
        #expect(item.carbs == 0)
        #expect(item.fat == 0)
    }
}
```

创建 `HealthFlowTests/ModelTests/DietRecordTests.swift`：

```swift
import Testing
import Foundation
@testable import HealthFlow

struct DietRecordTests {

    @Test("totalCalories 从 foodItems 动态聚合")
    func testTotalCaloriesAggregation() {
        let diet = DietRecord()
        let item1 = FoodItem()
        item1.calories = 100
        let item2 = FoodItem()
        item2.calories = 200
        diet.foodItems = [item1, item2]
        #expect(diet.totalCalories == 300)
    }

    @Test("空 foodItems 时 totalCalories 为 0")
    func testTotalCaloriesEmptyFoodItems() {
        let diet = DietRecord()
        diet.foodItems = []
        #expect(diet.totalCalories == 0)
    }

    @Test("totalProtein 正确聚合")
    func testTotalProteinAggregation() {
        let diet = DietRecord()
        let item = FoodItem()
        item.protein = 15.5
        diet.foodItems = [item]
        #expect(diet.totalProtein == 15.5)
    }

    @Test("totalCarbs 正确聚合")
    func testTotalCarbsAggregation() {
        let diet = DietRecord()
        let item = FoodItem()
        item.carbs = 40
        diet.foodItems = [item]
        #expect(diet.totalCarbs == 40)
    }

    @Test("totalFat 正确聚合")
    func testTotalFatAggregation() {
        let diet = DietRecord()
        let item = FoodItem()
        item.fat = 12
        diet.foodItems = [item]
        #expect(diet.totalFat == 12)
    }

    @Test("多个 foodItems 正确聚合所有营养素")
    func testFullAggregation() {
        let diet = DietRecord()
        let item1 = FoodItem()
        item1.calories = 100; item1.protein = 10; item1.carbs = 20; item1.fat = 5
        let item2 = FoodItem()
        item2.calories = 200; item2.protein = 20; item2.carbs = 30; item2.fat = 10
        diet.foodItems = [item1, item2]
        #expect(diet.totalCalories == 300)
        #expect(diet.totalProtein == 30)
        #expect(diet.totalCarbs == 50)
        #expect(diet.totalFat == 15)
    }

    @Test("imagePath 默认为 nil")
    func testImagePathDefaultsToNil() {
        let diet = DietRecord()
        #expect(diet.imagePath == nil)
    }
}
```

- [ ] **步骤 2：运行测试确认失败**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/FoodItemTests -only-testing:HealthFlowTests/DietRecordTests
```

期望：**BUILD FAILED**

- [ ] **步骤 3：编写实现（GREEN）**

创建 `HealthFlow/Model/FoodItem.swift`：

```swift
import Foundation
import SwiftData

@Model
final class FoodItem {
    var name: String = ""
    var amount: Double = 0
    var unit: String = "份"
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
}
```

创建 `HealthFlow/Model/DietRecord.swift`：

```swift
import Foundation
import SwiftData

@Model
final class DietRecord {
    var mealType: String = ""
    var timestamp: Date = Date()
    var imagePath: String?
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
```

- [ ] **步骤 4：运行测试确认通过（GREEN）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/FoodItemTests -only-testing:HealthFlowTests/DietRecordTests
```

期望：**9 tests passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 FoodItem + DietRecord 模型（含 @Transient 聚合计算）及单元测试"
```

---

## 任务 5：PhysiologicalMetric 模型

**文件：**
- 创建：`HealthFlow/Model/PhysiologicalMetric.swift`
- 测试：`HealthFlowTests/ModelTests/PhysiologicalMetricTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

创建 `HealthFlowTests/ModelTests/PhysiologicalMetricTests.swift`：

```swift
import Testing
import Foundation
@testable import HealthFlow

struct PhysiologicalMetricTests {

    @Test("非血压类型 valueSystolic 和 valueDiastolic 为 nil")
    func testNonBloodPressureDualValuesNil() {
        let metric = PhysiologicalMetric()
        metric.metricType = "weight"
        #expect(metric.valueSystolic == nil)
        #expect(metric.valueDiastolic == nil)
    }

    @Test("measurementGroupID 默认为 nil")
    func testDefaultMeasurementGroupID() {
        let metric = PhysiologicalMetric()
        #expect(metric.measurementGroupID == nil)
    }

    @Test("source 默认为 manual")
    func testDefaultSource() {
        let metric = PhysiologicalMetric()
        #expect(metric.source == "manual")
    }

    @Test("value 默认值为 0")
    func testDefaultValue() {
        let metric = PhysiologicalMetric()
        #expect(metric.value == 0)
    }

    @Test("healthKitUUID 默认为 nil")
    func testHealthKitUUIDDefaultsToNil() {
        let metric = PhysiologicalMetric()
        #expect(metric.healthKitUUID == nil)
    }
}
```

- [ ] **步骤 2：运行测试确认失败**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/PhysiologicalMetricTests
```

期望：**BUILD FAILED**

- [ ] **步骤 3：编写实现（GREEN）**

创建 `HealthFlow/Model/PhysiologicalMetric.swift`：

```swift
import Foundation
import SwiftData

@Model
final class PhysiologicalMetric {
    var metricType: String = ""
    var value: Double = 0
    var valueSystolic: Double?
    var valueDiastolic: Double?
    var unit: String = ""
    var timestamp: Date = Date()
    var source: String = "manual"
    @Attribute(.unique) var healthKitUUID: String?
    var measurementGroupID: String?
    var note: String?
}
```

- [ ] **步骤 4：运行测试确认通过（GREEN）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/PhysiologicalMetricTests
```

期望：**5 tests passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 PhysiologicalMetric 模型（血压双值 + measurementGroupID）及单元测试"
```

---

## 任务 6：AchievementBadge 模型补充测试

> 注意：AchievementBadge 模型已在 Part 1 的任务 2 中创建（BadgeDefinition.isEarned 依赖），此处补充独立测试文件。

**文件：**
- 创建：`HealthFlowTests/ModelTests/AchievementBadgeTests.swift`

- [ ] **步骤 1：编写测试**

创建 `HealthFlowTests/ModelTests/AchievementBadgeTests.swift`：

```swift
import Testing
import Foundation
@testable import HealthFlow

struct AchievementBadgeTests {

    @Test("创建时 earnedDate 在当前时间附近")
    func testEarnedDateOnCreation() {
        let badge = AchievementBadge()
        #expect(abs(badge.earnedDate.timeIntervalSinceNow) < 1)
    }

    @Test("badgeType 默认为空字符串")
    func testDefaultBadgeType() {
        let badge = AchievementBadge()
        #expect(badge.badgeType == "")
    }

    @Test("title 默认为空字符串")
    func testDefaultTitle() {
        let badge = AchievementBadge()
        #expect(badge.title == "")
    }
}
```

- [ ] **步骤 2：运行测试确认通过**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/AchievementBadgeTests
```

期望：**3 tests passed**

- [ ] **步骤 3：提交**

```bash
git add .
git commit -m "test: 补充 AchievementBadge 模型单元测试"
```

---

## 任务 7：MedicationRecord 模型

**文件：**
- 创建：`HealthFlow/Model/MedicationRecord.swift`
- 测试：`HealthFlowTests/ModelTests/MedicationRecordTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

创建 `HealthFlowTests/ModelTests/MedicationRecordTests.swift`：

```swift
import Testing
import Foundation
@testable import HealthFlow

struct MedicationRecordTests {

    @Test("takenAt 默认为 nil")
    func testTakenAtDefaultsNil() {
        let record = MedicationRecord()
        #expect(record.takenAt == nil)
    }

    @Test("source 默认为 manual")
    func testDefaultSource() {
        let record = MedicationRecord()
        #expect(record.source == "manual")
    }

    @Test("note 字段可读写")
    func testNoteField() {
        let record = MedicationRecord()
        record.note = "饭后服用"
        #expect(record.note == "饭后服用")
    }

    @Test("name 和 dosage 默认为空")
    func testNameAndDosageDefaults() {
        let record = MedicationRecord()
        #expect(record.name == "")
        #expect(record.dosage == "")
    }
}
```

- [ ] **步骤 2：运行测试确认失败**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/MedicationRecordTests
```

期望：**BUILD FAILED**

- [ ] **步骤 3：编写实现（GREEN）**

创建 `HealthFlow/Model/MedicationRecord.swift`：

```swift
import Foundation
import SwiftData

@Model
final class MedicationRecord {
    var name: String = ""
    var dosage: String = ""
    var scheduledTime: Date = Date()
    var takenAt: Date?
    var source: String = "manual"
    var note: String?
}
```

- [ ] **步骤 4：运行测试确认通过（GREEN）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/MedicationRecordTests
```

期望：**4 tests passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 MedicationRecord 模型（含 source + note）及单元测试"
```

---

## 任务 8：ChatMessage 模型

**文件：**
- 创建：`HealthFlow/Model/ChatMessage.swift`
- 测试：`HealthFlowTests/ModelTests/ChatMessageTests.swift`

- [ ] **步骤 1：编写失败测试（RED）**

创建 `HealthFlowTests/ModelTests/ChatMessageTests.swift`：

```swift
import Testing
import Foundation
@testable import HealthFlow

struct ChatMessageTests {

    @Test("默认值为空")
    func testDefaults() {
        let msg = ChatMessage()
        #expect(msg.role == "")
        #expect(msg.content == "")
        #expect(msg.promptType == nil)
    }

    @Test("设置 role 为 user 和 assistant")
    func testRoleValues() {
        let userMsg = ChatMessage()
        userMsg.role = "user"
        #expect(userMsg.role == "user")

        let aiMsg = ChatMessage()
        aiMsg.role = "assistant"
        #expect(aiMsg.role == "assistant")
    }

    @Test("promptType 可设置")
    func testPromptType() {
        let msg = ChatMessage()
        msg.promptType = QuickPromptType.todaySummary.rawValue
        #expect(msg.promptType == "today_summary")
    }

    @Test("timestamp 在创建时自动设置")
    func testTimestampOnCreation() {
        let before = Date()
        let msg = ChatMessage()
        #expect(msg.timestamp >= before)
        #expect(msg.timestamp <= Date())
    }
}
```

- [ ] **步骤 2：运行测试确认失败**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/ChatMessageTests
```

期望：**BUILD FAILED**

- [ ] **步骤 3：编写实现（GREEN）**

创建 `HealthFlow/Model/ChatMessage.swift`：

```swift
import Foundation
import SwiftData

@Model
final class ChatMessage {
    var role: String = ""
    var content: String = ""
    var timestamp: Date = Date()
    var promptType: String?
}
```

- [ ] **步骤 4：运行测试确认通过（GREEN）**

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/ChatMessageTests
```

期望：**4 tests passed**

- [ ] **步骤 5：提交**

```bash
git add .
git commit -m "feat: 添加 ChatMessage 模型（AI 对话持久化）及单元测试"
```

---

## 任务 9：FavoriteFood + IgnoredAlert 模型

**文件：**
- 创建：`HealthFlow/Model/FavoriteFood.swift`
- 创建：`HealthFlow/Model/IgnoredAlert.swift`

- [ ] **步骤 1：编写实现**

创建 `HealthFlow/Model/FavoriteFood.swift`：

```swift
import Foundation
import SwiftData

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

创建 `HealthFlow/Model/IgnoredAlert.swift`：

```swift
import Foundation
import SwiftData

@Model
final class IgnoredAlert {
    var alertType: String = ""
    var triggeredDate: Date = Date()
    var ignoredDate: Date = Date()
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
git commit -m "feat: 添加 FavoriteFood + IgnoredAlert 模型"
```

---

## 任务 10：运行全部模型测试确认

- [ ] 运行全部模型测试：

```bash
xcodebuild test -project HealthFlow.xcodeproj -scheme HealthFlow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HealthFlowTests/ModelTests
```

期望：全部测试通过（约 30+ tests）

---

## 第二部分完成

已创建文件：
- `HealthFlow/Model/DailyActivitySummary.swift`
- `HealthFlow/Model/WorkoutRecord.swift`
- `HealthFlow/Model/SleepRecord.swift`
- `HealthFlow/Model/FoodItem.swift`
- `HealthFlow/Model/DietRecord.swift`
- `HealthFlow/Model/PhysiologicalMetric.swift`
- `HealthFlow/Model/MedicationRecord.swift`
- `HealthFlow/Model/ChatMessage.swift`
- `HealthFlow/Model/FavoriteFood.swift`
- `HealthFlow/Model/IgnoredAlert.swift`
- 对应 9 个测试文件

继续 → **`phase1-part3-app-views.md`**（工具类、App 入口、MainTabView、ProfileViewModel、Views、组件、总体验证）
