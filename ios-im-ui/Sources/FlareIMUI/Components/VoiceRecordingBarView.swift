import SwiftUI

// MARK: - VoiceRecordingBar

/// Voice recording bar — live capsule with waveform, duration and cancel / send.
/// Spec: Composer/VoiceRecordingBar (`VoiceRecordingBarView`).
public struct VoiceRecordingBarView: View {
    private let durationLabel: String
    private let amplitudes: [Double]
    private let cancelling: Bool
    private let onCancel: (() -> Void)?
    private let onSend: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var blink = false

    public init(durationLabel: String, amplitudes: [Double] = [], cancelling: Bool = false,
                onCancel: (() -> Void)? = nil, onSend: (() -> Void)? = nil) {
        self.durationLabel = durationLabel; self.amplitudes = amplitudes; self.cancelling = cancelling
        self.onCancel = onCancel; self.onSend = onSend
    }

    private static let barCount = 28

    private var bars: [Double] {
        if amplitudes.isEmpty {
            return (0..<Self.barCount).map { 0.35 + 0.35 * (sin(Double($0) * 0.6) * 0.5 + 0.5) }
        }
        var out = [Double]()
        for i in 0..<Self.barCount { out.append(amplitudes[i % amplitudes.count]) }
        return out
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: FlareSizes.spacingMd) {
            cancelButton(colors)
            center(colors)
            right(colors)
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(
            Capsule().fill(cancelling ? colors.error.opacity(0.08) : colors.bgPrimary)
                .overlay(Capsule().stroke(cancelling ? colors.error.opacity(0.4) : colors.borderPrimary, lineWidth: 1))
        )
        .shadow(color: Color.black.opacity(0.12), radius: 14, y: 6)
    }

    private func cancelButton(_ colors: FlareColors) -> some View {
        Button { onCancel?() } label: {
            ZStack {
                Circle().fill(cancelling ? colors.error : colors.bgSecondary)
                Image(systemName: "trash").font(.system(size: 14))
                    .foregroundColor(cancelling ? .white : colors.textSecondary)
            }
            .frame(width: 36, height: 36)
        }.buttonStyle(.plain)
    }

    private func center(_ colors: FlareColors) -> some View {
        HStack(spacing: 8) {
            Circle().fill(Color.red).frame(width: 9, height: 9)
                .opacity(blink ? 0.25 : 1)
                .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: blink)
                .onAppear { blink = true }
            Text(durationLabel).font(.system(size: 13).monospacedDigit())
                .foregroundColor(colors.textPrimary)
            HStack(spacing: 2) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, amp in
                    Capsule()
                        .fill(cancelling ? colors.error : colors.primary.opacity(0.7))
                        .frame(width: 2, height: 4 + CGFloat(amp) * 20)
                }
            }
            .frame(height: 24)
        }
    }

    @ViewBuilder
    private func right(_ colors: FlareColors) -> some View {
        if cancelling {
            Text("松开取消").font(.system(size: 12, weight: .medium))
                .foregroundColor(colors.error)
                .padding(.trailing, 6)
        } else {
            Button { onSend?() } label: {
                ZStack {
                    Circle().fill(
                        LinearGradient(colors: [colors.primary, colors.primary.opacity(0.82)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "paperplane.fill").font(.system(size: 14)).foregroundColor(.white)
                }
                .frame(width: 36, height: 36)
            }.buttonStyle(.plain)
        }
    }
}
