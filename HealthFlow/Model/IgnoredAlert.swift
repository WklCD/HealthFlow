import Foundation
import SwiftData

@Model
final class IgnoredAlert {
    var alertType: String = ""
    var triggeredDate: Date = Date()
    var ignoredDate: Date = Date()

    init(alertType: String = "", triggeredDate: Date = Date(), ignoredDate: Date = Date()) {
        self.alertType = alertType
        self.triggeredDate = triggeredDate
        self.ignoredDate = ignoredDate
    }
}