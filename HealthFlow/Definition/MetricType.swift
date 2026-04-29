import Foundation

enum MetricType: String, CaseIterable {
    case weight = "weight"
    case heartRate = "heartRate"
    case bloodOxygen = "bloodOxygen"
    case bodyTemperature = "bodyTemperature"
    case bloodPressure = "bloodPressure"
    case bloodGlucose = "bloodGlucose"

    var displayName: String {
        switch self {
        case .weight: return "体重"
        case .heartRate: return "心率"
        case .bloodOxygen: return "血氧"
        case .bodyTemperature: return "体温"
        case .bloodPressure: return "血压"
        case .bloodGlucose: return "血糖"
        }
    }

    var unit: String {
        switch self {
        case .weight: return "kg"
        case .heartRate: return "bpm"
        case .bloodOxygen: return "%"
        case .bodyTemperature: return "°C"
        case .bloodPressure: return "mmHg"
        case .bloodGlucose: return "mmol/L"
        }
    }

    var requiresDualValues: Bool { self == .bloodPressure }

    var normalRangeDescription: String {
        switch self {
        case .weight: return "因人而异"
        case .heartRate: return "60-100 bpm（静息）"
        case .bloodOxygen: return "95-100%"
        case .bodyTemperature: return "36.0-37.3°C"
        case .bloodPressure: return "90-139 / 60-89 mmHg"
        case .bloodGlucose: return "3.9-6.1 mmol/L（空腹）"
        }
    }
}