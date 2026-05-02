import Testing
import Foundation
@testable import HealthFlow

struct KeychainServiceTests {

    @Test("存储和读取 API Key")
    func testSaveAndLoadAPIKey() throws {
        let service = KeychainService()
        let testKey = "test_HealthFlow_api_key_\(UUID().uuidString)"
        try service.save(key: testKey, value: "sk-test-12345")
        let loaded = try service.load(key: testKey)
        #expect(loaded == "sk-test-12345")
        try? service.delete(key: testKey)
    }

    @Test("删除后读取返回 nil")
    func testDeleteAPIKey() throws {
        let service = KeychainService()
        let testKey = "test_HealthFlow_delete_\(UUID().uuidString)"
        try service.save(key: testKey, value: "secret")
        try service.delete(key: testKey)
        let loaded = try? service.load(key: testKey)
        #expect(loaded == nil)
    }

    @Test("覆盖已有 Key")
    func testOverwriteAPIKey() throws {
        let service = KeychainService()
        let testKey = "test_HealthFlow_overwrite_\(UUID().uuidString)"
        try service.save(key: testKey, value: "old")
        try service.save(key: testKey, value: "new")
        let loaded = try service.load(key: testKey)
        #expect(loaded == "new")
        try? service.delete(key: testKey)
    }
}