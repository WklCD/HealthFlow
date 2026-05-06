import SwiftUI
import Charts

struct MetricDetailView: View {
    let vm: HealthDataViewModel
    @State private var selectedType: MetricType = .heartRate
    @State private var showingAddSheet = false
    @State private var showAllRecords = false

    private var filteredMetrics: [PhysiologicalMetric] {
        vm.metrics.filter { $0.metricType == selectedType.rawValue }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var displayMetrics: [PhysiologicalMetric] {
        if showAllRecords || filteredMetrics.count <= 5 {
            return filteredMetrics
        }
        return Array(filteredMetrics.prefix(5))
    }

    var body: some View {
        List {
            Section {
                Picker("指标类型", selection: $selectedType) {
                    ForEach(MetricType.displayCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            if selectedType == .heartRate {
                NavigationLink {
                    HeartRateChartView(metrics: vm.metrics.filter { $0.metricType == "heartRate" })
                } label: {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                        Text("心率趋势图")
                    }
                }
            } else if selectedType == .bloodOxygen {
                NavigationLink {
                    BloodOxygenChartView(metrics: vm.metrics.filter { $0.metricType == "bloodOxygen" })
                } label: {
                    HStack {
                        Image(systemName: "lungs.fill")
                            .foregroundStyle(.blue)
                        Text("血氧趋势图")
                    }
                }
            } else if selectedType == .bodyTemperature {
                NavigationLink {
                    BodyTemperatureChartView(metrics: vm.metrics.filter { $0.metricType == "bodyTemperature" })
                } label: {
                    HStack {
                        Image(systemName: "thermometer.medium")
                            .foregroundStyle(.orange)
                        Text("体温趋势图")
                    }
                }
            } else if selectedType == .weight {
                NavigationLink {
                    WeightChartView(metrics: vm.metrics.filter { $0.metricType == "weight" })
                } label: {
                    HStack {
                        Image(systemName: "scalemass.fill")
                            .foregroundStyle(.purple)
                        Text("体重趋势图")
                    }
                }
            }

            if filteredMetrics.isEmpty {
                Section {
                    Text("暂无\(selectedType.displayName)记录")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("\(selectedType.displayName)记录") {
                    ForEach(displayMetrics, id: \.self) { metric in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(metric.timestamp.chineseDateTime)
                                    .font(.subheadline)
                                Text(formatMetricValue(metric))
                                    .font(.headline)
                            }
                            Spacer()
                            Text(metric.source == "healthkit" ? "HealthKit" : "手动")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        let metrics = filteredMetrics
                        for index in indexSet {
                            vm.deletePhysiologicalMetric(metrics[index])
                        }
                    }

                    if !showAllRecords && filteredMetrics.count > 5 {
                        Button("查看全部 \(filteredMetrics.count) 条记录") {
                            showAllRecords = true
                        }
                    }
                }
            }
        }
        .navigationTitle("生理指标")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddMetricSheet(vm: vm, selectedType: selectedType)
        }
        .onChange(of: selectedType) { _, _ in
            showAllRecords = false
        }
    }

    private func formatMetricValue(_ metric: PhysiologicalMetric) -> String {
        if metric.metricType == MetricType.bloodPressure.rawValue,
           let systolic = metric.valueSystolic,
           let diastolic = metric.valueDiastolic {
            return "\(Int(systolic))/\(Int(diastolic)) \(selectedType.unit)"
        }
        if selectedType == .bloodOxygen {
            let displayValue = metric.value <= 1.0 ? metric.value * 100 : metric.value
            return String(format: "%.0f%%", displayValue)
        }
        return String(format: "%.1f %@", metric.value, selectedType.unit)
    }
}

struct AddMetricSheet: View {
    let vm: HealthDataViewModel
    let selectedType: MetricType
    @Environment(\.dismiss) private var dismiss
    @State private var value: Double = 0
    @State private var systolicValue: Double = 120
    @State private var diastolicValue: Double = 80
    @State private var note: String = ""
    @State private var timestamp = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("类型") {
                    Text(selectedType.displayName)
                        .font(.headline)
                }
                if selectedType.requiresDualValues {
                    Section("血压值") {
                        Stepper("收缩压: \(Int(systolicValue)) mmHg", value: $systolicValue, step: 1)
                        Stepper("舒张压: \(Int(diastolicValue)) mmHg", value: $diastolicValue, step: 1)
                    }
                } else {
                    Section("数值") {
                        Stepper("\(selectedType.displayName): \(String(format: "%.1f", value)) \(selectedType.unit)", value: $value, step: stepForType)
                    }
                }
                Section("时间") {
                    DatePicker("记录时间", selection: $timestamp)
                }
                Section("备注") {
                    TextField("备注（可选）", text: $note)
                }
            }
            .navigationTitle("添加\(selectedType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let metric = PhysiologicalMetric()
                        metric.metricType = selectedType.rawValue
                        metric.timestamp = timestamp
                        metric.source = "manual"
                        metric.note = note.isEmpty ? nil : note
                        if selectedType.requiresDualValues {
                            metric.value = systolicValue
                            metric.valueSystolic = systolicValue
                            metric.valueDiastolic = diastolicValue
                            metric.unit = selectedType.unit
                        } else {
                            metric.value = value
                            metric.unit = selectedType.unit
                        }
                        vm.addPhysiologicalMetric(metric)
                        dismiss()
                    }
                }
            }
        }
    }

    private var stepForType: Double {
        switch selectedType {
        case .weight: return 0.1
        case .heartRate: return 1
        case .bloodOxygen: return 1
        case .bodyTemperature: return 0.1
        case .bloodGlucose: return 0.1
        case .bloodPressure: return 1
        }
    }
}