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