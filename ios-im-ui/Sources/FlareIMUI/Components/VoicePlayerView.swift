import SwiftUI

// MARK: - VoicePlayer

/// Voice player — playable voice message bubble with waveform, speed and transcript.
/// Spec: Message/VoicePlayer (`VoicePlayerView`).
public struct VoicePlayerView: View {
    private let durationLabel: String
    private let elapsedLabel: String?
    private let progress: Double
    private let playing: Bool
    private let amplitudes: [Double]
    private let speed: Double
    private let transcript: String?
    private let transcriptOpen: Bool
    private let unplayed: Bool
    private let outbound: Bool
    private let onToggle: (() -> Void)?
    private let onSeek: ((Double) -> Void)?
    private let onCycleSpeed: (() -> Void)?
    private let onToggleTranscript: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(durationLabel: String, elapsedLabel: String? = nil, progress: Double = 0,
                playing: Bool = false, amplitudes: [Double] = [], speed: Double = 1,
                transcript: String? = nil, transcriptOpen: Bool = false, unplayed: Bool = false,
                outbound: Bool = false, onToggle: (() -> Void)? = nil, onSeek: ((Double) -> Void)? = nil,
                onCycleSpeed: (() -> Void)? = nil, onToggleTranscript: (() -> Void)? = nil) {
        self.durationLabel = durationLabel; self.elapsedLabel = elapsedLabel; self.progress = progress
        self.playing = playing; self.amplitudes = amplitudes; self.speed = speed
        self.transcript = transcript; self.transcriptOpen = transcriptOpen; self.unplayed = unplayed
        self.outbound = outbound; self.onToggle = onToggle; self.onSeek = onSeek
        self.onCycleSpeed = onCycleSpeed; self.onToggleTranscript = onToggleTranscript
    }

    private static let barCount = 32

    private var bars: [Double] {
        if amplitudes.isEmpty {
            return (0..<Self.barCount).map { 0.3 + 0.4 * (sin(Double($0) * 0.5) * 0.5 + 0.5) }
        }
        var out = [Double]()
        for i in 0..<Self.barCount { out.append(amplitudes[i % amplitudes.count]) }
        return out
    }

    private var speedLabel: String {
        if speed == speed.rounded() {
            return "\(Int(speed))×"
        }
        return String(format: "%.1f×", speed)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 8) {
            bar(colors)
            if transcript != nil {
                transcriptSection(colors)
            }
        }
        .padding(12)
        .frame(width: 264)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(outbound ? colors.bgSelected : colors.bgPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(outbound ? colors.primary.opacity(0.24) : colors.borderPrimary, lineWidth: 1)
                )
        )
    }

    private func bar(_ colors: FlareColors) -> some View {
        HStack(spacing: 10) {
            playButton(colors)
            waveform(colors)
            Text(playing && elapsedLabel != nil ? elapsedLabel! : durationLabel)
                .font(.system(size: 12).monospacedDigit())
                .foregroundColor(colors.textTertiary)
            speedButton(colors)
        }
    }

    private func playButton(_ colors: FlareColors) -> some View {
        Button { onToggle?() } label: {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle().fill(
                        LinearGradient(colors: [colors.primary, colors.primary.opacity(0.82)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 14)).foregroundColor(.white)
                }
                .frame(width: 36, height: 36)
                if unplayed && !playing {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                        .overlay(Circle().stroke(colors.bgPrimary, lineWidth: 1.5))
                        .offset(x: 2, y: -2)
                }
            }
            .frame(width: 36, height: 36)
        }.buttonStyle(.plain)
    }

    private func waveform(_ colors: FlareColors) -> some View {
        let filled = Int((progress * Double(Self.barCount)).rounded())
        return GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(Array(bars.enumerated()), id: \.offset) { i, amp in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(i < filled ? colors.primary : colors.borderHover)
                        .frame(maxWidth: .infinity)
                        .frame(height: 4 + CGFloat(amp) * 18)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let ratio = max(0, min(1, value.location.x / geo.size.width))
                        onSeek?(ratio)
                    }
            )
        }
        .frame(height: 26)
    }

    private func speedButton(_ colors: FlareColors) -> some View {
        Button { onCycleSpeed?() } label: {
            Text(speedLabel)
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundColor(colors.textSecondary)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(colors.bgSecondary)
                    .overlay(Capsule().stroke(colors.borderPrimary, lineWidth: 1)))
        }.buttonStyle(.plain)
    }

    @ViewBuilder
    private func transcriptSection(_ colors: FlareColors) -> some View {
        Button { onToggleTranscript?() } label: {
            HStack(spacing: 5) {
                Image(systemName: "doc.text").font(.system(size: 11))
                Text(transcriptOpen ? "收起文字" : "转文字")
                    .font(.system(size: 12, weight: .medium))
            }.foregroundColor(colors.primary)
        }.buttonStyle(.plain)

        if let transcript, transcriptOpen {
            Divider().overlay(colors.borderPrimary)
            Text(transcript).font(.system(size: 13)).foregroundColor(colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
