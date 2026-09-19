import SwiftUI

/// The frame of a bottom sheet's content: an optional title over the content, on the kit sheet
/// ground, inside the safe area (the ground runs on under the home indicator). Spec:
/// Overlay/BottomSheet (`BottomSheetView`). It draws no handle: the system drag indicator is
/// part of the presentation — present it with
/// ``SwiftUI/View/flareBottomSheet(item:title:onDismiss:content:)``, which wraps content in this frame.
public struct BottomSheetView<Content: View>: View {
    private let title: String?
    private let content: Content
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title; self.content = content()
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(spacing: 0) {
            if let title, !title.isEmpty {
                // A quiet caption heading, like the Select sheet (Android / Flutter parity).
                Text(title)
                    .font(.system(size: FlareSizes.fontSizeMd, weight: .medium))
                    .foregroundColor(colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, FlareSizes.spacingXl)
                    .padding(.bottom, FlareSizes.spacingSm)
                    .padding(.horizontal, FlareSizes.spacingLg)
                    .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(colors.bgPrimary.ignoresSafeArea(.container, edges: .bottom))
    }
}
