import SwiftUI

// The vocabulary 2 blocks of ``PluginView`` (spec Message/PluginView, `spec/plugin-view-vectors.json` → blocks2): a
// section, stats, a chart, an image, a QR code, a hero, steps, a banner and a timeline. Each draws resolved values
// only, with kit tokens and kit components; actions the hero or the banner own go back through ``PluginView``'s runner
// (confirm, form, then `onAction`).

/// A section: its label as a collapsible header (`collapsed` is how it starts) and its blocks; without a label the
/// blocks always show.
struct PluginSectionBlockView: View {
    let block: PluginSectionBlock
    let child: (Int, PluginBlock) -> AnyView
    @State private var expanded: Bool
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    init(block: PluginSectionBlock, child: @escaping (Int, PluginBlock) -> AnyView) {
        self.block = block; self.child = child
        self._expanded = State(initialValue: !block.collapsed)
    }

    private var label: String? { block.label.flatMap { $0.isEmpty ? nil : $0 } }

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            if let label {
                Button { expanded.toggle() } label: {
                    HStack(spacing: FlareSizes.spacingXs) {
                        Text(label)
                            .font(.system(size: FlareSizes.fontSizeMd * textScale, weight: .semibold))
                            .foregroundColor(colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        FlareIconImage(name: expanded ? "chevron-up" : "chevron-down",
                                       size: FlareSizes.iconSizeSm * textScale, weight: .semibold)
                            .foregroundColor(colors.textTertiary)
                    }
                    .frame(minHeight: FlareSizes.touchTargetMin)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isHeader)
                .accessibilityValue(expanded ? strings.collapse : strings.expand)
            }
            if expanded || label == nil {
                ForEach(Array(block.blocks.enumerated()), id: \.offset) { index, item in child(index, item) }
            }
        }
    }
}

/// The colour of a stat's value: its tone's ink, else the primary text.
func pluginStatColor(_ tone: PluginTone?, _ colors: FlareColors) -> Color {
    guard let tone, tone != .neutral else { return colors.textPrimary }
    return pluginToneText(tone, colors)
}

/// 2 to 6 figures in a grid: two columns, three for three or six figures.
struct PluginStatsBlockView: View {
    let block: PluginStatsBlock
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// Columns of the grid: three for three or six figures, else two.
    static func columns(_ count: Int) -> Int { count == 3 || count == 6 ? 3 : 2 }

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let columns = Array(repeating: GridItem(.flexible(), spacing: FlareSizes.spacingSm, alignment: .topLeading),
                            count: Self.columns(block.items.count))
        LazyVGrid(columns: columns, alignment: .leading, spacing: FlareSizes.spacingSm) {
            ForEach(Array(block.items.enumerated()), id: \.offset) { _, item in stat(item, colors) }
        }
    }

    private func stat(_ item: PluginStat, _ colors: FlareColors) -> some View {
        let value = PluginFormatRules.text(item.value, item.format, strings)
        return VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
            Text(item.label)
                .font(.system(size: FlareSizes.fontSizeSm * textScale))
                .foregroundColor(colors.textSecondary)
                .lineLimit(1)
            Text(value)
                .font(.system(size: FlareSizes.fontSize2xl * textScale, weight: .semibold).monospacedDigit())
                .foregroundColor(pluginStatColor(item.tone, colors))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let trend = item.trend, !trend.text.isEmpty { PluginTrendView(trend: trend) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FlareSizes.spacingSm)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd, style: .continuous).fill(colors.bgSecondary))
        .accessibilityElement(children: .combine)
    }
}

/// A trend: an arrow (none when flat) and the text, success up, error down, secondary flat; the direction is said.
struct PluginTrendView: View {
    let trend: PluginTrend
    @ScaledMetric(relativeTo: .caption) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    static func words(_ direction: PluginTrendDirection, _ strings: FlareStrings) -> String {
        switch direction {
        case .up: return strings.pluginViewTrendUp
        case .down: return strings.pluginViewTrendDown
        case .flat: return strings.pluginViewTrendFlat
        }
    }

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let ink: Color = trend.direction == .up ? colors.successText : trend.direction == .down ? colors.errorText
            : colors.textSecondary
        HStack(spacing: FlareSizes.spacing3xs) {
            if trend.direction != .flat {
                FlareIconImage(name: "arrow-down", size: FlareSizes.fontSizeSm * textScale, weight: .semibold)
                    .rotationEffect(.degrees(trend.direction == .up ? 180 : 0))
            }
            Text(trend.text).font(.system(size: FlareSizes.fontSizeSm * textScale, weight: .medium).monospacedDigit())
        }
        .foregroundColor(ink)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Self.words(trend.direction, strings)) \(trend.text)")
    }
}

/// The colours of a chart's series (and a donut's slices, in turn): the chart tokens `colors.chart.series1...6`, in
/// order, never the status colours.
func pluginChartPalette(_ colors: FlareColors) -> [Color] {
    [colors.chartSeries1, colors.chartSeries2, colors.chartSeries3,
     colors.chartSeries4, colors.chartSeries5, colors.chartSeries6]
}

/// A bar, line or donut chart over resolved points, drawn with `Canvas` and kit tokens; the empty text when no series
/// has a point. Series labels show as a legend under the chart when there is more than one, or for a donut its points.
struct PluginChartBlockView: View {
    let block: PluginChartBlock
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let palette = pluginChartPalette(colors)
        if !block.hasPoints {
            Text(block.emptyText.flatMap { $0.isEmpty ? nil : $0 } ?? strings.pluginViewEmpty)
                .font(.system(size: FlareSizes.fontSizeMd * textScale))
                .foregroundColor(colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
                switch block.chartKind {
                case .donut: donut(palette, colors)
                case .bar, .line: cartesian(palette, colors)
                }
                legend(palette, colors)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Self.summary(block))
        }
    }

    /// The legend's entries: a donut's points with their text; the series of a chart with more than one; else none.
    static func legend(_ block: PluginChartBlock) -> [(String, String?)] {
        if block.chartKind == .donut {
            return (block.series.first?.points ?? []).map { point -> (String, String?) in (point.label, point.text) }
        }
        guard block.series.count > 1 else { return [] }
        return block.series.map { series -> (String, String?) in (series.label ?? "", nil) }
    }

    /// What a screen reader says: each series' label and its points as "label text".
    static func summary(_ block: PluginChartBlock) -> String {
        block.series.map { series in
            let points = series.points.map { "\($0.label) \($0.text)" }.joined(separator: ", ")
            return [series.label, points].compactMap { $0.flatMap { $0.isEmpty ? nil : $0 } }.joined(separator: ": ")
        }.joined(separator: "; ")
    }

    private func cartesian(_ palette: [Color], _ colors: FlareColors) -> some View {
        let series = block.series.filter { !$0.points.isEmpty }
        let range = PluginChartRules.range(series)
        let labels = PluginChartRules.labels(series)
        let line = block.chartKind == .line
        return VStack(spacing: FlareSizes.spacing2xs) {
            Canvas { context, size in
                let height = size.height
                func y(_ value: Double) -> CGFloat {
                    height - CGFloat((value - range.min) / (range.max - range.min)) * height
                }
                // The zero line.
                var axis = Path()
                axis.move(to: CGPoint(x: 0, y: y(0))); axis.addLine(to: CGPoint(x: size.width, y: y(0)))
                context.stroke(axis, with: .color(colors.borderSecondary), lineWidth: 1)
                let slots = max(labels.count, 1)
                let slot = size.width / CGFloat(slots)
                for (s, item) in series.enumerated() {
                    let color = palette[s % palette.count]
                    if line {
                        var path = Path()
                        for (i, point) in item.points.enumerated() {
                            let at = CGPoint(x: slot * (CGFloat(i) + 0.5), y: y(point.value))
                            if i == 0 { path.move(to: at) } else { path.addLine(to: at) }
                        }
                        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round,
                                                                                    lineJoin: .round))
                        if item.points.count == 1, let point = item.points.first {
                            let at = CGPoint(x: slot * 0.5, y: y(point.value))
                            context.fill(Path(ellipseIn: CGRect(x: at.x - 3, y: at.y - 3, width: 6, height: 6)),
                                         with: .color(color))
                        }
                    } else {
                        let group = slot * 0.7
                        let width = group / CGFloat(series.count)
                        for (i, point) in item.points.enumerated() {
                            let x = slot * CGFloat(i) + (slot - group) / 2 + width * CGFloat(s)
                            let top = min(y(point.value), y(0))
                            let bar = CGRect(x: x + 1, y: top, width: max(width - 2, 1), height: abs(y(point.value) - y(0)))
                            context.fill(Path(roundedRect: bar, cornerRadius: min(FlareSizes.radiusXs, width / 2)),
                                         with: .color(color))
                        }
                    }
                }
            }
            .frame(height: 120 * textScale)
            if !labels.isEmpty {
                HStack(spacing: 0) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                        // Long series keep every fourth label so the axis stays legible.
                        Text(labels.count > 12 && index % 4 != 0 ? "" : label)
                            .font(.system(size: FlareSizes.fontSizeXs * textScale))
                            .foregroundColor(colors.textTertiary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func donut(_ palette: [Color], _ colors: FlareColors) -> some View {
        let points = block.series.first?.points ?? []
        let slices = PluginChartRules.donutSlices(points)
        return Canvas { context, size in
            let side = min(size.width, size.height)
            let ring = side * 0.18
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = (side - ring) / 2
            var track = Path()
            track.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
            context.stroke(track, with: .color(colors.bgTertiary), lineWidth: ring)
            for slice in slices {
                var arc = Path()
                arc.addArc(center: center, radius: radius, startAngle: .degrees(slice.start * 360 - 90),
                           endAngle: .degrees((slice.start + slice.sweep) * 360 - 90), clockwise: false)
                context.stroke(arc, with: .color(palette[slice.index % palette.count]), lineWidth: ring)
            }
        }
        .frame(height: 140 * textScale)
    }

    /// Several series name their colours; a donut names its points.
    @ViewBuilder private func legend(_ palette: [Color], _ colors: FlareColors) -> some View {
        let entries = Self.legend(block)
        if !entries.isEmpty {
            FlareFlowLayout(spacing: FlareSizes.spacingMd, lineSpacing: FlareSizes.spacingXs) {
                ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                    HStack(spacing: FlareSizes.spacing2xs) {
                        Circle().fill(palette[index % palette.count]).frame(width: 8, height: 8)
                        Text(entry.0).foregroundColor(colors.textSecondary)
                        if let text = entry.1 { Text(text).foregroundColor(colors.textPrimary).monospacedDigit() }
                    }
                    .font(.system(size: FlareSizes.fontSizeSm * textScale))
                }
            }
        }
    }
}

/// A picture in its fixed frame, asked of the host (`resolveImage`); while it loads or when it cannot be shown the
/// frame keeps its ratio and says so. The alt text is what a screen reader says.
struct PluginImageBlockView: View {
    let block: PluginImageBlock
    let resolveImage: (@Sendable (PluginImageSource) async -> URL?)?
    @State private var url: URL?
    @State private var failed = false
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusMd, style: .continuous)
        Color.clear
            .aspectRatio(block.aspect.ratio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay {
                if let url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFill()
                        case .failure: unavailable(colors)
                        default: ProgressView()
                        }
                    }
                } else if failed || resolveImage == nil {
                    unavailable(colors)
                } else {
                    ProgressView()
                }
            }
            .background(shape.fill(colors.bgSecondary))
            .clipShape(shape)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(block.alt)
            .accessibilityAddTraits(.isImage)
            .task(id: block.source) {
                guard let resolveImage else { return }
                failed = false
                url = PluginImageAddress.allowed(await resolveImage(block.source))
                if url == nil { failed = true }
            }
    }

    private func unavailable(_ colors: FlareColors) -> some View {
        VStack(spacing: FlareSizes.spacing2xs) {
            FlareIconImage(name: "image", size: FlareSizes.iconSizeMd * textScale).foregroundColor(colors.textTertiary)
            Text(strings.pluginViewImageUnavailable)
                .font(.system(size: FlareSizes.fontSizeSm * textScale))
                .foregroundColor(colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(FlareSizes.spacingSm)
    }
}

/// A QR code in the kit frame (dark on light whatever the theme), its label above and caption below. Once its expiry
/// has come the code is covered and says so; a block with a refresh offers the refresh key, which hands the host the
/// query to run (`onQrRefresh`). The view redraws at the expiry.
struct PluginQrBlockView: View {
    let block: PluginQrBlock
    let clock: PluginViewClock
    let onRefresh: ((PluginQrRefresh) -> Void)?
    let disabled: Bool
    @State private var cache = FlareQRCodeCache()
    @State private var nowMs: Int64
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    init(block: PluginQrBlock, clock: PluginViewClock, onRefresh: ((PluginQrRefresh) -> Void)?, disabled: Bool) {
        self.block = block; self.clock = clock; self.onRefresh = onRefresh; self.disabled = disabled
        self._nowMs = State(initialValue: clock.now())
    }

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let expired = block.expired(nowMs: nowMs)
        VStack(spacing: FlareSizes.spacingSm) {
            if let label = block.label, !label.isEmpty {
                Text(label).font(.system(size: FlareSizes.fontSizeMd * textScale, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
            }
            FlareQRCodeFrame(code: cache.image(for: block.value), label: block.label ?? strings.qrCode)
                .frame(maxWidth: 200)
                .overlay {
                    if expired {
                        RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                            .fill(colors.bgPrimary.opacity(0.92))
                            .overlay(Text(strings.pluginViewQrExpired)
                                .font(.system(size: FlareSizes.fontSizeMd * textScale, weight: .medium))
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(FlareSizes.spacingSm))
                    }
                }
            if let caption = block.caption, !caption.isEmpty {
                Text(caption).font(.system(size: FlareSizes.fontSizeSm * textScale))
                    .foregroundColor(colors.textTertiary).multilineTextAlignment(.center)
            }
            // Refresh is offered once the code has expired, as in every kit.
            if expired, let refresh = block.refresh, let onRefresh {
                ButtonView(label: strings.pluginViewQrRefresh, variant: .primary, size: .sm,
                           disabled: disabled, icon: "refresh") { onRefresh(refresh) }
            }
        }
        .frame(maxWidth: .infinity)
        .task(id: block) { await tick() }
    }

    /// Redraws when the code expires (waking at least daily, so a far-future expiry never overflows the sleep); a fixed
    /// test clock never ticks.
    private func tick() async {
        guard clock.nowMs == nil else { return }
        while !Task.isCancelled {
            nowMs = clock.now()
            guard let delay = block.refreshDelay(nowMs: nowMs) else { return }
            await flarePluginSleep(ms: delay)
        }
    }
}

/// The ink of a hero's value.
func pluginHeroColor(_ tone: PluginHeroTone, _ colors: FlareColors) -> Color {
    switch tone {
    case .neutral: return colors.textPrimary
    case .positive: return colors.successText
    case .warning: return colors.warningText
    case .brand: return colors.primaryText
    }
}

/// The lead figure of a page: the label, the value large (tabular figures for an amount), the subtitle and up to 3
/// keys it owns, the first primary.
struct PluginHeroBlockView: View {
    let block: PluginHeroBlock
    let busyActionId: String?
    let disabled: Bool
    let onAction: ((PluginViewAction) -> Void)?
    @ScaledMetric(relativeTo: .largeTitle) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    /// A maskable hero starts shown; the eye hides it for this view only.
    @State private var hidden = false

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let value = block.maskable && hidden
            ? PluginViewFormat.maskedValue : PluginFormatRules.text(block.value, block.format, strings)
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            if (block.label?.isEmpty == false) || block.maskable {
                HStack(spacing: FlareSizes.spacingXs) {
                    if let label = block.label, !label.isEmpty {
                        Text(label).font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textSecondary)
                    }
                    if block.maskable {
                        IconButtonView(icon: hidden ? "eye-off" : "eye",
                                       accessibilityLabel: hidden ? strings.accountShowBalance
                                                                  : strings.accountHideBalance) { hidden.toggle() }
                            .accessibilityIdentifier("flare-plugin-hero-mask")
                    }
                }
            }
            Text(value)
                .font(block.amount
                      ? .system(size: FlareSizes.fontSize5xl * textScale, weight: .semibold).monospacedDigit()
                      : .system(size: FlareSizes.fontSize5xl * textScale, weight: .semibold))
                .foregroundColor(pluginHeroColor(block.tone, colors))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if let subtitle = block.subtitle, !subtitle.isEmpty {
                Text(subtitle).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !block.actions.isEmpty {
                HStack(spacing: FlareSizes.spacingSm) {
                    ForEach(Array(block.actions.enumerated()), id: \.element.id) { index, action in
                        ButtonView(label: action.label,
                                   variant: action.style == .danger ? .danger : index == 0 ? .primary : .secondary,
                                   size: .sm, loading: busyActionId == action.id,
                                   disabled: (disabled && busyActionId != action.id) || onAction == nil,
                                   block: true) { onAction?(action) }
                    }
                }
                .padding(.top, FlareSizes.spacingXs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Steps in a row: a marker per step (done: a check, current: a filled ring, failed: a cross, pending: an outline)
/// joined by a line, the label under each; each says its state.
struct PluginStepsBlockView: View {
    let block: PluginStepsBlock
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    static func words(_ state: PluginStepState, _ strings: FlareStrings) -> String {
        switch state {
        case .pending: return strings.pluginViewStepPending
        case .current: return strings.pluginViewStepCurrent
        case .done: return strings.pluginViewStepDone
        case .failed: return strings.pluginViewStepFailed
        }
    }

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(block.items.enumerated()), id: \.offset) { index, step in
                VStack(spacing: FlareSizes.spacingXs) {
                    HStack(spacing: 0) {
                        connector(index > 0 ? block.items[index - 1].state == .done : nil, colors)
                        marker(step.state, colors)
                        connector(index < block.items.count - 1 ? step.state == .done : nil, colors)
                    }
                    Text(step.label)
                        .font(.system(size: FlareSizes.fontSizeSm * textScale,
                                      weight: step.state == .current ? .semibold : .regular))
                        .foregroundColor(step.state == .pending ? colors.textTertiary
                                         : step.state == .failed ? colors.errorText : colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(step.label), \(Self.words(step.state, strings))")
            }
        }
    }

    /// The line on one side of a marker: none at the ends, the primary once the earlier step is done.
    @ViewBuilder private func connector(_ done: Bool?, _ colors: FlareColors) -> some View {
        Rectangle().fill(done == nil ? Color.clear : done! ? colors.primary : colors.borderSecondary)
            .frame(height: 2).frame(maxWidth: .infinity)
    }

    private func marker(_ state: PluginStepState, _ colors: FlareColors) -> some View {
        let side = 20 * textScale
        return ZStack {
            switch state {
            case .done:
                Circle().fill(colors.primary)
                FlareIconImage(name: "check", size: side * 0.6, weight: .bold).foregroundColor(.white)
            case .current:
                Circle().stroke(colors.primary, lineWidth: 2)
                Circle().fill(colors.primary).padding(side * 0.25)
            case .failed:
                Circle().fill(colors.error)
                FlareIconImage(name: "close", size: side * 0.55, weight: .bold).foregroundColor(.white)
            case .pending:
                Circle().stroke(colors.borderHover, lineWidth: 1.5)
            }
        }
        .frame(width: side, height: side)
    }
}

/// A banner: the kit status banner in its tone with the action it owns as the banner's key.
struct PluginBannerBlockView: View {
    let block: PluginBannerBlock
    let disabled: Bool
    let onAction: ((PluginViewAction) -> Void)?

    var body: some View {
        let action = block.action.flatMap { onAction == nil || disabled ? nil : $0 }
        StatusBannerView(text: block.text, tone: block.tone.status, actionText: action?.label,
                         onAction: action.map { action -> () -> Void in { onAction?(action) } })
    }
}

/// A timeline: a dot and a line per item, its time (as the time blocks write it), title, detail and status badge; the
/// empty text when it has no item.
struct PluginTimelineBlockView: View {
    let block: PluginTimelineBlock
    let clock: PluginViewClock
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        if block.items.isEmpty {
            Text(block.emptyText.flatMap { $0.isEmpty ? nil : $0 } ?? strings.pluginViewEmpty)
                .font(.system(size: FlareSizes.fontSizeMd * textScale))
                .foregroundColor(colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            let now = clock.now()
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(block.items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: FlareSizes.spacingSm) {
                        VStack(spacing: 0) {
                            Circle().fill(index == 0 ? colors.primary : colors.borderHover)
                                .frame(width: 8, height: 8)
                                .padding(.top, 5 * textScale)
                            if index < block.items.count - 1 {
                                Rectangle().fill(colors.borderSecondary).frame(width: 1).frame(maxHeight: .infinity)
                            }
                        }
                        .frame(width: 8)
                        VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
                            HStack(alignment: .firstTextBaseline, spacing: FlareSizes.spacingXs) {
                                Text(item.title)
                                    .font(.system(size: FlareSizes.fontSizeMd * textScale, weight: .medium))
                                    .foregroundColor(colors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if let status = item.status { PluginBadgeView(badge: status) }
                            }
                            if let detail = item.detail, !detail.isEmpty {
                                Text(detail).font(.system(size: FlareSizes.fontSizeSm * textScale))
                                    .foregroundColor(colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Text(PluginViewFormat.dateTime(item.atMs, nowMs: now, strings,
                                                           utcOffsetMinutes: clock.utcOffsetMinutes))
                                .font(.system(size: FlareSizes.fontSizeXs * textScale).monospacedDigit())
                                .foregroundColor(colors.textTertiary)
                        }
                        .padding(.bottom, index < block.items.count - 1 ? FlareSizes.spacingMd : 0)
                        .accessibilityElement(children: .combine)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
