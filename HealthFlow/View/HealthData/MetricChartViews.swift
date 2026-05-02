import SwiftUI
import Charts

struct MetricDayGroup {
    let date: Date
    let metrics: [PhysiologicalMetric]

    var average: Double {
        guard !metrics.isEmpty else { return 0 }
        return metrics.map(\.value).reduce(0, +) / Double(metrics.count)
    }

    var min: Double {
        metrics.map(\.value).min() ?? 0
    }

    var max: Double {
        metrics.map(\.value).max() ?? 0
    }
}

private func normalizeBloodOxygen(_ value: Double) -> Double {
    value <= 1.0 ? value * 100 : value
}

struct HeartRateChartView: View {
    let metrics: [PhysiologicalMetric]
    @State private var selectedDayIndex: Int = 0

    private var groupedByDay: [MetricDayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: metrics) { metric in
            calendar.startOfDay(for: metric.timestamp)
        }
        return grouped.map { MetricDayGroup(date: $0.key, metrics: $0.value.sorted { $0.timestamp < $1.timestamp }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        let groups = groupedByDay
        if groups.isEmpty {
            ContentUnavailableView("暂无心率数据", systemImage: "heart.slash", description: Text("同步 HealthKit 心率数据后即可查看"))
        } else {
            VStack(spacing: 0) {
                dayNavigation(groups: groups)

                if selectedDayIndex < groups.count {
                    let group = groups[selectedDayIndex]
                    chartContent(group: group)
                    statisticsSection(group: group)
                }

                Spacer()
            }
            .navigationTitle("心率趋势")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func dayNavigation(groups: [MetricDayGroup]) -> some View {
        HStack {
            Button(action: {
                if selectedDayIndex < groups.count - 1 { selectedDayIndex += 1 }
            }) {
                Image(systemName: "chevron.left")
            }
            .disabled(selectedDayIndex >= groups.count - 1)

            Spacer()

            Text(groups[selectedDayIndex < groups.count ? selectedDayIndex : 0].date.chineseDate)
                .font(.headline)

            Spacer()

            Button(action: {
                if selectedDayIndex > 0 { selectedDayIndex -= 1 }
            }) {
                Image(systemName: "chevron.right")
            }
            .disabled(selectedDayIndex <= 0)
        }
        .padding()
    }

    private func chartContent(group: MetricDayGroup) -> some View {
        VStack {
            Chart(group.metrics, id: \.self) { metric in
                PointMark(
                    x: .value("时间", metric.timestamp, unit: .hour),
                    y: .value("心率", metric.value)
                )
                .foregroundStyle(.red)
                .symbolSize(12)
            }
            .chartYScale(domain: max(group.min - 10, 30)...(group.max + 10))
            .frame(height: 220)
            .padding(.horizontal)

            HStack(spacing: 24) {
                legendItem(color: .red, label: "心率")
            }
            .font(.caption)
            .padding(.top, 4)
        }
    }

    private func statisticsSection(group: MetricDayGroup) -> some View {
        List {
            Section("统计") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("平均")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f bpm", group.average))
                            .font(.title3.bold())
                    }
                    Spacer()
                    VStack(alignment: .center) {
                        Text("最低")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f bpm", group.min))
                            .font(.title3.bold())
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("最高")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f bpm", group.max))
                            .font(.title3.bold())
                            .foregroundStyle(.red)
                    }
                }
            }

            Section {
                NavigationLink {
                    HeartRateDetailList(metrics: group.metrics)
                } label: {
                    Text("查看详细记录（\(group.metrics.count)条）")
                }
            }
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
}

struct HeartRateDetailList: View {
    let metrics: [PhysiologicalMetric]

    var body: some View {
        List {
            ForEach(metrics, id: \.self) { metric in
                HStack {
                    Text(metric.timestamp.timeOnly)
                    Spacer()
                    Text(String(format: "%.0f bpm", metric.value))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("心率详细记录")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BloodOxygenChartView: View {
    let metrics: [PhysiologicalMetric]
    @State private var selectedDayIndex: Int = 0

    private var normalizedMetrics: [PhysiologicalMetric] {
        metrics.map { m in
            if m.metricType == "bloodOxygen" && m.value <= 1.0 {
                let normalized = PhysiologicalMetric()
                normalized.metricType = m.metricType
                normalized.value = m.value * 100.0
                normalized.unit = m.unit
                normalized.timestamp = m.timestamp
                normalized.source = m.source
                normalized.healthKitUUID = m.healthKitUUID
                normalized.measurementGroupID = m.measurementGroupID
                normalized.note = m.note
                return normalized
            }
            return m
        }
    }

    private var groupedByDay: [MetricDayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: normalizedMetrics) { metric in
            calendar.startOfDay(for: metric.timestamp)
        }
        return grouped.map { MetricDayGroup(date: $0.key, metrics: $0.value.sorted { $0.timestamp < $1.timestamp }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        let groups = groupedByDay
        if groups.isEmpty {
            ContentUnavailableView("暂无血氧数据", systemImage: "lungs", description: Text("同步 HealthKit 血氧数据后即可查看"))
        } else {
            VStack(spacing: 0) {
                dayNavigation(groups: groups)

                if selectedDayIndex < groups.count {
                    let group = groups[selectedDayIndex]
                    chartContent(group: group)
                    statisticsSection(group: group)
                }

                Spacer()
            }
            .navigationTitle("血氧趋势")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func dayNavigation(groups: [MetricDayGroup]) -> some View {
        HStack {
            Button(action: {
                if selectedDayIndex < groups.count - 1 { selectedDayIndex += 1 }
            }) {
                Image(systemName: "chevron.left")
            }
            .disabled(selectedDayIndex >= groups.count - 1)

            Spacer()

            Text(groups[selectedDayIndex < groups.count ? selectedDayIndex : 0].date.chineseDate)
                .font(.headline)

            Spacer()

            Button(action: {
                if selectedDayIndex > 0 { selectedDayIndex -= 1 }
            }) {
                Image(systemName: "chevron.right")
            }
            .disabled(selectedDayIndex <= 0)
        }
        .padding()
    }

    private func chartContent(group: MetricDayGroup) -> some View {
        VStack {
            Chart(group.metrics, id: \.self) { metric in
                PointMark(
                    x: .value("时间", metric.timestamp, unit: .hour),
                    y: .value("血氧", metric.value)
                )
                .foregroundStyle(.blue)
                .symbolSize(12)
            }
            .chartYScale(domain: min(group.min - 3, 85)...100)
            .frame(height: 220)
            .padding(.horizontal)

            HStack(spacing: 24) {
                legendItem(color: .blue, label: "血氧饱和度")
            }
            .font(.caption)
            .padding(.top, 4)
        }
    }

    private func statisticsSection(group: MetricDayGroup) -> some View {
        List {
            Section("统计") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("平均")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f%%", group.average))
                            .font(.title3.bold())
                    }
                    Spacer()
                    VStack(alignment: .center) {
                        Text("最低")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f%%", group.min))
                            .font(.title3.bold())
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("最高")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f%%", group.max))
                            .font(.title3.bold())
                            .foregroundStyle(.indigo)
                    }
                }
            }

            Section {
                NavigationLink {
                    BloodOxygenDetailList(metrics: group.metrics)
                } label: {
                    Text("查看详细记录（\(group.metrics.count)条）")
                }
            }
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
}

struct BloodOxygenDetailList: View {
    let metrics: [PhysiologicalMetric]

    var body: some View {
        List {
            ForEach(metrics, id: \.self) { metric in
                HStack {
                    Text(metric.timestamp.timeOnly)
                    Spacer()
                    Text(String(format: "%.0f%%", normalizeBloodOxygen(metric.value)))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("血氧详细记录")
        .navigationBarTitleDisplayMode(.inline)
    }
}