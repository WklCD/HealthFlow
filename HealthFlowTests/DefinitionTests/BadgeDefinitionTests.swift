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