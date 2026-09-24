import SwiftUI
import AVFoundation

/// Native capture/preview adapter. Message delivery remains a host responsibility.
@MainActor
private final class InlineVoiceCapture: ObservableObject {
    @Published var recording = false
    @Published var paused = false
    @Published var busy = false
    @Published var playing = false
    @Published var sending = false
    @Published var elapsed: TimeInterval = 0
    @Published var error: String?
    /// What the recorder says when it cannot record or cannot send. Set from the strings table by the
    /// view — a Chinese-first kit cannot keep these two in English because they live in a model.
    var copy = (micDenied: FlareStrings().inlineVoiceComposerMicDenied,
                sendFailed: FlareStrings().inlineVoiceComposerSendFailed)
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var segments: [URL] = []
    private var clip: URL?
    private var accumulated: TimeInterval = 0
    private var generation = 0
    private var settings: [String: Any] { [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 16000, AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false] }
    func start() async {
        guard !busy, elapsed < 65 else { return }
        generation += 1; let request = generation; busy = true; error = nil
        defer { if request == generation { busy = false } }
        let permitted = await AVCaptureDevice.requestAccess(for: .audio)
        guard request == generation else { return }
        guard permitted else { error = copy.micDenied; return }
        do {
            player?.stop(); playing = false
            #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            #endif
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("flare-voice-\(UUID().uuidString).wav")
            let next = try AVAudioRecorder(url: url, settings: settings)
            guard next.record() else { throw CocoaError(.fileWriteUnknown) }
            recorder = next; segments.append(url); recording = true; paused = false
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.elapsed = min(65, self.accumulated + (self.recorder?.currentTime ?? 0))
                    if self.elapsed >= 65 { self.pause() }
                }
            }
        } catch { self.error = error.localizedDescription }
    }
    func pause() {
        guard recording else { return }
        accumulated = min(65, accumulated + (recorder?.currentTime ?? 0)); elapsed = accumulated
        recorder?.stop(); recorder = nil; recording = false; paused = true; timer?.invalidate()
        do { try assemble() } catch { self.error = error.localizedDescription }
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
    private func assemble() throws {
        player?.stop(); player = nil; playing = false
        if let clip { try? FileManager.default.removeItem(at: clip) }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("flare-voice-preview-\(UUID().uuidString).wav")
        let output = try AVAudioFile(forWriting: url, settings: settings)
        for segment in segments {
            let input = try AVAudioFile(forReading: segment)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: input.processingFormat, frameCapacity: 4096) else { continue }
            while input.framePosition < input.length {
                try input.read(into: buffer); try output.write(from: buffer)
            }
        }
        clip = url
    }
    func preview() {
        guard let clip else { return }
        do {
            if player?.isPlaying == true { player?.pause(); playing = false; return }
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            if player == nil { player = try AVAudioPlayer(contentsOf: clip) }
            playing = player?.play() == true
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in Task { @MainActor in self?.playing = self?.player?.isPlaying == true } }
        } catch { self.error = error.localizedDescription }
    }
    func send(_ action: (URL, Int) async -> Bool) async -> Bool {
        guard !busy, let clip, elapsed >= 0.25 else { return false }
        busy = true; sending = true; player?.stop(); playing = false
        let accepted = await action(clip, Int(elapsed * 1000))
        busy = false; sending = false
        if accepted { self.clip = nil; cancel() } else { error = copy.sendFailed }
        return accepted
    }
    func cancel() {
        generation += 1; timer?.invalidate(); recorder?.stop(); recorder = nil; player?.stop(); player = nil
        for url in segments { try? FileManager.default.removeItem(at: url) }; segments = []
        if let clip, !sending { try? FileManager.default.removeItem(at: clip) }; clip = nil
        accumulated = 0; elapsed = 0; recording = false; paused = false; playing = false; busy = false
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
}

public struct InlineVoiceComposerView: View {
    private let disabled: Bool
    private let onKeyboard: () -> Void
    private let onSend: (URL, Int) async -> Bool
    @StateObject private var capture = InlineVoiceCapture()
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.scenePhase) private var phase
    @Environment(\.flareStrings) private var strings
    public init(disabled: Bool = false, onKeyboard: @escaping () -> Void, onSend: @escaping (URL, Int) async -> Bool) {
        self.disabled = disabled; self.onKeyboard = onKeyboard; self.onSend = onSend
    }
    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                control("keyboard", strings.inlineVoiceComposerKeyboard, enabled: !capture.sending) { capture.cancel(); onKeyboard() }
                if capture.paused {
                    control(capture.playing ? "pause" : "play", strings.inlineVoiceComposerPreview, enabled: !capture.busy) { capture.preview() }
                } else {
                    control(capture.recording ? "pause" : "mic", capture.recording ? strings.inlineVoiceComposerPause : strings.inlineVoiceComposerStart, accent: true, enabled: !capture.busy && !disabled) { if capture.recording { capture.pause() } else { Task { await capture.start() } } }
                }
                Canvas { context, size in
                    for x in stride(from: CGFloat(2), to: size.width, by: 6) {
                        let h = CGFloat(4 + Int(x) % 20)
                        let rect = CGRect(x: x, y: (size.height-h)/2, width: 2, height: h)
                        context.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(capture.recording || capture.paused ? colors.primary.opacity(0.45) : colors.borderPrimary))
                    }
                }.frame(height: 28).accessibilityHidden(true)
                Text(String(format: "%02d:%02d", Int(capture.elapsed)/60, Int(capture.elapsed)%60)).font(.system(size: 11, design: .monospaced)).foregroundColor(colors.textSecondary)
                if capture.paused {
                    control("mic", strings.inlineVoiceComposerResume, accent: true, enabled: !capture.busy && capture.elapsed < 65) { Task { await capture.start() } }
                    control("delete", strings.inlineVoiceComposerDiscard, enabled: !capture.busy) { capture.cancel() }
                    control("send", strings.send, accent: true, enabled: !capture.busy && !disabled && capture.elapsed >= 0.25) { Task { if await capture.send(onSend) { onKeyboard() } } }
                }
            }
            .padding(.horizontal, 3).padding(.vertical, 6)
            .background(colors.bgPrimary).clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusCard))
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusCard).strokeBorder(colors.borderPrimary, lineWidth: 1))
            if let error = capture.error { Text(error).font(.caption).foregroundColor(colors.errorText) }
        }
        // The recorder's own two messages come from the strings table, which only the view can read.
        .onAppear { capture.copy = (strings.inlineVoiceComposerMicDenied, strings.inlineVoiceComposerSendFailed) }
        .onDisappear { capture.cancel() }
        .onChange(of: disabled) { value in if value { capture.cancel() } }
        .onChange(of: phase) { value in if value != .active { capture.pause() } }
    }
    /// A recorder key: the kit icon `icon` in a 44pt target, named `label` from the strings table.
    private func control(_ icon: String, _ label: String, accent: Bool = false, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: flareIconSymbol(icon)).font(.system(size: 20, weight: .regular)).frame(width: FlareSizes.touchTargetMin, height: FlareSizes.touchTargetMin).contentShape(Rectangle()) }
            .buttonStyle(.plain).foregroundColor(accent ? FlareColors.of(scheme, brand: flareBrandTheme).primary : FlareColors.of(scheme, brand: flareBrandTheme).textSecondary)
            .disabled(!enabled).accessibilityLabel(label).help(label)
    }
}
