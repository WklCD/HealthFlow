import Foundation
import SwiftData

@Model
final class FoodItem {
    var name: String = ""
    var amount: Double = 0
    var unit: String = "份"
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0

    init(name: String = "", amount: Double = 0, unit: String = "份", calories: Double = 0, protein: Double = 0, carbs: Double = 0, fat: Double = 0) {
        self.name = name
        self.amount = amount
        self.unit = unit
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}