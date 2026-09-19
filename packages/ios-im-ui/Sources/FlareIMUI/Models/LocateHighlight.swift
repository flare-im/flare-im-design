import CoreGraphics
import Foundation
import SwiftUI

/// The mark a located row wears while the reader's eye catches up with the jump.
struct FlareLocateHighlightValue: Equatable {
    /// Whether the row is marked at all. False once the window is over.
    let marked: Bool
    /// The ring's opacity.
    let alpha: Double
    /// How far the ring reaches beyond the bubble's edge, in points.
    let spread: CGFloat

    static let none = FlareLocateHighlightValue(marked: false, alpha: 0, spread: 0)
}

/// The one locate-mark rule, shared with the Flutter and Compose kits and with Vue's stylesheet, and tested
/// against `spec/locate-highlight-vectors.json`.
enum FlareLocateHighlight {
    /// How long a located row stays marked. One number: the ring reaches nothing exactly as the window closes.
    static let durationMs: Double = 1600

    private static let stops: [(atMs: Double, alpha: Double, spread: CGFloat)] = [
        (0, 0.36, 0),
        (700, 0.18, 10),
        (durationMs, 0, 18),
    ]

    /// Held still for a reader who asked for less motion: the middle stop, for the whole window. Less motion
    /// is not no answer — the jump still has to say where it landed.
    private static let reducedMotion = FlareLocateHighlightValue(marked: true, alpha: 0.18, spread: 10)

    /// `elapsedMs` counts from the moment the list started moving towards the row.
    static func resolve(elapsedMs: Double, reduceMotion: Bool) -> FlareLocateHighlightValue {
        guard elapsedMs < durationMs else { return .none }
        guard !reduceMotion else { return reducedMotion }
        let elapsed = max(0, elapsedMs)
        for index in 0..<(stops.count - 1) {
            let from = stops[index]
            let to = stops[index + 1]
            if elapsed > to.atMs { continue }
            let t = (elapsed - from.atMs) / (to.atMs - from.atMs)
            return FlareLocateHighlightValue(
                marked: true,
                alpha: from.alpha + (to.alpha - from.alpha) * t,
                spread: from.spread + (to.spread - from.spread) * t
            )
        }
        return .none
    }
}

/// Which row is marked after a jump, and when its window started. The list owns both and puts them in the
/// environment; a bubble takes the mark only when it is the marked one. One row at a time: a second jump
/// replaces this value rather than adding to it.
struct FlareLocateMark: Equatable {
    let messageId: String?
    let startedAt: Date

    static let none = FlareLocateMark(messageId: nil, startedAt: .distantPast)
}

private struct FlareLocateMarkKey: EnvironmentKey {
    static let defaultValue = FlareLocateMark.none
}

extension EnvironmentValues {
    var flareLocateMark: FlareLocateMark {
        get { self[FlareLocateMarkKey.self] }
        set { self[FlareLocateMarkKey.self] = newValue }
    }
}
