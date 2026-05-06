import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ProfileViewModel?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        if let vm = viewModel {
                            PersonalInfoView(viewModel: vm)
                        }
                    } label: {
                        Label("个人档案", systemImage: "person.fill")
                    }
                }

                Section {
                    NavigationLink(destination: HealthReportView()) {
                        Label("健康报告", systemImage: "doc.text.fill")
                    }
                    NavigationLink(destination: ExportView()) {
                        Label("数据导出", systemImage: "square.and.arrow.up.fill")
                    }
                    NavigationLink(destination: AchievementView()) {
                        Label("成就徽章", systemImage: "medal.fill")
                    }
                    NavigationLink(destination: AlertHistoryView()) {
                        Label("预警管理", systemImage: "bell.badge.fill")
                    }
                }

                Section {
                    NavigationLink(destination: SettingsView()) {
                        Label("设置", systemImage: "gearshape.fill")
                    }
                }
            }
            .navigationTitle("我的")
        }
        .tabItem {
            Label("我的", systemImage: "person.circle.fill")
        }
        .task {
            let vm = ProfileViewModel(modelContext: modelContext)
            vm.loadProfile()
            viewModel = vm
        }
    }
}