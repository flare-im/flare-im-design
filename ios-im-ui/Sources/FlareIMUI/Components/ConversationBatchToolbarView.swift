import SwiftUI

// MARK: - Contract

/// Batch actions a host may expose over a multi-selection of conversations.
public enum ConversationBatchAction: String, CaseIterable, Sendable {
    case markRead, mute, archive, delete
}

/// Host-declared capabilities; a false entry hides the action entirely.
public struct ConversationBatchCapabilities: Sendable {
    public var markRead: Bool
    public var mute: Bool
    public var archive: Bool
    public var delete: Bool
    public init(markRead: Bool = false, mute: Bool = false, archive: Bool = false, delete: Bool = false) {
        self.markRead = markRead; self.mute = mute; self.archive = archive; self.delete = delete
    }
    public func allows(_ action: ConversationBatchAction) -> Bool {
        switch action {
        case .markRead: return markRead
        case .mute: return mute
        case .archive: return archive
        case .delete: return delete
        }
    }
}

/// One failed item of the previous batch, with a user-facing reason mapped by the host.
public struct ConversationBatchFailure: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let reason: String
    public init(id: String, title: String, reason: String) { self.id = id; self.title = title; self.reason = reason }
}

/// Outcome of the previous batch as written by the host.
public struct ConversationBatchResult: Sendable {
    public let succeeded: [String]
    public let failed: [ConversationBatchFailure]
    public init(succeeded: [String] = [], failed: [ConversationBatchFailure] = []) { self.succeeded = succeeded; self.failed = failed }
}

public struct ConversationBatchSummary: Equatable, Sendable {
    public let succeededCount: Int
    public let failedCount: Int
    public let retryIds: [String]
    public init(succeededCount: Int, failedCount: Int, retryIds: [String]) {
        self.succeededCount = succeededCount; self.failedCount = failedCount; self.retryIds = retryIds
    }
}

/// True when the host limit is positive and the selection exceeds it.
public func batchSelectionExceeded(_ selectedCount: Int, _ maxSelection: Int?) -> Bool {
    guard let maxSelection, maxSelection > 0 else { return false }
    return selectedCount > maxSelection
}

/// Actions the toolbar may offer right now: empty while busy, with nothing selected, or over
/// `maxSelection`; otherwise capability-enabled actions in canonical order.
public func batchActionsAvailable(_ selectedIds: [String], _ capabilities: ConversationBatchCapabilities?,
                                  _ busy: Bool, _ maxSelection: Int? = nil) -> [ConversationBatchAction] {
    if busy || selectedIds.isEmpty || batchSelectionExceeded(selectedIds.count, maxSelection) { return [] }
    guard let capabilities else { return [] }
    return ConversationBatchAction.allCases.filter(capabilities.allows)
}

/// Counts of the previous batch and the deduplicated IDs a retry should target.
public func summarizeBatchResult(_ result: ConversationBatchResult?) -> ConversationBatchSummary {
    guard let result else { return ConversationBatchSummary(succeededCount: 0, failedCount: 0, retryIds: []) }
    var seen = Set<String>()
    var retryIds: [String] = []
    for failure in result.failed where !failure.id.isEmpty && seen.insert(failure.id).inserted {
        retryIds.append(failure.id)
    }
    return ConversationBatchSummary(succeededCount: result.succeeded.count, failedCount: result.failed.count, retryIds: retryIds)
}

// MARK: - ConversationBatchToolbar

/// Batch toolbar for the conversation list in multi-select mode. Same bar / count / actions /
/// cancel visual as `MessageBatchToolbarView`, plus a partial-failure strip with per-item reasons
/// and a retry-failed entry. Emits intents only; the host owns `busy`, `result` and the
/// DangerConfirm step for `delete`. Spec: Conversation/ConversationBatchToolbar.
public struct ConversationBatchToolbarView: View {
    private enum Pending: Equatable { case action(ConversationBatchAction), retry }

    private let selectedIds: [String]
    private let capabilities: ConversationBatchCapabilities
    private let busy: Bool
    private let result: ConversationBatchResult?
    private let maxSelection: Int?
    private let onAction: ((ConversationBatchAction, [String]) -> Void)?
    private let onRetryFailed: (([String]) -> Void)?
    private let onClearSelection: (() -> Void)?
    private let onDismissResult: (() -> Void)?
    private let selectedText, emptyText, markReadText, muteText, archiveText, deleteText, cancelText, busyText: String
    private let succeededSummaryText, failedSummaryText, retryFailedText, dismissText, expandText, collapseText, maxSelectionText: String

    @State private var pending: Pending?
    @State private var expanded = false
    @Environment(\.colorScheme) private var scheme

    public init(selectedIds: [String], capabilities: ConversationBatchCapabilities, busy: Bool = false,
                result: ConversationBatchResult? = nil, maxSelection: Int? = nil,
                onAction: ((ConversationBatchAction, [String]) -> Void)? = nil,
                onRetryFailed: (([String]) -> Void)? = nil,
                onClearSelection: (() -> Void)? = nil,
                onDismissResult: (() -> Void)? = nil,
                selectedText: String = "已选", emptyText: String = "请选择会话",
                markReadText: String = "标为已读", muteText: String = "免打扰", archiveText: String = "归档",
                deleteText: String = "删除", cancelText: String = "取消选择", busyText: String = "处理中",
                succeededSummaryText: String = "成功 {n} 项", failedSummaryText: String = "{n} 项失败",
                retryFailedText: String = "重试失败项", dismissText: String = "关闭结果",
                expandText: String = "查看详情", collapseText: String = "收起", maxSelectionText: String = "最多可选 {n} 项") {
        self.selectedIds = selectedIds; self.capabilities = capabilities; self.busy = busy
        self.result = result; self.maxSelection = maxSelection
        self.onAction = onAction; self.onRetryFailed = onRetryFailed
        self.onClearSelection = onClearSelection; self.onDismissResult = onDismissResult
        self.selectedText = selectedText; self.emptyText = emptyText; self.markReadText = markReadText
        self.muteText = muteText; self.archiveText = archiveText; self.deleteText = deleteText
        self.cancelText = cancelText; self.busyText = busyText
        self.succeededSummaryText = succeededSummaryText; self.failedSummaryText = failedSummaryText
        self.retryFailedText = retryFailedText; self.dismissText = dismissText
        self.expandText = expandText; self.collapseText = collapseText; self.maxSelectionText = maxSelectionText
    }

    private func fill(_ template: String, _ n: Int) -> String { template.replacingOccurrences(of: "{n}", with: "\(n)") }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let count = selectedIds.count
        let exceeded = batchSelectionExceeded(count, maxSelection)
        let available = batchActionsAvailable(selectedIds, capabilities, busy, maxSelection)
        let summary = summarizeBatchResult(result)
        let hasResult = summary.failedCount > 0 || summary.succeededCount > 0
        let hint: String? = busy ? busyText : (count == 0 ? emptyText : (exceeded ? fill(maxSelectionText, maxSelection ?? 0) : nil))
        let visible = ConversationBatchAction.allCases.filter(capabilities.allows)

        VStack(spacing: 0) {
            MomentLikersFlow(spacing: FlareSizes.spacingMd, lineSpacing: FlareSizes.spacingSm) {
                HStack(spacing: FlareSizes.spacingMd) {
                    HStack(spacing: 4) {
                        Text("\(count)").font(.system(size: FlareSizes.fontSize2xl, weight: .bold)).foregroundColor(colors.primary)
                        Text(selectedText).font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textSecondary)
                    }
                    if let hint {
                        HStack(spacing: 6) {
                            if busy { ProgressView().controlSize(.small) }
                            else if exceeded { Image(systemName: "exclamationmark.circle").font(.system(size: 12)) }
                            Text(hint).font(.system(size: FlareSizes.fontSizeSm))
                        }
                        .foregroundColor(exceeded && !busy ? colors.warning : colors.textTertiary)
                        .accessibilityElement(children: .combine)
                    }
                }
                if onAction != nil || onClearSelection != nil {
                    MomentLikersFlow(spacing: 6, lineSpacing: 6) {
                        if let onAction {
                            ForEach(visible, id: \.self) { action in
                                button(colors, icon: icon(action), label: label(action),
                                       enabled: available.contains(action), pending: busy && pending == .action(action),
                                       tint: action == .delete ? colors.error : nil) {
                                    pending = .action(action)
                                    onAction(action, selectedIds)
                                }
                            }
                        }
                        if let onClearSelection {
                            iconButton(colors, "xmark", label: cancelText, enabled: !busy, action: onClearSelection)
                        }
                    }
                }
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, 10)

            if hasResult { resultStrip(colors, summary) }
        }
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderPrimary, lineWidth: 1)))
        .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
        .shadow(color: Color.black.opacity(0.12), radius: 16, y: 6)
        .onChange(of: busy) { if !$0 { pending = nil } }
        .onChange(of: result?.failed.count) { _ in expanded = false }
    }

    @ViewBuilder
    private func resultStrip(_ colors: FlareColors, _ summary: ConversationBatchSummary) -> some View {
        let failed = summary.failedCount > 0
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            MomentLikersFlow(spacing: FlareSizes.spacingSm, lineSpacing: 6) {
                HStack(spacing: FlareSizes.spacingSm) {
                    Image(systemName: failed ? "exclamationmark.circle" : "checkmark.circle")
                        .font(.system(size: 14)).foregroundColor(failed ? colors.error : colors.success)
                    HStack(spacing: 0) {
                        if failed {
                            Text(fill(failedSummaryText, summary.failedCount)).fontWeight(.semibold).foregroundColor(colors.error)
                        }
                        if failed && summary.succeededCount > 0 { Text(" · ") }
                        if summary.succeededCount > 0 || !failed { Text(fill(succeededSummaryText, summary.succeededCount)) }
                    }
                    .font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textPrimary)
                }
                .accessibilityElement(children: .combine)
                MomentLikersFlow(spacing: 6, lineSpacing: 6) {
                    if failed {
                        button(colors, icon: expanded ? "chevron.up" : "chevron.down", label: expanded ? collapseText : expandText,
                               enabled: true, pending: false, ghost: true) { expanded.toggle() }
                    }
                    if !summary.retryIds.isEmpty, let onRetryFailed {
                        button(colors, icon: "arrow.clockwise", label: "\(retryFailedText) (\(summary.retryIds.count))",
                               enabled: !busy, pending: busy && pending == .retry, primary: true) {
                            pending = .retry
                            onRetryFailed(summary.retryIds)
                        }
                    }
                    if let onDismissResult {
                        iconButton(colors, "xmark", label: dismissText, enabled: !busy) {
                            expanded = false
                            onDismissResult()
                        }
                    }
                }
            }
            if expanded, let result, !result.failed.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(result.failed.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .firstTextBaseline, spacing: FlareSizes.spacingSm) {
                                Text(item.title).font(.system(size: FlareSizes.fontSizeSm, weight: .medium))
                                    .foregroundColor(colors.textPrimary).lineLimit(1)
                                Text(item.reason).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 8).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusSm).fill(colors.bgPrimary))
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
        .background(colors.bgSecondary)
    }

    private func icon(_ a: ConversationBatchAction) -> String {
        switch a {
        case .markRead: return "checkmark.circle"
        case .mute: return "bell.slash"
        case .archive: return "archivebox"
        case .delete: return "trash"
        }
    }

    private func label(_ a: ConversationBatchAction) -> String {
        switch a {
        case .markRead: return markReadText
        case .mute: return muteText
        case .archive: return archiveText
        case .delete: return deleteText
        }
    }

    private func button(_ colors: FlareColors, icon: String, label: String, enabled: Bool, pending: Bool,
                        tint: Color? = nil, ghost: Bool = false, primary: Bool = false,
                        action: @escaping () -> Void) -> some View {
        let fg: Color = primary ? .white : (tint ?? (ghost ? colors.textSecondary : colors.textPrimary))
        let bg: Color = primary ? colors.primary : (ghost ? .clear : colors.bgSecondary)
        return Button(action: action) {
            HStack(spacing: 5) {
                if pending { ProgressView().controlSize(.small).tint(fg) }
                else { Image(systemName: icon).font(.system(size: 14)) }
                Text(label).font(.system(size: FlareSizes.fontSizeMd, weight: .medium)).lineLimit(1)
            }
            .foregroundColor(fg)
            .padding(.horizontal, FlareSizes.spacingMd)
            .frame(minWidth: FlareSizes.touchTarget, minHeight: FlareSizes.touchTarget)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(bg))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : (pending ? 0.85 : 0.45))
        .accessibilityLabel(pending ? "\(label) · \(busyText)" : label)
    }

    private func iconButton(_ colors: FlareColors, _ icon: String, label: String, enabled: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(colors.textSecondary)
                .frame(width: FlareSizes.touchTarget, height: FlareSizes.touchTarget)
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(colors.bgSecondary))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
        .accessibilityLabel(label)
    }
}
