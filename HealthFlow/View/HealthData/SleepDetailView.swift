import SwiftUI

struct SleepDetailView: View {
    let vm: HealthDataViewModel
    @State private var showingAddSheet = false

    var body: some View {
        List {
            if vm.sleepRecords.isEmpty {
                Section {
                    Text("暂无睡眠记录")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("最近记录") {
                    ForEach(vm.sleepRecords, id: \.self) { record in
                        NavigationLink {
                            SleepRecordDetail(record: record)
                        } label: {
                            HStack {
                                Image(systemName: "moon.zzz.fill")
                                    .foregroundStyle(.indigo)
                                VStack(alignment: .leading) {
                                    Text(record.startTime.formatted(date: .abbreviated, time: .shortened))
                                    Text(formatDuration(record.duration))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                qualityStars(record.quality)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            vm.deleteSleepRecord(vm.sleepRecords[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("睡眠")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddSleepSheet(vm: vm)
        }
    }

    private func qualityStars(_ quality: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= quality ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(star <= quality ? .yellow : .gray)
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)小时\(minutes)分钟"
    }
}

struct SleepRecordDetail: View {
    let record: SleepRecord

    var body: some View {
        List {
            Section("时间") {
                LabeledContent("入睡时间", value: record.startTime.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("起床时间", value: record.endTime.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("总时长", value: formatDuration(record.duration))
            }
            if let deepSleep = record.deepSleep, deepSleep > 0 {
                Section("睡眠分析") {
                    LabeledContent("深度睡眠", value: formatDuration(deepSleep))
                    if let remSleep = record.remSleep, remSleep > 0 {
                        LabeledContent("REM 睡眠", value: formatDuration(remSleep))
                    }
                }
            }
            Section("质量") {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= record.quality ? "star.fill" : "star")
                            .foregroundStyle(star <= record.quality ? .yellow : .gray)
                    }
                }
            }
            if let note = record.note, !note.isEmpty {
                Section("备注") { Text(note) }
            }
        }
        .navigationTitle("睡眠详情")
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)小时\(minutes)分钟"
    }
}

struct AddSleepSheet: View {
    let vm: HealthDataViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var quality: Int = 3
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("时间") {
                    DatePicker("入睡时间", selection: $startTime)
                    DatePicker("起床时间", selection: $endTime)
                }
                Section("质量评分") {
                    Picker("质量", selection: $quality) {
                        ForEach(1...5, id: \.self) { star in
                            Text(String(repeating: "★", count: star)).tag(star)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("备注") {
                    TextField("备注（可选）", text: $note)
                }
            }
            .navigationTitle("添加睡眠")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let record = SleepRecord()
                        record.startTime = startTime
                        record.endTime = endTime
                        record.duration = endTime.timeIntervalSince(startTime)
                        record.quality = quality
                        record.source = "manual"
                        record.note = note.isEmpty ? nil : note
                        vm.addSleepRecord(record)
                        dismiss()
                    }
                }
            }
        }
    }
}