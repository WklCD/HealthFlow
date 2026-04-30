import Testing
@testable import HealthFlow

struct FoodDatabaseServiceTests {
    @Test("搜索'鸡蛋'返回结果")
    func testSearchEgg() {
        let service = FoodDatabaseService.shared
        let results = service.search(query: "鸡蛋")
        #expect(!results.isEmpty)
        #expect(results.first?.name.contains("鸡蛋") ?? false)
    }

    @Test("按类别查询返回正确分类")
    func testGetByCategory() {
        let service = FoodDatabaseService.shared
        let proteins = service.getCategory(category: "protein")
        #expect(proteins.contains { $0.name.contains("鸡胸") })
    }

    @Test("搜索不存在的食物返回空结果")
    func testSearchNonExistent() {
        let service = FoodDatabaseService.shared
        let results = service.search(query: "不存在的食物xyz")
        #expect(results.isEmpty)
    }

    @Test("搜索大小写不敏感")
    func testSearchCaseInsensitive() {
        let service = FoodDatabaseService.shared
        let lowerResults = service.search(query: "鸡蛋")
        let upperResults = service.search(query: "鸡")
        #expect(!lowerResults.isEmpty)
        #expect(!upperResults.isEmpty)
    }

    @Test("按碳水类别查询")
    func testGetCarbsCategory() {
        let service = FoodDatabaseService.shared
        let carbs = service.getCategory(category: "carbs")
        #expect(!carbs.isEmpty)
    }
}