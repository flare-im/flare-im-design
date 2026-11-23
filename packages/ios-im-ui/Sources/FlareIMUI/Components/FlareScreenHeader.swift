import SwiftUI

private struct FlareScreenTitleKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

public extension EnvironmentValues {
    /// The title of the page a view is on (Vue `useFlareScreen().title`), so a panel there can leave out a heading
    /// that only repeats it (``VersionPanelView``). Set by ``SwiftUI/View/flareScreenHeader(_:actions:)``.
    var flareScreenTitle: String? {
        get { self[FlareScreenTitleKey.self] }
        set { self[FlareScreenTitleKey.self] = newValue }
    }
}

/// A page's header in the kit's form — Vue `FlareScreen`'s: back (only when the page was pushed or presented), the
/// title at the start, the actions at the end (``ScreenHeaderView``) — in place of the platform navigation bar.
struct FlareScreenHeaderModifier<Actions: View>: ViewModifier {
    let title: String
    let actions: Actions
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @Environment(\.flareStrings) private var strings

    func body(content: Content) -> some View {
        content
            // A page fills its column from the top: content shorter than the screen (a loading spinner) would
            // otherwise be centred, and the header inset with it.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .environment(\.flareScreenTitle, title)
            .safeAreaInset(edge: .top, spacing: 0) {
                ScreenHeaderView(title: title, leading: {
                    if isPresented {
                        IconButtonView(icon: "back", accessibilityLabel: strings.back) { dismiss() }
                    }
                }, actions: { actions })
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
    }
}

public extension View {
    /// Gives a page the kit header (back when pushed or presented, title, `actions`) and hides the platform
    /// navigation bar. Hosts that keep the edge swipe back while the bar is hidden add that themselves.
    func flareScreenHeader<Actions: View>(_ title: String,
                                          @ViewBuilder actions: () -> Actions = { EmptyView() }) -> some View {
        modifier(FlareScreenHeaderModifier(title: title, actions: actions()))
    }
}
