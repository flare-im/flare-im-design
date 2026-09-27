import SwiftUI

/// The frame of a bottom sheet's content: an optional title over the content, on the kit sheet
/// ground, inside the safe area (the ground runs on under the home indicator). Spec:
/// Overlay/BottomSheet (`BottomSheetView`). It draws no handle: the system drag indicator is
/// part of the presentation — present it with
/// ``SwiftUI/View/flareBottomSheet(isPresented:title:titleHidden:presentation:dismissible:size:maxHeight:onDismiss:content:)``
/// (or its `item` form), which wraps content in this frame, resolves `presentation` (a sheet on the phone form
/// factor, a ``ModalView`` otherwise) and takes `dismissible` and `size`.
///
/// - `titleHidden` keeps `title` as the accessible name without drawing the caption (an action panel whose rows
///   already say what they do).
/// - `maxHeight` caps the frame's height; the presenter's fitted sheet caps its detent the same way.
public struct BottomSheetView<Content: View>: View {
    private let title: String?
    private let titleHidden: Bool
    private let maxHeight: CGFloat?
    private let content: Content
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(title: String? = nil, titleHidden: Bool = false, maxHeight: CGFloat? = nil,
                @ViewBuilder content: () -> Content) {
        self.title = title; self.titleHidden = titleHidden; self.maxHeight = maxHeight; self.content = content()
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let named = title.map { !$0.isEmpty } ?? false
        VStack(spacing: 0) {
            if named && !titleHidden, let title {
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
        .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .top)
        .background(colors.bgPrimary.ignoresSafeArea(.container, edges: .bottom))
        .modifier(FlareSheetAccessibleName(name: named && titleHidden ? title : nil))
    }
}

/// Names the sheet for assistive technology when its title is not drawn.
private struct FlareSheetAccessibleName: ViewModifier {
    let name: String?

    func body(content: Content) -> some View {
        if let name {
            content.accessibilityElement(children: .contain).accessibilityLabel(name)
        } else {
            content
        }
    }
}
