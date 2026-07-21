import SwiftUI

/// Page surface for `FlareScreen` — mirrors the Vue contract.
public enum FlareScreenSurface { case canvas, surface, aurora }

/// FlareScreen — the base page scaffold every Flare business page builds on.
///
/// It owns the themed page surface (auto light/dark via `@Environment(\.colorScheme)`,
/// which follows the OS unless the app forces `.preferredColorScheme`), an optional
/// header (back / large title / actions), and a scrollable body. Business code
/// writes `FlareScreen(title: "设置", onBack: pop) { … }` and gets a consistent,
/// fully themeable page — no page-level colours are hard-coded.
public struct FlareScreen<Content: View>: View {
    private let title: String?
    private let onBack: (() -> Void)?
    private let surface: FlareScreenSurface
    private let padded: Bool
    private let scroll: Bool
    private let actions: AnyView?
    private let content: Content

    @Environment(\.colorScheme) private var scheme

    public init(
        title: String? = nil,
        onBack: (() -> Void)? = nil,
        surface: FlareScreenSurface = .canvas,
        padded: Bool = false,
        scroll: Bool = true,
        actions: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.onBack = onBack
        self.surface = surface
        self.padded = padded
        self.scroll = scroll
        self.actions = actions
        self.content = content()
    }

    private var hasHeader: Bool { title != nil || onBack != nil || actions != nil }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let base: Color = surface == .surface ? colors.bgPrimary : colors.bgSecondary
        VStack(spacing: 0) {
            if hasHeader {
                HStack(spacing: 8) {
                    if let onBack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(colors.textPrimary)
                        }
                    }
                    if let title {
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(colors.textPrimary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if let actions { actions }
                }
                .padding(.horizontal, FlareSizes.spacingMd)
                .padding(.vertical, FlareSizes.spacingSm)
            }
            if scroll {
                ScrollView { content.padding(padded ? FlareSizes.spacingLg : 0) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
                    .padding(padded ? FlareSizes.spacingLg : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                base
                // Aurora — a soft violet light wash at the top of the canvas.
                if surface == .aurora {
                    LinearGradient(colors: [colors.primary.opacity(0.16), Color.clear],
                                   startPoint: .top, endPoint: .center)
                }
            }
            .ignoresSafeArea()
        )
    }
}
