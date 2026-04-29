import Foundation
import SwiftData

@Model
final class DailyActivitySummary {
    var date: Date = Date()
    var steps: Int = 0
    var calories: Double = 0
    var distance: Double = 0
    var standHours: Int?
    var source: String = "healthkit"
    @Attribute(.unique) var healthKitUUID: String?
    var note: String?

    init(date: Date = Date(), steps: Int = 0, calories: Double = 0, distance: Double = 0, standHours: Int? = nil, source: String = "healthkit", healthKitUUID: String? = nil, note: String? = nil) {
        self.date = date
        self.steps = steps
        self.calories = calories
        self.distance = distance
        self.standHours = standHours
        self.source = source
        self.healthKitUUID = healthKitUUID
        self.note = note
    }
}