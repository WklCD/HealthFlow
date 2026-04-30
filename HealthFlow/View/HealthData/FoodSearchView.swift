import SwiftUI

struct FoodSearchView: View {
    let foodDatabase = FoodDatabaseService.shared
    let onSelect: (FoodDefinition) -> Void

    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory?
    @Environment(\.dismiss) private var dismiss

    private enum FoodCategory: String, CaseIterable {
        case protein = "protein"
        case carbs = "carbs"
        case fruit = "fruit"
        case vegetable = "vegetable"
        case fat = "fat"
        case dish = "dish"
        case beverage = "beverage"
        case snack = "snack"

        var displayName: String {
            switch self {
            case .protein: return "蛋白质"
            case .carbs: return "碳水化合物"
            case .fruit: return "水果"
            case .vegetable: return "蔬菜"
            case .fat: return "坚果油脂"
            case .dish: return "菜品"
            case .beverage: return "饮品"
            case .snack: return "零食"
            }
        }
    }

    private var results: [FoodDefinition] {
        if !searchText.isEmpty {
            return foodDatabase.search(query: searchText)
        } else if let category = selectedCategory {
            return foodDatabase.getCategory(category: category.rawValue)
        }
        return foodDatabase.search(query: "")
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("搜索食物", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("分类") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(FoodCategory.allCases, id: \.self) { cat in
                                Button(action: {
                                    selectedCategory = selectedCategory == cat ? nil : cat
                                    searchText = ""
                                }) {
                                    Text(cat.displayName)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedCategory == cat ? Color.accentColor : Color.gray.opacity(0.2))
                                        .foregroundStyle(selectedCategory == cat ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                Section(searchText.isEmpty ? "所有食物" : "搜索结果") {
                    ForEach(results) { food in
                        Button(action: { onSelect(food) }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(food.name)
                                        .font(.subheadline)
                                    Text("\(String(format: "%.0f", food.caloriesPerUnit * food.defaultAmount)) kcal / \(food.defaultUnit)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("蛋白 \(String(format: "%.1f", food.proteinPerUnit * food.defaultAmount))g")
                                        .font(.caption2)
                                    Text("碳水 \(String(format: "%.1f", food.carbsPerUnit * food.defaultAmount))g")
                                        .font(.caption2)
                                    Text("脂肪 \(String(format: "%.1f", food.fatPerUnit * food.defaultAmount))g")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("食物搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}