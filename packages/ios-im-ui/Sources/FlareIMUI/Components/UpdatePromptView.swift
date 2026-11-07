import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The update prompt: the SDK's update status in as plain values, the kit's words, progress and actions out, and every
/// action back to the host. Spec: Feedback/UpdatePrompt (`UpdatePromptView`).
///
/// What shows when is ``flareUpdatePrompt(form:mandatory:state:progress:errorCode:retryable:sizeBytes:canContinueReadOnly:reason:)``'s
/// call (`spec/update-prompt-vectors.json`, the same in every kit). The view holds no SDK and never closes itself. An
/// action is drawn only when the host passes its handler. The title and the message are announced when they change,
/// politely, or at once on a forced prompt; the percent is not re-announced.
///
/// This is the prompt's content: in the fullscreen form it brings its own ``FlareScreen`` page. Put it on screen with
/// ``SwiftUI/View/flareUpdatePrompt(isPresented:prompt:)``.
public struct UpdatePromptView: View {
    let form: FlareUpdatePromptForm
    private let version: String?
    private let notes: [String]
    private let reason: String?
    private let sizeBytes: Int64?
    private let mandatory: Bool
    private let state: String?
    private let progress: FlareUpdateProgress?
    private let errorCode: String?
    private let retryable: Bool
    private let fallbackTarget: FlareUpdateFallbackTarget
    private let canContinueReadOnly: Bool
    private let onUpdate: (() -> Void)?
    private let onLater: (() -> Void)?
    private let onSkip: (() -> Void)?
    private let onRetry: (() -> Void)?
    private let onFallback: (() -> Void)?
    private let onContinueReadOnly: (() -> Void)?
    @Environment(\.flareStrings) private var strings
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    /// - Parameters:
    ///   - form: `UpdateStatus.prompt`.
    ///   - version: `UpdateStatus.release?.version`; blank draws no version line.
    ///   - notes: `UpdateStatus.release.notes`, already in the reader's language.
    ///   - reason: `UpdateStatus.blockReason`, already in the reader's language: a forced offer says it in place of its
    ///     fixed words.
    ///   - sizeBytes: `UpdateStatus.release.sizeBytes`; nil on a store update.
    ///   - mandatory: `UpdateStatus.release.mandatory`: nothing here can postpone it.
    ///   - state: `UpdateStatus.state`.
    ///   - progress: `UpdateStatus.progress`, as it arrives.
    ///   - errorCode: `UpdateStatus.error.code`.
    ///   - retryable: `UpdateStatus.error.retryable`.
    ///   - fallbackTarget: where the fallback goes: the website on a direct install, the app store otherwise.
    ///   - canContinueReadOnly: a forced prompt may step aside into read-only browsing.
    ///   - onUpdate: update now, continue on a metered network, or restart to finish.
    ///   - onLater: put it off, or send the download to the background. The scrim, the swipe and Escape ask for this too.
    ///   - onSkip: skip this version (`update.skip`).
    ///   - onRetry: try the failed step again.
    ///   - onFallback: open the website or the app store.
    ///   - onContinueReadOnly: step aside into read-only browsing.
    public init(form: FlareUpdatePromptForm, version: String? = nil, notes: [String] = [], reason: String? = nil,
                sizeBytes: Int64? = nil, mandatory: Bool = false, state: String? = nil,
                progress: FlareUpdateProgress? = nil, errorCode: String? = nil, retryable: Bool = true,
                fallbackTarget: FlareUpdateFallbackTarget = .website, canContinueReadOnly: Bool = false,
                onUpdate: (() -> Void)? = nil, onLater: (() -> Void)? = nil, onSkip: (() -> Void)? = nil,
                onRetry: (() -> Void)? = nil, onFallback: (() -> Void)? = nil,
                onContinueReadOnly: (() -> Void)? = nil) {
        self.form = form; self.version = version; self.notes = notes; self.reason = reason; self.sizeBytes = sizeBytes
        self.mandatory = mandatory; self.state = state; self.progress = progress; self.errorCode = errorCode
        self.retryable = retryable; self.fallbackTarget = fallbackTarget; self.canContinueReadOnly = canContinueReadOnly
        self.onUpdate = onUpdate; self.onLater = onLater; self.onSkip = onSkip; self.onRetry = onRetry
        self.onFallback = onFallback; self.onContinueReadOnly = onContinueReadOnly
    }

    var model: FlareUpdatePromptModel {
        // Qualified: inside a View the bare name is the `flareUpdatePrompt(isPresented:prompt:)` modifier.
        FlareIMUI.flareUpdatePrompt(form: form, mandatory: mandatory, state: state, progress: progress,
                                    errorCode: errorCode, retryable: retryable, sizeBytes: sizeBytes,
                                    canContinueReadOnly: canContinueReadOnly, reason: reason)
    }

    /// Whether the scrim, the swipe and Escape may ask for later.
    var dismissible: Bool { model.dismissible && onLater != nil }

    /// A way out the layer took: the scrim, the swipe or Escape.
    func requestLater() { if dismissible { onLater?() } }

    private func handler(_ action: FlareUpdatePromptAction) -> (() -> Void)? {
        switch action {
        case .update, .continueDownload, .restart: return onUpdate
        case .retry: return onRetry
        case .fallback: return onFallback
        case .later, .background: return onLater
        case .skip: return onSkip
        case .continueReadOnly: return onContinueReadOnly
        }
    }

    private func variant(_ action: FlareUpdatePromptAction, index: Int) -> FlareButtonVariant {
        if index == 0 { return .primary }
        return action == .fallback || action == .continueReadOnly ? .secondary : .quiet
    }

    private var sizeText: String? { sizeBytes.flatMap { formatBytes(Double($0)) } }

    /// The version with the size beside it; nil draws no line.
    private var versionLine: String? {
        guard let version, flareUpdateVersionShown(version) else { return nil }
        let text = "\(strings.updatePromptVersion) \(version)"
        return sizeText.map { "\(text) · \($0)" } ?? text
    }

    private func spoken(_ model: FlareUpdatePromptModel) -> String {
        let title = model.title.label(strings)
        guard let message = model.message else { return title }
        return "\(title) \(message.label(strings, size: sizeText, reason: reason))"
    }

    @MainActor
    private func announce(_ model: FlareUpdatePromptModel) {
        if model.live == .assertive {
            flareAnnounceAtOnce(spoken(model))
        } else {
            flareAnnounce(spoken(model))
        }
    }

    public var body: some View {
        let model = self.model
        Group {
            switch form {
            case .fullscreen:
                FlareScreen(surface: .surface, padded: true) {
                    content(model)
                        .frame(maxWidth: FlareSizes.componentSheetDialogWidth)
                        .frame(maxWidth: .infinity)
                }
            case .sheet:
                content(model).padding(FlareSizes.spacingLg)
            case .modal:
                // The modal's own body already keeps its content off the edges.
                content(model)
            }
        }
        .onAppear { announce(model) }
        .onChange(of: spoken(model)) { _ in announce(self.model) }
    }

    private func content(_ model: FlareUpdatePromptModel) -> some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        return VStack(alignment: .leading, spacing: FlareSizes.spacingLg) {
            VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                Text(model.title.label(strings))
                    .font(.system(size: FlareSizes.fontSizeXl, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if let versionLine {
                    Text(versionLine)
                        .font(.system(size: FlareTextRoles.caption.fontSize))
                        .foregroundColor(colors.textSecondary)
                }
            }
            if let message = model.message {
                bodyText(message.label(strings, size: sizeText, reason: reason), colors)
            }
            if let bar = model.progress { progressSection(bar, model, colors) }
            if model.notes && !notes.isEmpty { releaseNotes(colors) }
            actionButtons(model)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bodyText(_ text: String, _ colors: FlareColors) -> some View {
        Text(text)
            .font(.system(size: FlareTextRoles.body.fontSize))
            .foregroundColor(colors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func progressSection(_ bar: FlareProgressBarValue, _ model: FlareUpdatePromptModel,
                                 _ colors: FlareColors) -> some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            ProgressBarView(value: bar.value, indeterminate: bar.value == nil, label: model.title.label(strings))
            if let text = progressText(bar) {
                Text(text)
                    .font(.system(size: FlareTextRoles.caption.fontSize))
                    .foregroundColor(colors.textSecondary)
            }
        }
    }

    private func progressText(_ bar: FlareProgressBarValue) -> String? {
        guard let percent = bar.percent else { return nil }
        guard let progress, let total = progress.total,
              let receivedText = formatBytes(Double(progress.received)),
              let totalText = formatBytes(Double(total)) else { return "\(percent)%" }
        return "\(percent)% · \(receivedText) / \(totalText)"
    }

    private func releaseNotes(_ colors: FlareColors) -> some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            Text(strings.updatePromptNotes)
                .font(.system(size: FlareTextRoles.body.fontSize, weight: .semibold))
                .foregroundColor(colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                bodyText("• \(note)", colors)
            }
        }
    }

    @ViewBuilder
    private func actionButtons(_ model: FlareUpdatePromptModel) -> some View {
        let drawn = model.actions.filter { handler($0) != nil }
        if !drawn.isEmpty {
            VStack(spacing: FlareSizes.spacingSm) {
                ForEach(Array(drawn.enumerated()), id: \.element) { index, action in
                    ButtonView(label: action.label(strings, fallbackTarget: fallbackTarget),
                               variant: variant(action, index: index), size: .lg, block: true,
                               action: handler(action))
                }
            }
        }
    }
}

/// Reads `message` to VoiceOver at once, over what it is saying (an assertive live region).
@MainActor
private func flareAnnounceAtOnce(_ message: String) {
    #if canImport(UIKit)
    let interrupting = NSAttributedString(string: message, attributes: [.accessibilitySpeechQueueAnnouncement: false])
    UIAccessibility.post(notification: .announcement, argument: interrupting)
    #elseif canImport(AppKit)
    NSAccessibility.post(element: NSApplication.shared, notification: .announcementRequested,
                         userInfo: [.announcement: message, .priority: NSAccessibilityPriorityLevel.high.rawValue])
    #endif
}

public extension View {
    /// Presents `prompt` while `isPresented`: the kit's bottom sheet, its modal, or a page over a full-screen cover (a
    /// system sheet below iOS 16.4 and on macOS, where it cannot be swiped away), by the prompt's form. A new `prompt`
    /// updates the open layer in place.
    ///
    /// The scrim, the swipe and Escape call the prompt's `onLater`, and nothing else does: `isPresented` stays the host's,
    /// which sets it false to close, in `onLater` included.
    func flareUpdatePrompt(isPresented: Binding<Bool>, prompt: UpdatePromptView) -> some View {
        modifier(FlareUpdatePromptPresenter(isPresented: isPresented, prompt: prompt))
    }
}

struct FlareUpdatePromptPresenter: ViewModifier {
    /// The form of the latest render. A layer reacts to `isPresented` with the binding of the render before, which
    /// held the prompt from before the first status and so a form that is not this one.
    private final class LatestForm {
        var form: FlareUpdatePromptForm?
    }

    @Binding var isPresented: Bool
    let prompt: UpdatePromptView
    @State private var presence = UUID()
    @State private var latest = LatestForm()
    @Environment(\.flareStrings) private var strings

    /// Open while the host says so and this is the prompt's form. Only a layer writes here: on its way out while still
    /// wanted it was the reader leaving, and once the host closed it, it is only reporting that it went.
    private func shown(_ form: FlareUpdatePromptForm) -> Binding<Bool> {
        let latest = latest
        return Binding(get: { isPresented && latest.form == form },
                       set: { presented in
                           if !presented, isPresented, latest.form == form { prompt.requestLater() }
                       })
    }

    func body(content: Content) -> some View {
        latest.form = prompt.form
        let title = prompt.model.title.label(strings)
        return content
            .flareBottomSheet(isPresented: shown(.sheet), title: title, titleHidden: true,
                              dismissible: prompt.dismissible) { prompt }
            .flareModal(isPresented: shown(.modal), title: title, titleHidden: true,
                        dismissible: prompt.dismissible, showClose: false) { prompt }
            .modifier(FlareLayerPresenter(
                isPresented: shown(.fullscreen), presence: presence, coverKind: .modal, registers: true,
                dismissible: false, compact: nil, allowsPush: false,
                resolve: { _ in .cover }, onDismiss: nil,
                sheetLayer: { EmptyView() },
                coverLayer: { FlareUpdatePromptPage(prompt: prompt, title: title) },
                pushLayer: { EmptyView() }
            ))
    }
}

/// The fullscreen form on its cover: the page fades with the layer and is the only thing VoiceOver reaches.
private struct FlareUpdatePromptPage: View {
    let prompt: UpdatePromptView
    let title: String
    @Environment(\.flareLayerVisible) private var visible

    var body: some View {
        prompt
            .opacity(visible ? 1 : 0)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isModal)
            .interactiveDismissDisabled(true)
    }
}
