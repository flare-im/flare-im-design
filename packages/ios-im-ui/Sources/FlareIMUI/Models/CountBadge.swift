import Foundation

// A count badge: a navigation item's count badge and a filter tab's badge (`spec/count-badge-vectors.json`, the same on
// all four kits). A badge takes a count and `more`, which says there are more than the count — the server had more than
// the one page it counted — and is false when left out.

/// The badge's text: 99+ when `more` or when `count` is above 99, else the count; a missing or negative count is 0.
public func flareCountBadgeText(count: Int?, more: Bool = false) -> String {
    let value = count ?? 0
    return more || value > 99 ? "99+" : String(max(0, value))
}

/// Whether a filter tab draws its badge: a count above 0, or `more`.
public func flareCountBadgeDrawn(count: Int?, more: Bool = false) -> Bool {
    more || (count ?? 0) > 0
}
