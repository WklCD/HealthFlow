import UIKit
import Foundation

struct ImageStorageService {
    private var directory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent(Constants.Storage.foodImagesDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func saveImage(_ image: UIImage) throws -> String {
        let resized = resizeImage(image, maxDimension: Constants.Storage.maxImageDimension)
        guard let data = resized.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法压缩图像"])
        }
        let filename = "\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(filename)
        try data.write(to: url)
        return filename
    }

    func loadImage(path: String) -> UIImage? {
        let url = directory.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func deleteImage(path: String) throws {
        let url = directory.appendingPathComponent(path)
        try FileManager.default.removeItem(at: url)
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}