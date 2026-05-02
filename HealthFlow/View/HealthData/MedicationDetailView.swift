import SwiftUI

struct MedicationDetailView: View {
    let vm: HealthDataViewModel
    @State private var showingAddSheet = false

    var body: some View {
        List {
            if vm.medications.isEmpty {
                Section {
                    Text("暂无用药记录")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("今日用药") {
                    ForEach(todayMedications, id: \.self) { med in
                        HStack {
                            Image(systemName: med.takenAt != nil ? "checkmark.circle.fill" : "clock.fill")
                                .foregroundStyle(med.takenAt != nil ? .green : .orange)
                            VStack(alignment: .leading) {
                                Text(med.name)
                                    .font(.headline)
                                Text(med.dosage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(med.scheduledTime.timeOnly)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let takenAt = med.takenAt {
                                    Text("已服 \(takenAt.timeOnly)")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if med.takenAt == nil {
                                vm.markMedicationTaken(med)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        let meds = todayMedications
                        for index in indexSet {
                            vm.deleteMedicationRecord(meds[index])
                        }
                    }
                }

                if !otherMedications.isEmpty {
                    Section("更早记录") {
                        ForEach(otherMedications, id: \.self) { med in
                            HStack {
                                Image(systemName: med.takenAt != nil ? "checkmark.circle.fill" : "clock.fill")
                                    .foregroundStyle(med.takenAt != nil ? .green : .orange)
                                VStack(alignment: .leading) {
                                    Text(med.name)
                                    Text(med.dosage)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(med.scheduledTime.chineseDateTime)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            let meds = otherMedications
                            for index in indexSet {
                                vm.deleteMedicationRecord(meds[index])
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("用药记录")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddMedicationSheet(vm: vm)
        }
    }

    private var todayMedications: [MedicationRecord] {
        let calendar = Calendar.current
        return vm.medications.filter { calendar.isDateInToday($0.scheduledTime) }
            .sorted { $0.scheduledTime < $1.scheduledTime }
    }

    private var otherMedications: [MedicationRecord] {
        let calendar = Calendar.current
        return vm.medications.filter { !calendar.isDateInToday($0.scheduledTime) }
            .sorted { $0.scheduledTime > $1.scheduledTime }
    }
}

struct AddMedicationSheet: View {
    let vm: HealthDataViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var dosage: String = ""
    @State private var scheduledTime = Date()
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("药物信息") {
                    TextField("药名", text: $name)
                    TextField("剂量（如 100mg）", text: $dosage)
                }
                Section("计划时间") {
                    DatePicker("计划服药时间", selection: $scheduledTime)
                }
                Section("备注") {
                    TextField("备注（可选）", text: $note)
                }
            }
            .navigationTitle("添加用药")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let med = MedicationRecord()
                        med.name = name
                        med.dosage = dosage
                        med.scheduledTime = scheduledTime
                        med.source = "manual"
                        med.note = note.isEmpty ? nil : note
                        vm.addMedicationRecord(med)
                        dismiss()
                    }
                }
            }
        }
    }
}