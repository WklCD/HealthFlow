import Foundation
import SwiftData

@Model
final class AchievementBadge {
    var badgeType: String = ""
    var title: String = ""
    var earnedDate: Date = Date()

    init(badgeType: String = "", title: String = "", earnedDate: Date = Date()) {
        self.badgeType = badgeType
        self.title = title
        self.earnedDate = earnedDate
    }
}