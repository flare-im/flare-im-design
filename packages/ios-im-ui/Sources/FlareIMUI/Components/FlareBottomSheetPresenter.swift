import SwiftUI

public extension View {
    /// Presents `content` for `item` as a kit bottom sheet: ``BottomSheetView`` with `title`, the
    /// system drag indicator, the kit ground and corner radius, and a height that fits the content
    /// up to the large detent (taller content scrolls). Setting `item` to nil closes it; `onDismiss`
    /// runs once it is gone. ``FlareFeedback`` toasts raised while the sheet is open show above it;
    /// a confirmation waits until the sheet is gone — so a sheet action can close the sheet and
    /// `await feedback.confirm(…)` right away.
    func flareBottomSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        title: String? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(FlareBottomSheetPresenter(item: item, title: title, onDismiss: onDismiss, sheetContent: content))
    }
}

private struct FlareBottomSheetPresenter<Item: Identifiable, SheetContent: View>: ViewModifier {
    @Binding var item: Item?
    let title: String?
    let onDismiss: (() -> Void)?
    let sheetContent: (Item) -> SheetContent
    /// This presenter's entry in the feedback's sheet registry.
    @State private var presence = UUID()
    @Environment(\.flareFeedback) private var feedback

    func body(content: Content) -> some View {
        content
            .sheet(item: $item, onDismiss: {
                // A replaced item is presented again right away; only a closed sheet is gone.
                if item == nil { feedback?.sheetDismissed(presence) }
                onDismiss?()
            }) { value in
                FlareBottomSheetFrame(title: title, presence: presence) { sheetContent(value) }
            }
            .onAppear { if item != nil { feedback?.sheetPresented(presence) } }
            .onChange(of: item == nil) { closed in
                if closed { feedback?.sheetClosing(presence) } else { feedback?.sheetPresented(presence) }
            }
            // A presenter that leaves the screen takes its sheet along.
            .onDisappear { feedback?.sheetDismissed(presence) }
    }
}

/// The sheet's content: the frame, measured for the detent, scrolling when it outgrows the sheet.
struct FlareBottomSheetFrame<Content: View>: View {
    let title: String?
    let presence: UUID
    let content: Content
    @State private var height: CGFloat = 0
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareFeedback) private var feedback

    init(title: String?, presence: UUID, @ViewBuilder content: () -> Content) {
        self.title = title; self.presence = presence; self.content = content()
    }

    var body: some View {
        let ground = FlareColors.of(scheme, brand: flareBrandTheme).bgPrimary
        ScrollView {
            BottomSheetView(title: title) { content }
                .environment(\.flareBottomSheetHosted, true)
                .background(GeometryReader { proxy in
                    Color.clear.preference(key: FlareSheetHeightKey.self, value: proxy.size.height)
                })
        }
        .onPreferenceChange(FlareSheetHeightKey.self) { height = $0 }
        .modifier(FlareSheetPresentation(detents: Self.detents(forHeight: height), ground: ground))
        .modifier(FlareSheetFeedback(feedback: feedback, presence: presence))
    }

    /// Medium until the content is measured, then the content's height (the system caps it at large).
    static func detents(forHeight height: CGFloat) -> Set<PresentationDetent> {
        height > 0 ? [.height(height)] : [.medium]
    }
}

private struct FlareBottomSheetHostedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True inside ``SwiftUI/View/flareBottomSheet(item:title:onDismiss:content:)`` content: the sheet
    /// already fits its detent to the content, so a sheet body (``FormSheetView``) sets none of its own.
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

private struct FlareSheetPresentation: ViewModifier {
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

/// Toasts above this sheet while it is the newest open kit sheet.
private struct FlareSheetFeedback: ViewModifier {
    let feedback: FlareFeedback?
    let presence: UUID

    func body(content: Content) -> some View {
        if let feedback {
            content.modifier(FlareToastLayer(feedback: feedback, presenter: .sheet(presence)))
        } else {
            content
        }
    }
}
