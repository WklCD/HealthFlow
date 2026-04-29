import Foundation
import SwiftData

@Model
final class WorkoutRecord {
    var exerciseType: String = ""
    var startTime: Date = Date()
    var endTime: Date = Date()
    var duration: TimeInterval = 0
    var calories: Double = 0
    var steps: Int?
    var distance: Double?
    var heartRateAvg: Double?
    var heartRateMax: Double?
    var source: String = "manual"
    @Attribute(.unique) var healthKitUUID: String?
    var note: String?

    init(exerciseType: String = "", startTime: Date = Date(), endTime: Date = Date(), duration: TimeInterval = 0, calories: Double = 0, steps: Int? = nil, distance: Double? = nil, heartRateAvg: Double? = nil, heartRateMax: Double? = nil, source: String = "manual", healthKitUUID: String? = nil, note: String? = nil) {
        self.exerciseType = exerciseType
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.calories = calories
        self.steps = steps
        self.distance = distance
        self.heartRateAvg = heartRateAvg
        self.heartRateMax = heartRateMax
        self.source = source
        self.healthKitUUID = healthKitUUID
        self.note = note
    }
}