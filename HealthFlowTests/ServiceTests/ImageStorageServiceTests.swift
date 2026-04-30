import Testing
import UIKit
@testable import HealthFlow

struct ImageStorageServiceTests {
    @Test("保存后再加载得到相同图像")
    func testSaveAndLoad() throws {
        let service = ImageStorageService()
        let image = UIImage(systemName: "fork.knife")!
        let path = try service.saveImage(image)
        let loaded = service.loadImage(path: path)
        #expect(loaded != nil)
    }

    @Test("删除后加载返回 nil")
    func testDeleteRemovesImage() throws {
        let service = ImageStorageService()
        let image = UIImage(systemName: "fork.knife")!
        let path = try service.saveImage(image)
        try service.deleteImage(path: path)
        let loaded = service.loadImage(path: path)
        #expect(loaded == nil)
    }

    @Test("保存返回非空路径")
    func testSaveReturnsNonEmptyPath() throws {
        let service = ImageStorageService()
        let image = UIImage(systemName: "heart.fill")!
        let path = try service.saveImage(image)
        #expect(!path.isEmpty)
        #expect(path.hasSuffix(".jpg"))
    }
}