import SwiftUI

public extension View {
    /// Presents `content` while `isPresented` as a kit bottom sheet. Spec: Overlay/BottomSheet.
    ///
    /// - `presentation`: `.auto` (default) is a bottom sheet on the phone form factor
    ///   (``SwiftUI/EnvironmentValues/flareCompactOverlays``) and otherwise the same content in a ``ModalView`` —
    ///   resolved once when it opens and kept until it closes; `.sheet` is always a bottom sheet.
    /// - The sheet is ``BottomSheetView`` with `title` (a quiet centered caption; `titleHidden` keeps it as the
    ///   accessible name only), the system drag indicator, the kit ground and corner radius.
    /// - `size`: `.fitted` fits the content (taller content scrolls) up to `maxHeight` (default 72% of the
    ///   feedback host's height; the large detent without a host); `.large` takes the large detent and lets the
    ///   content fill it and own its scrolling (search, pickers, flows with their own `NavigationStack`).
    /// - `dismissible` false blocks the swipe, the scrim, Escape and the close button; content can also block
    ///   them live with ``SwiftUI/View/flareLayerDismissDisabled(_:)``.
    ///
    /// Setting `isPresented` to false closes it; a swipe or `dismiss()` sets it false; `onDismiss` runs once it is
    /// gone. ``FlareFeedback`` toasts raised while it is open show above it; a confirmation waits until it is
    /// gone — so a sheet action can close the sheet and `await feedback.confirm(…)` right away.
    func flareBottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        title: String? = nil,
        titleHidden: Bool = false,
        presentation: FlareSheetPresentation = .auto,
        dismissible: Bool = true,
        size: FlareSheetSize = .fitted,
        maxHeight: CGFloat? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(FlareSheetLayerPresenter(
            isPresented: isPresented, title: title, titleHidden: titleHidden, presentation: presentation,
            dismissible: dismissible, size: size, maxHeight: maxHeight, registers: true, compact: nil,
            onDismiss: onDismiss, sheetContent: content
        ))
    }

    /// Presents `content` for `item` as a kit bottom sheet — the `item` form of
    /// ``SwiftUI/View/flareBottomSheet(isPresented:title:titleHidden:presentation:dismissible:size:maxHeight:onDismiss:content:)``.
    /// Setting `item` to nil closes it; a different item replaces the content in place (its state starts over).
    func flareBottomSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        title: String? = nil,
        titleHidden: Bool = false,
        presentation: FlareSheetPresentation = .auto,
        dismissible: Bool = true,
        size: FlareSheetSize = .fitted,
        maxHeight: CGFloat? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(FlareItemLayer(item: item) { presented, shown in
            FlareSheetLayerPresenter(
                isPresented: presented, title: title, titleHidden: titleHidden, presentation: presentation,
                dismissible: dismissible, size: size, maxHeight: maxHeight, registers: true, compact: nil,
                onDismiss: onDismiss
            ) {
                if let value = shown() { content(value).id(value.id) }
            }
        })
    }
}

/// Drives an `isPresented` presenter from an optional item, keeping the last item while the layer leaves so its
/// content does not empty on the way out.
struct FlareItemLayer<Item: Identifiable, Presenter: ViewModifier>: ViewModifier {
    @Binding var item: Item?
    let presenter: (Binding<Bool>, @escaping () -> Item?) -> Presenter
    @State private var last: Item?

    func body(content: Content) -> some View {
        let presented = Binding(get: { item != nil }, set: { if !$0 { item = nil } })
        let current = item
        let kept = last
        content
            .modifier(presenter(presented) { current ?? kept })
            .onAppear { if let item { last = item } }
            .onChange(of: item?.id) { _ in if let item { last = item } }
    }
}

/// A bottom sheet in the form its presentation resolves to: the kit sheet (``FlareBottomSheetFrame``), or the
/// same content in a ``ModalView`` (the cover form). `registers` false keeps it out of the feedback's layer stack
/// (the feedback's own confirmations).
struct FlareSheetLayerPresenter<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let title: String?
    let titleHidden: Bool
    let presentation: FlareSheetPresentation
    let dismissible: Bool
    let size: FlareSheetSize
    let maxHeight: CGFloat?
    let registers: Bool
    let compact: Bool?
    let onDismiss: (() -> Void)?
    let sheetContent: () -> SheetContent
    @State private var presence = UUID()

    init(isPresented: Binding<Bool>, title: String?, titleHidden: Bool, presentation: FlareSheetPresentation,
         dismissible: Bool, size: FlareSheetSize, maxHeight: CGFloat?, registers: Bool, compact: Bool?,
         onDismiss: (() -> Void)?, @ViewBuilder sheetContent: @escaping () -> SheetContent) {
        _isPresented = isPresented
        self.title = title; self.titleHidden = titleHidden; self.presentation = presentation
        self.dismissible = dismissible; self.size = size; self.maxHeight = maxHeight
        self.registers = registers; self.compact = compact; self.onDismiss = onDismiss
        self.sheetContent = sheetContent
    }

    func body(content: Content) -> some View {
        let presentation = presentation
        content.modifier(FlareLayerPresenter(
            isPresented: $isPresented, presence: presence, coverKind: .modalFromBottomSheet, registers: registers,
            dismissible: dismissible, compact: compact, allowsPush: false,
            resolve: { compact in FlareOverlayRules.sheetForm(presentation, compact: compact) },
            onDismiss: onDismiss,
            sheetLayer: {
                FlareBottomSheetFrame(title: title, titleHidden: titleHidden, size: size, maxHeight: maxHeight,
                                      presence: registers ? presence : nil) { sheetContent() }
            },
            coverLayer: {
                // The sheet's own chrome: no close button (the scrim and Escape close it), the slim body padding.
                ModalView(title: title, titleHidden: titleHidden, maxHeight: maxHeight, fill: size == .large,
                          dismissible: dismissible, showClose: false, scrollable: size == .fitted,
                          onClose: { isPresented = false }) {
                    sheetContent().environment(\.flareBottomSheetHosted, true)
                }
                .environment(\.flareModalSheetBody, true)
            },
            pushLayer: { EmptyView() }
        ))
    }
}

/// The sheet's content: the frame, measured for the detent (fitted), scrolling when it outgrows the sheet — or
/// the large detent filled by content that owns its scrolling.
struct FlareBottomSheetFrame<Content: View>: View {
    let title: String?
    let titleHidden: Bool
    let size: FlareSheetSize
    let maxHeight: CGFloat?
    /// This sheet's entry in the feedback's layer stack; nil when it does not register.
    let presence: UUID?
    let content: Content
    @State private var height: CGFloat = 0
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareFeedback) private var feedback
    @Environment(\.flareOverlayHostSize) private var hostSize

    init(title: String?, titleHidden: Bool = false, size: FlareSheetSize = .fitted, maxHeight: CGFloat? = nil,
         presence: UUID?, @ViewBuilder content: () -> Content) {
        self.title = title; self.titleHidden = titleHidden; self.size = size; self.maxHeight = maxHeight
        self.presence = presence; self.content = content()
    }

    var body: some View {
        let ground = FlareColors.of(scheme, brand: flareBrandTheme).bgPrimary
        framed(ground)
            .modifier(FlareSheetFeedback(feedback: feedback, presence: presence))
    }

    @ViewBuilder
    private func framed(_ ground: Color) -> some View {
        switch size {
        case .fitted:
            ScrollView {
                BottomSheetView(title: title, titleHidden: titleHidden) { content }
                    .environment(\.flareBottomSheetHosted, true)
                    .background(GeometryReader { proxy in
                        Color.clear.preference(key: FlareSheetHeightKey.self, value: proxy.size.height)
                    })
            }
            .onPreferenceChange(FlareSheetHeightKey.self) { height = $0 }
            .modifier(FlareSheetDetentChrome(detents: Self.detents(forHeight: height, cap: cap), ground: ground))
        case .large:
            BottomSheetView(title: title, titleHidden: titleHidden) {
                content.frame(maxHeight: .infinity, alignment: .top)
            }
            .environment(\.flareBottomSheetHosted, true)
            .frame(maxHeight: .infinity, alignment: .top)
            .modifier(FlareSheetDetentChrome(detents: [.large], ground: ground))
        }
    }

    /// The fitted sheet's cap: the host's `maxHeight`, else 72% of the feedback host's height when one is
    /// installed (the system caps at the large detent otherwise).
    private var cap: CGFloat? {
        if let maxHeight { return maxHeight }
        guard let hostSize, hostSize.height > 0 else { return nil }
        return FlareOverlayRules.maxHeight(requested: nil, available: hostSize.height)
    }

    /// Medium until the content is measured, then the content's height up to `cap` (the system caps it at large).
    static func detents(forHeight height: CGFloat, cap: CGFloat? = nil) -> Set<PresentationDetent> {
        guard height > 0 else { return [.medium] }
        return [.height(cap.map { min(height, $0) } ?? height)]
    }
}

private struct FlareBottomSheetHostedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True inside kit bottom sheet content (either form): the sheet already sizes itself to the content, so a
    /// sheet body (``FormSheetView``) sets no detents of its own.
    var flareBottomSheetHosted: Bool {
        get { self[FlareBottomSheetHostedKey.self] }
        set { self[FlareBottomSheetHostedKey.self] = newValue }
    }
}

/// The content's natural height inside the sheet.
private struct FlareSheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// The system sheet's detents, drag indicator, kit ground and corner radius.
private struct FlareSheetDetentChrome: ViewModifier {
    let detents: Set<PresentationDetent>
    let ground: Color

    func body(content: Content) -> some View {
        let fitted = content
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
        if #available(iOS 16.4, macOS 13.3, *) {
            fitted
                .scrollBounceBehavior(.basedOnSize)
                .presentationBackground(ground)
                .presentationCornerRadius(FlareSizes.radius2xl)
        } else {
            fitted.background(ground.ignoresSafeArea())
        }
    }
}

/// Toasts above this sheet while it is the topmost open kit layer.
private struct FlareSheetFeedback: ViewModifier {
    let feedback: FlareFeedback?
    let presence: UUID?

    func body(content: Content) -> some View {
        if let feedback, let presence {
            content.modifier(FlareToastLayer(feedback: feedback, presenter: .layer(presence)))
        } else {
            content
        }
    }
}
