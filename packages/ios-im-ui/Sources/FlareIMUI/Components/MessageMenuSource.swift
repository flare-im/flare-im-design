import SwiftUI

/// One source for a timeline's message menu, drawn in two places from the same entries: the long-press sheet
/// (``MessageActionSheetView``) and, on a pointer, the system context menu (a secondary click on macOS, and on iPad,
/// where it also takes the long press). Spec: MessageList `menu` (`FlareMessageMenuSource`).
///
/// - `availability` reads the host's snapshot of the core's action availability for a message, synchronously; nil
///   while the host has none yet. The host refreshes its snapshot asynchronously and redraws the list.
/// - `prefetch` is called with the ids of rows coming on screen that have no snapshot, so the host reads them ahead
///   of the menu.
/// - `hiddenActions` means what it means on ``MessageActionSheetView``; `extraActions` gives the host's own entries for
///   a message (its `actions` there), so an entry can depend on the message — "report" only on someone else's.
/// - `perform` gets the chosen entry's id from either menu.
///
/// Without a snapshot the pointer menu holds one disabled entry, "正在读取…" (`messageMenuLoading`), and asks for
/// that message; a long press asks for it and opens the sheet once the snapshot is there.
public struct FlareMessageMenuSource {
    public let availability: (FlareMessageData) -> FlareMessageActionAvailability?
    public let prefetch: ([String]) -> Void
    public let hiddenActions: Set<String>
    public let extraActions: (FlareMessageData) -> [FlareMessageMenuEntry]
    public let perform: (FlareMessageData, String) -> Void

    public init(availability: @escaping (FlareMessageData) -> FlareMessageActionAvailability?,
                prefetch: @escaping ([String]) -> Void = { _ in },
                hiddenActions: Set<String> = [],
                extraActions: @escaping (FlareMessageData) -> [FlareMessageMenuEntry] = { _ in [] },
                perform: @escaping (FlareMessageData, String) -> Void) {
        self.availability = availability; self.prefetch = prefetch; self.hiddenActions = hiddenActions
        self.extraActions = extraActions; self.perform = perform
    }

    /// The menu's entries for `message` (``messageMenuEntries(_:strings:hidden:extra:content:)``), or nil while the
    /// host has no snapshot for it. The sheet and the pointer menu both draw these.
    public func entries(for message: FlareMessageData, strings: FlareStrings) -> [FlareMessageMenuEntry]? {
        guard let snapshot = availability(message) else { return nil }
        return messageMenuEntries(snapshot, strings: strings, hidden: hiddenActions, extra: extraActions(message),
                                  content: message.content)
    }

    /// A pointer is the primary way to the menu: macOS, iPad (where the context menu also takes the long press)
    /// and a Mac running the iPad app. iPhone keeps the long-press sheet. Hosts read this rather than repeating it.
    public static var pointerIdiom: Bool { flareDeviceIsPointerFirst() }

    /// One item of the pointer menu.
    enum PointerItem: Equatable {
        case entry(FlareMessageMenuEntry)
        /// The disabled "正在读取…" while there is no snapshot.
        case loading
    }

    /// The pointer menu for `message`, in sections: the sheet's groups and order, or the one loading item.
    func pointerSections(for message: FlareMessageData, strings: FlareStrings) -> [[PointerItem]] {
        guard let entries = entries(for: message, strings: strings) else { return [[.loading]] }
        return messageMenuGroups(entries).map { $0.map(PointerItem.entry) }
    }

    /// A destructive entry takes the destructive role.
    static func role(_ entry: FlareMessageMenuEntry) -> ButtonRole? { entry.group == .destructive ? .destructive : nil }

    /// Whether a row's long press opens the sheet: not where the pointer menu takes the long press.
    static func longPressOpensSheet(pointerMenu: Bool) -> Bool { !pointerMenu }
}

/// Gathers the rows that came on screen within one turn of the run loop into one `prefetch` call, and asks for a
/// message once while it waits for its snapshot. The list settles a message once its snapshot arrives, so a snapshot
/// that lapses later is asked for again; a menu asked for without a snapshot always asks (``ask(_:_:)``).
final class FlareMessageMenuPrefetcher: ObservableObject {
    private var pending: [String] = []
    private var asked: Set<String> = []
    private var scheduled = false

    /// Asks for `id` on the next turn of the run loop, with every other id asked for in this one.
    func request(_ id: String, _ prefetch: @escaping ([String]) -> Void) {
        guard asked.insert(id).inserted else { return }
        pending.append(id)
        guard !scheduled else { return }
        scheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let ids = self.pending
            self.pending = []
            self.scheduled = false
            if !ids.isEmpty { prefetch(ids) }
        }
    }

    /// A menu was asked for and there is no snapshot: asks for `id` even while an earlier request waits — that one
    /// may have failed, or its snapshot lapsed since. A long press and the pointer menu's loading entry ask this way.
    func ask(_ id: String, _ prefetch: @escaping ([String]) -> Void) {
        settle(id)
        request(id, prefetch)
    }

    /// The snapshot for `id` arrived: a later miss may ask again.
    func settle(_ id: String) { asked.remove(id) }

    /// Settles every message asked for that `settled` answers true for: its snapshot arrived, or it left the list.
    func settleArrived(_ settled: (String) -> Bool) {
        guard !asked.isEmpty else { return }
        asked = asked.filter { !settled($0) }
    }
}

/// The message the long-press sheet is open for.
struct FlareMessageMenuTarget: Identifiable {
    let message: FlareMessageData
    var id: String { message.id }
}

/// The row's pointer menu, from the list's menu source.
struct RowPointerMenu: ViewModifier {
    let message: FlareMessageData
    let menu: FlareMessageMenuSource?
    let prefetcher: FlareMessageMenuPrefetcher
    @Environment(\.flareStrings) private var strings

    func body(content: Content) -> some View {
        if let menu {
            content.contextMenu {
                let sections = menu.pointerSections(for: message, strings: strings)
                ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                    if index > 0 { Divider() }
                    ForEach(Array(section.enumerated()), id: \.offset) { _, item in
                        switch item {
                        case .loading:
                            Button(strings.messageMenuLoading) {}
                                .disabled(true)
                                .onAppear { prefetcher.ask(message.id, menu.prefetch) }
                        case .entry(let entry):
                            Button(role: FlareMessageMenuSource.role(entry)) {
                                menu.perform(message, entry.id)
                            } label: {
                                Label(entry.label, systemImage: flareIconSymbol(entry.icon))
                            }
                            .disabled(!entry.enabled)
                        }
                    }
                }
            }
        } else {
            content
        }
    }
}
