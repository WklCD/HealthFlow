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