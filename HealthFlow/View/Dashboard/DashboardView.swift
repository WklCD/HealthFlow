import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text(DateFormatter.fullDate.string(from: Date()))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("今日健康指数：\(viewModel?.todayScore ?? 0)分")
                            .font(.title.bold())
                    }
                    .padding(.top)

                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                        StatCard(title: "运动", value: "\(viewModel?.todaySteps ?? 0)", unit: "步",
                                 iconName: "figure.walk", color: .orange)
                        StatCard(title: "睡眠", value: String(format: "%.1f", viewModel?.sleepHours ?? 0.0), unit: "h",
                                 iconName: "moon.zzz.fill", color: .indigo)
                        StatCard(title: "饮食", value: "\(Int(viewModel?.dietCalories ?? 0))", unit: "千卡",
                                 iconName: "fork.knife", color: .green)
                        StatCard(title: "心率", value: "\(Int(viewModel?.avgHeartRate ?? 0))", unit: "bpm",
                                 iconName: "heart.fill", color: .red)
                    }
                    .padding(.horizontal)

                    if let dataPoints = viewModel.flatMap({ vm in
                        let calendar = Calendar.current
                        let now = Date()
                        return (0..<24).compactMap { hour -> HourStepData? in
                            guard let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) else { return nil }
                            return HourStepData(hour: date, steps: hour <= calendar.component(.hour, from: now) ? Int.random(in: 0...500) : 0)
                        }
                    }), !dataPoints.isEmpty {
                        TodayTrendChart(dataPoints: dataPoints)
                            .padding(.horizontal)
                    }

                    if let alerts = viewModel?.alerts, !alerts.isEmpty {
                        ForEach(alerts, id: \.self) { alert in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                Text(alert)
                                    .font(.subheadline)
                                Spacer()
                                Button("忽略") {}
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.yellow.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("仪表盘")
            .task {
                let vm = DashboardViewModel(modelContext: modelContext)
                vm.loadToday()
                viewModel = vm
            }
        }
        .tabItem {
            Label("仪表盘", systemImage: "house.fill")
        }
    }
}