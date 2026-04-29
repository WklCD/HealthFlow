import Testing
import Foundation
@testable import HealthFlow

struct FoodItemTests {

    @Test("默认单位是'份'")
    func testDefaultUnit() {
        let item = FoodItem()
        #expect(item.unit == "份")
    }

    @Test("所有营养值默认为 0")
    func testNutrientDefaults() {
        let item = FoodItem()
        #expect(item.calories == 0)
        #expect(item.protein == 0)
        #expect(item.carbs == 0)
        #expect(item.fat == 0)
    }
}