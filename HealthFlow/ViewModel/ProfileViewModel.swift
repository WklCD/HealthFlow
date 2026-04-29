import Foundation
import SwiftUI
import SwiftData

@Observable
final class ProfileViewModel {
    var profile: UserProfile?
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            let profiles = try modelContext.fetch(descriptor)
            if let existing = profiles.first {
                profile = existing
            } else {
                let newProfile = UserProfile()
                modelContext.insert(newProfile)
                try modelContext.save()
                profile = newProfile
            }
        } catch {
            print("加载 UserProfile 失败: \(error)")
        }
    }

    func saveProfile(
        name: String,
        gender: String,
        birthDate: Date,
        height: Double,
        targetWeight: Double? = nil,
        targetSteps: Int? = nil,
        targetSleepHours: Double? = nil,
        targetCalories: Int? = nil
    ) {
        guard let p = profile else { return }
        p.name = name
        p.gender = gender
        p.birthDate = birthDate
        p.height = height
        p.targetWeight = targetWeight
        p.targetSteps = targetSteps
        p.targetSleepHours = targetSleepHours
        p.targetCalories = targetCalories
        do {
            try modelContext.save()
        } catch {
            print("保存 UserProfile 失败: \(error)")
        }
    }
}