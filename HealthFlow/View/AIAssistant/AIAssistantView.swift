import SwiftUI

struct AIAssistantView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple)
                Text("AI 助手")
                    .font(.title)
                Text("即将在第四阶段实现")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("AI 助手")
        }
        .tabItem {
            Label("AI 助手", systemImage: "brain")
        }
    }
}