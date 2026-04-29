import SwiftUI

struct HealthDataListView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "list.clipboard.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                Text("健康数据")
                    .font(.title)
                Text("即将在第二阶段实现")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("健康数据")
        }
        .tabItem {
            Label("健康数据", systemImage: "heart.text.clipboard.fill")
        }
    }
}