import CoreGraphics

/// How far a message row has been dragged sideways, and whether letting go of it now starts a reply.
struct FlareSwipeReplyGesture: Equatable {
    /// How far the row is drawn from its resting place, in points. Never negative: the direction is the
    /// layout's leading edge.
    let travel: CGFloat
    /// Whether releasing now replies. The affordance is fully drawn here, so the reader knows before
    /// letting go.
    let armed: Bool

    static let none = FlareSwipeReplyGesture(travel: 0, armed: false)
}

/// The one swipe-to-reply rule, shared with the Flutter and Compose kits and tested against
/// `spec/swipe-reply-vectors.json`: only the leading direction counts (mirrored under RTL), the list's own
/// scrolling wins a drag that is not mostly horizontal, and the row follows the finger to ``armDistance``
/// before resisting and stopping at ``maxTravel``.
enum FlareSwipeReply {
    /// Gesture geometry, in points. These are distances a hand works in rather than visual styling, so they
    /// are constants and not design tokens — and they are the same three numbers in the Flutter and Compose
    /// kits.
    static let armDistance: CGFloat = 56
    static let maxTravel: CGFloat = 72
    private static let resistance: CGFloat = 0.35
    private static let dominance: CGFloat = 1.25

    /// `dx` and `dy` are the drag's travel from where the finger went down.
    static func resolve(dx: CGFloat, dy: CGFloat, rtl: Bool) -> FlareSwipeReplyGesture {
        let leading = rtl ? dx < 0 : dx > 0
        guard leading else { return .none }
        let horizontal = abs(dx)
        // A drag that is mostly vertical belongs to the timeline's own scrolling.
        guard horizontal >= abs(dy) * dominance else { return .none }
        let travel = horizontal <= armDistance
            ? horizontal
            : min(maxTravel, armDistance + (horizontal - armDistance) * resistance)
        return FlareSwipeReplyGesture(travel: travel, armed: travel >= armDistance)
    }
}
