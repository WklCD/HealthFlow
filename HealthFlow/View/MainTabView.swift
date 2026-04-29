import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
            HealthDataListView()
            AIAssistantView()
            ProfileView()
        }
    }
}