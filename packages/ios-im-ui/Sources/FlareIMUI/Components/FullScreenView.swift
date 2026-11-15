import SwiftUI

/// The ground a ``FullScreenView`` draws under its content, edge to edge.
public enum FlareFullScreenGround: Sendable {
    /// The page ground (`colors.bgPrimary`).
    case surface
    /// The media stage (`colors.mediaStage`), for a camera viewfinder or a media viewer.
    case stage
}

/// A layer that takes the whole screen for a task the user finishes or leaves there: a camera, a document capture,
/// a media viewer. Spec: Overlay/FullScreen (`FullScreenView`).
///
/// Present it with ``SwiftUI/View/flareFullScreen(isPresented:label:ground:dismissible:onDismiss:content:)``
/// (a clear full-screen cover on iOS 16.4+, so it sits above tab bars, split columns and navigation bars; a
/// system sheet on earlier iOS and on macOS).
///
/// - The content owns its chrome: its own cancel or close button and its own header. The kit draws the `ground`
///   under the whole screen (safe areas included), keeps the content inside the safe area, and fades it in and
///   out (reduced motion shows it at once).
/// - Escape and the VoiceOver escape gesture call `onClose` while `dismissible` and no content raised
///   ``SwiftUI/View/flareLayerDismissDisabled(_:)``. There is no scrim to tap and no swipe down.
/// - VoiceOver: a modal container named by `label`, else ``FlareStrings/modalLabel``.
public struct FullScreenView<Content: View>: View {
    private let label: String?
    private let ground: FlareFullScreenGround
    private let dismissible: Bool
    private let onClose: () -> Void
    private let content: Content
    @State private var locked = false
    @Environment(\.flareLayerVisible) private var visible
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(label: String? = nil, ground: FlareFullScreenGround = .surface, dismissible: Bool = true,
                onClose: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.label = label; self.ground = ground; self.dismissible = dismissible
        self.onClose = onClose; self.content = content()
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let escape = FlareOverlayRules.escape(
            showBack: false,
            dismissAllowed: FlareOverlayRules.dismissAllowed(dismissible: dismissible, busy: false, locked: locked))
        content
            .environment(\.flareInOverlaySurface, true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(colors.textPrimary)
            .background(FlareOverlayRules.fullScreenGround(ground, colors: colors).ignoresSafeArea())
            .opacity(visible ? 1 : 0)
            .background(FlareOverlayEscapeKey(escape: escape, perform: onClose))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(FlareOverlayRules.accessibleName(title: nil, label: label, fallback: strings.modalLabel))
            .accessibilityAddTraits(.isModal)
            .accessibilityAction(.escape) { if escape == .close { onClose() } }
            .onPreferenceChange(FlareLayerDismissDisabledKey.self) { locked = $0 }
    }
}

extension FlareOverlayRules {
    /// The colour a full-screen layer draws under its content.
    static func fullScreenGround(_ ground: FlareFullScreenGround, colors: FlareColors) -> Color {
        switch ground {
        case .surface: return colors.bgPrimary
        case .stage: return colors.mediaStage
        }
    }
}

public extension View {
    /// Presents a ``FullScreenView`` with `content` while `isPresented`: over a clear full-screen cover on iOS
    /// 16.4+ (the kit draws the ground and fades the content in), a system sheet on earlier iOS and on macOS.
    /// Escape, a `dismiss()` from inside or setting `isPresented` to false close it — the content's own cancel
    /// button sets `isPresented` to false; `onDismiss` runs once it is gone. ``FlareFeedback`` toasts show above
    /// it and confirmations wait until it is gone. Works without a feedback host.
    func flareFullScreen<Content: View>(
        isPresented: Binding<Bool>,
        label: String? = nil,
        ground: FlareFullScreenGround = .surface,
        dismissible: Bool = true,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(FlareFullScreenPresenter(
            isPresented: isPresented, label: label, ground: ground, dismissible: dismissible,
            onDismiss: onDismiss, screenContent: content
        ))
    }

    /// The `item` form of
    /// ``SwiftUI/View/flareFullScreen(isPresented:label:ground:dismissible:onDismiss:content:)``: open while
    /// `item` is non-nil; closing sets it to nil, and a different item replaces the content in place (its state
    /// starts over).
    func flareFullScreen<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        label: String? = nil,
        ground: FlareFullScreenGround = .surface,
        dismissible: Bool = true,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(FlareItemLayer(item: item) { presented, shown in
            FlareFullScreenPresenter(
                isPresented: presented, label: label, ground: ground, dismissible: dismissible,
                onDismiss: onDismiss
            ) {
                if let value = shown() { content(value).id(value.id) }
            }
        })
    }
}

struct FlareFullScreenPresenter<ScreenContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let label: String?
    let ground: FlareFullScreenGround
    let dismissible: Bool
    let onDismiss: (() -> Void)?
    let screenContent: () -> ScreenContent
    @State private var presence = UUID()

    init(isPresented: Binding<Bool>, label: String?, ground: FlareFullScreenGround, dismissible: Bool,
         onDismiss: (() -> Void)?, @ViewBuilder screenContent: @escaping () -> ScreenContent) {
        _isPresented = isPresented
        self.label = label; self.ground = ground; self.dismissible = dismissible
        self.onDismiss = onDismiss; self.screenContent = screenContent
    }

    func body(content: Content) -> some View {
        content.modifier(FlareLayerPresenter(
            isPresented: $isPresented, presence: presence, coverKind: .modal, registers: true,
            dismissible: dismissible, compact: nil, allowsPush: false,
            resolve: { _ in .cover },
            onDismiss: onDismiss,
            sheetLayer: { EmptyView() },
            coverLayer: {
                FullScreenView(label: label, ground: ground, dismissible: dismissible,
                               onClose: { isPresented = false }) { screenContent() }
            },
            pushLayer: { EmptyView() }
        ))
    }
}
