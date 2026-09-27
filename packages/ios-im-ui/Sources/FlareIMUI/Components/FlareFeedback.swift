import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Options

/// A destructive or irreversible step the user must confirm, asked through
/// ``FlareFeedback/confirm(_:)`` and shown as ``DangerConfirmView``.
public struct FlareConfirmOptions {
    public let title: String
    public let description: String
    /// What the step applies to (a message, a contact), on its own line; nil shows none.
    public let target: String?
    public let confirmText: String?
    public let cancelText: String?
    /// Runs after the user confirms, with the dialog busy. A thrown error keeps the dialog
    /// open showing the error's `localizedDescription`, so the user can retry or cancel.
    public let action: (@MainActor () async throws -> Void)?

    public init(title: String, description: String, target: String? = nil,
                confirmText: String? = nil, cancelText: String? = nil,
                action: (@MainActor () async throws -> Void)? = nil) {
        self.title = title; self.description = description; self.target = target
        self.confirmText = confirmText; self.cancelText = cancelText; self.action = action
    }
}

/// One value the user types, asked through ``FlareFeedback/prompt(_:)`` and shown as a kit form sheet:
/// the title, an optional message, one input, cancel and confirm.
public struct FlarePromptOptions {
    public let title: String
    public let message: String?
    /// What the input starts with (the current remark, the group's name); "" for a new value.
    public let initialValue: String
    public let placeholder: String?
    /// The longest value the input takes; the input shows its count. Nil sets no limit.
    public let maxLength: Int?
    /// A multi-line input (a description, a comment).
    public let multiline: Bool
    /// Whether a blank value may be confirmed (clearing a remark); otherwise confirm waits for text.
    public let allowsEmpty: Bool
    public let confirmText: String?
    public let cancelText: String?
    /// Runs with the value (trimmed) after the user confirms, with the dialog busy. A thrown error keeps
    /// the dialog open with the draft and the error's `localizedDescription`; confirming again retries.
    public let submit: (@MainActor (String) async throws -> Void)?

    public init(title: String, message: String? = nil, initialValue: String = "", placeholder: String? = nil,
                maxLength: Int? = nil, multiline: Bool = false, allowsEmpty: Bool = false,
                confirmText: String? = nil, cancelText: String? = nil,
                submit: (@MainActor (String) async throws -> Void)? = nil) {
        self.title = title; self.message = message; self.initialValue = initialValue
        self.placeholder = placeholder; self.maxLength = maxLength; self.multiline = multiline
        self.allowsEmpty = allowsEmpty; self.confirmText = confirmText; self.cancelText = cancelText
        self.submit = submit
    }
}

/// One toast in the stack; the action closure stays with ``FlareFeedback``.
struct FlareToastEntry: Identifiable, Equatable {
    let id: Int
    let message: String
    let variant: ToastVariant
    let tone: FlareStatusTone?
    let actionLabel: String?
}

/// The confirmation on screen: its options, whether its action is running, the last failure.
struct FlareConfirmRequest: Identifiable {
    let id: Int
    let options: FlareConfirmOptions
    var busy = false
    var error: String?
}

/// The prompt on screen: its options, the draft, whether its submit is running, the last failure.
struct FlarePromptRequest: Identifiable {
    let id: Int
    let options: FlarePromptOptions
    var value: String
    var busy = false
    var error: String?

    /// Confirm is offered while nothing runs and the value is allowed (text, or blank when allowed).
    var canConfirm: Bool {
        !busy && (options.allowsEmpty || !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}

/// What a kit layer on screen is.
enum FlareLayerKind: Equatable {
    /// A kit bottom sheet shown as a system sheet.
    case sheet
    /// A kit bottom sheet whose `auto` presentation handed its content to a Modal.
    case modalFromBottomSheet
    /// A ``ModalView`` from ``SwiftUI/View/flareModal(isPresented:title:titleHidden:label:width:maxHeight:fill:dismissible:showClose:busy:scrollable:actions:footer:onDismiss:content:)``.
    case modal
    /// A ``DrawerView`` from ``SwiftUI/View/flareDrawer(isPresented:title:titleHidden:label:placement:width:dismissible:showClose:showBack:navigable:compactFallback:actions:footer:onBack:onDismiss:content:)``.
    case drawer
}

/// A kit layer on screen, and whether it is closing.
struct FlareLayerPresence: Equatable {
    let id: UUID
    var kind: FlareLayerKind
    var closing = false
}

/// Who shows toasts or the confirmation right now.
enum FlareFeedbackPresenter: Equatable {
    /// No kit layer is on screen: the host view.
    case host
    /// The topmost kit layer: toasts above its content; confirmations too when it is an open Drawer.
    case layer(UUID)
    /// Nobody until the topmost kit layer is gone.
    case waiting
}

// MARK: - Presenter state

/// Toasts and confirmations for an app, presented by ``SwiftUI/View/flareFeedbackHost(_:)``
/// (the Vue `createFlareFeedback` contract). Own one at the root, install the host there, and
/// reach it below through `@Environment(\.flareFeedback)`.
///
/// Toasts stack top-center below the safe area, at most ``toastLimit`` (a new one removes the
/// oldest), each with a close button; VoiceOver reads each message without interrupting. A toast
/// stays 4 s, 6 s in the danger tone, or until its action or close runs with `duration: 0`;
/// running its action dismisses it. A confirmation is ``DangerConfirmView`` and a prompt a kit form, one
/// at a time, each shown as a kit bottom sheet in its `auto` presentation (a sheet on the phone form
/// factor, a Modal otherwise; the host measures its own width for this and publishes it as
/// ``SwiftUI/EnvironmentValues/flareCompactOverlays``).
///
/// The kit's layers — bottom sheets, Modals and Drawers — form one ordered stack. Toasts show above the
/// topmost one. A confirmation or prompt waits while the topmost is a bottom sheet or a Modal, or is
/// closing — so a sheet action can close its sheet and ask right away; while the topmost is an open
/// Drawer, the Drawer presents it. The host cannot present over a system `.sheet`; ask from content that
/// is not inside one.
@MainActor
public final class FlareFeedback: ObservableObject {
    /// Toasts on screen at once.
    public nonisolated static let toastLimit = 3

    @Published private(set) var toasts: [FlareToastEntry] = []
    @Published private(set) var confirmRequest: FlareConfirmRequest?
    @Published private(set) var promptRequest: FlarePromptRequest?
    /// Kit layers on screen (sheets, Modals, Drawers), oldest first.
    @Published private(set) var layers: [FlareLayerPresence] = []

    private var toastActions: [Int: () -> Void] = [:]
    private var toastTimers: [Int: Task<Void, Never>] = [:]
    private var nextToastId = 0
    private var nextConfirmId = 0
    private var settle: CheckedContinuation<Bool, Never>?
    private var nextPromptId = 0
    private var settlePrompt: CheckedContinuation<String?, Never>?
    private let announce: @MainActor (String) -> Void

    public convenience init() {
        self.init(announce: flareAnnounce)
    }

    init(announce: @escaping @MainActor (String) -> Void) {
        self.announce = announce
    }

    /// Shows a toast and returns a function that dismisses it early.
    /// - Parameters:
    ///   - tone: Overrides the tone the variant implies (see ``ToastView``).
    ///   - action: Runs from the toast's `actionLabel` button, then dismisses the toast.
    ///   - duration: Seconds on screen; 0 keeps it until its action or close runs. Defaults to
    ///     4, or 6 in the danger tone.
    @discardableResult
    public func toast(_ message: String, variant: ToastVariant = .info, tone: FlareStatusTone? = nil,
                      actionLabel: String? = nil, action: (() -> Void)? = nil,
                      duration: TimeInterval? = nil) -> () -> Void {
        nextToastId += 1
        let id = nextToastId
        var entries = toasts
        entries.append(FlareToastEntry(id: id, message: message, variant: variant, tone: tone,
                                       actionLabel: action == nil ? nil : actionLabel))
        while entries.count > Self.toastLimit { forget(entries.removeFirst().id) }
        toasts = entries
        if let action { toastActions[id] = action }
        let seconds = Self.toastDuration(variant: variant, tone: tone, duration: duration)
        if seconds > 0 {
            toastTimers[id] = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                guard !Task.isCancelled else { return }
                self?.dismissToast(id)
            }
        }
        announce(message)
        return { [weak self] in self?.dismissToast(id) }
    }

    /// Asks the user to confirm; true once confirmed and `options.action` (if any) succeeded,
    /// false when cancelled. One request at a time: a newer request replaces an idle one, which
    /// resolves false; while an action runs a newer request resolves false at once.
    public func confirm(_ options: FlareConfirmOptions) async -> Bool {
        if confirmRequest?.busy == true { return false }
        if confirmRequest != nil { close(false) }
        return await withCheckedContinuation { continuation in
            settle = continuation
            nextConfirmId += 1
            confirmRequest = FlareConfirmRequest(id: nextConfirmId, options: options)
        }
    }

    /// Asks for one value: the value (trimmed) once confirmed and `options.submit` (if any) succeeded,
    /// nil when cancelled. One prompt at a time: a newer request replaces an idle one, which resolves nil;
    /// while a submit runs a newer request resolves nil at once.
    public func prompt(_ options: FlarePromptOptions) async -> String? {
        if promptRequest?.busy == true { return nil }
        if promptRequest != nil { closePrompt(nil) }
        return await withCheckedContinuation { continuation in
            settlePrompt = continuation
            nextPromptId += 1
            promptRequest = FlarePromptRequest(id: nextPromptId, options: options,
                                               value: Self.limited(options.initialValue, options.maxLength))
        }
    }

    /// Seconds a toast stays: `duration` when given, else 4, or 6 when the toast reads as danger
    /// — the danger tone, or the error variant without a tone (a loading toast never does).
    nonisolated static func toastDuration(variant: ToastVariant, tone: FlareStatusTone?, duration: TimeInterval?) -> TimeInterval {
        if let duration { return max(0, duration) }
        let danger = variant != .loading && (tone.map { $0 == .danger } ?? (variant == .error))
        return danger ? 6 : 4
    }

    // MARK: Host intents

    /// The dialog's confirm button: runs the action with the dialog busy, closes on success,
    /// keeps the error for a retry on failure.
    func accept() async {
        guard var request = confirmRequest, !request.busy else { return }
        guard let action = request.options.action else { close(true); return }
        request.busy = true
        request.error = nil
        confirmRequest = request
        do {
            try await action()
            close(true)
        } catch {
            request.busy = false
            request.error = error.localizedDescription
            confirmRequest = request
        }
    }

    /// The dialog's cancel button or a swipe down; ignored while the action runs.
    func cancel() {
        guard let request = confirmRequest, !request.busy else { return }
        close(false)
    }

    /// The prompt input's edit; ignored while the submit runs. The draft never exceeds `maxLength`.
    func updatePromptValue(_ value: String) {
        guard var request = promptRequest, !request.busy else { return }
        request.value = Self.limited(value, request.options.maxLength)
        promptRequest = request
    }

    /// The prompt's confirm button: runs the submit with the dialog busy, closes on success, keeps the
    /// draft and the error for a retry on failure.
    func acceptPrompt() async {
        guard var request = promptRequest, request.canConfirm else { return }
        let value = request.value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let submit = request.options.submit else { closePrompt(value); return }
        request.busy = true
        request.error = nil
        promptRequest = request
        do {
            try await submit(value)
            if promptRequest?.id == request.id { closePrompt(value) }
        } catch {
            guard var current = promptRequest, current.id == request.id else { return }
            current.busy = false
            current.error = error.localizedDescription
            promptRequest = current
        }
    }

    /// The prompt's cancel button or a swipe down; ignored while the submit runs.
    func cancelPrompt() {
        guard let request = promptRequest, !request.busy else { return }
        closePrompt(nil)
    }

    private func closePrompt(_ value: String?) {
        let done = settlePrompt
        settlePrompt = nil
        promptRequest = nil
        done?.resume(returning: value)
    }

    nonisolated static func limited(_ value: String, _ maxLength: Int?) -> String {
        guard let maxLength, value.count > maxLength else { return value }
        return String(value.prefix(max(0, maxLength)))
    }

    func runToastAction(_ id: Int) {
        let action = toastActions[id]
        dismissToast(id)
        action?()
    }

    func dismissToast(_ id: Int) {
        forget(id)
        if let index = toasts.firstIndex(where: { $0.id == id }) { toasts.remove(at: index) }
    }

    private func forget(_ id: Int) {
        toastTimers.removeValue(forKey: id)?.cancel()
        toastActions.removeValue(forKey: id)
    }

    private func close(_ confirmed: Bool) {
        let done = settle
        settle = nil
        confirmRequest = nil
        done?.resume(returning: confirmed)
    }

    // MARK: Kit layers

    /// Toasts show above the topmost open kit layer, on the host when none is on screen, and
    /// nowhere while the topmost one closes.
    var toastPresenter: FlareFeedbackPresenter {
        guard let top = layers.last else { return .host }
        return top.closing ? .waiting : .layer(top.id)
    }

    /// The confirmation and the prompt show from the host once no kit layer is on screen, and from the
    /// topmost layer while that is an open Drawer (a Drawer is where the person works; its actions ask).
    /// A sheet or Modal never shows them: a host may close it and ask in the same turn, before it reports
    /// closing, and SwiftUI cannot present from a layer on its way out.
    var confirmPresenter: FlareFeedbackPresenter {
        guard let top = layers.last else { return .host }
        return top.kind == .drawer && !top.closing ? .layer(top.id) : .waiting
    }

    /// A kit layer opened (or, reopened before it was gone, stopped closing).
    func layerPresented(_ id: UUID, kind: FlareLayerKind) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            if layers[index].closing { layers[index].closing = false }
            if layers[index].kind != kind { layers[index].kind = kind }
        } else {
            layers.append(FlareLayerPresence(id: id, kind: kind))
        }
    }

    func layerClosing(_ id: UUID) {
        if let index = layers.firstIndex(where: { $0.id == id }), !layers[index].closing { layers[index].closing = true }
    }

    func layerDismissed(_ id: UUID) {
        if let index = layers.firstIndex(where: { $0.id == id }) { layers.remove(at: index) }
    }

    /// Whether `presenter` shows the prompt: like the confirmation; dismissing it (a swipe, the scrim) cancels.
    func promptPresented(by presenter: FlareFeedbackPresenter) -> Binding<Bool> {
        Binding(
            get: { self.promptRequest != nil && self.confirmPresenter == presenter },
            set: { shown in if !shown && self.confirmPresenter == presenter { self.cancelPrompt() } }
        )
    }

    /// Whether `presenter` shows the confirmation; dismissing it (false) cancels, while dropping a
    /// presentation it no longer owns (a kit layer opened above) leaves the request waiting.
    func confirmPresented(by presenter: FlareFeedbackPresenter) -> Binding<Bool> {
        Binding(
            get: { self.confirmRequest != nil && self.confirmPresenter == presenter },
            set: { shown in if !shown && self.confirmPresenter == presenter { self.cancel() } }
        )
    }

    /// Whether the host shows the prompt.
    var hostPromptPresented: Binding<Bool> { promptPresented(by: .host) }

    /// Whether the host shows the confirmation.
    var hostConfirmPresented: Binding<Bool> { confirmPresented(by: .host) }
}

/// Reads `message` to VoiceOver after what it is saying (a polite live region).
@MainActor
func flareAnnounce(_ message: String) {
    if #available(iOS 17.0, macOS 14.0, *) {
        AccessibilityNotification.Announcement(message).post()
    } else {
        #if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: message)
        #elseif canImport(AppKit)
        NSAccessibility.post(element: NSApplication.shared, notification: .announcementRequested,
                             userInfo: [.announcement: message, .priority: NSAccessibilityPriorityLevel.medium.rawValue])
        #endif
    }
}

// MARK: - Host

private struct FlareFeedbackKey: EnvironmentKey {
    static let defaultValue: FlareFeedback? = nil
}

public extension EnvironmentValues {
    /// The app's ``FlareFeedback``, installed by ``SwiftUI/View/flareFeedbackHost(_:)``;
    /// nil when no host is installed above.
    var flareFeedback: FlareFeedback? {
        get { self[FlareFeedbackKey.self] }
        set { self[FlareFeedbackKey.self] = newValue }
    }
}

public extension View {
    /// Presents `feedback`'s toast stack, confirmations and prompts over this view and installs it as
    /// `EnvironmentValues.flareFeedback` below. It also measures its own box live and publishes
    /// ``SwiftUI/EnvironmentValues/flareCompactOverlays`` from that width, which the kit's `auto`
    /// overlays resolve with. Install once, near the app root.
    func flareFeedbackHost(_ feedback: FlareFeedback) -> some View {
        modifier(FlareFeedbackHost(feedback: feedback))
            .environment(\.flareFeedback, feedback)
    }
}

/// The feedback host's measured box.
private struct FlareFeedbackHostSizeKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
}

private struct FlareFeedbackHost: ViewModifier {
    @ObservedObject var feedback: FlareFeedback
    @State private var size: CGSize?
    @Environment(\.flareShellResponsiveMode) private var shellMode

    func body(content: Content) -> some View {
        content
            .environment(\.flareOverlayHostSize, size)
            .background(GeometryReader { proxy in
                Color.clear.preference(key: FlareFeedbackHostSizeKey.self, value: proxy.size)
            })
            .onPreferenceChange(FlareFeedbackHostSizeKey.self) { measured in
                if measured.width > 0 { size = measured }
            }
            .modifier(FlareToastLayer(feedback: feedback, presenter: .host))
            // The host's own confirmations never register: they would wait on themselves.
            .modifier(FlareFeedbackRequests(
                feedback: feedback, presenter: .host,
                compact: FlareOverlayRules.compact(shellMode: shellMode, hostWidth: size?.width)
            ))
    }
}

/// The confirmation and the prompt, presented by `presenter` (the host or an open Drawer) as kit bottom
/// sheets in the `auto` presentation, without registering in the layer stack.
struct FlareFeedbackRequests: ViewModifier {
    @ObservedObject var feedback: FlareFeedback
    let presenter: FlareFeedbackPresenter
    /// The form factor when the presenter knows it better than its environment (the host measures itself).
    let compact: Bool?

    func body(content: Content) -> some View {
        let confirm = feedback.confirmRequest
        let prompt = feedback.promptRequest
        content
            .modifier(FlareSheetLayerPresenter(
                isPresented: feedback.confirmPresented(by: presenter), title: confirm?.options.title,
                titleHidden: true, presentation: .auto, dismissible: confirm?.busy != true, size: .fitted,
                maxHeight: nil, registers: false, compact: compact, onDismiss: nil
            ) { FlareConfirmSheet(feedback: feedback) })
            // A second presentation needs its own anchor view.
            .background(Color.clear.modifier(FlareSheetLayerPresenter(
                isPresented: feedback.promptPresented(by: presenter), title: prompt?.options.title,
                titleHidden: true, presentation: .auto, dismissible: prompt?.busy != true, size: .fitted,
                maxHeight: nil, registers: false, compact: compact, onDismiss: nil
            ) { FlarePromptSheet(feedback: feedback) }))
    }
}

/// The toast stack over the content while `presenter` is the one showing toasts.
struct FlareToastLayer: ViewModifier {
    @ObservedObject var feedback: FlareFeedback
    let presenter: FlareFeedbackPresenter

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if feedback.toastPresenter == presenter { FlareToastStack(feedback: feedback) }
        }
    }
}

/// The toast stack, newest last, each toast with its close button.
private struct FlareToastStack: View {
    @ObservedObject var feedback: FlareFeedback
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: FlareSizes.spacingSm) {
            ForEach(feedback.toasts) { entry in
                ToastView(message: entry.message, variant: entry.variant, tone: entry.tone,
                          actionLabel: entry.actionLabel,
                          onAction: entry.actionLabel == nil ? nil : { feedback.runToastAction(entry.id) },
                          onClose: { feedback.dismissToast(entry.id) })
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        // Clear the page header. A toast anchored to the very top lands on the title and the
        // header's own actions — readable text over readable text, and the actions under it
        // stop taking taps for as long as the toast is up.
        .padding(.top, FlareSizes.screenHeaderHeight + FlareSizes.spacingSm)
        .animation(reduceMotion ? nil : FlareMotion.normalAnimation, value: feedback.toasts)
    }
}

/// ``DangerConfirmView`` for the current request. Keeps the last request while the sheet or Modal
/// animates away, so it does not empty on its way out.
private struct FlareConfirmSheet: View {
    @ObservedObject var feedback: FlareFeedback
    @State private var shown: FlareConfirmRequest?

    var body: some View {
        Group {
            if let request = feedback.confirmRequest ?? shown {
                DangerConfirmView(
                    title: request.options.title,
                    description: request.options.description,
                    target: request.options.target ?? "",
                    busy: request.busy,
                    error: request.error,
                    confirmText: request.options.confirmText,
                    cancelText: request.options.cancelText,
                    onConfirm: { Task { await feedback.accept() } },
                    onCancel: { feedback.cancel() }
                )
            }
        }
        .onReceive(feedback.$confirmRequest) { request in if let request { shown = request } }
    }
}

/// The prompt for the current request, as a kit form sheet. Keeps the last request while the sheet
/// animates away, so it does not empty on its way out.
private struct FlarePromptSheet: View {
    @ObservedObject var feedback: FlareFeedback
    @State private var shown: FlarePromptRequest?

    var body: some View {
        Group {
            if let request = feedback.promptRequest ?? shown {
                FlarePromptForm(request: request,
                                onChange: { feedback.updatePromptValue($0) },
                                onConfirm: { Task { await feedback.acceptPrompt() } },
                                onCancel: { feedback.cancelPrompt() })
            }
        }
        .onReceive(feedback.$promptRequest) { request in if let request { shown = request } }
    }
}

/// A prompt's form: ``FormSheetView`` with the message, one ``InputView`` and the failure under it.
struct FlarePromptForm: View {
    let request: FlarePromptRequest
    let onChange: (String) -> Void
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @Environment(\.flareStrings) private var strings
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var brand

    var body: some View {
        let options = request.options
        FormSheetView(title: options.title, confirmLabel: options.confirmText ?? strings.confirm,
                      cancelLabel: options.cancelText ?? strings.cancel, busy: request.busy,
                      confirmEnabled: request.canConfirm, onConfirm: onConfirm, onClose: onCancel) {
            if let message = options.message, !message.isEmpty {
                Text(message).font(.system(size: FlareSizes.fontSizeMd))
                    .foregroundColor(FlareColors.of(scheme, brand: brand).textSecondary)
            }
            FormFieldView(error: request.error) {
                InputView(text: Binding(get: { request.value }, set: onChange),
                          placeholder: options.placeholder ?? "", multiline: options.multiline,
                          maxLength: options.maxLength, onSubmit: options.multiline ? nil : onConfirm)
            }
        }
    }
}
