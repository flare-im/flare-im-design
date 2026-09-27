import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// The overlay family shared by BottomSheet, Drawer and Modal: the public choices, the pure rules every
// presenter resolves with, the dismiss lock content raises, and the one presentation engine.

// MARK: - Public choices

/// How ``SwiftUI/View/flareBottomSheet(isPresented:title:titleHidden:presentation:dismissible:size:maxHeight:onDismiss:content:)``
/// appears. Spec: BottomSheet.presentation.
public enum FlareSheetPresentation: Sendable {
    /// A bottom sheet on the phone form factor (``SwiftUI/EnvironmentValues/flareCompactOverlays``), otherwise the
    /// same content in a ``ModalView``. Resolved once when the sheet opens and kept until it closes.
    case auto
    /// Always a bottom sheet.
    case sheet
}

/// How tall a kit bottom sheet is.
public enum FlareSheetSize: Sendable {
    /// Fits the content (measured), up to the height cap; taller content scrolls.
    case fitted
    /// The large detent, with no measuring scroll view: the content fills it and owns its scrolling — search,
    /// pickers, flows with their own `NavigationStack`. As a Modal it takes the fixed-height (`fill`) form.
    case large
}

/// The inline edge a ``DrawerView`` docks to; `end` and `start` follow the layout direction (RTL mirrors them).
public enum FlareDrawerPlacement: Sendable {
    case end, start
}

/// What ``SwiftUI/View/flareDrawer(isPresented:title:titleHidden:label:placement:width:dismissible:showClose:showBack:navigable:compactFallback:actions:footer:onBack:onDismiss:content:)``
/// does on the phone form factor.
public enum FlareDrawerCompactFallback: Sendable {
    /// A drawer anyway (clamped so a strip of scrim remains).
    case none
    /// Push the content as a page onto the enclosing `NavigationStack` instead.
    case push
}

// MARK: - Rules

/// How a layer is on screen once its presenter resolved it.
enum FlareLayerForm: Equatable {
    /// A system sheet (a kit bottom sheet).
    case sheet
    /// The kit layer (Drawer or Modal) over a clear full-screen cover; a system sheet below iOS 16.4 and on macOS.
    case cover
    /// A page pushed onto the enclosing navigation stack.
    case push
}

/// What Escape, the accessibility escape gesture or platform back does in a layer.
enum FlareLayerEscape: Equatable {
    case close, back, none
}

/// The pure rules of the overlay family, shared by every presenter and tested on their own.
enum FlareOverlayRules {
    /// The share of the available height a Modal or sheet takes at most when the host gives no `maxHeight`.
    static let maxHeightFraction: CGFloat = 0.72

    /// Whether overlays take their phone form (a bottom sheet, a page): the nearest shell's responsive mode when
    /// inside one, else the width the feedback host measured (below ``FlareSizes/navigationRailMinWidth``), else
    /// true — with nothing measured the kit keeps today's sheet. A zero or infinite width counts as unknown.
    static func compact(shellMode: FlareApplicationResponsiveMode?, hostWidth: CGFloat?) -> Bool {
        if let shellMode { return shellMode == .mobile }
        guard let hostWidth, hostWidth.isFinite, hostWidth > 0 else { return true }
        return hostWidth < FlareSizes.navigationRailMinWidth
    }

    /// A bottom sheet's form: `sheet` always a sheet; `auto` a sheet when compact, else a Modal (the cover form).
    static func sheetForm(_ presentation: FlareSheetPresentation, compact: Bool) -> FlareLayerForm {
        presentation == .sheet || compact ? .sheet : .cover
    }

    /// A drawer's form: pushed as a page when compact and the host asked for that, else the drawer layer.
    static func drawerForm(_ fallback: FlareDrawerCompactFallback, compact: Bool) -> FlareLayerForm {
        fallback == .push && compact ? .push : .cover
    }

    /// The drawer panel's width: the requested width (default ``FlareSizes/componentSheetWidth``), clamped so a
    /// touch-target-wide strip of scrim always remains beside it.
    static func drawerWidth(requested: CGFloat?, window: CGFloat) -> CGFloat {
        let preferred = requested ?? FlareSizes.componentSheetWidth
        return max(0, min(preferred, window - FlareSizes.touchTarget))
    }

    /// The Modal box's width: the requested width (default ``FlareSizes/componentSheetDialogWidth``), clamped to
    /// the window less an extra-large gutter on each side.
    static func modalWidth(requested: CGFloat?, window: CGFloat) -> CGFloat {
        let preferred = requested ?? FlareSizes.componentSheetDialogWidth
        return max(0, min(preferred, window - 2 * FlareSizes.spacingXl))
    }

    /// The height cap: the requested one, never more than what is available; 72% of the available height by default.
    static func maxHeight(requested: CGFloat?, available: CGFloat) -> CGFloat {
        let bounded = max(0, available)
        return min(requested ?? bounded * maxHeightFraction, bounded)
    }

    /// The edge the drawer's panel docks to and slides from (leading / trailing follow the layout direction).
    static func edge(_ placement: FlareDrawerPlacement) -> Edge {
        placement == .end ? .trailing : .leading
    }

    static func alignment(_ placement: FlareDrawerPlacement) -> Alignment {
        placement == .end ? .trailing : .leading
    }

    /// Whether the panel's rounded corners are on its physical left: the corners that face the page, on the side
    /// opposite the docked edge. A shape path is not mirrored for RTL, so the side is resolved here.
    static func roundsLeftCorners(_ placement: FlareDrawerPlacement, layoutDirection: LayoutDirection) -> Bool {
        let dockedOnRight = (placement == .end) == (layoutDirection == .leftToRight)
        return dockedOnRight
    }

    /// Whether anything may close the layer now: allowed by the host, nothing running, no content lock.
    static func dismissAllowed(dismissible: Bool, busy: Bool, locked: Bool) -> Bool {
        dismissible && !busy && !locked
    }

    /// Escape and the escape gesture: back while a back step is offered, otherwise close; nothing while locked.
    static func escape(showBack: Bool, dismissAllowed: Bool) -> FlareLayerEscape {
        guard dismissAllowed else { return .none }
        return showBack ? .back : .close
    }

    /// The layer's accessible name: the title (shown or hidden), else the label, else the kit fallback.
    static func accessibleName(title: String?, label: String?, fallback: String) -> String {
        if let title, !title.isEmpty { return title }
        if let label, !label.isEmpty { return label }
        return fallback
    }

    /// The header row is drawn when it has something: a visible title, actions, a back or a close button.
    static func showsHeader(visibleTitle: Bool, hasActions: Bool, showBack: Bool, showClose: Bool) -> Bool {
        visibleTitle || hasActions || showBack || showClose
    }
}

// MARK: - Dismiss lock

/// Raised by content inside a kit layer while it must not be dismissed (a form saving, a confirmation running its
/// action). ``ModalView`` and ``DrawerView`` read it to disable the scrim tap, Escape, the escape gesture and the
/// close button; a system sheet honours the `interactiveDismissDisabled` that
/// ``SwiftUI/View/flareLayerDismissDisabled(_:)`` sets alongside it.
public struct FlareLayerDismissDisabledKey: PreferenceKey {
    public static let defaultValue = false
    public static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

public extension View {
    /// Blocks dismissing the kit layer (sheet, Modal, Drawer) around this view while `disabled` is true.
    func flareLayerDismissDisabled(_ disabled: Bool) -> some View {
        preference(key: FlareLayerDismissDisabledKey.self, value: disabled)
            .interactiveDismissDisabled(disabled)
    }
}

/// The system sheet's own dismiss lock at the presentation root: the host's `dismissible` together with any lock
/// the content raised (``FlareLayerDismissDisabledKey``). A parent's `interactiveDismissDisabled` replaces its
/// content's, so the root applies the combined value rather than `dismissible` alone.
struct FlareSystemDismissLock: ViewModifier {
    let dismissible: Bool
    @State private var locked = false

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(FlareLayerDismissDisabledKey.self) { locked = $0 }
            .interactiveDismissDisabled(!dismissible || locked)
    }
}

// MARK: - Environment

/// The size of the feedback host's box, measured live (nil without a host).
private struct FlareOverlayHostSizeKey: EnvironmentKey {
    static let defaultValue: CGSize? = nil
}

/// Whether the layer around this view is on screen (false while it enters and leaves). True outside a presenter.
private struct FlareLayerVisibleKey: EnvironmentKey {
    static let defaultValue = true
}

/// True when the layer is shown inside a system sheet (below iOS 16.4, on macOS): no scrim, the sheet is the panel.
private struct FlareLayerChromelessKey: EnvironmentKey {
    static let defaultValue = false
}

/// A Modal standing in for a bottom sheet keeps the sheet's slim body padding.
private struct FlareModalSheetBodyKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// Whether overlays take their phone form here: a bottom sheet rather than a Modal, a page rather than a
    /// Drawer. Inside an ``IMAppKitView`` shell it follows the shell's responsive mode; below
    /// ``SwiftUI/View/flareFeedbackHost(_:)`` it follows the host's live width (below
    /// ``FlareSizes/navigationRailMinWidth``); with neither it is true. Hosts deciding between a page and a
    /// Drawer or Modal read this rather than a size class.
    var flareCompactOverlays: Bool {
        FlareOverlayRules.compact(shellMode: flareShellResponsiveMode, hostWidth: flareOverlayHostSize?.width)
    }
}

extension EnvironmentValues {
    var flareOverlayHostSize: CGSize? {
        get { self[FlareOverlayHostSizeKey.self] }
        set { self[FlareOverlayHostSizeKey.self] = newValue }
    }

    var flareLayerVisible: Bool {
        get { self[FlareLayerVisibleKey.self] }
        set { self[FlareLayerVisibleKey.self] = newValue }
    }

    var flareLayerChromeless: Bool {
        get { self[FlareLayerChromelessKey.self] }
        set { self[FlareLayerChromelessKey.self] = newValue }
    }

    var flareModalSheetBody: Bool {
        get { self[FlareModalSheetBodyKey.self] }
        set { self[FlareModalSheetBodyKey.self] = newValue }
    }
}

// MARK: - Presentation engine

enum FlareLayerPlatform {
    /// Whether the kit draws its own layer over a clear full-screen cover (iOS 16.4+); otherwise a system sheet.
    static var clearCover: Bool {
        #if os(iOS)
        if #available(iOS 16.4, *) { return true }
        #endif
        return false
    }

    /// Ends editing so the keyboard does not cover the layer that is opening.
    @MainActor
    static func endEditing() {
        #if canImport(UIKit) && !os(watchOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

/// Presents one kit layer from `isPresented` in the form `resolve` picks when it opens — a system sheet
/// (`sheetLayer`), the kit's own layer over a clear full-screen cover (`coverLayer`), or a pushed page
/// (`pushLayer`) — and keeps that form until it is gone. The cover runs without the system slide: the layer
/// animates itself in, and out before the cover goes. A `dismiss()` from inside, a swipe or a pop writes
/// `isPresented` back and runs `onDismiss`. A registering presenter records itself in the feedback's layer stack,
/// so toasts show above it and confirmations wait (or, for a Drawer, show from it).
struct FlareLayerPresenter<SheetLayer: View, CoverLayer: View, PushLayer: View>: ViewModifier {
    @Binding var isPresented: Bool
    /// The layer's entry in the feedback's layer stack (owned by the public presenter, which also hands it to
    /// the sheet form's toast layer).
    let presence: UUID
    /// The layer's kind in the feedback stack when it takes the cover form.
    let coverKind: FlareLayerKind
    let registers: Bool
    let dismissible: Bool
    /// Overrides the environment's form factor (the feedback host measures its own box).
    let compact: Bool?
    let allowsPush: Bool
    let resolve: (Bool) -> FlareLayerForm
    let onDismiss: (() -> Void)?
    let sheetLayer: () -> SheetLayer
    let coverLayer: () -> CoverLayer
    let pushLayer: () -> PushLayer

    @State private var form: FlareLayerForm?
    @State private var sheetShown = false
    @State private var coverShown = false
    @State private var pushShown = false
    @State private var closing = false
    @State private var generation = 0
    @Environment(\.flareFeedback) private var feedback
    @Environment(\.flareCompactOverlays) private var compactOverlays
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        pushable(content.sheet(isPresented: $sheetShown, onDismiss: sheetGone) {
            sheetLayer().modifier(FlareSystemDismissLock(dismissible: dismissible))
        })
        // A second presentation needs its own anchor view.
        .background(coverAnchor)
        .onAppear { if isPresented { open() } }
        .onChange(of: isPresented) { presented in presented ? open() : close() }
        .onChange(of: pushShown) { shown in if !shown && form == .push { finish() } }
        // A presenter that leaves the screen takes its layer along. While its cover is up the cover's own content
        // reports the layer gone (a full-screen presentation may take the presenter off screen while it stays).
        .onDisappear { if registers && !coverShown { feedback?.layerDismissed(presence) } }
    }

    @ViewBuilder
    private var coverAnchor: some View {
        #if os(iOS)
        if #available(iOS 16.4, *) {
            Color.clear.fullScreenCover(isPresented: $coverShown, onDismiss: finish) {
                stage.presentationBackground(.clear)
            }
        } else {
            Color.clear.sheet(isPresented: $coverShown, onDismiss: finish) {
                stage.presentationDetents([.large]).modifier(FlareSystemDismissLock(dismissible: dismissible))
            }
        }
        #else
        Color.clear.sheet(isPresented: $coverShown, onDismiss: finish) {
            stage.modifier(FlareSystemDismissLock(dismissible: dismissible))
        }
        #endif
    }

    private var stage: some View {
        FlareLayerStage(closing: closing, chromeless: !FlareLayerPlatform.clearCover,
                        feedback: registers ? feedback : nil, presence: presence,
                        presentsRequests: coverKind == .drawer) { coverLayer() }
    }

    @ViewBuilder
    private func pushable<V: View>(_ view: V) -> some View {
        if allowsPush {
            view.navigationDestination(isPresented: $pushShown) { pushLayer() }
        } else {
            view
        }
    }

    private func open() {
        generation += 1
        closing = false
        let resolved = form ?? resolve(compact ?? compactOverlays)
        form = resolved
        switch resolved {
        case .sheet:
            if registers { feedback?.layerPresented(presence, kind: .sheet) }
            FlareLayerPlatform.endEditing()
            sheetShown = true
        case .cover:
            if registers { feedback?.layerPresented(presence, kind: coverKind) }
            FlareLayerPlatform.endEditing()
            guard !coverShown else { return }
            if FlareLayerPlatform.clearCover {
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) { coverShown = true }
            } else {
                coverShown = true
            }
        case .push:
            pushShown = true
        }
    }

    private func close() {
        guard let form else { return }
        if registers { feedback?.layerClosing(presence) }
        switch form {
        case .sheet:
            sheetShown = false
        case .push:
            pushShown = false
        case .cover:
            guard coverShown else { return }
            guard FlareLayerPlatform.clearCover else { coverShown = false; return }
            // Animate the layer out, then drop the cover without the system slide.
            closing = true
            let pending = generation
            let delay = reduceMotion ? 0 : FlareMotion.normal
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard pending == generation, closing else { return }
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) { coverShown = false }
            }
        }
    }

    /// A sheet is gone: dismissed by the host, a swipe or `dismiss()`.
    private func sheetGone() {
        guard form == .sheet else { return }
        finish()
    }

    /// The layer is gone from the screen, whichever way it went.
    private func finish() {
        guard form != nil else { return }
        form = nil
        closing = false
        if registers { feedback?.layerDismissed(presence) }
        if isPresented { isPresented = false }
        onDismiss?()
    }
}

/// The cover's content: the layer, told when it is visible (entering after it appears, leaving while `closing`),
/// with the toasts above it and — for a Drawer — the confirmations the Drawer presents itself.
struct FlareLayerStage<Content: View>: View {
    let closing: Bool
    let chromeless: Bool
    let feedback: FlareFeedback?
    let presence: UUID
    let presentsRequests: Bool
    let content: Content
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(closing: Bool, chromeless: Bool, feedback: FlareFeedback?, presence: UUID, presentsRequests: Bool,
         @ViewBuilder content: () -> Content) {
        self.closing = closing; self.chromeless = chromeless; self.feedback = feedback
        self.presence = presence; self.presentsRequests = presentsRequests; self.content = content()
    }

    var body: some View {
        let visible = chromeless || (appeared && !closing)
        layered
            .environment(\.flareLayerVisible, visible)
            .environment(\.flareLayerChromeless, chromeless)
            .animation(reduceMotion ? nil : FlareMotion.normalAnimation, value: visible)
            .onAppear { appeared = true }
            // The cover's content lives exactly as long as the layer is on screen, however it went.
            .onDisappear { feedback?.layerDismissed(presence) }
    }

    @ViewBuilder
    private var layered: some View {
        if let feedback {
            if presentsRequests {
                content
                    .modifier(FlareToastLayer(feedback: feedback, presenter: .layer(presence)))
                    .modifier(FlareFeedbackRequests(feedback: feedback, presenter: .layer(presence), compact: nil))
            } else {
                content.modifier(FlareToastLayer(feedback: feedback, presenter: .layer(presence)))
            }
        } else {
            content
        }
    }
}

// MARK: - Shared chrome

/// The scrim behind a Drawer or Modal: `color` (the layer passes the `colors.scrim` token), full bleed, a tap
/// closes when allowed. VoiceOver skips it (the layer is modal; its escape gesture closes).
struct FlareOverlayScrim: View {
    let color: Color
    let visible: Bool
    let onTap: (() -> Void)?

    var body: some View {
        color
            .opacity(visible ? 1 : 0)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { onTap?() }
            .accessibilityHidden(true)
    }
}

/// The header row of a Drawer or Modal: [back?] title … [actions] [close?].
struct FlareOverlayHeader: View {
    let title: String?
    let showBack: Bool
    let showClose: Bool
    let actions: AnyView?
    let enabled: Bool
    let onBack: (() -> Void)?
    let onClose: () -> Void
    @AccessibilityFocusState private var headingFocused: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        HStack(spacing: FlareSizes.spacingXs) {
            if showBack {
                IconButtonView(icon: "back", accessibilityLabel: strings.back, disabled: !enabled,
                               action: { onBack?() })
                    .flipsForRightToLeftLayoutDirection(true)
            }
            if let title {
                Text(title)
                    .font(.system(size: FlareSizes.fontSizeXl, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($headingFocused)
                    .padding(.leading, showBack ? 0 : FlareSizes.spacingSm)
            }
            Spacer(minLength: FlareSizes.spacingSm)
            if let actions { actions }
            if showClose {
                IconButtonView(icon: "close", accessibilityLabel: strings.close, disabled: !enabled, action: onClose)
            }
        }
        .padding(.horizontal, FlareSizes.spacingSm)
        .padding(.vertical, FlareSizes.spacingXs)
        .onAppear { if title != nil { headingFocused = true } }
    }
}

/// Escape on a hardware keyboard: a zero-size button carrying the cancel shortcut, so the shortcut works with or
/// without a visible close button. A cover limits it to the topmost layer.
struct FlareOverlayEscapeKey: View {
    let escape: FlareLayerEscape
    let perform: () -> Void

    var body: some View {
        Button(action: perform) { EmptyView() }
            .keyboardShortcut(.cancelAction)
            .disabled(escape == .none)
            .frame(width: 0, height: 0)
            .opacity(0)
            .accessibilityHidden(true)
    }
}

/// A rectangle whose corners on one physical side are rounded (iOS 16 has no uneven rounded rectangle).
struct FlareSideRoundedRectangle: Shape {
    let radius: CGFloat
    let roundsLeft: Bool

    func path(in rect: CGRect) -> Path {
        let r = min(radius, rect.width / 2, rect.height / 2)
        var path = Path()
        if roundsLeft {
            path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r), radius: r,
                        startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r,
                        startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r,
                        startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r,
                        startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

extension View {
    /// Applies every layer of a shadow token.
    func flareShadow(_ layers: [FlareShadowLayer]) -> some View {
        layers.reduce(AnyView(self)) { view, layer in
            AnyView(view.shadow(color: layer.color, radius: layer.blur / 2, x: layer.x, y: layer.y))
        }
    }
}
