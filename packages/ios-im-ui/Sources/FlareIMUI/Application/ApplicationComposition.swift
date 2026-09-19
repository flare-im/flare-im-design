import SwiftUI

public enum FlareApplicationResponsiveMode: String, Sendable {
    case mobile, tablet, desktop, wideDesktop
}

public enum FlareApplicationNavigationPresentation: String, Sendable {
    case bottom, rail, sidebar, expandedSidebar
}

public enum FlareApplicationWorkspacePane: String, Sendable {
    case primary, content, detail
}

public enum FlareApplicationViewStatus: String, Sendable {
    case loading, ready, empty, error, offline
}

public struct FlareApplicationNavigationBadge: Sendable, Equatable {
    public enum Kind: String, Sendable { case dot, count, mention }
    public var kind: Kind
    public var count: Int
    public var label: String?

    public init(kind: Kind = .count, count: Int = 0, label: String? = nil) {
        self.kind = kind; self.count = count; self.label = label
    }
}

public struct FlareApplicationNavigationItem: Identifiable, Sendable, Equatable {
    public var id: String
    public var label: String
    /// Semantic kit icon name (``flareIconNames``); the selected item may draw the platform's filled
    /// variant, which is the kit's own idiom — the host passes only the name.
    public var icon: String
    public var accessibilityLabel: String
    public var badge: FlareApplicationNavigationBadge?
    public var enabled: Bool
    public var visible: Bool
    public var order: Int?
    public var capability: String?
    public var intent: FlareNavigationIntent?

    public init(id: String, label: String, icon: String,
                accessibilityLabel: String? = nil,
                badge: FlareApplicationNavigationBadge? = nil, enabled: Bool = true,
                visible: Bool = true, order: Int? = nil, capability: String? = nil,
                intent: FlareNavigationIntent? = nil) {
        self.id = id; self.label = label; self.icon = icon
        self.accessibilityLabel = accessibilityLabel ?? label
        self.badge = badge; self.enabled = enabled; self.visible = visible
        self.order = order; self.capability = capability; self.intent = intent
    }
}

public struct FlareApplicationNavigationGroup: Identifiable, Sendable, Equatable {
    public var id: String
    public var items: [FlareApplicationNavigationItem]
    public var label: String?

    public init(id: String, items: [FlareApplicationNavigationItem], label: String? = nil) {
        self.id = id; self.items = items; self.label = label
    }
}

public struct FlareApplicationViewState<Value> {
    public var status: FlareApplicationViewStatus
    public var value: Value?
    /// What went wrong, for `error` and `offline`; never the empty state's words (FR-057).
    public var error: String?
    /// What an empty list should say. Without it the container falls back to its own words.
    public var emptyTitle: String?
    /// A failed refresh over content that is still worth showing: the rows stay and the failure is a
    /// banner above them, instead of replacing everything a person was reading (FR-057).
    public var stale: Bool
    public var hasMore: Bool

    public init(status: FlareApplicationViewStatus = .ready, value: Value? = nil,
                error: String? = nil, emptyTitle: String? = nil, stale: Bool = false,
                hasMore: Bool = false) {
        self.status = status; self.value = value; self.error = error
        self.emptyTitle = emptyTitle; self.stale = stale; self.hasMore = hasMore
    }
}

/// What a container draws for a state: the rows, the rows under a banner, or a state of its own.
public enum FlareViewPresentation: String, Sendable, CaseIterable {
    case content, contentWithNotice, state
}

/// How a list container presents a state (`spec/view-state-vectors.json`, the same table on four kits).
public func flareViewPresentation(_ status: FlareApplicationViewStatus, stale: Bool) -> FlareViewPresentation {
    if status == .ready { return .content }
    if stale, status == .error || status == .offline { return .contentWithNotice }
    return .state
}

public struct FlareCapabilitySet: Sendable, Equatable {
    public var values: Set<String>
    public init(_ values: Set<String> = []) { self.values = values }
    public func contains(_ capability: String) -> Bool { values.contains(capability) }
}

public struct FlareApplicationFeatures: Sendable, Equatable {
    public var search = true
    public var contacts = true
    public var groups = true
    public var calls = false
    public var media = true
    public var savedMessages = true
    public var settings = true
    public init() {}
}

public struct FlareIMAppConfiguration: Sendable, Equatable {
    public var features: FlareApplicationFeatures
    public var capabilities: FlareCapabilitySet
    public var locale: String?

    public init(features: FlareApplicationFeatures = FlareApplicationFeatures(),
                capabilities: FlareCapabilitySet = FlareCapabilitySet(), locale: String? = nil) {
        self.features = features; self.capabilities = capabilities; self.locale = locale
    }
}

public protocol FlareDataSource {
    associatedtype Request
    associatedtype Value
    func load(_ request: Request) async -> FlareApplicationViewState<Value>
}

public protocol FlareIMHostAdapter {
    func execute(_ intent: FlareNavigationIntent) async throws
}

public enum FlareNavigationIntent: Sendable, Equatable {
    case openConversation(String)
    case openContact(String)
    case openGroup(String)
    case openSearch(String)
    case openSettings
    case custom(id: String, payload: [String: String])
}

/// The app shell's own navigation, named by the strings table so a host that overrides ``FlareStrings``
/// (or ships another language) reaches these labels too — they used to be English literals in a
/// Chinese-first kit.
public func flareDefaultIMNavigation(_ strings: FlareStrings = FlareStrings()) -> [FlareApplicationNavigationItem] {
    [
        .init(id: "chats", label: strings.navChats, icon: "chats", order: 0),
        .init(id: "contacts", label: strings.navContacts, icon: "people", order: 1),
        .init(id: "profile", label: strings.navProfile, icon: "person", order: 2),
    ]
}

/// The contacts page's own sections, named by the strings table (see ``flareDefaultIMNavigation(_:)``).
public func flareDefaultContactNavigation(_ strings: FlareStrings = FlareStrings()) -> [FlareApplicationNavigationItem] {
    [
        .init(id: "friends", label: strings.navFriends, icon: "person", order: 0),
        .init(id: "groups", label: strings.navGroups, icon: "group", order: 1),
        .init(id: "newFriends", label: strings.navNewFriends, icon: "person-add", order: 2),
        .init(id: "favorites", label: strings.favorites, icon: "star", order: 3),
    ]
}

public func resolveNavigationItems(
    defaults: [FlareApplicationNavigationItem],
    items: [FlareApplicationNavigationItem]? = nil,
    capabilities: FlareCapabilitySet = FlareCapabilitySet()
) -> [FlareApplicationNavigationItem] {
    var seen = Set<String>()
    return (items ?? defaults).enumerated()
        .filter { _, item in
            !item.id.isEmpty && item.visible && seen.insert(item.id).inserted
                && (item.capability == nil || capabilities.contains(item.capability!))
        }
        .sorted { left, right in
            let leftOrder = left.element.order ?? left.offset
            let rightOrder = right.element.order ?? right.offset
            return leftOrder == rightOrder ? left.offset < right.offset : leftOrder < rightOrder
        }
        .map(\.element)
}

public struct FlareMessageActionExtension {
    public var id: String
    public var label: String
    public var capability: String?
    public var group: String?
    public var order: Int?
    public var visible: Bool
    public var enabled: (String) -> Bool
    public var available: (String) -> Bool
    public var intent: String?
    public var accessibilityLabel: String
    public var disabledReason: String?
    public var invoke: (String) -> Void

    public init(id: String, label: String, capability: String? = nil,
                group: String? = nil, order: Int? = nil, visible: Bool = true,
                enabled: @escaping (String) -> Bool = { _ in true },
                available: @escaping (String) -> Bool = { _ in true },
                intent: String? = nil, accessibilityLabel: String? = nil,
                disabledReason: String? = nil,
                invoke: @escaping (String) -> Void) {
        self.id = id; self.label = label; self.capability = capability
        self.group = group; self.order = order; self.visible = visible
        self.enabled = enabled; self.available = available; self.intent = intent
        self.accessibilityLabel = accessibilityLabel ?? label
        self.disabledReason = disabledReason; self.invoke = invoke
    }
}

/// Shared breakpoints with Vue/Flutter/Compose: 600 / 900 / 1500 on width divided by the text scale.
public func resolveApplicationResponsiveMode(width: CGFloat, textScale: CGFloat = 1) -> FlareApplicationResponsiveMode {
    let effective = width / max(1, textScale)
    if effective < FlareSizes.navigationRailMinWidth { return .mobile }
    if effective < FlareSizes.appShellCompactMinWidth { return .tablet }
    if effective < FlareSizes.appShellExpandedMinWidth { return .desktop }
    return .wideDesktop
}

public enum FlareWorkspacePaneMode: String, Sendable { case singlePane, dualPane, triplePane }

public enum FlareWorkspaceDetailPresentation: String, Sendable { case hidden, inline, overlay, route }

public struct FlareWorkspacePresentation: Sendable, Equatable {
    public let paneMode: FlareWorkspacePaneMode
    public let detail: FlareWorkspaceDetailPresentation
    public init(paneMode: FlareWorkspacePaneMode, detail: FlareWorkspaceDetailPresentation) {
        self.paneMode = paneMode; self.detail = detail
    }
}

/// Width the navigation presentation for `mode` occupies beside the panes.
public func resolveNavigationWidth(_ mode: FlareApplicationResponsiveMode) -> CGFloat {
    switch mode {
    case .mobile: return 0
    case .tablet: return FlareSizes.navigationRailWidth
    case .wideDesktop: return FlareSizes.primaryPaneDefaultWidth
    case .desktop: return FlareSizes.primaryPaneMinWidth
    }
}

/// Width that `paneMode` needs side by side — the one pane rule of every layout in the kit (FR-110,
/// `spec/application-layout-vectors.json` `panes`). Two panes: navigation + list + a usable chat
/// (``FlareSizes/chatMinWidth`` times the text scale, never less than the minimum); three: that plus the
/// detail. Navigation, list and detail are drawn at fixed widths, so only the chat grows with the text.
/// A 72 pt rail + 320 pt list + 360 pt chat = 752 pt. One pane needs nothing.
public func paneModeMinWidth(_ paneMode: FlareWorkspacePaneMode, navigationWidth: CGFloat = 0,
                             primaryWidth: CGFloat = FlareSizes.primaryPaneDefaultWidth,
                             detailWidth: CGFloat = FlareSizes.detailPaneDefaultWidth,
                             textScale: CGFloat = 1) -> CGFloat {
    if paneMode == .singlePane { return 0 }
    let scale = textScale.isFinite ? max(1, textScale) : 1
    let two = max(0, navigationWidth) + max(0, primaryWidth) + FlareSizes.chatMinWidth * scale
    return paneMode == .dualPane ? two : two + max(0, detailWidth)
}

/// The most panes that fit side by side in `width` (a third only when there is a detail to show).
public func resolvePaneMode(width: CGFloat, hasDetail: Bool = false, textScale: CGFloat = 1,
                            navigationWidth: CGFloat = 0,
                            primaryWidth: CGFloat = FlareSizes.primaryPaneDefaultWidth,
                            detailWidth: CGFloat = FlareSizes.detailPaneDefaultWidth) -> FlareWorkspacePaneMode {
    func needs(_ mode: FlareWorkspacePaneMode) -> CGFloat {
        paneModeMinWidth(mode, navigationWidth: navigationWidth, primaryWidth: primaryWidth,
                         detailWidth: detailWidth, textScale: textScale)
    }
    guard width >= needs(.dualPane) else { return .singlePane }
    return hasDetail && width >= needs(.triplePane) ? .triplePane : .dualPane
}

/// Shared rule (spec/application-layout-vectors.json): the pane rule above with the navigation `mode`
/// draws, and the detail inline only when three panes fit.
public func resolveWorkspacePresentation(_ mode: FlareApplicationResponsiveMode, hasDetail: Bool = false,
                                         width: CGFloat? = nil, textScale: CGFloat = 1, navigationWidth: CGFloat? = nil,
                                         primaryWidth: CGFloat = FlareSizes.primaryPaneDefaultWidth,
                                         detailWidth: CGFloat = FlareSizes.detailPaneDefaultWidth) -> FlareWorkspacePresentation {
    let routed: FlareWorkspaceDetailPresentation = hasDetail ? .route : .hidden
    if mode == .mobile { return FlareWorkspacePresentation(paneMode: .singlePane, detail: routed) }
    let measured = width.map(\.isFinite) ?? false
    func fit(_ detail: Bool) -> FlareWorkspacePaneMode {
        resolvePaneMode(width: width ?? 0, hasDetail: detail, textScale: textScale,
                        navigationWidth: navigationWidth ?? resolveNavigationWidth(mode),
                        primaryWidth: primaryWidth, detailWidth: detailWidth)
    }
    if mode == .tablet {
        // A tablet's layout has no detail column: two panes at most, and a detail over them. One pane makes
        // the detail a page the host routes to. A width the caller does not know keeps two panes rather
        // than collapsing on a guess.
        if measured && fit(false) == .singlePane { return FlareWorkspacePresentation(paneMode: .singlePane, detail: routed) }
        return FlareWorkspacePresentation(paneMode: .dualPane, detail: hasDetail ? .overlay : .hidden)
    }
    let paneMode: FlareWorkspacePaneMode = measured ? fit(hasDetail) : (hasDetail ? .triplePane : .dualPane)
    switch paneMode {
    case .triplePane: return FlareWorkspacePresentation(paneMode: .triplePane, detail: .inline)
    // Two panes: a detail opens over the chat rather than crushing the navigation.
    case .dualPane: return FlareWorkspacePresentation(paneMode: .dualPane, detail: hasDetail ? .overlay : .hidden)
    case .singlePane: return FlareWorkspacePresentation(paneMode: .singlePane, detail: routed)
    }
}

public func resolveApplicationNavigationPresentation(
    _ mode: FlareApplicationResponsiveMode
) -> FlareApplicationNavigationPresentation {
    switch mode {
    case .mobile: return .bottom
    case .tablet: return .rail
    case .desktop: return .sidebar
    case .wideDesktop: return .expandedSidebar
    }
}

public func resolveMessageActionExtensions(
    _ extensions: [FlareMessageActionExtension], capabilities: FlareCapabilitySet, messageID: String
) -> [FlareMessageActionExtension] {
    extensions.enumerated()
        .filter { _, action in
            action.visible
                && (action.capability == nil || capabilities.contains(action.capability!))
                && action.available(messageID)
        }
        .sorted { left, right in
            let leftOrder = left.element.order ?? left.offset
            let rightOrder = right.element.order ?? right.offset
            return leftOrder == rightOrder ? left.offset < right.offset : leftOrder < rightOrder
        }
        .map(\.element)
}

public struct AdaptiveNavigationView: View {
    private let groups: [FlareApplicationNavigationGroup]
    private let activeID: String
    private let responsiveMode: FlareApplicationResponsiveMode
    private let presentation: FlareApplicationNavigationPresentation?
    private let onNavigate: (String) -> Void
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(groups: [FlareApplicationNavigationGroup], activeID: String,
                responsiveMode: FlareApplicationResponsiveMode,
                presentation: FlareApplicationNavigationPresentation? = nil,
                onNavigate: @escaping (String) -> Void) {
        self.groups = groups; self.activeID = activeID; self.responsiveMode = responsiveMode
        self.presentation = presentation; self.onNavigate = onNavigate
    }

    public var body: some View {
        let resolved = presentation ?? resolveApplicationNavigationPresentation(responsiveMode)
        let items = groups.flatMap(\.items).filter(\.visible)
        if resolved == .bottom {
            HStack(spacing: 0) {
                ForEach(items) { item in navButton(item, expanded: false).frame(maxWidth: .infinity) }
            }
            .padding(.bottom, FlareSizes.spacingXs)
            .background(FlareColors.of(scheme, brand: flareBrandTheme).bgPrimary)
            .overlay(Divider(), alignment: .top)
        } else {
            VStack(spacing: FlareSizes.spacingXs) {
                ForEach(items) { item in navButton(item, expanded: resolved == .sidebar || resolved == .expandedSidebar) }
                Spacer(minLength: 0)
            }
            .padding(FlareSizes.spacingSm)
            // The widths the pane rule assumes for each presentation (resolveNavigationWidth).
            .frame(width: resolved == .rail ? FlareSizes.navigationRailWidth
                   : resolved == .expandedSidebar ? FlareSizes.primaryPaneDefaultWidth : FlareSizes.primaryPaneMinWidth)
            .background(FlareColors.of(scheme, brand: flareBrandTheme).bgSecondary)
        }
    }

    private func badgeText(_ badge: FlareApplicationNavigationBadge) -> String {
        switch badge.kind {
        case .dot: return ""
        case .mention: return badge.label ?? "@"
        case .count: return badge.count > 99 ? "99+" : "\(max(0, badge.count))"
        }
    }

    private func navButton(_ item: FlareApplicationNavigationItem, expanded: Bool) -> some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        return Button { onNavigate(item.id) } label: {
            Group {
                if expanded {
                    HStack(spacing: FlareSizes.spacingSm) { navIcon(item); Text(item.label); Spacer(minLength: 0) }
                } else {
                    VStack(spacing: FlareSizes.spacingXs) { navIcon(item); Text(item.label).font(.system(size: FlareSizes.fontSizeXs)) }
                }
            }
            .foregroundColor(item.id == activeID ? colors.primaryText : colors.textSecondary)
            .frame(minWidth: FlareSizes.touchTarget, minHeight: FlareSizes.touchTarget)
            .padding(.horizontal, FlareSizes.spacingXs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!item.enabled)
        .opacity(item.enabled ? 1 : FlareOpacity.disabled)
        .accessibilityLabel(item.accessibilityLabel)
        .accessibilityAddTraits(item.id == activeID ? .isSelected : [])
    }

    private func navIcon(_ item: FlareApplicationNavigationItem) -> some View {
        Image(systemName: flareIconSymbol(item.icon))
            .font(.system(size: FlareSizes.iconSizeMd))
            .overlay(alignment: .topTrailing) {
                if let badge = item.badge {
                    Text(badgeText(badge))
                        .font(.system(size: FlareSizes.fontSizeXs))
                        .foregroundColor(.white)
                        .padding(.horizontal, badge.kind == .dot ? 0 : FlareSizes.spacingXs)
                        .frame(minWidth: FlareSizes.spacingSm, minHeight: FlareSizes.spacingSm)
                        .background(Capsule().fill(FlareColors.of(scheme, brand: flareBrandTheme).error))
                        .offset(x: FlareSizes.spacingSm, y: -FlareSizes.spacing2xs)
                        .accessibilityLabel(badge.label ?? item.accessibilityLabel)
                }
            }
    }
}

/// The application frame: navigation beside (or under) the panes the host supplies.
///
/// Inside a shell it takes the shell's responsive mode (`\.flareShellResponsiveMode`); on its own it resolves the
/// mode from its own box. It measures **its own box**, not the window, and decides from that width how many panes
/// fit (``resolveWorkspacePresentation(_:hasDetail:width:textScale:navigationWidth:primaryWidth:detailWidth:)``):
/// below navigation + list + a usable chat (``paneModeMinWidth(_:navigationWidth:primaryWidth:detailWidth:textScale:)``,
/// 752 pt with the tablet rail and the default list) it shows **one pane at a time** — the host's
/// `activePane` — and keeps the navigation rail; a detail is then a page the host routes to, not an
/// overlay over a pane that already fills the container. A phone always shows one pane, and a pane other than
/// the list is a page beyond the destination's root.
///
/// `onLayoutChange` hands the host the presentation actually in use (pane mode and detail mode) on the
/// first resolution and whenever it changes, so a host never has to guess it back from a width.
public struct AppLayoutView: View {
    private let activePane: FlareApplicationWorkspacePane
    private let navigation: AnyView?
    private let primary: AnyView?
    private let content: AnyView
    private let detail: AnyView?
    private let overlay: AnyView?
    private let floating: AnyView?
    private let onLayoutChange: ((FlareWorkspacePresentation) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    /// Inside a shell the mode is the shell's: it measured the box the whole app lives in.
    @Environment(\.flareShellResponsiveMode) private var shellMode
    /// The reader's text size as a factor: the chat's minimum width grows with it, so a container that fits
    /// two panes at the default size can stop fitting them at 150%.
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1

    public init(activePane: FlareApplicationWorkspacePane = .content,
                navigation: AnyView? = nil, primary: AnyView? = nil, content: AnyView,
                detail: AnyView? = nil, overlay: AnyView? = nil, floating: AnyView? = nil,
                onLayoutChange: ((FlareWorkspacePresentation) -> Void)? = nil) {
        self.activePane = activePane
        self.navigation = navigation; self.primary = primary; self.content = content
        self.detail = detail; self.overlay = overlay; self.floating = floating
        self.onLayoutChange = onLayoutChange
    }

    /// The pane the host asked for, for a layout that shows one at a time.
    @ViewBuilder private var activePaneBody: some View {
        switch activePane {
        case .primary: primary ?? content
        case .content: content
        case .detail: detail ?? content
        }
    }

    public var body: some View {
        ZStack {
            GeometryReader { geometry in
                // On its own the layout is its own shell and resolves the mode from the box it was given.
                let mode = shellMode ?? resolveApplicationResponsiveMode(width: geometry.size.width, textScale: textScale)
                let presentation = mode == .mobile
                    ? resolveWorkspacePresentation(.mobile, hasDetail: detail != nil)
                    : resolveWorkspacePresentation(
                        mode, hasDetail: detail != nil, width: geometry.size.width,
                        textScale: textScale, navigationWidth: navigation == nil ? 0 : nil)
                Group {
                    if mode == .mobile {
                        // A phone shows the host's active pane; its navigation is the shell's.
                        activePaneBody.frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        HStack(spacing: 0) {
                            if let navigation { navigation; Divider() }
                            if presentation.paneMode == .singlePane {
                                // One pane: the host's active pane fills what is left beside the rail.
                                activePaneBody.frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                if let primary { primary.frame(width: FlareSizes.primaryPaneDefaultWidth); Divider() }
                                content.frame(maxWidth: .infinity, maxHeight: .infinity)
                                if let detail, presentation.detail == .inline { Divider(); detail.frame(width: FlareSizes.detailPaneDefaultWidth) }
                            }
                        }
                        .overlay(alignment: .trailing) {
                            if let detail, presentation.detail == .overlay, activePane == .detail {
                                detail.frame(width: FlareSizes.detailPaneDefaultWidth).frame(maxHeight: .infinity)
                                    .background(FlareColors.of(scheme, brand: flareBrandTheme).bgPrimary)
                                    .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
                            }
                        }
                    }
                }
                .modifier(ReportWorkspacePresentation(presentation: presentation, onLayoutChange: onLayoutChange))
                // One pane showing something other than the list is a page beyond the destination's root.
                .flareDestinationDepth(presentation.paneMode == .singlePane && primary != nil && activePane != .primary)
            }
            overlay
            floating
        }
    }
}

/// Tells the host which presentation a layout settled on: once when it first appears, then on every change.
/// Reporting from a modifier keeps it out of `body`, which must not change state as it runs. Shared by the
/// application frames and `ResponsiveLayoutView`, so both layout families report panes the same way.
struct ReportWorkspacePresentation: ViewModifier {
    let presentation: FlareWorkspacePresentation
    let onLayoutChange: ((FlareWorkspacePresentation) -> Void)?
    func body(content: Content) -> some View {
        content
            .onAppear { onLayoutChange?(presentation) }
            .onChange(of: presentation) { value in onLayoutChange?(value) }
    }
}

public struct MobileAppShellView: View {
    private let groups: [FlareApplicationNavigationGroup]
    private let activeID: String
    private let onNavigate: (String) -> Void
    private let content: AnyView
    private let hideNavigation: Bool
    public init(groups: [FlareApplicationNavigationGroup], activeID: String,
                onNavigate: @escaping (String) -> Void, hideNavigation: Bool = false,
                content: AnyView) {
        self.groups = groups; self.activeID = activeID; self.onNavigate = onNavigate
        self.hideNavigation = hideNavigation; self.content = content
    }
    public var body: some View {
        VStack(spacing: 0) {
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
            if !hideNavigation {
                AdaptiveNavigationView(groups: groups, activeID: activeID, responsiveMode: .mobile, onNavigate: onNavigate)
            }
        }
    }
}

/// The desktop shell: navigation beside the host's content. It arranges no panes of its own — the
/// navigation column and one content slot — so there is no presentation for it to report; a host that
/// needs that composes ``WorkspaceFrameView`` or ``IMAppKitView``, which do arrange panes.
public struct DesktopAppShellView: View {
    private let groups: [FlareApplicationNavigationGroup]
    private let activeID: String
    private let responsiveMode: FlareApplicationResponsiveMode
    private let onNavigate: (String) -> Void
    private let content: AnyView
    public init(groups: [FlareApplicationNavigationGroup], activeID: String,
                responsiveMode: FlareApplicationResponsiveMode = .desktop,
                onNavigate: @escaping (String) -> Void, content: AnyView) {
        self.groups = groups; self.activeID = activeID; self.responsiveMode = responsiveMode
        self.onNavigate = onNavigate; self.content = content
    }
    public var body: some View {
        HStack(spacing: 0) {
            AdaptiveNavigationView(groups: groups, activeID: activeID, responsiveMode: responsiveMode, onNavigate: onNavigate)
            // A desktop shell is told its presentation rather than measuring for it; frames inside read it.
            Divider(); content.frame(maxWidth: .infinity, maxHeight: .infinity)
                .environment(\.flareShellResponsiveMode, responsiveMode)
        }
    }
}

/// One host state per pane, plus the cross-pane banner. Contacts, settings,
/// search and media all come through here, so the fallback text stays generic
/// and the panes resolve through the same `WorkspacePaneView` the inbox uses.
public struct FlareWorkspaceState: Sendable, Equatable {
    public var primary: FlareWorkspacePaneState
    public var content: FlareWorkspacePaneState
    public var detail: FlareWorkspacePaneState
    public var banner: FlareWorkspaceBanner?

    public init(primary: FlareWorkspacePaneState = .init(),
                content: FlareWorkspacePaneState = .init(),
                detail: FlareWorkspacePaneState = .init(),
                banner: FlareWorkspaceBanner? = nil) {
        self.primary = primary; self.content = content
        self.detail = detail; self.banner = banner
    }

    func pane(_ pane: FlareApplicationWorkspacePane) -> FlareWorkspacePaneState {
        switch pane {
        case .primary: return primary
        case .content: return content
        case .detail: return detail
        }
    }
}

public struct WorkspaceFrameView: View {
    private let activePane: FlareApplicationWorkspacePane
    private let primary: AnyView?
    private let content: AnyView
    private let detail: AnyView?
    private let state: FlareWorkspaceState
    private let onRetry: ((FlareApplicationWorkspacePane) -> Void)?
    private let onEmptyAction: ((FlareApplicationWorkspacePane) -> Void)?
    private let onBannerAction: (() -> Void)?
    private let onLayoutChange: ((FlareWorkspacePresentation) -> Void)?
    @Environment(\.flareStrings) private var strings

    /// - Parameter onLayoutChange: The inner ``AppLayoutView``'s report, passed straight through: one
    ///   pane or two, and how a detail is presented.
    public init(activePane: FlareApplicationWorkspacePane = .content,
                primary: AnyView? = nil, content: AnyView, detail: AnyView? = nil,
                state: FlareWorkspaceState = .init(),
                onRetry: ((FlareApplicationWorkspacePane) -> Void)? = nil,
                onEmptyAction: ((FlareApplicationWorkspacePane) -> Void)? = nil,
                onBannerAction: (() -> Void)? = nil,
                onLayoutChange: ((FlareWorkspacePresentation) -> Void)? = nil) {
        self.activePane = activePane
        self.primary = primary; self.content = content; self.detail = detail
        self.state = state; self.onRetry = onRetry
        self.onEmptyAction = onEmptyAction; self.onBannerAction = onBannerAction
        self.onLayoutChange = onLayoutChange
    }

    private static func skeleton(_ pane: FlareApplicationWorkspacePane) -> SkeletonVariant {
        switch pane {
        case .primary: return .conversation
        case .content: return .message
        case .detail: return .profile
        }
    }

    private static func skeletonRows(_ pane: FlareApplicationWorkspacePane) -> Int {
        switch pane {
        case .primary: return 6
        case .content: return 5
        case .detail: return 1
        }
    }

    private static func icon(_ pane: FlareApplicationWorkspacePane) -> String {
        switch pane {
        case .primary: return "folder"
        case .content: return "comment"
        case .detail: return "info"
        }
    }

    private func pane(_ key: FlareApplicationWorkspacePane, _ body: AnyView) -> AnyView {
        AnyView(WorkspacePaneView(
            state: state.pane(key),
            skeleton: Self.skeleton(key),
            skeletonRows: Self.skeletonRows(key),
            emptyIcon: Self.icon(key),
            emptyText: strings.workspaceFrameEmpty,
            failureText: strings.workspaceFrameFailure,
            loadingText: strings.workspaceFrameLoading,
            onRetry: onRetry.map { handler in { handler(key) } },
            onEmptyAction: onEmptyAction.map { handler in { handler(key) } },
            content: body
        ))
    }

    public var body: some View {
        let banner = state.banner
        let bannerAction = workspaceBannerActionVisible(banner, hasAction: onBannerAction != nil)
        return VStack(spacing: 0) {
            if let banner, workspaceBannerVisible(banner) {
                StatusBannerView(text: banner.message, tone: workspaceBannerTone(banner.tone),
                                 actionText: bannerAction ? banner.actionLabel : nil,
                                 onAction: bannerAction ? onBannerAction : nil)
                    .padding(FlareSizes.spacingSm)
            }
            AppLayoutView(activePane: activePane,
                          primary: primary.map { pane(.primary, $0) },
                          content: pane(.content, content),
                          detail: detail.map { pane(.detail, $0) },
                          onLayoutChange: onLayoutChange)
        }
    }
}


/// The application shell (FR-095). It measures its own box — not the window — for the responsive mode and hands that
/// mode down (`\.flareShellResponsiveMode`), draws the navigation the mode calls for, and shows one destination per
/// navigation item from `destination`. A destination arranges its own panes (``AppLayoutView``,
/// ``WorkspaceFrameView``, ``ConversationWorkspaceView``, or a `NavigationSplitView` of its own).
///
/// Every destination opened so far stays in the hierarchy (invisible, not hit-testable and hidden from
/// VoiceOver while another is active), like `TabView`, so coming back finds the list scrolled where it was and a
/// pushed chat still open; a change of mode does not rebuild them either. The phone navigation steps aside while
/// the active destination shows a page beyond its root (``SwiftUI/View/flareDestinationDepth(_:)``).
public struct IMAppKitView: View {
    private let configuration: FlareIMAppConfiguration
    private let groups: [FlareApplicationNavigationGroup]
    private let activeID: String
    private let onNavigate: (String) -> Void
    private let destination: (String) -> AnyView
    @StateObject private var depths = FlareShellDepths()
    @State private var visited: [String] = []
    @Environment(\.flareShellNavigationProbe) private var navigationProbe
    /// The reader's text size as a factor: the mode is resolved on width divided by it.
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1

    public init(configuration: FlareIMAppConfiguration = FlareIMAppConfiguration(),
                groups: [FlareApplicationNavigationGroup], activeID: String,
                onNavigate: @escaping (String) -> Void,
                destination: @escaping (String) -> AnyView) {
        self.configuration = configuration; self.groups = groups; self.activeID = activeID
        self.onNavigate = onNavigate; self.destination = destination
    }

    /// The destinations to keep: every one opened so far whose navigation item still exists, and the active one.
    private func kept(from list: [String]) -> [String] {
        let known = Set(groups.flatMap(\.items).map(\.id))
        var ids = list.filter { $0 == activeID || known.contains($0) }
        if !ids.contains(activeID) { ids.append(activeID) }
        return ids
    }

    public var body: some View {
        let _ = configuration
        let shown = kept(from: visited)
        GeometryReader { geometry in
            let mode = resolveApplicationResponsiveMode(width: geometry.size.width, textScale: textScale)
            let mobile = mode == .mobile
            let navigationHidden = mobile && depths.depth(of: activeID) > 0
            // One structure for every mode, so the destinations keep their identity when the window crosses a
            // breakpoint: the navigation column is an optional sibling before them, the bottom bar one after.
            HStack(spacing: 0) {
                if !mobile {
                    AdaptiveNavigationView(groups: groups, activeID: activeID, responsiveMode: mode, onNavigate: onNavigate)
                    Divider()
                }
                VStack(spacing: 0) {
                    GeometryReader { region in
                        // The panes the destination region holds, for a destination that splits with a platform
                        // container of its own; a kit frame inside measures the same box itself.
                        let panes = resolveWorkspacePresentation(mode, width: region.size.width, textScale: textScale,
                                                                 navigationWidth: 0)
                        ZStack {
                            ForEach(shown, id: \.self) { id in
                                let active = id == activeID
                                destination(id)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .environment(\.flareDestinationHandle, FlareDestinationHandle(depths: depths, id: id))
                                    .environment(\.flareDestinationActive, active)
                                    .opacity(active ? 1 : 0)
                                    .allowsHitTesting(active)
                                    .accessibilityHidden(!active)
                                    .zIndex(active ? 1 : 0)
                            }
                        }
                        .environment(\.flareShellResponsiveMode, mode)
                        .environment(\.flareDestinationPresentation, panes)
                    }
                    if mobile && !navigationHidden {
                        AdaptiveNavigationView(groups: groups, activeID: activeID, responsiveMode: .mobile, onNavigate: onNavigate)
                    }
                }
            }
            .onAppear { navigationProbe?(!navigationHidden) }
            .onChange(of: navigationHidden) { navigationProbe?(!$0) }
        }
        .onAppear { visited = kept(from: visited) }
        .onChange(of: activeID) { _ in visited = kept(from: visited) }
        .onChange(of: groups.flatMap(\.items).map(\.id)) { _ in
            visited = kept(from: visited)
            depths.forget(except: Set(visited))
        }
    }
}

public struct ConversationListContainerView<Content: View>: View {
    private let state: FlareApplicationViewState<[String]>
    private let retryLabel: String
    private let loadMoreLabel: String
    /// The container's own words for an empty list; `state.emptyTitle` overrides it per state.
    private let emptyTitle: String
    private let onRetry: (() -> Void)?
    private let onLoadMore: (() -> Void)?
    private let header: AnyView?
    private let search: AnyView?
    private let content: Content

    public init(state: FlareApplicationViewState<[String]> = FlareApplicationViewState(),
                retryLabel: String = "", loadMoreLabel: String = "", emptyTitle: String = "",
                onRetry: (() -> Void)? = nil, onLoadMore: (() -> Void)? = nil,
                header: AnyView? = nil, search: AnyView? = nil,
                @ViewBuilder content: () -> Content) {
        self.state = state; self.retryLabel = retryLabel; self.loadMoreLabel = loadMoreLabel
        self.emptyTitle = emptyTitle
        self.onRetry = onRetry; self.onLoadMore = onLoadMore
        self.header = header; self.search = search; self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            header; search
            Group {
                switch flareViewPresentation(state.status, stale: state.stale) {
                case .content: content
                // A failed refresh over rows worth keeping: the failure is a banner, the rows stay readable.
                case .contentWithNotice:
                    VStack(spacing: 0) {
                        StatusBannerView(text: state.error ?? "", tone: state.status == .error ? .danger : .neutral,
                                         actionText: onRetry == nil || retryLabel.isEmpty ? nil : retryLabel, onAction: onRetry)
                        content
                    }
                case .state:
                    switch state.status {
                    case .empty: EmptyStateView(title: state.emptyTitle ?? emptyTitle)
                    case .error, .offline:
                        StatusBannerView(text: state.error ?? "", tone: state.status == .error ? .danger : .neutral,
                                         actionText: onRetry == nil || retryLabel.isEmpty ? nil : retryLabel, onAction: onRetry)
                    default: SkeletonView(variant: .conversation)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if state.hasMore, let onLoadMore, !loadMoreLabel.isEmpty {
                ButtonView(label: loadMoreLabel, size: .lg, block: true, action: onLoadMore).padding(FlareSizes.spacingSm)
            }
        }
    }
}

public struct FriendListContainerView<Content: View>: View {
    private let container: ConversationListContainerView<Content>
    public init(state: FlareApplicationViewState<[String]> = FlareApplicationViewState(),
                retryLabel: String = "", emptyTitle: String = "", onRetry: (() -> Void)? = nil,
                header: AnyView? = nil, search: AnyView? = nil,
                @ViewBuilder content: () -> Content) {
        container = ConversationListContainerView(
            state: state, retryLabel: retryLabel, emptyTitle: emptyTitle, onRetry: onRetry,
            header: header, search: search, content: content
        )
    }
    public var body: some View { container }
}
