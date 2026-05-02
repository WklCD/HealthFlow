import SwiftUI
import SwiftData

struct DietDetailView: View {
    let vm: HealthDataViewModel
    @State private var showingAddSheet = false

    private var groupedRecords: [(MealType, [DietRecord])] {
        let grouped = Dictionary(grouping: vm.dietRecords) { MealType(rawValue: $0.mealType) ?? .breakfast }
        return MealType.allCases.compactMap { type in
            let records = grouped[type] ?? []
            return records.isEmpty ? nil : (type, records)
        }
    }

    var body: some View {
        List {
            if vm.dietRecords.isEmpty {
                Section {
                    Text("暂无饮食记录")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(groupedRecords, id: \.0) { mealType, records in
                    Section(mealType.displayName) {
                        ForEach(records, id: \.self) { record in
                            NavigationLink {
                                DietRecordDetail(record: record)
                            } label: {
                                HStack {
                                    Image(systemName: mealType.iconName)
                                        .foregroundStyle(.green)
                                    VStack(alignment: .leading) {
                                        Text(record.timestamp.chineseDateTime)
                                        if let items = record.foodItems, !items.isEmpty {
                                            Text(items.map(\.name).joined(separator: "、"))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    Text("\(Int(record.totalCalories)) kcal")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            let recordsToDelete = indexSet.map { records[$0] }
                            for record in recordsToDelete {
                                vm.deleteDietRecord(record)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("饮食")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddDietSheet(vm: vm)
        }
    }
}

struct DietRecordDetail: View {
    let record: DietRecord

    var body: some View {
        List {
            Section("时间") {
                LabeledContent("餐次", value: MealType(rawValue: record.mealType)?.displayName ?? record.mealType)
                LabeledContent("记录时间", value: record.timestamp.chineseDateTime)
            }
            Section("营养汇总") {
                LabeledContent("总热量", value: "\(Int(record.totalCalories)) kcal")
                LabeledContent("蛋白质", value: String(format: "%.1fg", record.totalProtein))
                LabeledContent("碳水化合物", value: String(format: "%.1fg", record.totalCarbs))
                LabeledContent("脂肪", value: String(format: "%.1fg", record.totalFat))
            }
            if let items = record.foodItems, !items.isEmpty {
                Section("食物明细") {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text("\(String(format: "%.0f", item.amount))\(item.unit) \(Int(item.calories))kcal")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("饮食详情")
    }
}

struct AddDietSheet: View {
    let vm: HealthDataViewModel
    @State private var selectedMealType: MealType = .breakfast
    @Environment(\.dismiss) private var dismiss
    @State private var showingFoodSearch = false
    @State private var selectedFoods: [(food: FoodDefinition, amount: Double)] = []
    @State private var note: String = ""
    @State private var timestamp = Date()

    var body: some View {
        NavigationStack {
            List {
                Section("餐次") {
                    Picker("餐次", selection: $selectedMealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("食物") {
                    ForEach(selectedFoods.indices, id: \.self) { index in
                        HStack {
                            Text(selectedFoods[index].food.name)
                            Spacer()
                            Stepper("\(String(format: "%.1f", selectedFoods[index].amount)) \(selectedFoods[index].food.defaultUnit)",
                                    value: $selectedFoods[index].amount,
                                    step: selectedFoods[index].food.defaultAmount)
                                .font(.subheadline)
                        }
                    }
                    .onDelete { indexSet in
                        selectedFoods.remove(atOffsets: indexSet)
                    }

                    Button(action: { showingFoodSearch = true }) {
                        Label("添加食物", systemImage: "plus.circle.fill")
                    }
                }

                if !selectedFoods.isEmpty {
                    Section("营养汇总") {
                        let totalCal = selectedFoods.reduce(0.0) { $0 + $1.food.caloriesPerUnit * $1.amount / $1.food.defaultAmount }
                        let totalPro = selectedFoods.reduce(0.0) { $0 + $1.food.proteinPerUnit * $1.amount / $1.food.defaultAmount }
                        let totalCarb = selectedFoods.reduce(0.0) { $0 + $1.food.carbsPerUnit * $1.amount / $1.food.defaultAmount }
                        let totalFat = selectedFoods.reduce(0.0) { $0 + $1.food.fatPerUnit * $1.amount / $1.food.defaultAmount }
                        LabeledContent("热量", value: "\(Int(totalCal)) kcal")
                        LabeledContent("蛋白质", value: String(format: "%.1fg", totalPro))
                        LabeledContent("碳水", value: String(format: "%.1fg", totalCarb))
                        LabeledContent("脂肪", value: String(format: "%.1fg", totalFat))
                    }
                }

                Section("时间") {
                    DatePicker("记录时间", selection: $timestamp)
                }
            }
            .navigationTitle("添加\(selectedMealType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveDietRecord()
                        dismiss()
                    }
                    .disabled(selectedFoods.isEmpty)
                }
            }
            .sheet(isPresented: $showingFoodSearch) {
                FoodSearchView { food in
                    selectedFoods.append((food: food, amount: food.defaultAmount))
                    showingFoodSearch = false
                }
            }
        }
    }

    private func saveDietRecord() {
        let record = DietRecord()
        record.mealType = selectedMealType.rawValue
        record.timestamp = timestamp
        record.source = "manual"

        let foodItems = selectedFoods.map { entry in
            let item = FoodItem()
            item.name = entry.food.name
            item.amount = entry.amount
            item.unit = entry.food.defaultUnit
            item.calories = entry.food.caloriesPerUnit * entry.amount / entry.food.defaultAmount
            item.protein = entry.food.proteinPerUnit * entry.amount / entry.food.defaultAmount
            item.carbs = entry.food.carbsPerUnit * entry.amount / entry.food.defaultAmount
            item.fat = entry.food.fatPerUnit * entry.amount / entry.food.defaultAmount
            return item
        }
        record.foodItems = foodItems

        vm.addDietRecord(record)
    }
}