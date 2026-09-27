import SwiftUI

/// A centered box over the scrim for a focused task: the whole layer — scrim, box, header, body and footer.
/// Spec: Overlay/Modal (`ModalView`).
///
/// Present it with ``SwiftUI/View/flareModal(isPresented:title:titleHidden:label:width:maxHeight:fill:dismissible:showClose:busy:scrollable:actions:footer:onDismiss:content:)``
/// (a clear full-screen cover on iOS 16.4+, so it sits above tab bars, split columns and navigation bars; a
/// system sheet on earlier iOS and on macOS, where it draws no scrim). A kit bottom sheet in its `auto`
/// presentation hands its content here off the phone form factor.
///
/// - The box is ``FlareSizes/componentSheetDialogWidth`` wide by default (`width` overrides), never wider than
///   the window less an extra-large gutter each side, and at most `maxHeight` tall (default 72% of the height
///   available above the keyboard). `fill` keeps it at that height, so page-like content (global search) does
///   not resize as results arrive.
/// - `scrollable` (default) scrolls the body; false hands the content bounded constraints and its own scrolling.
/// - Header: title … [actions] [close]; none when there is no visible title, no actions and `showClose` is false.
///   `footer` is the button row under the body.
/// - The scrim, Escape, the VoiceOver escape gesture and the close button call `onClose` while `dismissible`, not
///   `busy`, and no content raised ``SwiftUI/View/flareLayerDismissDisabled(_:)``.
/// - VoiceOver: a modal container named by the title, else `label`, else ``FlareStrings/modalLabel``.
public struct ModalView<Content: View>: View {
    private let title: String?
    private let titleHidden: Bool
    private let label: String?
    private let width: CGFloat?
    private let maxHeight: CGFloat?
    private let fill: Bool
    private let dismissible: Bool
    private let showClose: Bool
    private let busy: Bool
    private let scrollable: Bool
    private let actions: AnyView?
    private let footer: AnyView?
    private let onClose: () -> Void
    private let content: Content
    @State private var locked = false
    @State private var bodyHeight: CGFloat = 0
    @Environment(\.flareLayerVisible) private var visible
    @Environment(\.flareLayerChromeless) private var chromeless
    @Environment(\.flareModalSheetBody) private var sheetBody
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(title: String? = nil, titleHidden: Bool = false, label: String? = nil, width: CGFloat? = nil,
                maxHeight: CGFloat? = nil, fill: Bool = false, dismissible: Bool = true, showClose: Bool = true,
                busy: Bool = false, scrollable: Bool = true, actions: AnyView? = nil, footer: AnyView? = nil,
                onClose: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title; self.titleHidden = titleHidden; self.label = label; self.width = width
        self.maxHeight = maxHeight; self.fill = fill; self.dismissible = dismissible; self.showClose = showClose
        self.busy = busy; self.scrollable = scrollable; self.actions = actions; self.footer = footer
        self.onClose = onClose; self.content = content()
    }

    public var body: some View {
        Group {
            if chromeless {
                box(width: nil, cap: nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                GeometryReader { proxy in
                    let colors = FlareColors.of(scheme, brand: flareBrandTheme)
                    let preferred = width ?? FlareSizes.componentSheetDialogWidth
                    ZStack {
                        FlareOverlayScrim(color: colors.scrim, visible: visible, onTap: dismissAllowed ? onClose : nil)
                        if visible {
                            box(width: FlareOverlayRules.modalWidth(requested: preferred, window: proxy.size.width),
                                cap: FlareOverlayRules.maxHeight(requested: maxHeight, available: proxy.size.height))
                                .transition(.scale(scale: 0.96).combined(with: .opacity))
                        }
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
        }
        .onPreferenceChange(FlareLayerDismissDisabledKey.self) { locked = $0 }
        .interactiveDismissDisabled(!dismissAllowed)
    }

    private var dismissAllowed: Bool {
        FlareOverlayRules.dismissAllowed(dismissible: dismissible, busy: busy, locked: locked)
    }

    private var visibleTitle: String? {
        guard let title, !title.isEmpty, !titleHidden else { return nil }
        return title
    }

    private var bodyPadding: CGFloat { sheetBody ? FlareSizes.spacingSm : FlareSizes.spacingLg }

    private func box(width: CGFloat?, cap: CGFloat?) -> some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let escape = FlareOverlayRules.escape(showBack: false, dismissAllowed: dismissAllowed)
        let hasHeader = FlareOverlayRules.showsHeader(visibleTitle: visibleTitle != nil, hasActions: actions != nil,
                                                      showBack: false, showClose: showClose)
        return VStack(spacing: 0) {
            if hasHeader {
                FlareOverlayHeader(title: visibleTitle, showBack: false, showClose: showClose, actions: actions,
                                   enabled: dismissAllowed, onBack: nil, onClose: onClose)
            }
            modalBody(filled: fill || cap == nil)
            if let footer {
                footer
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, FlareSizes.spacingLg)
                    .padding(.vertical, FlareSizes.spacingMd)
            }
        }
        .frame(width: width)
        .frame(height: fill ? cap : nil)
        .foregroundColor(colors.textPrimary)
        .background(RoundedRectangle(cornerRadius: chromeless ? 0 : FlareSizes.radiusXl).fill(colors.bgPrimary))
        .clipShape(RoundedRectangle(cornerRadius: chromeless ? 0 : FlareSizes.radiusXl))
        .flareShadow(chromeless ? [] : FlareShadows.of(scheme).xl)
        .background(FlareOverlayEscapeKey(escape: escape, perform: onClose))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(FlareOverlayRules.accessibleName(title: title, label: label, fallback: strings.modalLabel))
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { if escape == .close { onClose() } }
        // The cap: the box keeps its own height inside it.
        .frame(maxHeight: cap)
    }

    @ViewBuilder
    private func modalBody(filled: Bool) -> some View {
        if scrollable {
            ScrollView {
                content
                    .padding(bodyPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GeometryReader { proxy in
                        Color.clear.preference(key: FlareModalBodyHeightKey.self, value: proxy.size.height)
                    })
            }
            .onPreferenceChange(FlareModalBodyHeightKey.self) { bodyHeight = $0 }
            // Fits the content; the box's cap compresses it and the rest scrolls.
            .frame(maxHeight: filled ? .infinity : bodyHeight)
        } else {
            content
                .padding(.horizontal, bodyPadding)
                .padding(.bottom, bodyPadding)
                .frame(maxWidth: .infinity, maxHeight: filled ? .infinity : nil, alignment: .top)
        }
    }
}

/// The scrollable body's natural height.
private struct FlareModalBodyHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

public extension View {
    /// Presents a ``ModalView`` with `content` while `isPresented`: over a clear full-screen cover on iOS 16.4+
    /// (the kit draws the scrim and animates the box; reduced motion shows it at once), a system sheet on earlier
    /// iOS and on macOS. The scrim, Escape, the close button, a `dismiss()` from inside or setting `isPresented`
    /// to false close it; `onDismiss` runs once it is gone. ``FlareFeedback`` toasts show above it and
    /// confirmations wait until it is gone. Works without a feedback host.
    func flareModal<Content: View>(
        isPresented: Binding<Bool>,
        title: String? = nil,
        titleHidden: Bool = false,
        label: String? = nil,
        width: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        fill: Bool = false,
        dismissible: Bool = true,
        showClose: Bool = true,
        busy: Bool = false,
        scrollable: Bool = true,
        actions: AnyView? = nil,
        footer: AnyView? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(FlareModalPresenter(
            isPresented: isPresented, title: title, titleHidden: titleHidden, label: label, width: width,
            maxHeight: maxHeight, fill: fill, dismissible: dismissible, showClose: showClose, busy: busy,
            scrollable: scrollable, actions: actions, footer: footer, onDismiss: onDismiss, modalContent: content
        ))
    }

    /// The `item` form of
    /// ``SwiftUI/View/flareModal(isPresented:title:titleHidden:label:width:maxHeight:fill:dismissible:showClose:busy:scrollable:actions:footer:onDismiss:content:)``:
    /// open while `item` is non-nil; closing sets it to nil.
    func flareModal<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        title: String? = nil,
        titleHidden: Bool = false,
        label: String? = nil,
        width: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        fill: Bool = false,
        dismissible: Bool = true,
        showClose: Bool = true,
        busy: Bool = false,
        scrollable: Bool = true,
        actions: AnyView? = nil,
        footer: AnyView? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(FlareItemLayer(item: item) { presented, shown in
            FlareModalPresenter(
                isPresented: presented, title: title, titleHidden: titleHidden, label: label, width: width,
                maxHeight: maxHeight, fill: fill, dismissible: dismissible, showClose: showClose, busy: busy,
                scrollable: scrollable, actions: actions, footer: footer, onDismiss: onDismiss
            ) {
                if let value = shown() { content(value).id(value.id) }
            }
        })
    }
}

struct FlareModalPresenter<ModalContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let title: String?
    let titleHidden: Bool
    let label: String?
    let width: CGFloat?
    let maxHeight: CGFloat?
    let fill: Bool
    let dismissible: Bool
    let showClose: Bool
    let busy: Bool
    let scrollable: Bool
    let actions: AnyView?
    let footer: AnyView?
    let onDismiss: (() -> Void)?
    let modalContent: () -> ModalContent
    @State private var presence = UUID()

    init(isPresented: Binding<Bool>, title: String?, titleHidden: Bool, label: String?, width: CGFloat?,
         maxHeight: CGFloat?, fill: Bool, dismissible: Bool, showClose: Bool, busy: Bool, scrollable: Bool,
         actions: AnyView?, footer: AnyView?, onDismiss: (() -> Void)?,
         @ViewBuilder modalContent: @escaping () -> ModalContent) {
        _isPresented = isPresented
        self.title = title; self.titleHidden = titleHidden; self.label = label; self.width = width
        self.maxHeight = maxHeight; self.fill = fill; self.dismissible = dismissible; self.showClose = showClose
        self.busy = busy; self.scrollable = scrollable; self.actions = actions; self.footer = footer
        self.onDismiss = onDismiss; self.modalContent = modalContent
    }

    func body(content: Content) -> some View {
        content.modifier(FlareLayerPresenter(
            isPresented: $isPresented, presence: presence, coverKind: .modal, registers: true,
            dismissible: dismissible && !busy, compact: nil, allowsPush: false,
            resolve: { _ in .cover }, onDismiss: onDismiss,
            sheetLayer: { EmptyView() },
            coverLayer: {
                ModalView(title: title, titleHidden: titleHidden, label: label, width: width, maxHeight: maxHeight,
                          fill: fill, dismissible: dismissible, showClose: showClose, busy: busy,
                          scrollable: scrollable, actions: actions, footer: footer,
                          onClose: { isPresented = false }) { modalContent() }
            },
            pushLayer: { EmptyView() }
        ))
    }
}
