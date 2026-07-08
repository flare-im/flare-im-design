import SwiftUI

/// Muted, small timestamp label. Spec: General/TimeStamp (`TimeStampView`).
/// Pure display — the caller formats `label` upstream.
public struct TimeStampView: View {
    private let label: String
    @Environment(\.colorScheme) private var scheme

    public init(label: String) {
        self.label = label
    }

    public var body: some View {
        Text(label)
            .font(.system(size: FlareSizes.fontSizeXs))
            .foregroundColor(FlareColors.of(scheme).textTertiary)
    }
}
