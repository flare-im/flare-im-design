import Foundation

// Vocabulary 2 of the resolved plugin view (flare-plugin-protocol blocks.rs / formats.rs / inputs.rs): the blocks
// section, stats, chart, image, qr, hero, steps, banner and timeline, the value formats a field, a stat, a hero or a
// cell may carry, the money input's rules and the document input's side. Each decodes the core's camelCase JSON
// leniently, like the vocabulary 1 models in `PluginViewModel.swift`; `spec/plugin-view-vectors.json` → blocks2,
// formats2, moneyInput and upgradeNotice hold the facts the four kits share.

// MARK: - Formats

/// What a value's format adds to its plain text (`ResolvedUiFormat`). A surface that does not know a format draws the
/// plain text; the kit rewrites only `count` (compact) and `duration` (the viewer's words), see ``PluginFormatRules``.
public enum PluginValueFormat: Codable, Equatable, Sendable {
    /// Minor units as sent; `scale` absent: still minor units, the host may scale them by `assetId`.
    case money(minor: String, scale: Int?, assetId: String?)
    case enumeration(raw: String)
    case person(userId: String)
    /// `labelled` false: the value is the bare id.
    case reference(id: String, labelled: Bool)
    case time(atMs: Int64)
    /// A ratio already multiplied by 100; the plain text is already "12.5%".
    case percent(percent: Double, decimals: Int)
    case duration(ms: Double)
    case count(Double)
    /// The plain text is already "1.5 MB".
    case bytes(Double)

    private enum CodingKeys: String, CodingKey {
        case kind, minor, scale, assetId, raw, userId, id, labelled, atMs, percent, decimals, ms, count, bytes
    }

    public var kind: String {
        switch self {
        case .money: return "money"
        case .enumeration: return "enum"
        case .person: return "person"
        case .reference: return "reference"
        case .time: return "time"
        case .percent: return "percent"
        case .duration: return "duration"
        case .count: return "count"
        case .bytes: return "bytes"
        }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(String.self, forKey: .kind)
        func need<T: Decodable>(_ type: T.Type, _ key: CodingKeys) throws -> T {
            guard let value = c.lenient(type, key) else {
                throw DecodingError.keyNotFound(key, .init(codingPath: c.codingPath, debugDescription: key.rawValue))
            }
            return value
        }
        switch kind {
        case "money":
            self = .money(minor: try need(String.self, .minor), scale: c.lenient(Int.self, .scale),
                          assetId: c.lenient(String.self, .assetId))
        case "enum": self = .enumeration(raw: try need(String.self, .raw))
        case "person": self = .person(userId: try need(String.self, .userId))
        case "reference":
            self = .reference(id: try need(String.self, .id), labelled: c.lenient(Bool.self, .labelled) ?? false)
        case "time": self = .time(atMs: Int64(try need(Double.self, .atMs)))
        case "percent":
            self = .percent(percent: try need(Double.self, .percent), decimals: c.lenient(Int.self, .decimals) ?? 0)
        case "duration": self = .duration(ms: try need(Double.self, .ms))
        case "count": self = .count(try need(Double.self, .count))
        case "bytes": self = .bytes(try need(Double.self, .bytes))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: c, debugDescription: "format kind \(kind)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(kind, forKey: .kind)
        switch self {
        case let .money(minor, scale, assetId):
            try c.encode(minor, forKey: .minor)
            try c.encodeIfPresent(scale, forKey: .scale)
            try c.encodeIfPresent(assetId, forKey: .assetId)
        case .enumeration(let raw): try c.encode(raw, forKey: .raw)
        case .person(let userId): try c.encode(userId, forKey: .userId)
        case let .reference(id, labelled):
            try c.encode(id, forKey: .id)
            try c.encode(labelled, forKey: .labelled)
        case .time(let atMs): try c.encode(atMs, forKey: .atMs)
        case let .percent(percent, decimals):
            try c.encode(percent, forKey: .percent)
            try c.encode(decimals, forKey: .decimals)
        case .duration(let ms): try c.encode(ms, forKey: .ms)
        case .count(let count): try c.encode(count, forKey: .count)
        case .bytes(let bytes): try c.encode(bytes, forKey: .bytes)
        }
    }
}

/// The words a formatted value is drawn with (spec formats2): `count` compact in the viewer's units ("1.2万"),
/// `duration` in the viewer's units ("2 小时 5 分钟"); every other format draws the plain text the core wrote.
enum PluginFormatRules {
    static func text(_ value: String, _ format: PluginValueFormat?, _ strings: FlareStrings) -> String {
        switch format {
        case .count(let count)?:
            return count.isFinite ? compactCount(count, units: strings.pluginFormatCountUnits) : value
        case .duration(let ms)?:
            return ms.isFinite ? durationText(ms, strings) : value
        default:
            return value
        }
    }

    /// The compact units of `units` ("4:万|8:亿": exponent and suffix pairs), largest first; malformed pairs skipped.
    static func units(_ units: String) -> [(exponent: Int, suffix: String)] {
        units.split(separator: "|").compactMap { pair -> (exponent: Int, suffix: String)? in
            guard let at = pair.firstIndex(of: ":"), let exponent = Int(pair[..<at]), exponent > 0 else { return nil }
            let suffix = String(pair[pair.index(after: at)...])
            return suffix.isEmpty ? nil : (exponent: exponent, suffix: suffix)
        }
        .sorted { $0.exponent > $1.exponent }
    }

    /// A count written compact (spec formats2.count): the largest unit the count reaches, one decimal cut (never
    /// rounded up) and a trailing ".0" dropped; below every unit, the count itself.
    static func compactCount(_ count: Double, units: String) -> String {
        let whole = count.rounded(.towardZero)
        let sign = whole < 0 ? "-" : ""
        let n = abs(whole)
        guard let unit = Self.units(units).first(where: { n >= pow(10, Double($0.exponent)) }) else {
            return sign + integerText(n)
        }
        let tenths = (n * 10 / pow(10, Double(unit.exponent))).rounded(.down)
        let head = (tenths / 10).rounded(.down)
        let digit = tenths - head * 10
        let text = digit == 0 ? integerText(head) : "\(integerText(head)).\(integerText(digit))"
        return sign + text + unit.suffix
    }

    /// A duration in the viewer's words (spec formats2.duration): whole seconds; under a minute the seconds alone, else
    /// the largest unit that is not zero and, when it is not zero, the next one ("2 小时 5 分钟", "1 天").
    static func durationText(_ ms: Double, _ strings: FlareStrings) -> String {
        let total = Int64((max(0, ms) / 1000).rounded(.down))
        func unit(_ template: String, _ n: Int64) -> String { template.replacingOccurrences(of: "{n}", with: String(n)) }
        if total < 60 { return unit(strings.pluginFormatSeconds, total) }
        let parts: [(Int64, String)] = [
            (total / 86_400, strings.myInviteUnitDays),
            ((total % 86_400) / 3_600, strings.myInviteUnitHours),
            ((total % 3_600) / 60, strings.myInviteUnitMinutes),
            (total % 60, strings.pluginFormatSeconds),
        ]
        guard let first = parts.firstIndex(where: { $0.0 > 0 }) else { return unit(strings.pluginFormatSeconds, 0) }
        var text = unit(parts[first].1, parts[first].0)
        if first + 1 < parts.count, parts[first + 1].0 > 0 { text += " " + unit(parts[first + 1].1, parts[first + 1].0) }
        return text
    }

    private static func integerText(_ value: Double) -> String { String(format: "%.0f", value) }
}

// MARK: - Blocks

/// `section`: blocks under a heading (never a section, rows or protected media), collapsible.
public struct PluginSectionBlock: Codable, Equatable, Sendable {
    public let label: String?
    public let collapsed: Bool
    /// The children the kit reads; kinds it does not know were skipped.
    public let blocks: [PluginBlock]
    public init(label: String? = nil, collapsed: Bool = false, blocks: [PluginBlock]) {
        self.label = label; self.collapsed = collapsed; self.blocks = blocks
    }
    private enum CodingKeys: String, CodingKey { case label, collapsed, blocks }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = c.lenient(String.self, .label)
        collapsed = c.lenient(Bool.self, .collapsed) ?? false
        // A nested section is not allowed: dropped like an unknown kind.
        blocks = (c.lenient([PluginLossy<PluginBlock>].self, .blocks) ?? []).compactMap(\.value).filter {
            if case .section = $0 { return false }
            if case .rows = $0 { return false }
            return true
        }
    }
}

/// Which way a figure moved; anything the kit does not know is flat.
public enum PluginTrendDirection: String, Codable, Sendable {
    case up, down, flat
    public init(from decoder: Decoder) throws {
        self = PluginTrendDirection(rawValue: (try? decoder.singleValueContainer().decode(String.self)) ?? "") ?? .flat
    }
}

/// How a figure moved: the text as sent and its direction.
public struct PluginTrend: Codable, Equatable, Sendable {
    public let text: String
    public let direction: PluginTrendDirection
    public init(text: String, direction: PluginTrendDirection = .flat) { self.text = text; self.direction = direction }
    private enum CodingKeys: String, CodingKey { case text, direction }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = c.lenient(String.self, .text) ?? ""
        direction = c.lenient(PluginTrendDirection.self, .direction) ?? .flat
    }
}

/// One figure of a stats block.
public struct PluginStat: Codable, Equatable, Sendable {
    public let label: String
    /// The plain text, whatever `format` says.
    public let value: String
    public let format: PluginValueFormat?
    public let trend: PluginTrend?
    public let tone: PluginTone?
    public init(label: String, value: String, format: PluginValueFormat? = nil, trend: PluginTrend? = nil,
                tone: PluginTone? = nil) {
        self.label = label; self.value = value; self.format = format; self.trend = trend; self.tone = tone
    }
    private enum CodingKeys: String, CodingKey { case label, value, format, trend, tone }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = c.lenient(String.self, .label) ?? ""
        value = c.lenient(String.self, .value) ?? ""
        format = c.lenient(PluginValueFormat.self, .format)
        trend = c.lenient(PluginTrend.self, .trend)
        tone = c.lenient(PluginTone.self, .tone)
    }
}

/// `stats`: 2 to 6 figures side by side.
public struct PluginStatsBlock: Codable, Equatable, Sendable {
    public let items: [PluginStat]
    public init(items: [PluginStat]) { self.items = items }
    private enum CodingKeys: String, CodingKey { case items }
    public init(from decoder: Decoder) throws {
        items = (try decoder.container(keyedBy: CodingKeys.self).lenient([PluginLossy<PluginStat>].self, .items) ?? [])
            .compactMap(\.value)
    }
}

public enum PluginChartKind: String, Codable, Sendable { case bar, line, donut }

public struct PluginChartPoint: Codable, Equatable, Sendable {
    public let label: String
    public let value: Double
    /// The value as text, through the block's format.
    public let text: String
    public init(label: String, value: Double, text: String) { self.label = label; self.value = value; self.text = text }
    private enum CodingKeys: String, CodingKey { case label, value, text }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = c.lenient(String.self, .label) ?? ""
        guard let value = c.lenient(Double.self, .value), value.isFinite else {
            throw DecodingError.keyNotFound(CodingKeys.value, .init(codingPath: c.codingPath, debugDescription: "value"))
        }
        self.value = value
        text = c.lenient(String.self, .text) ?? PluginViewFormat.number(value)
    }
}

public struct PluginChartSeries: Codable, Equatable, Sendable {
    public let label: String?
    public let points: [PluginChartPoint]
    public init(label: String? = nil, points: [PluginChartPoint]) { self.label = label; self.points = points }
    private enum CodingKeys: String, CodingKey { case label, points }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = c.lenient(String.self, .label)
        points = (c.lenient([PluginLossy<PluginChartPoint>].self, .points) ?? []).compactMap(\.value)
    }
}

/// `chart`: up to 3 series (a donut draws one) of up to 60 points, drawn with kit tokens, no chart library.
public struct PluginChartBlock: Codable, Equatable, Sendable {
    public let chartKind: PluginChartKind
    public let series: [PluginChartSeries]
    /// Shown instead of a chart when no series has a point.
    public let emptyText: String?
    public init(chartKind: PluginChartKind, series: [PluginChartSeries], emptyText: String? = nil) {
        self.chartKind = chartKind; self.series = series; self.emptyText = emptyText
    }
    private enum CodingKeys: String, CodingKey { case chartKind, series, emptyText }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        chartKind = try c.decode(PluginChartKind.self, forKey: .chartKind)
        series = (c.lenient([PluginLossy<PluginChartSeries>].self, .series) ?? []).compactMap(\.value)
        emptyText = c.lenient(String.self, .emptyText)
    }
    /// Some series has a point.
    public var hasPoints: Bool { series.contains { !$0.points.isEmpty } }
}

public enum PluginImageAspect: String, Codable, Sendable {
    case square = "1:1", standard = "4:3", wide = "16:9", portrait = "3:4"
    public init(from decoder: Decoder) throws {
        self = PluginImageAspect(rawValue: (try? decoder.singleValueContainer().decode(String.self)) ?? "") ?? .square
    }
    /// Width over height.
    public var ratio: CGFloat {
        switch self {
        case .square: return 1
        case .standard: return 4.0 / 3.0
        case .wide: return 16.0 / 9.0
        case .portrait: return 3.0 / 4.0
        }
    }
}

/// What the host's `resolveImage` is asked for: a package asset, or a privately uploaded file of the plugin. Never a
/// URL: the host turns either into one.
public struct PluginImageSource: Codable, Equatable, Hashable, Sendable {
    public let asset: String?
    public let fileId: String?
    public init(asset: String? = nil, fileId: String? = nil) { self.asset = asset; self.fileId = fileId }
}

/// `image`: one picture in a fixed frame.
public struct PluginImageBlock: Codable, Equatable, Sendable {
    public let asset: String?
    public let fileId: String?
    public let aspect: PluginImageAspect
    public let alt: String
    public init(asset: String? = nil, fileId: String? = nil, aspect: PluginImageAspect = .square, alt: String) {
        self.asset = asset; self.fileId = fileId; self.aspect = aspect; self.alt = alt
    }
    private enum CodingKeys: String, CodingKey { case asset, fileId, aspect, alt }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        asset = c.lenient(String.self, .asset)
        fileId = c.lenient(String.self, .fileId)
        aspect = c.lenient(PluginImageAspect.self, .aspect) ?? .square
        alt = c.lenient(String.self, .alt) ?? ""
    }
    public var source: PluginImageSource { PluginImageSource(asset: asset, fileId: fileId) }
}

/// `qr`: a QR code of `value`; `refreshOperation` (a query) returns a fresh one, read at the block's own paths.
public struct PluginQrBlock: Codable, Equatable, Sendable {
    public let value: String
    public let label: String?
    public let caption: String?
    /// Absent on a read-only copy.
    public let refreshOperation: String?
    public let valuePath: String
    public let expiresAtPath: String?
    public let expiresAtMs: Int64?
    public init(value: String, label: String? = nil, caption: String? = nil, refreshOperation: String? = nil,
                valuePath: String = "", expiresAtPath: String? = nil, expiresAtMs: Int64? = nil) {
        self.value = value; self.label = label; self.caption = caption; self.refreshOperation = refreshOperation
        self.valuePath = valuePath; self.expiresAtPath = expiresAtPath; self.expiresAtMs = expiresAtMs
    }
    private enum CodingKeys: String, CodingKey {
        case value, label, caption, refreshOperation, valuePath, expiresAtPath, expiresAtMs
    }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        value = try c.decode(String.self, forKey: .value)
        label = c.lenient(String.self, .label)
        caption = c.lenient(String.self, .caption)
        refreshOperation = c.lenient(String.self, .refreshOperation)
        valuePath = c.lenient(String.self, .valuePath) ?? ""
        expiresAtPath = c.lenient(String.self, .expiresAtPath)
        expiresAtMs = c.lenient(Double.self, .expiresAtMs).map { Int64($0) }
    }

    /// The code names an expiry and that instant has come (spec blocks2.qr).
    public func expired(nowMs: Int64) -> Bool { expiresAtMs.map { $0 <= nowMs } ?? false }

    /// How long until the code expires, to draw it again then; nil without an expiry or once expired.
    public func refreshDelay(nowMs: Int64) -> Int64? {
        guard let expiresAtMs, expiresAtMs > nowMs else { return nil }
        return expiresAtMs - nowMs
    }

    /// What the refresh key hands the host, nil when the block has no refresh.
    public var refresh: PluginQrRefresh? {
        refreshOperation.map { PluginQrRefresh(operation: $0, valuePath: valuePath, expiresAtPath: expiresAtPath) }
    }
}

/// What `onQrRefresh` carries: the host runs the query (with `{}`) and passes back a view with the fresh code, read
/// at `valuePath` and `expiresAtPath` in its result.
public struct PluginQrRefresh: Codable, Equatable, Sendable {
    public let operation: String
    public let valuePath: String
    public let expiresAtPath: String?
    public init(operation: String, valuePath: String, expiresAtPath: String? = nil) {
        self.operation = operation; self.valuePath = valuePath; self.expiresAtPath = expiresAtPath
    }
}

public enum PluginHeroTone: String, Codable, Sendable {
    case neutral, positive, warning, brand
    public init(from decoder: Decoder) throws {
        self = PluginHeroTone(rawValue: (try? decoder.singleValueContainer().decode(String.self)) ?? "") ?? .neutral
    }
}

/// `hero`: the page's lead figure (one per document), with up to 3 owned actions.
public struct PluginHeroBlock: Codable, Equatable, Sendable {
    public let label: String?
    /// The plain text, whatever `format` says.
    public let value: String
    /// The value is an amount: drawn with tabular figures.
    public let amount: Bool
    public let format: PluginValueFormat?
    public let subtitle: String?
    public let tone: PluginHeroTone
    /// Empty on a read-only copy.
    public let actions: [PluginViewAction]
    public init(label: String? = nil, value: String, amount: Bool = false, format: PluginValueFormat? = nil,
                subtitle: String? = nil, tone: PluginHeroTone = .neutral, actions: [PluginViewAction] = []) {
        self.label = label; self.value = value; self.amount = amount; self.format = format; self.subtitle = subtitle
        self.tone = tone; self.actions = actions
    }
    private enum CodingKeys: String, CodingKey { case label, value, amount, format, subtitle, tone, actions }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = c.lenient(String.self, .label)
        value = c.lenient(String.self, .value) ?? ""
        amount = c.lenient(Bool.self, .amount) ?? false
        format = c.lenient(PluginValueFormat.self, .format)
        subtitle = c.lenient(String.self, .subtitle)
        tone = c.lenient(PluginHeroTone.self, .tone) ?? .neutral
        actions = (c.lenient([PluginLossy<PluginViewAction>].self, .actions) ?? []).compactMap(\.value)
    }
}

public enum PluginStepState: String, Codable, Sendable {
    case pending, current, done, failed
    /// Anything the kit does not know is pending (spec blocks2.steps).
    public init(from decoder: Decoder) throws {
        self = PluginStepState(rawValue: (try? decoder.singleValueContainer().decode(String.self)) ?? "") ?? .pending
    }
}

public struct PluginStep: Codable, Equatable, Sendable {
    public let label: String
    public let state: PluginStepState
    public init(label: String, state: PluginStepState = .pending) { self.label = label; self.state = state }
    private enum CodingKeys: String, CodingKey { case label, state }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = c.lenient(String.self, .label) ?? ""
        state = c.lenient(PluginStepState.self, .state) ?? .pending
    }
}

/// `steps`: a process in 2 to 6 steps.
public struct PluginStepsBlock: Codable, Equatable, Sendable {
    public let items: [PluginStep]
    public init(items: [PluginStep]) { self.items = items }
    private enum CodingKeys: String, CodingKey { case items }
    public init(from decoder: Decoder) throws {
        items = (try decoder.container(keyedBy: CodingKeys.self).lenient([PluginLossy<PluginStep>].self, .items) ?? [])
            .compactMap(\.value)
    }
}

public enum PluginBannerTone: String, Codable, Sendable {
    case info, success, warning, danger
    public init(from decoder: Decoder) throws {
        self = PluginBannerTone(rawValue: (try? decoder.singleValueContainer().decode(String.self)) ?? "") ?? .info
    }
    /// The kit status banner's tone.
    var status: FlareStatusTone {
        switch self {
        case .info: return .info
        case .success: return .success
        case .warning: return .warning
        case .danger: return .danger
        }
    }
}

/// `banner`: a prominent notice (at most 2 per document) with an optional owned action.
public struct PluginBannerBlock: Codable, Equatable, Sendable {
    public let tone: PluginBannerTone
    public let text: String
    /// Absent on a read-only copy.
    public let action: PluginViewAction?
    public init(tone: PluginBannerTone = .info, text: String, action: PluginViewAction? = nil) {
        self.tone = tone; self.text = text; self.action = action
    }
    private enum CodingKeys: String, CodingKey { case tone, text, action }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tone = c.lenient(PluginBannerTone.self, .tone) ?? .info
        text = try c.decode(String.self, forKey: .text)
        action = c.lenient(PluginViewAction.self, .action)
    }
}

public struct PluginTimelineItem: Codable, Equatable, Sendable {
    public let atMs: Int64
    public let title: String
    public let detail: String?
    public let status: PluginBadge?
    public init(atMs: Int64, title: String, detail: String? = nil, status: PluginBadge? = nil) {
        self.atMs = atMs; self.title = title; self.detail = detail; self.status = status
    }
    private enum CodingKeys: String, CodingKey { case atMs, title, detail, status }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let at = c.lenient(Double.self, .atMs) else {
            throw DecodingError.keyNotFound(CodingKeys.atMs, .init(codingPath: c.codingPath, debugDescription: "atMs"))
        }
        atMs = Int64(at)
        title = c.lenient(String.self, .title) ?? ""
        detail = c.lenient(String.self, .detail)
        status = c.lenient(PluginBadge.self, .status).flatMap { $0.text.isEmpty ? nil : $0 }
    }
}

/// `timeline`: up to 50 dated items, in the plugin's order.
public struct PluginTimelineBlock: Codable, Equatable, Sendable {
    public let items: [PluginTimelineItem]
    public let emptyText: String?
    public init(items: [PluginTimelineItem], emptyText: String? = nil) { self.items = items; self.emptyText = emptyText }
    private enum CodingKeys: String, CodingKey { case items, emptyText }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        items = (c.lenient([PluginLossy<PluginTimelineItem>].self, .items) ?? []).compactMap(\.value)
        emptyText = c.lenient(String.self, .emptyText)
    }
}

// MARK: - Chart geometry

/// One slice of a donut: the point it draws, its start and its sweep as fractions of the whole.
struct PluginDonutSlice: Equatable, Sendable {
    let index: Int
    let start: Double
    let sweep: Double
}

enum PluginChartRules {
    /// A donut's slices (spec blocks2.donut): every point with a positive finite value, its start and sweep as
    /// fractions of the sum of those values, in point order; nothing when no value is positive.
    static func donutSlices(_ points: [PluginChartPoint]) -> [PluginDonutSlice] {
        let shown = points.enumerated().filter { $0.element.value.isFinite && $0.element.value > 0 }
        let total = shown.reduce(0) { $0 + $1.element.value }
        guard total > 0 else { return [] }
        var start = 0.0
        return shown.map { index, point in
            let sweep = point.value / total
            defer { start += sweep }
            return PluginDonutSlice(index: index, start: start, sweep: sweep)
        }
    }

    /// The value range a bar or line chart scales to: from 0 (or the smallest value when it is negative) to the largest
    /// value (or 0 when every value is negative); a flat range is widened to 1.
    static func range(_ series: [PluginChartSeries]) -> (min: Double, max: Double) {
        let values = series.flatMap { $0.points.map(\.value) }.filter(\.isFinite)
        let low = min(0, values.min() ?? 0)
        let high = max(0, values.max() ?? 0)
        return high > low ? (low, high) : (low, low + 1)
    }

    /// The labels along the x axis: the longest series' point labels.
    static func labels(_ series: [PluginChartSeries]) -> [String] {
        series.max { $0.points.count < $1.points.count }?.points.map(\.label) ?? []
    }
}

// MARK: - Walking blocks

enum PluginBlockWalk {
    /// The blocks in reading order with every section's children after it (spec blocks2.flatten).
    static func flat(_ blocks: [PluginBlock]) -> [PluginBlock] {
        blocks.flatMap { block -> [PluginBlock] in
            if case .section(let section) = block { return [block] + section.blocks }
            return [block]
        }
    }
}

// MARK: - Inputs

/// The amount rules of a money input, read by the core SDK: no paths are left.
public struct PluginMoneyRules: Codable, Equatable, Sendable {
    public let currency: String?
    /// Fraction digits the amount may have; 2 when absent.
    public let scale: Int?
    /// Bounds as decimal strings.
    public let min: String?
    public let max: String?
    public init(currency: String?, scale: Int? = nil, min: String? = nil, max: String? = nil) {
        self.currency = currency; self.scale = scale; self.min = min; self.max = max
    }
    private enum CodingKeys: String, CodingKey { case currency, scale, min, max }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currency = c.lenient(String.self, .currency)
        scale = c.lenient(Int.self, .scale)
        min = c.lenient(String.self, .min)
        max = c.lenient(String.self, .max)
    }
    /// The scale that applies: a declared one in 0...18, else 2.
    public var effectiveScale: Int {
        guard let scale, (0...18).contains(scale) else { return 2 }
        return scale
    }
}

/// A money input's value (`UiMoneyValue`).
public struct PluginMoneyValue: Codable, Equatable, Sendable {
    public let amount: String
    public let currency: String
    public init(amount: String, currency: String) { self.amount = amount; self.currency = currency }
    public var json: PluginJSONValue { .object(["amount": .string(amount), "currency": .string(currency)]) }
}

/// Which side of an identity document a document input captures.
public enum PluginDocumentSide: String, Codable, Sendable, CaseIterable { case front, back, holding }

enum PluginMoneyRulesCheck {
    /// The amount typed, as the protocol writes decimals (spec moneyInput.normalize): spaces gone, leading zeros of the
    /// whole part dropped (one kept), a leading "." gets a "0", a trailing "." goes. Anything else stays for the check.
    static func amount(_ typed: String) -> String {
        var text = typed.filter { !$0.isWhitespace }
        if text.hasPrefix(".") { text = "0" + text }
        if text.hasSuffix(".") { text.removeLast() }
        let parts = text.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let whole = parts.first.map(String.init) ?? ""
        let rest = parts.count > 1 ? "." + parts[1] : ""
        guard !whole.isEmpty, whole.allSatisfy(\.isASCIIDigit) else { return text }
        var trimmed = Substring(whole)
        while trimmed.count > 1, trimmed.first == "0" { trimmed = trimmed.dropFirst() }
        return String(trimmed) + rest
    }

    /// A decimal the protocol accepts: no sign or exponent, no leading zero, ≤30 whole and ≤`scale` fraction digits.
    static func isDecimal(_ amount: String, scale: Int) -> Bool {
        let parts = amount.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        guard let whole = parts.first, !whole.isEmpty, whole.count <= 30, whole.allSatisfy(\.isASCIIDigit),
              whole == "0" || whole.first != "0" else { return false }
        guard parts.count > 1 else { return true }
        let fraction = parts[1]
        return !fraction.isEmpty && fraction.count <= scale && fraction.allSatisfy(\.isASCIIDigit)
    }

    /// The order of two decimals ``isDecimal(_:scale:)`` accepts.
    static func compare(_ a: String, _ b: String) -> ComparisonResult {
        func split(_ s: String) -> (String, String) {
            let parts = s.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
            var fraction = parts.count > 1 ? String(parts[1]) : ""
            while fraction.hasSuffix("0") { fraction.removeLast() }
            return (String(parts.first ?? ""), fraction)
        }
        let (aw, af) = split(a)
        let (bw, bf) = split(b)
        if aw.count != bw.count { return aw.count < bw.count ? .orderedAscending : .orderedDescending }
        if aw != bw { return aw < bw ? .orderedAscending : .orderedDescending }
        let width = Swift.max(af.count, bf.count)
        let ap = af.padding(toLength: width, withPad: "0", startingAt: 0)
        let bp = bf.padding(toLength: width, withPad: "0", startingAt: 0)
        return ap == bp ? .orderedSame : (ap < bp ? .orderedAscending : .orderedDescending)
    }

    /// The light check of a money draft (spec moneyInput.check): what the core SDK will say about the amount.
    static func check(_ input: PluginInput, _ draft: PluginJSONValue?) -> PluginFormIssue? {
        let amount = Self.amount(draft?.stringValue ?? "")
        if amount.isEmpty { return input.required ? .required : nil }
        guard let rules = input.money, let currency = rules.currency, !currency.isEmpty,
              isDecimal(amount, scale: rules.effectiveScale) else { return .invalidType }
        if let min = rules.min, compare(amount, min) == .orderedAscending { return .outOfRange }
        if let max = rules.max, compare(amount, max) == .orderedDescending { return .outOfRange }
        return nil
    }

    /// What submit hands over for a money input: `{amount, currency}`, nil while no amount was typed.
    static func value(_ input: PluginInput, _ draft: PluginJSONValue?) -> PluginMoneyValue? {
        let amount = Self.amount(draft?.stringValue ?? "")
        guard !amount.isEmpty, let currency = input.money?.currency, !currency.isEmpty else { return nil }
        return PluginMoneyValue(amount: amount, currency: currency)
    }

    /// The draft of a money input: the amount as typed (a `{amount}` value or a string), the currency comes from the
    /// input.
    static func draft(_ raw: PluginJSONValue?) -> PluginJSONValue {
        if let text = raw?.stringValue { return .string(text) }
        return .string(raw?["amount"]?.stringValue ?? "")
    }
}

private extension Character {
    var isASCIIDigit: Bool { ("0"..."9").contains(self) }
}

// MARK: - Upgrade

/// What the engine's `update.plugin_upgrade_status` answers for a placeholder's `minBuild`.
public struct PluginUpgradeStatus: Codable, Equatable, Sendable {
    /// A build at least `minBuild` is offered to this device.
    public let available: Bool
    public let build: Int64?
    public init(available: Bool, build: Int64? = nil) { self.available = available; self.build = build }
    private enum CodingKeys: String, CodingKey { case available, build }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        available = c.lenient(Bool.self, .available) ?? false
        build = c.lenient(Double.self, .build).map { Int64($0) }
    }
}

/// What an upgrade notice offers (spec upgradeNotice): `update` — a newer build is offered to this device and the host
/// handles the update, so the key shows; `notAvailable` — no build for this device yet (also while it rolls out
/// elsewhere), only the copy; `description` — the status is not known yet, or there is no handler.
public enum PluginUpgradeMode: String, Sendable {
    case update, notAvailable, description

    public static func of(_ status: PluginUpgradeStatus?, canUpdate: Bool) -> PluginUpgradeMode {
        if status?.available == true { return canUpdate ? .update : .description }
        return status == nil ? .description : .notAvailable
    }
}
