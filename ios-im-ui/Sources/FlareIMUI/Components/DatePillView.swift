import SwiftUI

// MARK: - DatePill

/// Date pill — centered floating day separator chip.
/// Spec: Message/DatePill (`DatePillView`).
public struct DatePillView: View {
    private let label: String
    private let floating: Bool
    @Environment(\.colorScheme) private var scheme

    public init(label: String, floating: Bool = false) {
        self.label = label; self.floating = floating
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack {
            Spacer()
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(colors.textSecondary)
                .padding(.vertical, 3).padding(.horizontal, 12)
                .background(Capsule().fill(colors.bgPrimary.opacity(0.78))
                    .overlay(Capsule().stroke(colors.borderPrimary, lineWidth: 1)))
                .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
            Spacer()
        }
    }
}
