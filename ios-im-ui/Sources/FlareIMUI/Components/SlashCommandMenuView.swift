import SwiftUI

// MARK: - SlashCommandMenu

/// Slash command menu — filterable "/command" palette for the composer.
/// Spec: Composer/SlashCommandMenu (`SlashCommandMenuView`).
public struct SlashCommandMenuView: View {
    private let commands: [SlashCommand]
    private let query: String
    private let onSelect: ((SlashCommand) -> Void)?
    private let onClose: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(commands: [SlashCommand], query: String = "",
                onSelect: ((SlashCommand) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.commands = commands; self.query = query; self.onSelect = onSelect; self.onClose = onClose
    }

    private var filtered: [SlashCommand] {
        var q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.hasPrefix("/") { q.removeFirst() }
        if q.isEmpty { return commands }
        return commands.filter {
            $0.command.lowercased().contains(q) || ($0.description?.lowercased().contains(q) ?? false)
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "terminal").font(.system(size: 11)).foregroundColor(colors.textTertiary)
                Text("命令").font(.system(size: 11, weight: .semibold)).foregroundColor(colors.textTertiary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8).padding(.vertical, 6)

            if filtered.isEmpty {
                Text("没有匹配的命令")
                    .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textTertiary)
                    .frame(maxWidth: .infinity).padding(.vertical, 22)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filtered) { c in row(colors, c) }
                    }
                }
                .frame(maxHeight: 280)
            }
        }
        .padding(6)
        .frame(width: 300)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    private func row(_ colors: FlareColors, _ c: SlashCommand) -> some View {
        Button { onSelect?(c) } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("/\(c.command)").font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(colors.primary)
                    if let hint = c.hint, !hint.isEmpty {
                        Text(hint).font(.system(size: 13, design: .monospaced)).foregroundColor(colors.textTertiary)
                    }
                    Spacer(minLength: 0)
                }
                if let desc = c.description, !desc.isEmpty {
                    Text(desc).font(.system(size: 12)).foregroundColor(colors.textSecondary).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8).padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
