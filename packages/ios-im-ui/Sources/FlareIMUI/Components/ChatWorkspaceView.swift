import SwiftUI

/// Coherent Context -> Header -> Timeline -> Composer chat surface.
public struct ChatWorkspaceView<Header: View, Context: View, Timeline: View, Composer: View>: View {
    private let header: Header
    private let context: Context
    private let timeline: Timeline
    private let composer: Composer
    private let semanticLabel: String?

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(
        semanticLabel: String? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder context: () -> Context,
        @ViewBuilder timeline: () -> Timeline,
        @ViewBuilder composer: () -> Composer
    ) {
        self.semanticLabel = semanticLabel
        self.header = header(); self.context = context(); self.timeline = timeline(); self.composer = composer()
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(spacing: 0) {
            context.padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
                .background(colors.bgPrimary)
            header
            timeline.frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider().overlay(colors.borderPrimary)
            composer.background(colors.bgPrimary)
        }
        .background(colors.bgSecondary)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(semanticLabel ?? "Conversation")
    }
}

public extension ChatWorkspaceView where Context == EmptyView {
    init(
        semanticLabel: String? = nil,
        @ViewBuilder header: () -> Header,
        @ViewBuilder timeline: () -> Timeline,
        @ViewBuilder composer: () -> Composer
    ) {
        self.init(semanticLabel: semanticLabel, header: header, context: { EmptyView() }, timeline: timeline, composer: composer)
    }
}
