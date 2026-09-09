import SwiftUI

public enum FlareTransferAction: String, CaseIterable, Sendable { case pause, resume, cancel, retry, open }
public enum FlareTransferState: String, CaseIterable, Sendable {
    case queued, transferring, paused, failed, completed, cancelled
    public var actions: [FlareTransferAction] {
        switch self {
        case .queued: return [.cancel]
        case .transferring: return [.pause, .cancel]
        case .paused: return [.resume, .cancel]
        case .failed, .cancelled: return [.retry]
        case .completed: return [.open]
        }
    }
    public func normalizedProgress(_ value: Double?) -> Double? {
        if self == .completed { return 1 }
        guard let value, value.isFinite else { return nil }
        return min(1, max(0, value))
    }
}

/// The host supplies capabilities and measured progress, and handles all operations.
public struct TransferProgressView: View {
    let name: String
    let state: FlareTransferState
    let statusText: String
    let progress: Double?
    let actionLabels: [FlareTransferAction: String]
    let busy: Bool
    let onAction: ((FlareTransferAction) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @ScaledMetric private var nameSize: CGFloat = 14
    @ScaledMetric private var statusSize: CGFloat = 13
    public init(name: String, state: FlareTransferState, statusText: String, progress: Double? = nil,
                actionLabels: [FlareTransferAction: String] = [:], busy: Bool = false,
                onAction: ((FlareTransferAction) -> Void)? = nil) {
        self.name = name; self.state = state; self.statusText = statusText; self.progress = progress
        self.actionLabels = actionLabels; self.busy = busy; self.onAction = onAction
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        let value = state.normalizedProgress(progress)
        VStack(alignment: .leading, spacing: 8) {
            Text(name).font(.system(size: nameSize, weight: .semibold)).foregroundColor(colors.textPrimary).fixedSize(horizontal: false, vertical: true)
            Text(statusText).font(.system(size: statusSize)).foregroundColor(colors.textSecondary).fixedSize(horizontal: false, vertical: true)
            if let value { ProgressView(value: value).tint(colors.primary).accessibilityLabel(name + " — " + statusText) }
            else if state == .transferring { ProgressView().tint(colors.primary).accessibilityLabel(name + " — " + statusText) }
            // A vertical action group remains readable at accessibility sizes on small phones.
            ForEach(state.actions, id: \.self) { action in
                if let label = actionLabels[action], !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, onAction != nil {
                    Button { if !busy { onAction?(action) } } label: {
                        Text(label).font(.system(size: statusSize)).frame(minWidth: 48, minHeight: 48)
                    }.buttonStyle(.plain).foregroundColor(colors.textPrimary).disabled(busy)
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(colors.bgPrimary))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(colors.borderPrimary, lineWidth: 1))
    }
}
