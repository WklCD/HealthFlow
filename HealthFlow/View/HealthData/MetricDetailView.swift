import SwiftUI

struct MetricDetailView: View {
    let vm: HealthDataViewModel
    @State private var selectedType: MetricType = .weight
    @State private var showingAddSheet = false

    var body: some View {
        List {
            Section {
                Picker("指标类型", selection: $selectedType) {
                    ForEach(MetricType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("参考范围") {
                Text(selectedType.normalRangeDescription)
                    .foregroundStyle(.secondary)
            }

            if filteredMetrics.isEmpty {
                Section {
                    Text("暂无\(selectedType.displayName)记录")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("\(selectedType.displayName)记录") {
                    ForEach(filteredMetrics, id: \.self) { metric in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(metric.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                if selectedType == .bloodPressure, let systolic = metric.valueSystolic, let diastolic = metric.valueDiastolic {
                                    Text("\(Int(systolic))/\(Int(diastolic)) \(selectedType.unit)")
                                        .font(.headline)
                                } else {
                                    Text(String(format: "%.1f %@", metric.value, selectedType.unit))
                                        .font(.headline)
                                }
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
    }

    private var filteredMetrics: [PhysiologicalMetric] {
        vm.metrics.filter { $0.metricType == selectedType.rawValue }
            .sorted { $0.timestamp > $1.timestamp }
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
        case .bloodOxygen: return 0.1
        case .bodyTemperature: return 0.1
        case .bloodGlucose: return 0.1
        case .bloodPressure: return 1
        }
    }
}