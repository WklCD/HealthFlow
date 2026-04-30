import SwiftUI

struct ActivityDetailView: View {
    let vm: HealthDataViewModel
    @State private var selectedDate = Date()
    @State private var showingWorkoutDetail = false

    var body: some View {
        List {
            Section("每日活动") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("步数")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(todaySteps)")
                            .font(.title2.bold())
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("卡路里")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f", todayCalories))
                            .font(.title2.bold())
                    }
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text("距离")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f km", todayDistance / 1000))
                            .font(.title2.bold())
                    }
                    Spacer()
                }
            }

            Section("运动记录") {
                ForEach(vm.workouts, id: \.self) { workout in
                    NavigationLink {
                        WorkoutDetailView(vm: vm, workout: workout)
                    } label: {
                        HStack {
                            Image(systemName: exerciseIcon(for: workout.exerciseType))
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading) {
                                Text(exerciseDisplayName(for: workout.exerciseType))
                                Text(formatDuration(workout.duration))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if workout.calories > 0 {
                                Text(String(format: "%.0f kcal", workout.calories))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let workout = vm.workouts[index]
                        vm.deleteWorkout(workout)
                    }
                }
            }
        }
        .navigationTitle("运动")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingWorkoutDetail = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingWorkoutDetail) {
            AddWorkoutSheet(vm: vm)
        }
    }

    private var todayActivities: DailyActivitySummary? {
        let calendar = Calendar.current
        return vm.dailyActivities.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var todaySteps: Int {
        todayActivities?.steps ?? 0
    }

    private var todayCalories: Double {
        todayActivities?.calories ?? 0
    }

    private var todayDistance: Double {
        todayActivities?.distance ?? 0
    }

    private func exerciseIcon(for type: String) -> String {
        ExerciseType(rawValue: type)?.iconName ?? "figure.mixed.cardio"
    }

    private func exerciseDisplayName(for type: String) -> String {
        ExerciseType(rawValue: type)?.displayName ?? type
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

struct AddWorkoutSheet: View {
    let vm: HealthDataViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: ExerciseType = .walking
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var calories: Double = 0
    @State private var steps: Int = 0
    @State private var distance: Double = 0
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("运动类型") {
                    Picker("类型", selection: $selectedType) {
                        ForEach(ExerciseType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                Section("时间") {
                    DatePicker("开始时间", selection: $startTime)
                    DatePicker("结束时间", selection: $endTime)
                }
                Section("数据") {
                    Stepper("卡路里: \(Int(calories)) kcal", value: $calories, step: 10)
                    Stepper("步数: \(steps)", value: $steps, step: 100)
                    Stepper("距离: \(String(format: "%.1f", distance / 1000)) km", value: $distance, step: 100)
                }
                Section("备注") {
                    TextField("备注", text: $note)
                }
            }
            .navigationTitle("添加运动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let workout = WorkoutRecord()
                        workout.exerciseType = selectedType.rawValue
                        workout.startTime = startTime
                        workout.endTime = endTime
                        workout.duration = endTime.timeIntervalSince(startTime)
                        workout.calories = calories
                        workout.steps = steps
                        workout.distance = distance
                        workout.source = "manual"
                        workout.note = note.isEmpty ? nil : note
                        vm.addWorkout(workout)
                        dismiss()
                    }
                }
            }
        }
    }
}