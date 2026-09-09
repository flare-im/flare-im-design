import SwiftUI

// MARK: - ImageGrid

/// Image grid — up to `max` thumbnails with a "+N" overflow scrim on the last cell.
/// Spec: Message/ImageGrid (`ImageGridView`).
public struct ImageGridView: View {
    private let images: [GridImage]
    private let max: Int
    private let onOpen: ((Int) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(images: [GridImage], max: Int = 9, onOpen: ((Int) -> Void)? = nil) {
        self.images = images; self.max = max; self.onOpen = onOpen
    }

    private var visible: [GridImage] { Array(images.prefix(max)) }
    private var overflow: Int { images.count - visible.count }

    private var cols: Int {
        let n = visible.count
        if n <= 1 { return 1 }
        if n == 4 { return 2 }
        if n <= 3 { return n }
        return 3
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        if visible.count <= 1, let image = visible.first {
            // Single image: fit (no crop) within 220×260, like Android / Flutter.
            singleCell(colors, image)
                .onTapGesture { onOpen?(0) }
        } else {
            let columns = Array(repeating: GridItem(.fixed(84), spacing: 4), count: cols)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(visible.enumerated()), id: \.element.id) { index, image in
                    cell(colors, image, side: 84,
                         showOverflow: overflow > 0 && index == visible.count - 1)
                        .onTapGesture { onOpen?(index) }
                }
            }
            .frame(width: CGFloat(cols) * 84 + CGFloat(cols - 1) * 4)
        }
    }

    private func singleCell(_ colors: FlareColors, _ image: GridImage) -> some View {
        Group {
            if let urlStr = image.url, let url = URL(string: urlStr) {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFit()
                } placeholder: {
                    colors.bgSecondary.frame(width: 220, height: 160)
                }
            } else {
                colors.bgSecondary.frame(width: 220, height: 160)
            }
        }
        .frame(maxWidth: 220, maxHeight: 260)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }

    private func cell(_ colors: FlareColors, _ image: GridImage, side: CGFloat, showOverflow: Bool) -> some View {
        ZStack {
            if let urlStr = image.url, let url = URL(string: urlStr) {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    colors.bgSecondary
                }
            } else {
                colors.bgSecondary
            }
            if showOverflow {
                Color.black.opacity(0.42)
                Text("+\(overflow)")
                    .font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }
}
