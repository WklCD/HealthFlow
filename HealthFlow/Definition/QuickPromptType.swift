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