import SwiftUI

/// Product authentication scaffold shared by Flare SwiftUI applications.
///
/// The design kit owns the responsive brand/form composition. Hosts provide
/// localized copy and their business controls through `content`.
public struct FlareAuthShell<Content: View>: View {
    private let product: String
    private let title: String
    private let subtitle: String
    private let tagline: String?
    private let headline: String?
    private let description: String?
    private let backLabel: String?
    private let onBack: (() -> Void)?
    private let content: Content

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var brand

    public init(
        product: String,
        title: String,
        subtitle: String,
        tagline: String? = nil,
        headline: String? = nil,
        description: String? = nil,
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
        self.backLabel = backLabel
        self.onBack = onBack
        self.content = content()
    }

    public var body: some View {
        FlareScreen(surface: .brand, scroll: false) {
            GeometryReader { proxy in
                let wide = proxy.size.width >= FlareSizes.appShellCompactMinWidth
                Group {
                    if wide {
                        let brandWidth = min(560, max(360, proxy.size.width * 0.44))
                        HStack(spacing: 0) {
                            brandPanel
                                .frame(width: brandWidth)
                                .frame(maxHeight: .infinity)
                            formPanel(showBrand: false)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(colors.bgPrimary)
                    } else {
                        formPanel(showBrand: true)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(colors.bgPrimary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    private var colors: FlareColors { FlareColors.of(scheme, brand: brand) }

    private var brandPanel: some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacing2xl) {
            brandLockup(logoSize: 72)
            Spacer(minLength: FlareSizes.spacing2xl)
            VStack(alignment: .leading, spacing: FlareSizes.spacingLg) {
                if let headline {
                    Text(headline)
                        .font(.system(size: FlareSizes.fontSize5xl, weight: .bold))
                        .foregroundStyle(colors.textPrimary)
                        .lineSpacing(4)
                }
                if let description {
                    Text(description)
                        .font(.system(size: FlareSizes.fontSize2xl))
                        .foregroundStyle(colors.textSecondary)
                        .lineSpacing(6)
                }
            }
            .frame(maxWidth: 420, alignment: .leading)
            Spacer(minLength: FlareSizes.spacing2xl)
        }
        .padding(56)
        .background(
            LinearGradient(
                colors: [colors.info.opacity(0.16), colors.primary.opacity(0.08), colors.bgSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func formPanel(showBrand: Bool) -> some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                if showBrand {
                    brandLockup(logoSize: 52)
                        .padding(.bottom, FlareSizes.spacing2xl)
                }
                if let backLabel, let onBack {
                    Button(action: onBack) {
                        Label(backLabel, systemImage: "arrow.left")
                            .font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                            .frame(minHeight: FlareSizes.touchTargetMin)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(colors.textLink)
                    .accessibilityLabel(backLabel)
                    .padding(.bottom, FlareSizes.spacingMd)
                }
                Text(title)
                    .font(.system(size: FlareSizes.fontSize5xl, weight: .bold))
                    .foregroundStyle(colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.system(size: FlareSizes.fontSize2xl))
                    .foregroundStyle(colors.textSecondary)
                    .lineSpacing(5)
                    .padding(.top, FlareSizes.spacingSm)
                    content
                        .padding(.top, FlareSizes.spacing2xl)
                }
                .frame(maxWidth: 500, alignment: .leading)
                .padding(.horizontal, showBrand ? FlareSizes.spacing2xl : 64)
                .padding(.vertical, showBrand ? FlareSizes.spacing2xl : 48)
                .frame(
                    maxWidth: .infinity,
                    minHeight: proxy.size.height,
                    alignment: showBrand ? .top : .center
                )
            }
            .background(colors.bgPrimary)
        }
    }

    private func brandLockup(logoSize: CGFloat) -> some View {
        HStack(spacing: FlareSizes.spacingLg) {
            FlareBrandLogo(size: logoSize)
            VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                Text(product)
                    .font(.system(size: FlareSizes.fontSize3xl, weight: .bold))
                    .foregroundStyle(colors.textPrimary)
                if let tagline {
                    Text(tagline)
                        .font(.system(size: FlareSizes.fontSizeSm, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(colors.primaryText)
                }
            }
        }
    }
}
