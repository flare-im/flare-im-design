import SwiftUI
import ImageIO

private struct DecodedMemoryImage: @unchecked Sendable {
    let image: CGImage?
}

/// Bounded rendering for host-owned private bytes. No URL, file or global cache.
public struct PrivateMemoryImageView: View {
    private let data: Data
    private let alt: String
    private let maxPixelSize: Int
    @State private var image: CGImage?
    @State private var failed = false
    @Environment(\.flareStrings) private var strings
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var brand

    public init(data: Data, alt: String, maxPixelSize: Int = 1024) {
        precondition(maxPixelSize > 0)
        self.data = data; self.alt = alt; self.maxPixelSize = maxPixelSize
    }

    private struct Source: Hashable {
        let data: Data
        let maxPixelSize: Int
    }

    public var body: some View {
        Group {
            if let image {
                Image(decorative: image, scale: 1).resizable().scaledToFit()
                    .accessibilityLabel(alt)
            } else if failed {
                let colors = FlareColors.of(scheme, brand: brand)
                VStack(spacing: FlareSizes.spacingSm) {
                    FlareIconImage(name: "image", size: FlareSizes.iconSizeXl)
                    Text(strings.imageLoadFailed).font(.system(size: FlareSizes.fontSizeSm))
                }.foregroundColor(colors.textTertiary)
            } else {
                ProgressView().accessibilityLabel(strings.loading)
            }
        }
        .task(id: Source(data: data, maxPixelSize: maxPixelSize)) {
            image = nil; failed = false
            let bytes = data
            let limit = maxPixelSize
            let result = await Task.detached(priority: .userInitiated) {
                guard let source = CGImageSourceCreateWithData(bytes as CFData,
                    [kCGImageSourceShouldCache: false] as CFDictionary) else {
                    return DecodedMemoryImage(image: nil)
                }
                return DecodedMemoryImage(image: CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceThumbnailMaxPixelSize: limit,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceShouldCacheImmediately: true,
                ] as CFDictionary))
            }.value
            guard !Task.isCancelled else { return }
            image = result.image; failed = result.image == nil
        }
        .onDisappear { image = nil }
    }
}
