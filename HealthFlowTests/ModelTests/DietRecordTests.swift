import Testing
import Foundation
@testable import HealthFlow

struct DietRecordTests {

    @Test("totalCalories 从 foodItems 动态聚合")
    func testTotalCaloriesAggregation() {
        let diet = DietRecord()
        let item1 = FoodItem()
        item1.calories = 100
        let item2 = FoodItem()
        item2.calories = 200
        diet.foodItems = [item1, item2]
        #expect(diet.totalCalories == 300)
    }

    @Test("空 foodItems 时 totalCalories 为 0")
    func testTotalCaloriesEmptyFoodItems() {
        let diet = DietRecord()
        diet.foodItems = []
        #expect(diet.totalCalories == 0)
    }

    @Test("totalProtein 正确聚合")
    func testTotalProteinAggregation() {
        let diet = DietRecord()
        let item = FoodItem()
        item.protein = 15.5
        diet.foodItems = [item]
        #expect(diet.totalProtein == 15.5)
    }

    @Test("totalCarbs 正确聚合")
    func testTotalCarbsAggregation() {
        let diet = DietRecord()
        let item = FoodItem()
        item.carbs = 40
        diet.foodItems = [item]
        #expect(diet.totalCarbs == 40)
    }

    @Test("totalFat 正确聚合")
    func testTotalFatAggregation() {
        let diet = DietRecord()
        let item = FoodItem()
        item.fat = 12
        diet.foodItems = [item]
        #expect(diet.totalFat == 12)
    }

    @Test("多个 foodItems 正确聚合所有营养素")
    func testFullAggregation() {
        let diet = DietRecord()
        let item1 = FoodItem()
        item1.calories = 100; item1.protein = 10; item1.carbs = 20; item1.fat = 5
        let item2 = FoodItem()
        item2.calories = 200; item2.protein = 20; item2.carbs = 30; item2.fat = 10
        diet.foodItems = [item1, item2]
        #expect(diet.totalCalories == 300)
        #expect(diet.totalProtein == 30)
        #expect(diet.totalCarbs == 50)
        #expect(diet.totalFat == 15)
    }

    @Test("imagePath 默认为 nil")
    func testImagePathDefaultsToNil() {
        let diet = DietRecord()
        #expect(diet.imagePath == nil)
    }
}