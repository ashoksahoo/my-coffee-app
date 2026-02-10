import SwiftUI

@MainActor
struct BrewImageRenderer {
    static func render(brew: BrewLog, scale: CGFloat = 3.0) -> UIImage? {
        let renderer = ImageRenderer(content: BrewCardView(brew: brew))
        renderer.scale = scale
        return renderer.uiImage
    }

    static func renderToData(brew: BrewLog, scale: CGFloat = 3.0) -> Data? {
        render(brew: brew, scale: scale)?.pngData()
    }
}
