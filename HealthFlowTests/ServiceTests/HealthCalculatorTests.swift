import Testing
import Foundation
import SwiftData
@testable import HealthFlow

struct HealthCalculatorTests {

    @Test("步数达标时运动评分满分")
    func testPerfectExerciseScore() {
        let score = HealthCalculator.exerciseScore(steps: 12000, target: 10000)
        #expect(score == 25)
    }

    @Test("步数一半时运动评分约为半")
    func testHalfExerciseScore() {
        let score = HealthCalculator.exerciseScore(steps: 5000, target: 10000)
        #expect(score == 13)
    }

    @Test("零目标时运动评分为0")
    func testExerciseScoreZeroTarget() {
        let score = HealthCalculator.exerciseScore(steps: 5000, target: 0)
        #expect(score == 0)
    }

    @Test("睡眠时长达标且质量满分时睡眠评分满分")
    func testPerfectSleepScore() {
        let score = HealthCalculator.sleepScore(hours: 8, target: 8, quality: 5)
        #expect(score == 25)
    }

    @Test("睡眠时长不足且质量低")
    func testLowSleepScore() {
        let score = HealthCalculator.sleepScore(hours: 4, target: 8, quality: 1)
        #expect(score < 15)
    }

    @Test("饮食评分达标区间满分")
    func testPerfectDietScore() {
        let score = HealthCalculator.dietScore(calories: 2000, target: 2000)
        #expect(score == 20)
    }

    @Test("饮食评分偏高区间中等")
    func testDietScoreAboveRange() {
        let score = HealthCalculator.dietScore(calories: 2600, target: 2000)
        #expect(score == 10)
    }

    @Test("饮食评分为零时得0分")
    func testZeroDietScore() {
        let score = HealthCalculator.dietScore(calories: 0, target: 2000)
        #expect(score == 0)
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

    @Test("活跃天数评分7天满分")
    func testActiveDaysScoreFullWeek() {
        let score = HealthCalculator.activeDaysScore(daysInWeek: 7)
        #expect(score == 10)
    }

    @Test("活跃天数评分0天为0")
    func testActiveDaysScoreZero() {
        let score = HealthCalculator.activeDaysScore(daysInWeek: 0)
        #expect(score == 0)
    }

    @Test("连续3天睡眠不足触发预警")
    func testSleepDeficitAlert() {
        let sleeps = [-3, -2, -1].map { daysAgo in
            let date = Calendar.current.date(byAdding: .day, value: daysAgo, to: Date())!
            let record = SleepRecord()
            record.endTime = date
            record.duration = 5 * 3600
            return record
        }
        #expect(HealthCalculator.checkSleepDeficit(sleeps: sleeps, threshold: 6))
    }

    @Test("睡眠充足不触发预警")
    func testNoSleepDeficitAlert() {
        let sleeps = [-3, -2, -1].map { daysAgo in
            let date = Calendar.current.date(byAdding: .day, value: daysAgo, to: Date())!
            let record = SleepRecord()
            record.endTime = date
            record.duration = 8 * 3600
            return record
        }
        #expect(!HealthCalculator.checkSleepDeficit(sleeps: sleeps, threshold: 6))
    }

    @Test("心率异常触发预警")
    func testHeartRateAbnormal() {
        #expect(HealthCalculator.isHeartRateAbnormal(bpm: 110, max: 100, min: 50))
        #expect(HealthCalculator.isHeartRateAbnormal(bpm: 40, max: 100, min: 50))
        #expect(!HealthCalculator.isHeartRateAbnormal(bpm: 72, max: 100, min: 50))
    }

    @Test("久坐预警无运动记录触发")
    func testSedentaryAlert() {
        let workouts: [WorkoutRecord] = []
        #expect(HealthCalculator.checkSedentary(workouts: workouts, daysBack: 7))
    }

    @Test("久坐预警有运动记录不触发")
    func testNoSedentaryAlert() {
        let workout = WorkoutRecord()
        workout.startTime = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        #expect(!HealthCalculator.checkSedentary(workouts: [workout], daysBack: 7))
    }
}