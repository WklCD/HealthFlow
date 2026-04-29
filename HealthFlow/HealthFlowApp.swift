import SwiftUI
import SwiftData

@main
struct HealthFlowApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                UserProfile.self,
                DailyActivitySummary.self,
                WorkoutRecord.self,
                SleepRecord.self,
                DietRecord.self,
                FoodItem.self,
                PhysiologicalMetric.self,
                AchievementBadge.self,
                MedicationRecord.self,
                ChatMessage.self,
                FavoriteFood.self,
                IgnoredAlert.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            ensureUserProfileExists()
        } catch {
            fatalError("无法初始化 ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }

    private func ensureUserProfileExists() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            let profiles = try context.fetch(descriptor)
            if profiles.isEmpty {
                let defaultProfile = UserProfile()
                context.insert(defaultProfile)
                try context.save()
            }
        } catch {
            print("检查 UserProfile 时出错: \(error)")
        }
    }
}