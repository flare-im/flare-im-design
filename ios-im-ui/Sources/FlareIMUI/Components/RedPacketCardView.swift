import SwiftUI

// MARK: - RedPacketCard

/// Red packet card — festive lucky-money envelope with open / claimed states.
/// Spec: Message/RedPacketCard (`RedPacketCardView`).
public struct RedPacketCardView: View {
    private let blessing: String
    private let amount: String?
    private let opened: Bool
    private let finished: Bool
    private let onOpen: (() -> Void)?

    public init(blessing: String, amount: String? = nil, opened: Bool = false,
                finished: Bool = false, onOpen: (() -> Void)? = nil) {
        self.blessing = blessing; self.amount = amount; self.opened = opened
        self.finished = finished; self.onOpen = onOpen
    }

    private let gold = Color(.sRGB, red: 1.0, green: 0.831, blue: 0.463, opacity: 1)

    public var body: some View {
        Button { onOpen?() } label: { card }
            .buttonStyle(.plain)
            .disabled(finished)
    }

    private var card: some View {
        HStack(spacing: FlareSizes.spacingMd) {
            ZStack {
                Circle().fill(
                    RadialGradient(colors: [Color(.sRGB, red: 1.0, green: 0.914, blue: 0.722, opacity: 1),
                                            Color(.sRGB, red: 0.965, green: 0.769, blue: 0.325, opacity: 1)],
                                   center: .center, startRadius: 2, endRadius: 24))
                    .frame(width: 42, height: 42)
                Image(systemName: "gift.fill").font(.system(size: 18))
                    .foregroundColor(Color(.sRGB, red: 0.784, green: 0.161, blue: 0.122, opacity: 1))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(blessing).font(.system(size: 14, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                status
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 248)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(
                LinearGradient(colors: [Color(.sRGB, red: 0.941, green: 0.314, blue: 0.235, opacity: 1),
                                        Color(.sRGB, red: 0.886, green: 0.231, blue: 0.180, opacity: 1),
                                        Color(.sRGB, red: 0.784, green: 0.161, blue: 0.122, opacity: 1)],
                               startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            Text("Flare 红包").font(.system(size: 10)).foregroundColor(.white.opacity(0.5))
                .padding(10),
            alignment: .bottomTrailing
        )
        .saturation(finished ? 0.55 : 1)
        .brightness(finished ? -0.03 : 0)
        .shadow(color: Color(.sRGB, red: 0.784, green: 0.161, blue: 0.122, opacity: 1).opacity(0.35), radius: 16, y: 8)
    }

    @ViewBuilder
    private var status: some View {
        if opened, let amount {
            HStack(spacing: 4) {
                Text("已领取 · ").font(.system(size: 12)).foregroundColor(.white.opacity(0.85))
                    + Text(amount).font(.system(size: 12, weight: .semibold)).foregroundColor(gold)
            }
        } else if finished {
            Text("已被抢光").font(.system(size: 12)).foregroundColor(.white.opacity(0.85))
        } else {
            Text("点击拆开").font(.system(size: 12)).foregroundColor(.white.opacity(0.85))
        }
    }
}
