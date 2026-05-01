import SwiftUI
import SwiftData

struct HealthReportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HealthReportViewModel?
    @State private var selectedRange: HealthReportViewModel.DateRange = .week

    var body: some View {
        Group {
            if let data = viewModel?.reportData {
                List {
                    Section("日期范围") {
                        Text(data.dateRange)
                    }

                    Section("运动") {
                        HStack {
                            Label("日均步数", systemImage: "figure.walk")
                            Spacer()
                            Text("\(data.avgSteps) 步")
                        }
                        HStack {
                            Label("运动次数", systemImage: "dumbbell")
                            Spacer()
                            Text("\(data.totalWorkouts) 次")
                        }
                    }

                    Section("睡眠") {
                        HStack {
                            Label("平均时长", systemImage: "moon.zzz.fill")
                            Spacer()
                            Text(String(format: "%.1f h", data.avgSleepHours))
                        }
                        HStack {
                            Label("平均质量", systemImage: "star.fill")
                            Spacer()
                            Text(String(format: "%.1f / 5", data.avgSleepQuality))
                        }
                    }

                    Section("饮食") {
                        HStack {
                            Label("日均卡路里", systemImage: "fork.knife")
                            Spacer()
                            Text("\(Int(data.avgCalories)) 千卡")
                        }
                    }

                    Section("体征") {
                        HStack {
                            Label("平均心率", systemImage: "heart.fill")
                            Spacer()
                            Text("\(Int(data.avgHeartRate)) bpm")
                        }
                        HStack {
                            Label("体重趋势", systemImage: "scalemass.fill")
                            Spacer()
                            Text(data.weightTrend)
                        }
                    }

                    if !data.alerts.isEmpty {
                        Section("健康提醒") {
                            ForEach(data.alerts, id: \.self) { alert in
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.yellow)
                                    Text(alert)
                                }
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView("暂无数据", systemImage: "doc.text", description: Text("选择日期范围生成健康报告"))
            }
        }
        .navigationTitle("健康报告")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("范围", selection: $selectedRange) {
                    Text("周报").tag(HealthReportViewModel.DateRange.week)
                    Text("月报").tag(HealthReportViewModel.DateRange.month)
                }
                .pickerStyle(.segmented)
            }
        }
        .onChange(of: selectedRange) { _, newValue in
            viewModel?.selectedRange = newValue
            viewModel?.generateReport()
        }
        .task {
            let vm = HealthReportViewModel(modelContext: modelContext)
            vm.generateReport()
            viewModel = vm
        }
    }
}