import SwiftUI

/// A full-height panel from the inline end (default) or start edge over the scrim, for long-lived secondary
/// content beside the main view — conversation, group and contact details, settings stacks, the profile editor.
/// The whole layer: scrim, docked panel, header, content and footer. Spec: Overlay/Drawer (`DrawerView`).
///
/// Present it with ``SwiftUI/View/flareDrawer(isPresented:title:titleHidden:label:placement:width:dismissible:showClose:showBack:navigable:compactFallback:actions:footer:onBack:onDismiss:content:)``
/// (a clear full-screen cover on iOS 16.4+, above tab bars, split columns and navigation bars; a system sheet on
/// earlier iOS and on macOS, where it draws no scrim). On the phone form factor hosts show the same content as a
/// page instead (`compactFallback: .push`).
///
/// - The panel is ``FlareSizes/componentSheetWidth`` wide by default (`width` overrides), clamped so a
///   touch-target-wide strip of scrim always remains; `end` / `start` follow the layout direction.
/// - Header: [back] title … [actions] [close]; none when there is no visible title, no actions, no back and
///   `showClose` is false (page content that brings its own header). `footer` sits under the content.
/// - `navigable` wraps the content in a `NavigationStack` (it pushes with `navigationDestination` and titles
///   itself with `navigationTitle`); the kit header is not drawn and close is the root page's primary action.
/// - Escape and the VoiceOver escape gesture step back (`onBack`) while `showBack`, else close; the scrim and the
///   close button close — all only while `dismissible` and no content raised
///   ``SwiftUI/View/flareLayerDismissDisabled(_:)``. There is no drag to dismiss (it would fight the navigation
///   stack's own swipe back).
/// - VoiceOver: a modal container named by the title, else `label`, else ``FlareStrings/drawerLabel``.
public struct DrawerView<Content: View>: View {
    private let title: String?
    private let titleHidden: Bool
    private let label: String?
    private let placement: FlareDrawerPlacement
    private let width: CGFloat?
    private let dismissible: Bool
    private let showClose: Bool
    private let showBack: Bool
    private let navigable: Bool
    private let actions: AnyView?
    private let footer: AnyView?
    private let onBack: (() -> Void)?
    private let onClose: () -> Void
    private let content: Content
    @State private var locked = false
    @Environment(\.flareLayerVisible) private var visible
    @Environment(\.flareLayerChromeless) private var chromeless
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(title: String? = nil, titleHidden: Bool = false, label: String? = nil,
                placement: FlareDrawerPlacement = .end, width: CGFloat? = nil, dismissible: Bool = true,
                showClose: Bool = true, showBack: Bool = false, navigable: Bool = false,
                actions: AnyView? = nil, footer: AnyView? = nil, onBack: (() -> Void)? = nil,
                onClose: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title; self.titleHidden = titleHidden; self.label = label; self.placement = placement
        self.width = width; self.dismissible = dismissible; self.showClose = showClose; self.showBack = showBack
        self.navigable = navigable; self.actions = actions; self.footer = footer; self.onBack = onBack
        self.onClose = onClose; self.content = content()
    }

    public var body: some View {
        Group {
            if chromeless {
                panel(width: nil, rounded: false)
            } else {
                GeometryReader { proxy in
                    let colors = FlareColors.of(scheme, brand: flareBrandTheme)
                    let window = proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing
                    let preferred = width ?? FlareSizes.componentSheetWidth
                    ZStack(alignment: FlareOverlayRules.alignment(placement)) {
                        FlareOverlayScrim(color: colors.scrim, visible: visible, onTap: dismissAllowed ? onClose : nil)
                        if visible {
                            panel(width: FlareOverlayRules.drawerWidth(requested: preferred, window: window), rounded: true)
                                .transition(.move(edge: FlareOverlayRules.edge(placement)))
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
        FlareOverlayRules.dismissAllowed(dismissible: dismissible, busy: false, locked: locked)
    }

    private var backOffered: Bool { showBack && onBack != nil }

    private var escape: FlareLayerEscape {
        FlareOverlayRules.escape(showBack: backOffered, dismissAllowed: dismissAllowed)
    }

    private var visibleTitle: String? {
        guard let title, !title.isEmpty, !titleHidden else { return nil }
        return title
    }

    private func performEscape() {
        switch escape {
        case .back: onBack?()
        case .close: onClose()
        case .none: break
        }
    }

    private func panel(width: CGFloat?, rounded: Bool) -> some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let roundsLeft = FlareOverlayRules.roundsLeftCorners(placement, layoutDirection: layoutDirection)
        let ground = FlareSideRoundedRectangle(radius: rounded ? FlareSizes.radiusXl : 0, roundsLeft: roundsLeft)
        return VStack(spacing: 0) {
            if navigable {
                NavigationStack {
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                if showClose {
                                    IconButtonView(icon: "close", accessibilityLabel: strings.close,
                                                   disabled: !dismissAllowed, action: onClose)
                                }
                            }
                        }
                }
            } else {
                if FlareOverlayRules.showsHeader(visibleTitle: visibleTitle != nil, hasActions: actions != nil,
                                                 showBack: backOffered, showClose: showClose) {
                    FlareOverlayHeader(title: visibleTitle, showBack: backOffered, showClose: showClose,
                                       actions: actions, enabled: dismissAllowed, onBack: onBack, onClose: onClose)
                }
                content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            if let footer {
                footer
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, FlareSizes.spacingLg)
                    .padding(.vertical, FlareSizes.spacingMd)
            }
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .foregroundColor(colors.textPrimary)
        // The ground runs on under the status bar and home indicator; the content keeps the safe area.
        .background(ground.fill(colors.bgPrimary).ignoresSafeArea(.container))
        .flareShadow(rounded ? FlareShadows.of(scheme).xl : [])
        .background(FlareOverlayEscapeKey(escape: escape, perform: performEscape))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(FlareOverlayRules.accessibleName(title: title, label: label, fallback: strings.drawerLabel))
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { performEscape() }
    }
}

public extension View {
    /// Presents a ``DrawerView`` with `content` while `isPresented`: over a clear full-screen cover on iOS 16.4+
    /// (the kit draws the scrim and slides the panel in from its edge; reduced motion shows it at once), a
    /// system sheet on earlier iOS and on macOS. The scrim, Escape, the close button, a `dismiss()` from inside or
    /// setting `isPresented` to false close it; `onDismiss` runs once it is gone.
    ///
    /// With `compactFallback: .push`, on the phone form factor (``SwiftUI/EnvironmentValues/flareCompactOverlays``,
    /// resolved when it opens) the content is pushed as a page onto the enclosing `NavigationStack` instead — one
    /// binding drives both forms. ``FlareFeedback`` toasts show above an open drawer, and confirmations and
    /// prompts asked while it is the topmost layer show from it. Works without a feedback host.
    func flareDrawer<Content: View>(
        isPresented: Binding<Bool>,
        title: String? = nil,
        titleHidden: Bool = false,
        label: String? = nil,
        placement: FlareDrawerPlacement = .end,
        width: CGFloat? = nil,
        dismissible: Bool = true,
        showClose: Bool = true,
        showBack: Bool = false,
        navigable: Bool = false,
        compactFallback: FlareDrawerCompactFallback = .none,
        actions: AnyView? = nil,
        footer: AnyView? = nil,
        onBack: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(FlareDrawerPresenter(
            isPresented: isPresented, title: title, titleHidden: titleHidden, label: label, placement: placement,
            width: width, dismissible: dismissible, showClose: showClose, showBack: showBack, navigable: navigable,
            compactFallback: compactFallback, actions: actions, footer: footer, onBack: onBack,
            onDismiss: onDismiss, drawerContent: content
        ))
    }

    /// The `item` form of
    /// ``SwiftUI/View/flareDrawer(isPresented:title:titleHidden:label:placement:width:dismissible:showClose:showBack:navigable:compactFallback:actions:footer:onBack:onDismiss:content:)``:
    /// open while `item` is non-nil; closing sets it to nil.
    func flareDrawer<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        title: String? = nil,
        titleHidden: Bool = false,
        label: String? = nil,
        placement: FlareDrawerPlacement = .end,
        width: CGFloat? = nil,
        dismissible: Bool = true,
        showClose: Bool = true,
        showBack: Bool = false,
        navigable: Bool = false,
        compactFallback: FlareDrawerCompactFallback = .none,
        actions: AnyView? = nil,
        footer: AnyView? = nil,
        onBack: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(FlareItemLayer(item: item) { presented, shown in
            FlareDrawerPresenter(
                isPresented: presented, title: title, titleHidden: titleHidden, label: label, placement: placement,
                width: width, dismissible: dismissible, showClose: showClose, showBack: showBack,
                navigable: navigable, compactFallback: compactFallback, actions: actions, footer: footer,
                onBack: onBack, onDismiss: onDismiss
            ) {
                if let value = shown() { content(value).id(value.id) }
            }
        })
    }
}

struct FlareDrawerPresenter<DrawerContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let title: String?
    let titleHidden: Bool
    let label: String?
    let placement: FlareDrawerPlacement
    let width: CGFloat?
    let dismissible: Bool
    let showClose: Bool
    let showBack: Bool
    let navigable: Bool
    let compactFallback: FlareDrawerCompactFallback
    let actions: AnyView?
    let footer: AnyView?
    let onBack: (() -> Void)?
    let onDismiss: (() -> Void)?
    let drawerContent: () -> DrawerContent
    @State private var presence = UUID()

    init(isPresented: Binding<Bool>, title: String?, titleHidden: Bool, label: String?,
         placement: FlareDrawerPlacement, width: CGFloat?, dismissible: Bool, showClose: Bool, showBack: Bool,
         navigable: Bool, compactFallback: FlareDrawerCompactFallback, actions: AnyView?, footer: AnyView?,
         onBack: (() -> Void)?, onDismiss: (() -> Void)?,
         @ViewBuilder drawerContent: @escaping () -> DrawerContent) {
        _isPresented = isPresented
        self.title = title; self.titleHidden = titleHidden; self.label = label; self.placement = placement
        self.width = width; self.dismissible = dismissible; self.showClose = showClose; self.showBack = showBack
        self.navigable = navigable; self.compactFallback = compactFallback; self.actions = actions
        self.footer = footer; self.onBack = onBack; self.onDismiss = onDismiss; self.drawerContent = drawerContent
    }

    func body(content: Content) -> some View {
        let fallback = compactFallback
        content.modifier(FlareLayerPresenter(
            isPresented: $isPresented, presence: presence, coverKind: .drawer, registers: true,
            dismissible: dismissible, compact: nil, allowsPush: fallback == .push,
            resolve: { compact in FlareOverlayRules.drawerForm(fallback, compact: compact) },
            onDismiss: onDismiss,
            sheetLayer: { EmptyView() },
            coverLayer: {
                DrawerView(title: title, titleHidden: titleHidden, label: label, placement: placement, width: width,
                           dismissible: dismissible, showClose: showClose, showBack: showBack, navigable: navigable,
                           actions: actions, footer: footer, onBack: onBack,
                           onClose: { isPresented = false }) { drawerContent() }
            },
            pushLayer: { pushedPage }
        ))
    }

    /// The page form: the content in the enclosing stack, titled with the drawer's title when it has one.
    @ViewBuilder
    private var pushedPage: some View {
        if let title, !title.isEmpty, !navigable {
            drawerContent().navigationTitle(title)
        } else {
            drawerContent()
        }
    }
}
