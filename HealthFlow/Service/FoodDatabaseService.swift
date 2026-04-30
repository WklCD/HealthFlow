import Foundation

struct FoodDefinition: Codable, Identifiable {
    let name: String
    let category: String
    let defaultUnit: String
    let defaultAmount: Double
    let caloriesPerUnit: Double
    let proteinPerUnit: Double
    let carbsPerUnit: Double
    let fatPerUnit: Double
    var id: String { name }
}

final class FoodDatabaseService {
    private var foods: [FoodDefinition] = []

    init() { loadFoods() }

    private func loadFoods() {
        guard let url = Bundle.main.url(forResource: "FoodDatabase", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([FoodDefinition].self, from: data)
        else { return }
        foods = decoded
    }

    func search(query: String) -> [FoodDefinition] {
        foods.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func getCategory(category: String) -> [FoodDefinition] {
        foods.filter { $0.category == category }
    }
}