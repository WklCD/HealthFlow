import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String = ""
    var gender: String = "unset"
    var birthDate: Date = Date()
    var height: Double = 0
    var targetWeight: Double?
    var targetSteps: Int?
    var targetSleepHours: Double?
    var targetCalories: Int?
    var createdAt: Date = Date()

    init(name: String = "",
         gender: String = "unset",
         birthDate: Date = Date(),
         height: Double = 0,
         targetWeight: Double? = nil,
         targetSteps: Int? = nil,
         targetSleepHours: Double? = nil,
         targetCalories: Int? = nil) {
        self.name = name
        self.gender = gender
        self.birthDate = birthDate
        self.height = height
        self.targetWeight = targetWeight
        self.targetSteps = targetSteps
        self.targetSleepHours = targetSleepHours
        self.targetCalories = targetCalories
        self.createdAt = Date()
    }
}