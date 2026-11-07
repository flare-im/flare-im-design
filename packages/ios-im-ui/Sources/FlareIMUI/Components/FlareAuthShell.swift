import SwiftUI

/// The shared product entry for account, registration and recovery flows.
/// Hosts provide localized copy and their form; the kit owns brand, layout and scrolling.
public struct FlareAuthShell<Content: View>: View {
    private let product: String
    private let title: String
    private let subtitle: String
    private let tagline: String?
    private let headline: String?
    private let description: String?
    private let eyebrow: String?
    private let footer: String?
    private let backLabel: String?
    private let onBack: (() -> Void)?
    private let content: Content

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var brand
    @ScaledMetric(relativeTo: .title) private var titleSize = FlareSizes.fontSizeAuthTitle
    @ScaledMetric(relativeTo: .largeTitle) private var headlineSize = FlareSizes.fontSizeAuthHeadline
    @ScaledMetric(relativeTo: .body) private var bodySize = FlareSizes.fontSize2xl
    @ScaledMetric(relativeTo: .headline) private var wordmarkSize = FlareSizes.fontSize4xl
    @ScaledMetric(relativeTo: .caption) private var captionSize = FlareSizes.fontSizeSm

    public init(
        product: String,
        title: String,
        subtitle: String,
        tagline: String? = nil,
        headline: String? = nil,
        description: String? = nil,
        eyebrow: String? = nil,
        footer: String? = nil,
        backLabel: String? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.product = product
        self.title = title
        self.subtitle = subtitle
        self.tagline = tagline
        self.headline = headline
        self.description = description
        self.eyebrow = eyebrow
        self.footer = footer
        self.backLabel = backLabel
        self.onBack = onBack
        self.content = content()
    }

    public var body: some View {
        FlareScreen(surface: .surface, scroll: false) {
            GeometryReader { proxy in
                let wide = proxy.size.width >= FlareSizes.appShellCompactMinWidth
                HStack(spacing: 0) {
                    if wide {
                        brandPanel
                            .frame(width: proxy.size.width * 0.44)
                            .overlay(alignment: .trailing) {
                                colors.borderPrimary.frame(width: 1)
                            }
                    }
                    formPanel(showBrand: !wide)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(pageBackground.ignoresSafeArea())
            }
        }
    }

    private var colors: FlareColors { FlareColors.of(scheme, brand: brand) }

    private var pageBackground: some View {
        LinearGradient(colors: [colors.primary.opacity(0.10), .clear],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .background(colors.bgSecondary)
    }

    private var brandPanel: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    brandLockup(logoSize: FlareSizes.authBrandLogoSize)
                    Spacer(minLength: FlareSizes.spacing2xl * 2)
                    VStack(alignment: .leading, spacing: FlareSizes.spacingLg) {
                        if let headline {
                            Text(headline)
                                .font(.system(size: headlineSize, weight: .bold))
                                .foregroundStyle(colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if let description {
                            Text(description)
                                .font(.system(size: bodySize))
                                .foregroundStyle(colors.textSecondary)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        FlareAuthBrandArtwork(colors: colors)
                            .aspectRatio(1.6, contentMode: .fit)
                            .frame(maxWidth: FlareSizes.authArtworkWidth)
                            .padding(.top, FlareSizes.spacingXl)
                    }
                    .frame(maxWidth: FlareSizes.authFormMaxWidth, alignment: .leading)
                    Spacer(minLength: FlareSizes.spacing2xl * 2)
                }
                .padding(FlareSizes.spacing2xl * 2)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .topLeading)
            }
            .background(colors.bgSelected)
        }
    }

    private func formPanel(showBrand: Bool) -> some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: FlareSizes.spacing2xl) {
                    if showBrand {
                        brandLockup(logoSize: FlareSizes.authMobileLogoSize)
                            .frame(maxWidth: FlareSizes.authFormMaxWidth, alignment: .leading)
                    }
                    taskSurface(compact: showBrand)
                }
                .frame(maxWidth: FlareSizes.authFormMaxWidth, alignment: .leading)
                .padding(.horizontal, showBrand ? FlareSizes.spacing2xl : FlareSizes.spacing2xl * 2)
                .padding(.vertical, showBrand ? FlareSizes.spacing2xl : FlareSizes.spacing2xl * 2)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height,
                       alignment: showBrand ? .top : .center)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    /// One task surface keeps the heading, fields and recovery feedback together.
    /// It stays in the scroll view so neither the keyboard nor a short screen clips it.
    private func taskSurface(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let backLabel, let onBack {
                Button(action: onBack) {
                    Label(backLabel, systemImage: "arrow.left")
                        .font(.system(size: bodySize, weight: .semibold))
                        .frame(minWidth: FlareSizes.touchTargetMin, minHeight: FlareSizes.touchTargetMin)
                }
                .buttonStyle(.plain)
                .foregroundStyle(colors.textLink)
                .accessibilityLabel(backLabel)
                .padding(.bottom, FlareSizes.spacingMd)
            }
            if let eyebrow {
                Text(eyebrow)
                    .font(.system(size: captionSize, weight: .semibold))
                    .foregroundStyle(colors.primaryText)
                    .tracking(1)
                    .padding(.bottom, FlareSizes.spacingSm)
            }
            Text(title)
                .font(.system(size: titleSize, weight: .bold))
                .foregroundStyle(colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.system(size: bodySize))
                .foregroundStyle(colors.textSecondary)
                .lineSpacing(4)
                .padding(.top, FlareSizes.spacingSm)
                .fixedSize(horizontal: false, vertical: true)
            content
                .padding(.top, FlareSizes.spacing2xl)
            if let footer {
                Text(footer)
                    .font(.system(size: captionSize))
                    .foregroundStyle(colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, FlareSizes.spacing2xl)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(compact ? FlareSizes.spacingXl : FlareSizes.spacing2xl)
        .frame(maxWidth: FlareSizes.authFormMaxWidth, alignment: .leading)
        .background(colors.bgPrimary, in: RoundedRectangle(cornerRadius: FlareSizes.radius2xl, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: FlareSizes.radius2xl, style: .continuous)
                .strokeBorder(colors.borderPrimary, lineWidth: 1)
                .allowsHitTesting(false)
        }
        .flareShadow(FlareShadows.of(scheme).sm)
    }

    private func brandLockup(logoSize: CGFloat) -> some View {
        HStack(spacing: FlareSizes.spacingMd) {
            FlareBrandLogo(size: logoSize)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                Text(product)
                    .font(.system(size: wordmarkSize, weight: .bold))
                    .foregroundStyle(colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let tagline {
                    Text(tagline)
                        .font(.system(size: captionSize))
                        .foregroundStyle(colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// Static linked-message geometry shared with Vue, Compose and Flutter.
/// It is brand artwork, not a preview of a person's conversation.
private struct FlareAuthBrandArtwork: View {
    let colors: FlareColors

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 320, y: size.height / 200)
            var rear = Path()
            rear.move(to: CGPoint(x: 48, y: 24))
            rear.addLine(to: CGPoint(x: 200, y: 24))
            rear.addQuadCurve(to: CGPoint(x: 220, y: 44), control: CGPoint(x: 220, y: 24))
            rear.addLine(to: CGPoint(x: 220, y: 120))
            rear.addQuadCurve(to: CGPoint(x: 200, y: 140), control: CGPoint(x: 220, y: 140))
            rear.addLine(to: CGPoint(x: 80, y: 140))
            rear.addLine(to: CGPoint(x: 58, y: 158))
            rear.addLine(to: CGPoint(x: 58, y: 140))
            rear.addLine(to: CGPoint(x: 48, y: 140))
            rear.addQuadCurve(to: CGPoint(x: 28, y: 120), control: CGPoint(x: 28, y: 140))
            rear.addLine(to: CGPoint(x: 28, y: 44))
            rear.addQuadCurve(to: CGPoint(x: 48, y: 24), control: CGPoint(x: 28, y: 24))
            rear.closeSubpath()
            context.fill(rear, with: .color(colors.bgSelected))
            context.stroke(rear, with: .color(colors.primaryText.opacity(0.24)), lineWidth: 1.5)

            var front = Path()
            front.move(to: CGPoint(x: 138, y: 82))
            front.addLine(to: CGPoint(x: 274, y: 82))
            front.addQuadCurve(to: CGPoint(x: 292, y: 100), control: CGPoint(x: 292, y: 82))
            front.addLine(to: CGPoint(x: 292, y: 160))
            front.addQuadCurve(to: CGPoint(x: 274, y: 178), control: CGPoint(x: 292, y: 178))
            front.addLine(to: CGPoint(x: 258, y: 178))
            front.addLine(to: CGPoint(x: 258, y: 194))
            front.addLine(to: CGPoint(x: 238, y: 178))
            front.addLine(to: CGPoint(x: 138, y: 178))
            front.addQuadCurve(to: CGPoint(x: 120, y: 160), control: CGPoint(x: 120, y: 178))
            front.addLine(to: CGPoint(x: 120, y: 100))
            front.addQuadCurve(to: CGPoint(x: 138, y: 82), control: CGPoint(x: 120, y: 82))
            front.closeSubpath()
            context.fill(front, with: .color(colors.bgPrimary))
            context.stroke(front, with: .color(colors.primaryText.opacity(0.55)), lineWidth: 1.5)
            for x in [CGFloat(166), 198, 230] {
                context.fill(Path(ellipseIn: CGRect(x: x - 4, y: 126, width: 8, height: 8)),
                             with: .color(colors.primaryText.opacity(0.70)))
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
