import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedType: ExportType = .workouts
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State private var endDate = Date()
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    enum ExportType: String, CaseIterable {
        case workouts, sleep, diet, metrics, medications
        var displayName: String {
            switch self {
            case .workouts: return "运动数据"
            case .sleep: return "睡眠数据"
            case .diet: return "饮食数据"
            case .metrics: return "生理指标"
            case .medications: return "用药记录"
            }
        }
    }

    var body: some View {
        Form {
            Picker("数据类型", selection: $selectedType) {
                ForEach(ExportType.allCases, id: \.rawValue) { type in
                    Text(type.displayName).tag(type)
                }
            }
            DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
            DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
            Section {
                Button(action: exportCSV) {
                    Label("导出 CSV", systemImage: "square.and.arrow.up")
                }
            }
            if let url = exportURL {
                Section {
                    ShareLink(item: url) {
                        Label("分享文件", systemImage: "share")
                    }
                }
            }
        }
        .navigationTitle("数据导出")
    }

    private func exportCSV() {
        let service = ExportService()
        let predicate = #Predicate<Date> { date in
            date >= startDate && date <= endDate
        }

        do {
            let csv: String
            switch selectedType {
            case .workouts:
                let descriptor = FetchDescriptor<WorkoutRecord>(
                    predicate: #Predicate<WorkoutRecord> { $0.startTime >= startDate && $0.startTime <= endDate }
                )
                let items = try modelContext.fetch(descriptor)
                csv = try service.exportCSV(workouts: items)
            case .sleep:
                let descriptor = FetchDescriptor<SleepRecord>(
                    predicate: #Predicate<SleepRecord> { $0.startTime >= startDate && $0.startTime <= endDate }
                )
                let items = try modelContext.fetch(descriptor)
                csv = try service.exportCSV(sleeps: items)
            case .diet:
                let descriptor = FetchDescriptor<DietRecord>(
                    predicate: #Predicate<DietRecord> { $0.timestamp >= startDate && $0.timestamp <= endDate }
                )
                let items = try modelContext.fetch(descriptor)
                csv = try service.exportCSV(diets: items)
            case .metrics:
                let descriptor = FetchDescriptor<PhysiologicalMetric>(
                    predicate: #Predicate<PhysiologicalMetric> { $0.timestamp >= startDate && $0.timestamp <= endDate }
                )
                let items = try modelContext.fetch(descriptor)
                csv = try service.exportCSV(metrics: items)
            case .medications:
                let descriptor = FetchDescriptor<MedicationRecord>(
                    predicate: #Predicate<MedicationRecord> { $0.scheduledTime >= startDate && $0.scheduledTime <= endDate }
                )
                let items = try modelContext.fetch(descriptor)
                csv = try service.exportCSV(medications: items)
            }
            let url = try service.exportToFile(data: csv, filename: "\(selectedType.rawValue)_export.csv")
            exportURL = url
        } catch {
            print("导出失败: \(error)")
        }
    }
}