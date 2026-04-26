import UIKit

enum ImageCompressor {
    /// Decodes, downscales (longest edge ≤ `maxEdge`), and JPEG-encodes image data.
    /// Safe to call from any actor — does no main-thread work.
    static func compress(_ data: Data, maxEdge: CGFloat = 1200, quality: CGFloat = 0.75) -> Data {
        guard let img = UIImage(data: data) else { return data }
        let scale = min(1, maxEdge / max(img.size.width, img.size.height))
        let target = CGSize(width: img.size.width * scale, height: img.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in img.draw(in: CGRect(origin: .zero, size: target)) }
        return resized.jpegData(compressionQuality: quality) ?? data
    }
}
