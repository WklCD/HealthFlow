import Foundation
import SwiftData

@Model
final class FavoriteFood {
    var foodName: String = ""
    var category: String = ""
    var defaultUnit: String = ""
    var caloriesPerUnit: Double = 0
    var proteinPerUnit: Double = 0
    var carbsPerUnit: Double = 0
    var fatPerUnit: Double = 0
    var addedAt: Date = Date()

    init(foodName: String = "", category: String = "", defaultUnit: String = "", caloriesPerUnit: Double = 0, proteinPerUnit: Double = 0, carbsPerUnit: Double = 0, fatPerUnit: Double = 0, addedAt: Date = Date()) {
        self.foodName = foodName
        self.category = category
        self.defaultUnit = defaultUnit
        self.caloriesPerUnit = caloriesPerUnit
        self.proteinPerUnit = proteinPerUnit
        self.carbsPerUnit = carbsPerUnit
        self.fatPerUnit = fatPerUnit
        self.addedAt = addedAt
    }
}