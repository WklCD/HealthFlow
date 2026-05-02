import SwiftUI

enum MetricType: String, CaseIterable {
    case heartRate = "heartRate"
    case bloodOxygen = "bloodOxygen"
    case bodyTemperature = "bodyTemperature"
    case weight = "weight"
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

    static var displayCases: [MetricType] {
        [.heartRate, .bloodOxygen, .bodyTemperature, .weight]
    }

    var icon: String {
        switch self {
        case .weight: return "scalemass.fill"
        case .heartRate: return "heart.fill"
        case .bloodOxygen: return "lungs.fill"
        case .bodyTemperature: return "thermometer.medium"
        case .bloodPressure: return "heart.text.square.fill"
        case .bloodGlucose: return "drop.fill"
        }
    }

    var strokeColor: Color {
        switch self {
        case .heartRate: return .red
        case .bloodOxygen: return .blue
        case .bodyTemperature: return .orange
        case .weight: return .purple
        case .bloodPressure: return .red
        case .bloodGlucose: return .mint
        }
    }
}