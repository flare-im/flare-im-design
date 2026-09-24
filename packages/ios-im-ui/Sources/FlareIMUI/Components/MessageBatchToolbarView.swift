import SwiftUI

// MARK: - Contract

/// Batch actions a host may expose over a multi-selection of messages.
public enum MessageBatchAction: String, CaseIterable, Sendable {
    case forwardEach, forwardMerged, pin, pinSelf, delete
}

/// Host-declared capabilities; a false entry hides the action entirely.
public struct MessageBatchCapabilities: Sendable {
    public var forwardEach: Bool
    public var forwardMerged: Bool
    public var pin: Bool
    public var pinSelf: Bool
    public var delete: Bool
    public init(forwardEach: Bool = false, forwardMerged: Bool = false, pin: Bool = false,
                pinSelf: Bool = false, delete: Bool = false) {
        self.forwardEach = forwardEach; self.forwardMerged = forwardMerged
        self.pin = pin; self.pinSelf = pinSelf; self.delete = delete
    }
    public func allows(_ action: MessageBatchAction) -> Bool {
        switch action {
        case .forwardEach: return forwardEach
        case .forwardMerged: return forwardMerged
        case .pin: return pin
        case .pinSelf: return pinSelf
        case .delete: return delete
        }
    }
}

/// What an action needs to mean anything: merging messages into one card needs two.
public let flareMessageBatchMinimumSelection: [MessageBatchAction: Int] = [.forwardMerged: 2]

/// Actions the toolbar may offer right now (`spec/message-batch-vectors.json`, the same table on four
/// kits): empty while busy or with nothing selected; otherwise the capability-enabled actions in
/// canonical order, minus those the selection is too small for.
public func messageBatchActionsAvailable(_ selectedIds: [String], _ capabilities: MessageBatchCapabilities?,
                                         _ busy: Bool) -> [MessageBatchAction] {
    if busy || selectedIds.isEmpty { return [] }
    guard let capabilities else { return [] }
    return MessageBatchAction.allCases.filter {
        capabilities.allows($0) && selectedIds.count >= (flareMessageBatchMinimumSelection[$0] ?? 1)
    }
}

// MARK: - MessageBatchToolbar

/// Multi-select batch toolbar over a set of chosen messages. Same contract as
/// ``ConversationBatchToolbarView`` (FR-034): the host declares what it can do over the selection and
/// the toolbar reports one action with the ids; selecting all and clearing the selection stay their own
/// handlers, because they change the selection, not the world.
/// Spec: Message/MessageBatchToolbar (`MessageBatchToolbarView`).
public struct MessageBatchToolbarView: View {
    private let selectedIds: [String]
    private let total: Int
    private let capabilities: MessageBatchCapabilities
    private let busy: Bool
    private let onAction: ((MessageBatchAction, [String]) -> Void)?
    private let onSelectAll: (() -> Void)?
    private let onClearSelection: (() -> Void)?
    private let onExit: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(selectedIds: [String], total: Int, capabilities: MessageBatchCapabilities,
                busy: Bool = false, onAction: ((MessageBatchAction, [String]) -> Void)? = nil,
                onSelectAll: (() -> Void)? = nil, onClearSelection: (() -> Void)? = nil,
                onExit: (() -> Void)? = nil) {
        self.selectedIds = selectedIds; self.total = total; self.capabilities = capabilities
        self.busy = busy; self.onAction = onAction; self.onSelectAll = onSelectAll
        self.onClearSelection = onClearSelection; self.onExit = onExit
    }

    private func label(_ action: MessageBatchAction) -> String {
        switch action {
        case .forwardEach: return strings.forwardEach
        case .forwardMerged: return strings.forwardMerged
        case .pin: return strings.messageBatchPin
        case .pinSelf: return strings.messageBatchPinSelf
        case .delete: return strings.delete
        }
    }

    private func icon(_ action: MessageBatchAction) -> String {
        switch action {
        case .forwardEach: return "arrowshape.turn.up.right"
        case .forwardMerged: return flareIconSymbol("merge-forward")
        case .pin: return flareIconSymbol("pin")
        case .pinSelf: return flareIconSymbol("pin-self")
        case .delete: return "trash"
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let count = selectedIds.count
        let available = messageBatchActionsAvailable(selectedIds, capabilities, busy)
        let visible = MessageBatchAction.allCases.filter(capabilities.allows)
        HStack(spacing: FlareSizes.spacingMd) {
            HStack(spacing: 4) {
                Text("\(count)").font(.system(size: FlareSizes.fontSizeLg, weight: .bold)).foregroundColor(colors.primaryText)
                Text("/ \(total) · \(strings.selectedSuffix)").font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
            }
            .layoutPriority(1)
            // The keys wrap onto another line where the bar is too narrow for them all — a phone in portrait is: in one
            // row their labels were squeezed into broken, clipped columns.
            FlareFlowLayout(spacing: FlareSizes.spacingSm, lineSpacing: FlareSizes.spacingXs, alignment: .trailing) {
                button(colors, "checkmark.circle", strings.selectAll, onSelectAll, disabled: total == 0 || busy)
                button(colors, flareIconSymbol("close"), strings.messageBatchClear, onClearSelection, disabled: count == 0 || busy)
                ForEach(visible, id: \.self) { action in
                    button(colors, icon(action), label(action), { onAction?(action, selectedIds) },
                           disabled: !available.contains(action), tint: action == .delete ? colors.error : nil)
                }
                iconButton(colors, "close", label: strings.exitMultiSelect, onExit)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingMd)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.12), radius: 16, y: 6)
        .modifier(MessageBatchEscape(busy: busy, onExit: onExit))
    }

    private func button(_ colors: FlareColors, _ icon: String, _ label: String, _ onTap: (() -> Void)?,
                        disabled: Bool, tint: Color? = nil) -> some View {
        Button { onTap?() } label: {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 14))
                Text(label).font(.system(size: FlareSizes.fontSizeMd, weight: .medium))
                    .lineLimit(1).fixedSize(horizontal: true, vertical: false)
            }
            .foregroundColor(tint ?? colors.textPrimary)
            .padding(.horizontal, FlareSizes.spacingMd)
            .frame(height: 32)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(colors.bgSecondary))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }

    /// The exit key: the kit icon `icon` on a 32pt ground, named `label`, with a 44pt target.
    private func iconButton(_ colors: FlareColors, _ icon: String, label: String, _ onTap: (() -> Void)?) -> some View {
        Button { onTap?() } label: {
            Image(systemName: flareIconSymbol(icon)).font(.system(size: 14)).foregroundColor(colors.textSecondary)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(colors.bgSecondary))
                .flareTouchTarget()
        }
        .buttonStyle(.plain)
        .flareCompactLayout(width: FlareSizes.controlHeightSm, height: FlareSizes.controlHeightSm)
        .accessibilityLabel(label)
    }
}

/// The toolbar being on screen is the selection being on: Escape (a hardware keyboard on macOS) and the
/// assistive escape gesture leave the selection. While busy the press is consumed and nothing exits — the
/// same rule as the disabled exit key. Nothing on iOS delivers a bare Escape to a view, so there the
/// gesture is the only path; the exit key itself is always there.
struct MessageBatchEscape: ViewModifier {
    let busy: Bool
    let onExit: (() -> Void)?
    func body(content: Content) -> some View {
        let escaped = content.accessibilityAction(.escape) { if !busy { onExit?() } }
        #if os(macOS)
        return escaped.onExitCommand { if !busy { onExit?() } }
        #else
        return escaped
        #endif
    }
}
