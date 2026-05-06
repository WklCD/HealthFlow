import SwiftUI
import SwiftData

struct AlertHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \IgnoredAlert.ignoredDate, order: .reverse) var ignoredAlerts: [IgnoredAlert]
    @State private var showingThresholdForm = false

    var body: some View {
        List {
            Section("预警管理") {
                Button(action: { showingThresholdForm = true }) {
                    Label("自定义预警阈值", systemImage: "slider.horizontal.3")
                }
            }

            if ignoredAlerts.isEmpty {
                Section {
                    EmptyStateView(
                        iconName: "bell.slash",
                        title: "暂无预警记录",
                        message: "被忽略的预警警报将显示在这里"
                    )
                }
            } else {
                Section("已忽略的预警 (\(ignoredAlerts.count))") {
                    ForEach(ignoredAlerts, id: \.self) { alert in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(alert.alertType)
                                    .font(.headline)
                                Text(alert.triggeredDate, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(alert.ignoredDate, style: .date)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .onDelete(perform: deleteAlerts)
                }
            }
        }
        .navigationTitle("预警历史")
        .sheet(isPresented: $showingThresholdForm) {
            ThresholdSettingsView()
        }
    }

    private func deleteAlerts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(ignoredAlerts[index])
        }
    }
}

struct ThresholdSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("alert_heartRate_high") private var heartRateHigh: Double = 100
    @AppStorage("alert_heartRate_low") private var heartRateLow: Double = 50
    @AppStorage("alert_bloodOxygen_low") private var bloodOxygenLow: Double = 95
    @AppStorage("alert_weight_change") private var weightChange: Double = 2
    @AppStorage("alert_sleep_low") private var sleepQualityLow: Double = 2

    var body: some View {
        NavigationStack {
            Form {
                Section("心率预警阈值") {
                    Stepper("最高心率: \(Int(heartRateHigh)) bpm", value: $heartRateHigh, in: 80...200, step: 5)
                    Stepper("最低心率: \(Int(heartRateLow)) bpm", value: $heartRateLow, in: 30...80, step: 5)
                }
                Section("血氧预警阈值") {
                    Stepper("最低血氧: \(Int(bloodOxygenLow))%", value: $bloodOxygenLow, in: 85...100, step: 1)
                }
                Section("体重预警阈值") {
                    Stepper("体重变化超过: \(String(format: "%.1f", weightChange)) kg", value: $weightChange, in: 0.5...10, step: 0.5)
                }
                Section("睡眠质量预警阈值") {
                    Stepper("最低睡眠评分: \(Int(sleepQualityLow))", value: $sleepQualityLow, in: 1...5, step: 1)
                }
            }
            .navigationTitle("预警阈值设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}