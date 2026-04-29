import Foundation
import SwiftData

@Model
final class MedicationRecord {
    var name: String = ""
    var dosage: String = ""
    var scheduledTime: Date = Date()
    var takenAt: Date?
    var source: String = "manual"
    var note: String?

    init(name: String = "", dosage: String = "", scheduledTime: Date = Date(), takenAt: Date? = nil, source: String = "manual", note: String? = nil) {
        self.name = name
        self.dosage = dosage
        self.scheduledTime = scheduledTime
        self.takenAt = takenAt
        self.source = source
        self.note = note
    }
}