import UIKit

struct ImageCompressor {
    static func compress(
        imageData: Data,
        maxDimension: CGFloat = 1024,
        quality: CGFloat = 0.7
    ) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }

        let scale = min(
            maxDimension / image.size.width,
            maxDimension / image.size.height,
            1.0
        )

        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        return resized.jpegData(compressionQuality: quality)
    }
}
