import Foundation
import SwiftData

@Model
final class DietRecord {
    var mealType: String = ""
    var timestamp: Date = Date()
    var imagePath: String?
    var source: String = "manual"
    @Relationship(deleteRule: .cascade) var foodItems: [FoodItem]? = []

    @Transient
    var totalCalories: Double {
        foodItems?.reduce(0) { $0 + $1.calories } ?? 0
    }

    @Transient
    var totalProtein: Double {
        foodItems?.reduce(0) { $0 + $1.protein } ?? 0
    }

    @Transient
    var totalCarbs: Double {
        foodItems?.reduce(0) { $0 + $1.carbs } ?? 0
    }

    @Transient
    var totalFat: Double {
        foodItems?.reduce(0) { $0 + $1.fat } ?? 0
    }

    init(mealType: String = "", timestamp: Date = Date(), imagePath: String? = nil, source: String = "manual", foodItems: [FoodItem]? = []) {
        self.mealType = mealType
        self.timestamp = timestamp
        self.imagePath = imagePath
        self.source = source
        self.foodItems = foodItems
    }
}