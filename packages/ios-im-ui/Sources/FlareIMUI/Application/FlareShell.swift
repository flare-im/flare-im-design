import SwiftUI

// The shell contract (FR-095): a shell measures its own box and hands the mode down, keeps each destination it has
// shown, and steps its phone navigation aside while the active destination shows a page beyond its root.

/// The pages beyond their root that are showing, per destination of one shell.
final class FlareShellDepths: ObservableObject {
    @Published private(set) var byDestination: [String: Int] = [:]

    func depth(of id: String) -> Int { byDestination[id] ?? 0 }

    func enter(_ id: String) { byDestination[id] = depth(of: id) + 1 }

    func leave(_ id: String) { byDestination[id] = max(0, depth(of: id) - 1) }

    func forget(except kept: Set<String>) {
        let gone = byDestination.keys.filter { !kept.contains($0) }
        for id in gone { byDestination[id] = nil }
    }
}

/// What a view inside a shell destination uses to say it is a page beyond the destination's root.
struct FlareDestinationHandle {
    let depths: FlareShellDepths
    let id: String
}

private struct FlareShellResponsiveModeKey: EnvironmentKey {
    static let defaultValue: FlareApplicationResponsiveMode? = nil
}

private struct FlareDestinationHandleKey: EnvironmentKey {
    static let defaultValue: FlareDestinationHandle? = nil
}

private struct FlareDestinationActiveKey: EnvironmentKey {
    static let defaultValue = true
}

private struct FlareDestinationPresentationKey: EnvironmentKey {
    static let defaultValue = FlareWorkspacePresentation(paneMode: .singlePane, detail: .hidden)
}

/// Test seam: told whether the shell's phone navigation is showing, on appearance and on every change.
private struct FlareShellNavigationProbeKey: EnvironmentKey {
    static let defaultValue: ((Bool) -> Void)? = nil
}

public extension EnvironmentValues {
    /// The responsive mode the nearest shell resolved from its own box, or nil outside any shell. A pane frame
    /// inside a shell takes this mode; one outside any shell resolves its own.
    var flareShellResponsiveMode: FlareApplicationResponsiveMode? {
        get { self[FlareShellResponsiveModeKey.self] }
        set { self[FlareShellResponsiveModeKey.self] = newValue }
    }

    /// Whether the destination this view is in is the one on screen. A shell keeps every destination it has shown
    /// in the hierarchy, so a view in a hidden one is still "on screen" to SwiftUI; work that only makes sense
    /// while the person is looking (marking a conversation read) reads this. True outside any shell.
    var flareDestinationActive: Bool {
        get { self[FlareDestinationActiveKey.self] }
        set { self[FlareDestinationActiveKey.self] = newValue }
    }

    /// How many panes the destination's own box holds, by the one pane rule, for a destination that arranges its
    /// panes with a platform container (a `NavigationSplitView` beside a `NavigationStack`) rather than a kit frame.
    /// One pane outside any shell.
    var flareDestinationPresentation: FlareWorkspacePresentation {
        get { self[FlareDestinationPresentationKey.self] }
        set { self[FlareDestinationPresentationKey.self] = newValue }
    }
}

extension EnvironmentValues {
    var flareDestinationHandle: FlareDestinationHandle? {
        get { self[FlareDestinationHandleKey.self] }
        set { self[FlareDestinationHandleKey.self] = newValue }
    }

    var flareShellNavigationProbe: ((Bool) -> Void)? {
        get { self[FlareShellNavigationProbeKey.self] }
        set { self[FlareShellNavigationProbeKey.self] = newValue }
    }
}

private struct FlareDestinationDepthModifier: ViewModifier {
    let active: Bool
    @Environment(\.flareDestinationHandle) private var handle
    @State private var entered = false

    func body(content: Content) -> some View {
        content
            .onAppear { sync(active) }
            .onChange(of: active) { sync($0) }
            .onDisappear {
                guard entered, let handle else { return }
                entered = false
                handle.depths.leave(handle.id)
            }
    }

    private func sync(_ on: Bool) {
        guard let handle else { return }
        if on && !entered {
            entered = true
            handle.depths.enter(handle.id)
        } else if !on && entered {
            entered = false
            handle.depths.leave(handle.id)
        }
    }
}

public extension View {
    /// While `active` is true, this view is a page beyond the root of the destination it is shown in: a detail, a
    /// sub-page, a chat that took the list's place. The shell hides its phone navigation while the active
    /// destination has one. Kit pages declare themselves (`FlareScreen` with a back action, a pane frame showing a
    /// pane other than its root); a page the host draws itself — a `NavigationStack` with something pushed — says
    /// so with this. Outside a shell it does nothing.
    func flareDestinationDepth(_ active: Bool) -> some View {
        modifier(FlareDestinationDepthModifier(active: active))
    }
}
