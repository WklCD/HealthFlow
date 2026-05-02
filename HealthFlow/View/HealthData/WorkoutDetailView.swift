import SwiftUI

struct WorkoutDetailView: View {
    let vm: HealthDataViewModel
    let workout: WorkoutRecord

    var body: some View {
        List {
            Section("运动信息") {
                LabeledContent("类型", value: ExerciseType(rawValue: workout.exerciseType)?.displayName ?? workout.exerciseType)
                LabeledContent("开始时间", value: workout.startTime.chineseDateTime)
                LabeledContent("结束时间", value: workout.endTime.chineseDateTime)
                LabeledContent("时长", value: formatDuration(workout.duration))
            }
            Section("数据") {
                if workout.calories > 0 {
                    LabeledContent("卡路里", value: String(format: "%.0f kcal", workout.calories))
                }
                if let steps = workout.steps, steps > 0 {
                    LabeledContent("步数", value: "\(steps)")
                }
                if let distance = workout.distance, distance > 0 {
                    LabeledContent("距离", value: String(format: "%.1f km", distance / 1000))
                }
            }
            if let note = workout.note, !note.isEmpty {
                Section("备注") {
                    Text(note)
                }
            }
            Section("来源") {
                LabeledContent("来源", value: workout.source == "healthkit" ? "HealthKit" : "手动录入")
            }
        }
        .navigationTitle("运动详情")
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours > 0 {
            return "\(hours)小时\(remainingMinutes)分钟"
        }
        return "\(minutes)分钟"
    }
}