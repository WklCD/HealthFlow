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