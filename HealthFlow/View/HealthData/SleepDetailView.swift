import SwiftUI
import Charts

struct SleepDayGroup: Identifiable {
    let id = UUID()
    let date: Date
    let records: [SleepRecord]

    var earliestStart: Date {
        records.map(\.startTime).min() ?? date
    }

    var latestEnd: Date {
        records.map(\.endTime).max() ?? date
    }

    var totalDuration: TimeInterval {
        records.reduce(0) { $0 + $1.duration }
    }

    var totalDeepSleep: TimeInterval {
        records.filter { $0.sleepStage == "deep" }.reduce(0) { $0 + $1.duration }
    }

    var totalREMSleep: TimeInterval {
        records.filter { $0.sleepStage == "rem" }.reduce(0) { $0 + $1.duration }
    }

    var totalCoreSleep: TimeInterval {
        records.filter { $0.sleepStage == "core" }.reduce(0) { $0 + $1.duration }
    }

    var totalAwake: TimeInterval {
        records.filter { $0.sleepStage == "awake" }.reduce(0) { $0 + $1.duration }
    }

    var quality: Int {
        let manualRecord = records.first { $0.source == "manual" && $0.quality > 0 }
        if let record = manualRecord { return record.quality }
        return Self.calculateQuality(duration: totalDuration, deepPercent: totalDeepSleep / max(totalDuration, 1))
    }

    static func calculateQuality(duration: TimeInterval, deepPercent: Double) -> Int {
        let hours = duration / 3600
        var score = 3
        if hours >= 7 && hours <= 9 { score += 1 }
        if deepPercent >= 0.15 { score += 1 }
        if hours < 5 { score -= 1 }
        return min(5, max(1, score))
    }
}

struct SleepDetailView: View {
    let vm: HealthDataViewModel
    @State private var showingAddSheet = false

    private var groupedByDay: [SleepDayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: vm.sleepRecords) { record in
            let start = record.startTime
            if calendar.component(.hour, from: start) >= 20 {
                return calendar.startOfDay(for: start)
            } else if calendar.component(.hour, from: start) < 4 {
                let prevDay = calendar.date(byAdding: .day, value: -1, to: start) ?? start
                return calendar.startOfDay(for: prevDay)
            } else {
                return calendar.startOfDay(for: start)
            }
        }
        return grouped.map { SleepDayGroup(date: $0.key, records: $0.value.sorted { $0.startTime < $1.startTime }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            if vm.sleepRecords.isEmpty {
                Section {
                    Text("暂无睡眠记录")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(groupedByDay) { group in
                    NavigationLink {
                        SleepDayDetail(group: group)
                    } label: {
                        SleepDayRow(group: group)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let records = groupedByDay[index].records
                        for record in records {
                            vm.deleteSleepRecord(record)
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
}

struct SleepDayRow: View {
    let group: SleepDayGroup

    var body: some View {
        HStack {
            Image(systemName: "moon.zzz.fill")
                .foregroundStyle(.indigo)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(group.date.chineseDate)
                    .font(.headline)
                HStack(spacing: 12) {
                    Text(formatDuration(group.totalDuration))
                        .font(.subheadline)
                    Text("\(group.earliestStart.timeOnly) - \(group.latestEnd.timeOnly)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            qualityStars(group.quality)
        }
        .padding(.vertical, 2)
    }

    private func qualityStars(_ quality: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= quality ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(star <= quality ? .yellow : .gray.opacity(0.3))
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        }
        return "\(minutes)分钟"
    }
}

struct SleepDayDetail: View {
    let group: SleepDayGroup

    var body: some View {
        List {
            Section("睡眠时长") {
                HStack {
                    Label(formatDuration(group.totalDuration), systemImage: "moon.zzz.fill")
                        .font(.title3.bold())
                    Spacer()
                    qualityStars(group.quality)
                }
                HStack {
                    LabeledContent("入睡", value: group.earliestStart.timeOnly)
                    LabeledContent("起床", value: group.latestEnd.timeOnly)
                }
            }

            Section("睡眠阶段") {
                SleepStageLayeredChart(records: group.records, startTime: group.earliestStart, endTime: group.latestEnd)
                    .frame(height: 200)
            }

            let hasDeep = group.totalDeepSleep > 0
            let hasREM = group.totalREMSleep > 0
            let hasCore = group.totalCoreSleep > 0
            let hasAwake = group.totalAwake > 0

            if hasDeep || hasREM || hasCore || hasAwake {
                Section("阶段时长") {
                    if hasAwake {
                        stageRow(name: "清醒", duration: group.totalAwake, color: .orange)
                    }
                    if hasREM {
                        stageRow(name: "REM 睡眠", duration: group.totalREMSleep, color: .purple)
                    }
                    if hasCore {
                        stageRow(name: "核心睡眠", duration: group.totalCoreSleep, color: .blue.opacity(0.7))
                    }
                    if hasDeep {
                        stageRow(name: "深度睡眠", duration: group.totalDeepSleep, color: .indigo)
                    }
                }
            }

            Section("详细记录") {
                ForEach(group.records, id: \.self) { record in
                    HStack {
                        Circle()
                            .fill(colorForStage(record.sleepStage))
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading) {
                            Text(stageDisplayName(record.sleepStage))
                                .font(.subheadline)
                            Text("\(record.startTime.timeOnly) - \(record.endTime.timeOnly)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(formatDuration(record.duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if group.records.contains(where: { $0.note != nil && !$0.note!.isEmpty }) {
                Section("备注") {
                    ForEach(group.records.filter { $0.note != nil && !$0.note!.isEmpty }, id: \.self) { record in
                        if let note = record.note {
                            Text(note)
                        }
                    }
                }
            }
        }
        .navigationTitle(group.date.chineseDate)
    }

    private func qualityStars(_ quality: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= quality ? "star.fill" : "star")
                    .foregroundStyle(star <= quality ? .yellow : .gray.opacity(0.3))
            }
        }
    }

    private func stageRow(name: String, duration: TimeInterval, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 12, height: 12)
            Text(name)
            Spacer()
            Text(formatDuration(duration))
                .foregroundStyle(.secondary)
        }
    }

    private func stageDisplayName(_ stage: String) -> String {
        switch stage {
        case "deep": return "深度睡眠"
        case "rem": return "REM 睡眠"
        case "core": return "核心睡眠"
        case "awake": return "清醒"
        case "inBed": return "在床"
        default: return "睡眠"
        }
    }

    private func colorForStage(_ stage: String) -> Color {
        switch stage {
        case "deep": return .indigo
        case "rem": return .purple
        case "core": return .blue.opacity(0.7)
        case "awake": return .orange
        case "inBed": return .gray.opacity(0.25)
        default: return .blue.opacity(0.5)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        }
        return "\(minutes)分钟"
    }
}

struct SleepStageLayeredChart: View {
    let records: [SleepRecord]
    let startTime: Date
    let endTime: Date

    private let stageOrder: [(String, String, Color)] = [
        ("awake", "清醒", .orange),
        ("rem", "REM", .purple),
        ("core", "核心", .blue.opacity(0.7)),
        ("deep", "深度", .indigo)
    ]

    var body: some View {
        let totalDuration = max(endTime.timeIntervalSince(startTime), 1)

        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 2) {
                ForEach(stageOrder, id: \.0) { stageKey, stageName, color in
                    HStack(spacing: 6) {
                        Text(stageName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .trailing)

                        SleepStageRow(
                            records: records.filter { $0.sleepStage == stageKey },
                            totalDuration: totalDuration,
                            startTime: startTime,
                            color: color
                        )
                    }
                }
            }

            HStack {
                Text(DateFormatter.timeOnly.string(from: startTime))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(DateFormatter.timeOnly.string(from: endTime))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 34)
        }
    }
}

struct SleepStageRow: View {
    let records: [SleepRecord]
    let totalDuration: TimeInterval
    let startTime: Date
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.1))

                ForEach(records, id: \.self) { record in
                    let startOffset = max(0, record.startTime.timeIntervalSince(startTime)) / totalDuration
                    let widthRatio = min(1 - startOffset, record.duration / totalDuration)
                    if widthRatio > 0.005 {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: max(2, geo.size.width * CGFloat(widthRatio)))
                            .offset(x: geo.size.width * CGFloat(startOffset))
                    }
                }
            }
        }
        .frame(height: 20)
    }
}

struct AddSleepSheet: View {
    let vm: HealthDataViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(8 * 3600)
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