import Foundation
import SwiftData

@Model
final class PhysiologicalMetric {
    var metricType: String = ""
    var value: Double = 0
    var valueSystolic: Double?
    var valueDiastolic: Double?
    var unit: String = ""
    var timestamp: Date = Date()
    var source: String = "manual"
    @Attribute(.unique) var healthKitUUID: String?
    var measurementGroupID: String?
    var note: String?

    init(metricType: String = "", value: Double = 0, valueSystolic: Double? = nil, valueDiastolic: Double? = nil, unit: String = "", timestamp: Date = Date(), source: String = "manual", healthKitUUID: String? = nil, measurementGroupID: String? = nil, note: String? = nil) {
        self.metricType = metricType
        self.value = value
        self.valueSystolic = valueSystolic
        self.valueDiastolic = valueDiastolic
        self.unit = unit
        self.timestamp = timestamp
        self.source = source
        self.healthKitUUID = healthKitUUID
        self.measurementGroupID = measurementGroupID
        self.note = note
    }
}