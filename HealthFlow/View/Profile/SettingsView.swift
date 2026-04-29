import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var darkModeSelection: String = "system"

    var body: some View {
        Form {
            Section("隐私与安全") {
                HStack {
                    Label("隐私锁", systemImage: "lock.fill")
                    Spacer()
                    Toggle("", isOn: .constant(false))
                        .disabled(true)
                }
            }

            Section("AI 配置") {
                NavigationLink(destination: EmptyView()) {
                    Label("API 配置", systemImage: "key.fill")
                }
            }

            Section("外观") {
                Picker(selection: $darkModeSelection) {
                    Text("跟随系统").tag("system")
                    Text("浅色模式").tag("light")
                    Text("深色模式").tag("dark")
                } label: {
                    Label("深色模式", systemImage: "moon.fill")
                }
            }

            Section("数据管理") {
                Button {} label: {
                    Label("数据备份", systemImage: "arrow.triangle.2.circlepath")
                }
            }

            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("设置")
    }
}