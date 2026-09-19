import SwiftUI

// MARK: - MentionPicker

/// @mention picker — search field + optional "Everyone" + member list.
/// Spec: Composer/MentionPicker (`MentionPickerView`).
public struct MentionPickerView: View {
    private let candidates: [MentionCandidate]
    private let allowEveryone: Bool
    private let onSelect: ((MentionCandidate) -> Void)?
    private let onClose: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.flarePlatform) private var platform
    @State private var query: String = ""
    /// The row Enter picks; arrows move it (FR-103).
    @State private var highlighted = 0
    @FocusState private var searchFocused: Bool

    public init(candidates: [MentionCandidate], allowEveryone: Bool = false,
                onSelect: ((MentionCandidate) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.candidates = candidates; self.allowEveryone = allowEveryone
        self.onSelect = onSelect; self.onClose = onClose
    }

    /// The rows for `query`: the everyone mention first when allowed, then the candidates, each kept when
    /// its name or detail contains the query (trimmed, any case) — Vue `results`.
    static func results(_ candidates: [MentionCandidate], allowEveryone: Bool, everyoneLabel: String,
                        query: String) -> [MentionCandidate] {
        let all = allowEveryone
            ? [MentionCandidate(id: everyoneId, name: everyoneLabel, isEveryone: true)] + candidates
            : candidates
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty else { return all }
        return all.filter { "\($0.name) \($0.detail ?? "")".lowercased().contains(needle) }
    }

    /// The everyone row's id (Vue `__all__`).
    static let everyoneId = "__all__"

    /// The highlight after an arrow: one row up or down, wrapping at either end; 0 without rows.
    static func movedHighlight(_ index: Int, by delta: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((index + delta) % count + count) % count
    }

    private var rows: [MentionCandidate] {
        Self.results(candidates, allowEveryone: allowEveryone, everyoneLabel: strings.everyone, query: query)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let rows = self.rows
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: FlareSizes.spacingSm) {
                Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundColor(colors.textTertiary)
                    .accessibilityHidden(true)
                TextField(strings.searchMembers, text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary)
                    .focused($searchFocused)
                    // Return picks the highlighted person. The Return that commits an IME composition
                    // belongs to the input method and does not submit.
                    .onSubmit { pick(at: highlighted, in: rows) }
                    .modifier(MentionPickerKeys(move: { delta in
                        highlighted = Self.movedHighlight(highlighted, by: delta, count: rows.count)
                    }, close: { onClose?() }))
            }
            .padding(.horizontal, FlareSizes.spacingMd).padding(.vertical, FlareSizes.spacingSm)

            Divider().overlay(colors.borderPrimary)

            if rows.isEmpty {
                Text(strings.noMatchingMembers)
                    .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textTertiary)
                    .frame(maxWidth: .infinity).padding(.vertical, 24)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                                let active = searchFocused && index == highlighted
                                Group {
                                    if row.isEveryone { everyoneRow(colors, row, active: active) }
                                    else { personRow(colors, row, active: active) }
                                }
                                .id(row.id)
                            }
                        }
                    }
                    .frame(maxHeight: 264)
                    .onChange(of: highlighted) { index in
                        guard rows.indices.contains(index) else { return }
                        proxy.scrollTo(rows[index].id)
                    }
                }
            }
        }
        .frame(width: 280)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
        // A new query highlights its first match again.
        .onChange(of: query) { _ in highlighted = 0 }
        // With a hardware keyboard the search field takes focus, so "@", a few letters and Return mention
        // someone without leaving the keyboard. Touch keeps its behaviour: no keyboard pops up by itself.
        .onAppear { if Self.focusesSearchOnOpen(platform.capabilities) { searchFocused = true } }
    }

    /// Whether the search field takes focus when the picker opens: where a keyboard is the input (macOS,
    /// or a host that declares keyboard shortcuts), never on touch alone.
    static func focusesSearchOnOpen(_ capabilities: FlarePlatformCapabilities) -> Bool {
        #if os(macOS)
        return true
        #else
        return capabilities.keyboardShortcut
        #endif
    }

    private func pick(at index: Int, in rows: [MentionCandidate]) {
        guard rows.indices.contains(index) else { return }
        onSelect?(rows[index])
    }

    private func everyoneRow(_ colors: FlareColors, _ row: MentionCandidate, active: Bool) -> some View {
        Button {
            onSelect?(row)
        } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                Image(systemName: "person.2").font(.system(size: 15)).foregroundColor(.white)
                    .frame(width: 32, height: 32).background(Circle().fill(colors.primary))
                VStack(alignment: .leading, spacing: 1) {
                    Text(strings.everyone).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary)
                    Text(strings.notifyEveryone).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, FlareSizes.spacingMd).padding(.vertical, FlareSizes.spacingSm)
            .background(active ? colors.bgSelected : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    private func personRow(_ colors: FlareColors, _ c: MentionCandidate, active: Bool) -> some View {
        Button { onSelect?(c) } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: c.id, displayName: c.name, avatarURL: c.avatarURL, size: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text(c.name).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary).lineLimit(1)
                    if let d = c.detail, !d.isEmpty {
                        Text(d).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, FlareSizes.spacingMd).padding(.vertical, FlareSizes.spacingSm)
            .background(active ? colors.bgSelected : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

/// The picker's keys while its search field has focus: the arrows move the highlight and Escape closes.
/// Key presses need iOS 17 / macOS 14; before that Escape still closes on macOS, and Return (on the field)
/// picks the highlighted row everywhere.
private struct MentionPickerKeys: ViewModifier {
    let move: (Int) -> Void
    let close: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            content
                .onKeyPress(.upArrow) { move(-1); return .handled }
                .onKeyPress(.downArrow) { move(1); return .handled }
                .onKeyPress(.escape) { close(); return .handled }
        } else {
            #if os(macOS)
            content.onExitCommand(perform: close)
            #else
            content
            #endif
        }
    }
}
