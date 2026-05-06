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
            let storeURL = URL.applicationSupportDirectory.appendingPathComponent("HealthFlow.sqlite")
            let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("无法初始化 ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
        }
        .modelContainer(container)
    }
}

struct ContentView: View {
    let container: ModelContainer
    @Environment(\.scenePhase) private var scenePhase
    @State private var lockVM = PrivacyLockViewModel()

    var body: some View {
        ZStack {
            MainTabView()
            if lockVM.showLock && lockVM.needsAuthentication {
                PrivacyLockView(viewModel: lockVM)
                    .transition(.opacity)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                if lockVM.needsAuthentication { lockVM.lock() }
            }
        }
        .task {
            await ensureUserProfileExists()
        }
    }

    @MainActor
    private func ensureUserProfileExists() async {
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