import Foundation
import SwiftData

@Model
final class SleepRecord {
    var startTime: Date = Date()
    var endTime: Date = Date()
    var duration: TimeInterval = 0
    var deepSleep: TimeInterval?
    var remSleep: TimeInterval?
    var quality: Int = 0
    var source: String = "manual"
    @Attribute(.unique) var healthKitUUID: String?
    var note: String?

    init(startTime: Date = Date(), endTime: Date = Date(), duration: TimeInterval = 0, deepSleep: TimeInterval? = nil, remSleep: TimeInterval? = nil, quality: Int = 0, source: String = "manual", healthKitUUID: String? = nil, note: String? = nil) {
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.deepSleep = deepSleep
        self.remSleep = remSleep
        self.quality = quality
        self.source = source
        self.healthKitUUID = healthKitUUID
        self.note = note
    }
}