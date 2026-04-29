import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                Text("仪表盘")
                    .font(.title)
                Text("即将在第三阶段实现")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("仪表盘")
        }
        .tabItem {
            Label("仪表盘", systemImage: "house.fill")
        }
    }
}