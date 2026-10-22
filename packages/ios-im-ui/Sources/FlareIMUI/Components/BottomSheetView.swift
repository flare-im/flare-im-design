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
/// - `fill` is the fixed-height mode: the frame takes the whole of `maxHeight` (all of the height it is offered when
///   there is none) and the content fills what the title leaves, owning its scrolling — for pickers with their own
///   header (``LocationPickerView``, ``ContactPickerView``). Content that declares its own header with
///   ``SwiftUI/View/flareSheetOwnHeader(_:)`` then gets no second, visible title: `title` stays the accessible name.
///   Without `fill` the declaration changes nothing.
public struct BottomSheetView<Content: View>: View {
    private let title: String?
    private let titleHidden: Bool
    private let maxHeight: CGFloat?
    private let fill: Bool
    private let content: Content
    /// The content declared its own header row (``FlareSheetOwnHeaderKey``).
    @State private var ownHeader = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(title: String? = nil, titleHidden: Bool = false, maxHeight: CGFloat? = nil, fill: Bool = false,
                @ViewBuilder content: () -> Content) {
        self.title = title; self.titleHidden = titleHidden; self.maxHeight = maxHeight; self.fill = fill
        self.content = content()
    }

    /// Whether the caption is drawn: a title, not hidden, and not a filled sheet whose content brings its own header.
    static func drawsTitle(title: String?, titleHidden: Bool, fill: Bool, ownHeader: Bool) -> Bool {
        guard let title, !title.isEmpty, !titleHidden else { return false }
        return !(fill && ownHeader)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let named = title.map { !$0.isEmpty } ?? false
        let drawsTitle = Self.drawsTitle(title: title, titleHidden: titleHidden, fill: fill, ownHeader: ownHeader)
        VStack(spacing: 0) {
            if drawsTitle, let title {
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
            if fill {
                content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                content
            }
        }
        .onPreferenceChange(FlareSheetOwnHeaderKey.self) { ownHeader = $0 }
        // The declaration is this sheet's; an enclosing one never sees it.
        .transformPreference(FlareSheetOwnHeaderKey.self) { $0 = false }
        .frame(maxWidth: .infinity, minHeight: fill ? maxHeight : nil,
               maxHeight: fill ? (maxHeight ?? .infinity) : maxHeight, alignment: .top)
        .background(colors.bgPrimary.ignoresSafeArea(.container, edges: .bottom))
        .modifier(FlareSheetAccessibleName(name: named && !drawsTitle ? title : nil))
    }
}

/// Whether a kit sheet's content draws its own header row; declared with
/// ``SwiftUI/View/flareSheetOwnHeader(_:)`` and read by ``BottomSheetView`` and the sheet presenters.
struct FlareSheetOwnHeaderKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

public extension View {
    /// Declares that this content draws its own header row (a title with Cancel), as ``LocationPickerView`` and
    /// ``ContactPickerView`` do. In a kit bottom sheet with `fill` the sheet then draws no visible title and keeps its
    /// `title` as the accessible name only, so the two never repeat each other; without `fill`, or outside a sheet,
    /// it changes nothing. Spec: Overlay/BottomSheet.
    func flareSheetOwnHeader(_ owns: Bool = true) -> some View {
        preference(key: FlareSheetOwnHeaderKey.self, value: owns)
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
