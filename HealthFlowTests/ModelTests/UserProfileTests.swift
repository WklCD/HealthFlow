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