import SwiftUI

public struct FlareCommandPaletteCommand: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let description: String?
    public let keywords: [String]
    public let shortcut: String?
    public let disabled: Bool

    public init(id: String, label: String, description: String? = nil,
                keywords: [String] = [], shortcut: String? = nil, disabled: Bool = false) {
        self.id = id; self.label = label; self.description = description
        self.keywords = keywords; self.shortcut = shortcut; self.disabled = disabled
    }
}

public struct FlareCommandPaletteGroup: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let commands: [FlareCommandPaletteCommand]

    public init(id: String, label: String, commands: [FlareCommandPaletteCommand]) {
        self.id = id; self.label = label; self.commands = commands
    }
}

/// Searchable command surface. The host owns command execution and open state.
public struct CommandPaletteView: View {
    private let open: Bool
    private let groups: [FlareCommandPaletteGroup]
    private let label: String
    private let placeholder: String
    private let emptyText: String
    private let busy: Bool
    private let selectedId: String?
    private let requestedQuery: String
    private let onQueryChange: (String) -> Void
    private let onInvoke: (FlareCommandPaletteCommand) -> Void
    private let onClose: () -> Void
    private let onSelectedIdChange: ((String) -> Void)?
    @State private var query: String
    @State private var internalSelectedId: String?
    @FocusState private var inputFocused: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(open: Bool, query: String, groups: [FlareCommandPaletteGroup],
                label: String, placeholder: String, emptyText: String,
                onQueryChange: @escaping (String) -> Void,
                onInvoke: @escaping (FlareCommandPaletteCommand) -> Void,
                onClose: @escaping () -> Void,
                busy: Bool = false, selectedId: String? = nil,
                onSelectedIdChange: ((String) -> Void)? = nil) {
        self.open = open; self.groups = groups; self.label = label
        self.requestedQuery = query
        self.placeholder = placeholder; self.emptyText = emptyText; self.busy = busy
        self.selectedId = selectedId; self.onQueryChange = onQueryChange
        self.onInvoke = onInvoke; self.onClose = onClose
        self.onSelectedIdChange = onSelectedIdChange
        _query = State(initialValue: query); _internalSelectedId = State(initialValue: selectedId)
    }

    private var visibleGroups: [FlareCommandPaletteGroup] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return groups }
        return groups.compactMap { group in
            let commands = group.commands.filter { command in
                ([command.label, command.description].compactMap { $0 } + command.keywords)
                    .contains { $0.lowercased().contains(needle) }
            }
            return commands.isEmpty ? nil : FlareCommandPaletteGroup(id: group.id, label: group.label, commands: commands)
        }
    }

    private var enabledCommands: [FlareCommandPaletteCommand] {
        visibleGroups.flatMap(\.commands).filter { !$0.disabled }
    }

    private var activeId: String? {
        let requested = selectedId ?? internalSelectedId
        return enabledCommands.contains { $0.id == requested } ? requested : enabledCommands.first?.id
    }

    public var body: some View {
        if open {
            let colors = FlareColors.of(scheme, brand: flareBrandTheme)
            ZStack(alignment: .top) {
                Color.black.opacity(0.32).ignoresSafeArea().onTapGesture(perform: onClose)
                VStack(spacing: 0) {
                    TextField(placeholder, text: $query)
                        .focused($inputFocused)
                        .disabled(busy)
                        .textFieldStyle(.plain)
                        .padding(FlareSizes.spacingMd)
                        .frame(minHeight: FlareSizes.touchTarget)
                        .onChange(of: query, perform: onQueryChange)
                        .onSubmit {
                            if let command = enabledCommands.first(where: { $0.id == activeId }), !busy { onInvoke(command) }
                        }
                    Divider()
                    if busy { ProgressView().padding(FlareSizes.spacingMd) }
                    if visibleGroups.isEmpty {
                        Text(emptyText).foregroundColor(colors.textSecondary)
                            .frame(maxWidth: .infinity).padding(FlareSizes.spacingXl)
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(visibleGroups) { group in
                                    Text(group.label).font(.caption).foregroundColor(colors.textTertiary)
                                        .padding(.horizontal, FlareSizes.spacingMd).padding(.top, FlareSizes.spacingMd)
                                        .accessibilityAddTraits(.isHeader)
                                    ForEach(group.commands) { command in
                                        commandRow(command, colors: colors)
                                    }
                                }
                            }.padding(FlareSizes.spacingXs)
                        }
                    }
                }
                .frame(maxWidth: 640, maxHeight: 560)
                .background(colors.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
                .shadow(color: .black.opacity(0.14), radius: 8, y: 4)
                .padding(.horizontal, FlareSizes.spacingMd).padding(.top, 72)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(label)
            .onAppear { inputFocused = true }
            .onChange(of: requestedQuery) { query = $0 }
        }
    }

    private func commandRow(_ command: FlareCommandPaletteCommand, colors: FlareColors) -> some View {
        Button {
            internalSelectedId = command.id; onSelectedIdChange?(command.id); onInvoke(command)
        } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                    Text(command.label).foregroundColor(colors.textPrimary)
                    if let description = command.description {
                        Text(description).font(.caption).foregroundColor(colors.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                if let shortcut = command.shortcut { Text(shortcut).font(.caption).foregroundColor(colors.textTertiary) }
            }
            .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTarget, alignment: .leading)
            .padding(.horizontal, FlareSizes.spacingSm)
            .background(command.id == activeId ? colors.bgSelected : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusSm))
        }
        .buttonStyle(.plain)
        .disabled(busy || command.disabled)
    }
}
