import SwiftUI

struct PersonalInfoView: View {
    let viewModel: ProfileViewModel

    @State private var name: String = ""
    @State private var gender: String = "unset"
    @State private var birthDate: Date = Date()
    @State private var height: Double = 170
    @State private var targetWeight: Double?
    @State private var targetSteps: Int?
    @State private var targetSleepHours: Double?
    @State private var targetCalories: Int?

    let genderOptions: [(String, String)] = [
        ("unset", "未设置"),
        ("male", "男"),
        ("female", "女"),
        ("other", "其他"),
    ]

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("姓名", text: $name)
                Picker("性别", selection: $gender) {
                    ForEach(genderOptions, id: \.0) { value, label in
                        Text(label).tag(value)
                    }
                }
                DatePicker("出生日期", selection: $birthDate, displayedComponents: .date)
                HStack {
                    Text("身高")
                    Spacer()
                    Text("\(Int(height)) cm")
                        .foregroundStyle(.secondary)
                    Stepper("", value: $height, in: 100...250, step: 1)
                        .labelsHidden()
                }
            }

            Section("健康目标") {
                HStack {
                    Text("每日步数")
                    Spacer()
                    TextField("目标步数", value: $targetSteps, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("每日睡眠")
                    Spacer()
                    TextField("小时", value: $targetSleepHours, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("每日卡路里")
                    Spacer()
                    TextField("千卡", value: $targetCalories, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("目标体重")
                    Spacer()
                    TextField("kg", value: $targetWeight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .navigationTitle("个人档案")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") {
                    viewModel.saveProfile(
                        name: name,
                        gender: gender,
                        birthDate: birthDate,
                        height: height,
                        targetWeight: targetWeight,
                        targetSteps: targetSteps,
                        targetSleepHours: targetSleepHours,
                        targetCalories: targetCalories
                    )
                }
            }
        }
        .onAppear {
            loadProfileData()
        }
    }

    private func loadProfileData() {
        guard let profile = viewModel.profile else { return }
        name = profile.name
        gender = profile.gender
        birthDate = profile.birthDate
        height = profile.height
        targetWeight = profile.targetWeight
        targetSteps = profile.targetSteps
        targetSleepHours = profile.targetSleepHours
        targetCalories = profile.targetCalories
    }
}