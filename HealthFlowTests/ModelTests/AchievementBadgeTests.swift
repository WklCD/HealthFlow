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