import SwiftUI

/// Presentation composition only: the host owns picking, bytes, transfer and local preview. An image input asks to
/// choose a picture and a document input to capture its side (the host reads `input.kind` and `input.side` from the
/// ``PluginFileAction`` to open its picker, camera or document capture); a file input chooses a file.
struct PluginFileUploadField: View {
    let input: PluginInput
    let state: PluginFileState?
    let disabled: Bool
    let onAction: (PluginFileActionKind) -> Void
    @Environment(\.flareStrings) private var strings

    private var phase: PluginFilePhase { state?.phase ?? .empty }
    private var status: String {
        if let error = state?.error, !error.isEmpty { return error }
        switch phase {
        case .empty: return Self.chooseText(input, strings)
        case .selected: return strings.pluginFileSelected
        case .uploading: return strings.pluginFileUploading
        case .uploaded: return state?.fileName ?? strings.pluginFileUploaded
        case .failed: return strings.pluginFileFailed
        }
    }
    /// The words of the choose key for the input's kind.
    static func chooseText(_ input: PluginInput, _ strings: FlareStrings) -> String {
        switch input.kind {
        case .image: return strings.pluginFormChooseImage
        case .document: return strings.pluginFormCaptureDocument
        default: return strings.pluginFileChoose
        }
    }

    /// A document input's side, as the slot's title says it ("证件正面"); nil for other kinds.
    static func sideText(_ input: PluginInput, _ strings: FlareStrings) -> String? {
        guard input.kind == .document, let side = input.side else { return nil }
        switch side {
        case .front: return strings.pluginFormDocumentFront
        case .back: return strings.pluginFormDocumentBack
        case .holding: return strings.pluginFormDocumentHolding
        }
    }

    private var slotState: FlareImageUploadState {
        switch phase {
        case .empty: return .empty
        case .selected, .uploading: return .uploading
        case .uploaded: return .uploaded
        case .failed: return .failed
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            ImageUploadSlotView(title: Self.sideText(input, strings) ?? input.label, state: slotState, statusText: status,
                actionText: Self.chooseText(input, strings), retryText: strings.retry, disabled: disabled,
                onChoose: { onAction(.choose) }, onRetry: state?.fileName != nil ? { onAction(.retry) } : nil,
                previewLabel: state?.preview == true ? strings.pluginFilePreview : nil,
                previewLoading: state?.previewLoading ?? false, previewDisabled: disabled,
                onPreview: state?.preview == true ? { onAction(.preview) } : nil)
            if let progress = state?.progress, progress.isFinite, phase == .uploading {
                ProgressView(value: min(1, max(0, progress)))
                    .accessibilityLabel(strings.pluginFileUploading)
            }
            if phase != .empty {
                HStack(spacing: FlareSizes.spacingSm) {
                    if phase == .uploading || phase == .selected {
                        ButtonView(label: strings.cancel, variant: .secondary, size: .sm, disabled: disabled) { onAction(.cancel) }
                    } else {
                        ButtonView(label: strings.pluginFileReplace, variant: .secondary, size: .sm, disabled: disabled) { onAction(.replace) }
                        ButtonView(label: strings.pluginFileRemove, variant: .text, size: .sm, disabled: disabled) { onAction(.remove) }
                    }
                }
            }
        }
    }
}
