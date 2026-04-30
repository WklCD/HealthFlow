import SwiftUI
import SwiftData

struct HealthDataListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HealthDataViewModel?

    var body: some View {
        NavigationStack {
            List {
                Section("运动") {
                    NavigationLink {
                        if let vm = viewModel {
                            ActivityDetailView(vm: vm)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "figure.walk").foregroundStyle(.orange)
                            Text("运动")
                            Spacer()
                            if let vm = viewModel {
                                Text("\(vm.workouts.count)次").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("睡眠") {
                    NavigationLink {
                        if let vm = viewModel {
                            SleepDetailView(vm: vm)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "moon.zzz.fill").foregroundStyle(.indigo)
                            Text("睡眠")
                        }
                    }
                }
                Section("饮食") {
                    NavigationLink {
                        if let vm = viewModel {
                            DietDetailView(vm: vm)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "fork.knife").foregroundStyle(.green)
                            Text("饮食")
                        }
                    }
                }
                Section("生理指标") {
                    NavigationLink {
                        if let vm = viewModel {
                            MetricDetailView(vm: vm)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "heart.text.square.fill").foregroundStyle(.red)
                            Text("生理指标")
                        }
                    }
                }
                Section("用药记录") {
                    NavigationLink {
                        if let vm = viewModel {
                            MedicationDetailView(vm: vm)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "pills.fill").foregroundStyle(.blue)
                            Text("用药记录")
                        }
                    }
                }
            }
            .navigationTitle("健康数据")
        }
        .tabItem { Label("健康数据", systemImage: "heart.text.clipboard.fill") }
        .task {
            let vm = HealthDataViewModel(modelContext: modelContext, healthKit: HealthKitManager.shared)
            vm.loadAllData()
            viewModel = vm
            await vm.requestAuthorizationAndSync()
        }
    }
}