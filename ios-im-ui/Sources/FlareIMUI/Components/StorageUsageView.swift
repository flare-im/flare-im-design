import SwiftUI

/// One storage category as the host measured it. `id` must be stable — it is
/// echoed in every callback.
public struct FlareStorageCategory: Identifiable, Equatable, Sendable {
    public let id: String
    public let label: String
    /// Bytes this category occupies. `nil` (or any non-finite or negative value)
    /// means "not measured yet" — the row says so instead of printing 0 B, and
    /// draws no share bar.
    public let bytes: Double?
    /// How many files make up the category; omitted when the host does not count them.
    public let fileCount: Int?
    /// Host can clear this category. `false` hides the clear button entirely.
    public let clearable: Bool
    /// This category's clear command is in flight — that row alone locks.
    public let busy: Bool
    /// Why this category's last clear failed; kept until the host dismisses it.
    public let error: String?

    public init(id: String, label: String, bytes: Double? = nil, fileCount: Int? = nil,
                clearable: Bool = false, busy: Bool = false, error: String? = nil) {
        self.id = id; self.label = label; self.bytes = bytes; self.fileCount = fileCount
        self.clearable = clearable; self.busy = busy; self.error = error
    }
}

/// Result of `storageTotals`.
public struct FlareStorageTotals: Equatable, Sendable {
    /// Sum of the categories whose size is actually known.
    public let knownBytes: Double
    /// At least one category has no measured size, so `knownBytes` is a floor.
    public let hasUnknown: Bool
    /// What to display as the total: the host's `totalBytes` when usable, else `knownBytes`.
    public let total: Double
}

private let flareStorageUnits = ["KB", "MB", "GB", "TB"]

private func flareIsKnownBytes(_ value: Double?) -> Bool {
    guard let value else { return false }
    return value.isFinite && value >= 0
}

/// Human byte size, or `nil` when the size is not known.
///
/// The rules are identical on all four platforms and deliberately
/// locale-invariant, so one snapshot reads the same on web, Flutter, iOS and
/// Android: unknown (`nil` / NaN / infinite / negative) → `nil`; below 1024 →
/// `"N B"`; then 1024 per step through KB, MB, GB, TB with one decimal. TB is
/// the last unit, matching `MessageContentView.bytes`.
///
/// `locale` is accepted so hosts can thread their locale through; digits and
/// unit suffixes are the same in every locale on purpose — the same storage
/// snapshot must never read differently on two of the user's devices.
public func formatBytes(_ bytes: Double?, locale: String? = nil) -> String? {
    _ = locale
    guard flareIsKnownBytes(bytes), let bytes else { return nil }
    let rounded = Int(bytes.rounded())
    if rounded < 1024 { return "\(rounded) B" }
    var value = bytes / 1024
    var unit = 0
    while value >= 1024, unit < flareStorageUnits.count - 1 {
        value /= 1024
        unit += 1
    }
    return String(format: "%.1f %@", value, flareStorageUnits[unit])
}

/// What to show as the overall footprint — same rule set as the other platforms.
///
/// `knownBytes` only sums the categories that actually have a size and
/// `hasUnknown` says whether anything was left out, so the view can label its
/// own sum "at least" instead of passing a partial sum off as the truth. A
/// usable host `totalBytes` wins; an unusable one falls back to the sum.
public func storageTotals(_ categories: [FlareStorageCategory],
                          totalBytes: Double? = nil) -> FlareStorageTotals {
    var knownBytes = 0.0
    var hasUnknown = false
    for category in categories {
        if flareIsKnownBytes(category.bytes), let bytes = category.bytes { knownBytes += bytes }
        else { hasUnknown = true }
    }
    return FlareStorageTotals(
        knownBytes: knownBytes,
        hasUnknown: hasUnknown,
        total: flareIsKnownBytes(totalBytes) ? (totalBytes ?? knownBytes) : knownBytes
    )
}

/// This category's share of `total`, in 0...1, or `nil` when it cannot be drawn:
/// the size is unknown, or the total is zero/unknown. A missing bar is the
/// honest answer — a zero-width bar would read as "this category is empty".
public func storageShare(_ bytes: Double?, total: Double?) -> Double? {
    guard flareIsKnownBytes(bytes), let bytes,
          flareIsKnownBytes(total), let total, total > 0 else { return nil }
    let share = bytes / total
    return share > 1 ? 1 : share
}

/// Whether to offer a clear button at all. The host must say the category is
/// clearable, and a category measured at exactly 0 bytes offers nothing to
/// clear. An unknown size keeps the button: not having measured it is not
/// evidence that it is empty.
public func canClearStorage(_ category: FlareStorageCategory?) -> Bool {
    guard let category, category.clearable else { return false }
    return category.bytes != 0
}

/// Storage management — the "storage space" section of the settings page.
///
/// The host measures the categories and says which ones it can clear; this view
/// only shows the snapshot and dispatches the intent. Clearing is irreversible,
/// so the button carries danger colour + icon, but the second confirmation is
/// **not** here: the host wraps `onClear` in DangerConfirm. A category whose
/// size the host has not measured reads `unknownText`, never 0 B.
/// Spec: Profile/StorageUsage.
public struct StorageUsageView: View {
    let categories: [FlareStorageCategory]
    let totalBytes: Double?
    let deviceFreeBytes: Double?
    let loading: Bool
    let error: String?
    let locale: String?
    let title, unknownText, atLeastText: String
    let clearText, clearingText: String
    let totalText, deviceFreeText: String
    let reloadText, retryText, dismissErrorText: String
    let loadingText, emptyText, fileCountText: String
    let onClear: ((String) -> Void)?
    let onReload: (() -> Void)?
    /// `nil` dismisses the whole-snapshot error; a String dismisses that category's.
    let onDismissError: ((String?) -> Void)?

    @Environment(\.colorScheme) private var scheme

    public init(categories: [FlareStorageCategory],
                totalBytes: Double? = nil,
                deviceFreeBytes: Double? = nil,
                loading: Bool = false,
                error: String? = nil,
                locale: String? = nil,
                title: String = "存储空间",
                unknownText: String = "未知",
                atLeastText: String = "至少",
                clearText: String = "清理",
                clearingText: String = "清理中",
                totalText: String = "总计",
                deviceFreeText: String = "可用空间",
                reloadText: String = "重新统计",
                retryText: String = "失败重试",
                dismissErrorText: String = "忽略此错误",
                loadingText: String = "正在统计存储占用",
                emptyText: String = "没有可统计的存储分类",
                fileCountText: String = "{count} 个文件",
                onClear: ((String) -> Void)? = nil,
                onReload: (() -> Void)? = nil,
                onDismissError: ((String?) -> Void)? = nil) {
        self.categories = categories; self.totalBytes = totalBytes
        self.deviceFreeBytes = deviceFreeBytes; self.loading = loading; self.error = error
        self.locale = locale; self.title = title; self.unknownText = unknownText
        self.atLeastText = atLeastText; self.clearText = clearText
        self.clearingText = clearingText; self.totalText = totalText
        self.deviceFreeText = deviceFreeText; self.reloadText = reloadText
        self.retryText = retryText; self.dismissErrorText = dismissErrorText
        self.loadingText = loadingText; self.emptyText = emptyText
        self.fileCountText = fileCountText
        self.onClear = onClear; self.onReload = onReload; self.onDismissError = onDismissError
    }

    public func sizeText(_ bytes: Double?) -> String {
        formatBytes(bytes, locale: locale) ?? unknownText
    }

    public func fileCountLabel(_ count: Int?) -> String? {
        guard let count, count >= 0 else { return nil }
        return fileCountText.replacingOccurrences(of: "{count}", with: "\(count)")
    }

    /// The sum is only a floor when this view computed it and something is unmeasured.
    func totalIsFloor(_ totals: FlareStorageTotals) -> Bool {
        totals.hasUnknown && !flareIsKnownBytes(totalBytes)
    }

    public func totalLabel(_ totals: FlareStorageTotals) -> String {
        let value = sizeText(totals.total)
        return totalIsFloor(totals) ? "\(atLeastText) \(value)" : value
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let totals = storageTotals(categories, totalBytes: totalBytes)
        let showSkeleton = loading && categories.isEmpty
        let showEmpty = !loading && error == nil && categories.isEmpty
        VStack(alignment: .leading, spacing: 0) {
            head(colors, totals)
            if loading { loadingView(colors) }
            if let error { globalError(error, colors: colors) }
            if showSkeleton {
                skeleton(colors)
            } else if showEmpty {
                Text(emptyText)
                    .font(.system(size: FlareSizes.fontSizeMd))
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, FlareSizes.spacingMd)
            } else {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                    if index > 0 {
                        Rectangle().fill(colors.borderSecondary).frame(height: 1)
                    }
                    rowView(category, totals: totals, colors: colors)
                }
            }
        }
        .padding(FlareSizes.spacingMd)
        .background(
            RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                .fill(colors.bgPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                        .stroke(colors.borderPrimary, lineWidth: 1)
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }

    private func head(_ colors: FlareColors, _ totals: FlareStorageTotals) -> some View {
        HStack(alignment: .top, spacing: FlareSizes.spacingSm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                Text(headSummary(totals))
                    .font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if let onReload {
                textButton(symbol: "arrow.clockwise", label: reloadText,
                           enabled: !loading, colors: colors, action: onReload)
            }
        }
        .padding(.bottom, FlareSizes.spacingSm)
    }

    func headSummary(_ totals: FlareStorageTotals) -> String {
        let total = "\(totalText) \(totalLabel(totals))"
        guard let free = formatBytes(deviceFreeBytes, locale: locale) else { return total }
        return "\(total) · \(deviceFreeText) \(free)"
    }

    private func loadingView(_ colors: FlareColors) -> some View {
        HStack(spacing: 5) {
            ProgressView().controlSize(.small)
            Text(loadingText)
                .font(.system(size: FlareSizes.fontSizeSm))
                .foregroundColor(colors.textTertiary)
        }
        .padding(.bottom, FlareSizes.spacingSm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(loadingText)
    }

    /// The whole snapshot failed: the categories already known stay on screen and
    /// the banner offers a re-measure.
    private func globalError(_ message: String, colors: FlareColors) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 12))
                .foregroundColor(colors.error)
            Text(message)
                .font(.system(size: FlareSizes.fontSizeSm))
                .foregroundColor(colors.error)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if let onReload {
                textButton(symbol: "arrow.clockwise", label: reloadText,
                           enabled: !loading, colors: colors, action: onReload)
            }
            if let onDismissError {
                Button { onDismissError(nil) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundColor(colors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(dismissErrorText)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusSm).fill(colors.error.opacity(0.08)))
        .padding(.bottom, FlareSizes.spacingSm)
    }

    /// A first measurement in progress — bounded placeholder rows, never an
    /// empty-list message.
    private func skeleton(_ colors: FlareColors) -> some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: FlareSizes.radiusSm)
                        .fill(colors.bgSecondary).frame(width: 120, height: 14)
                    RoundedRectangle(cornerRadius: FlareSizes.radiusSm)
                        .fill(colors.bgSecondary).frame(height: 8)
                }
                .frame(minHeight: FlareSizes.touchTarget)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func rowView(_ category: FlareStorageCategory,
                         totals: FlareStorageTotals,
                         colors: FlareColors) -> some View {
        let share = storageShare(category.bytes, total: totals.total)
        let canClear = canClearStorage(category) && onClear != nil
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            HStack(spacing: FlareSizes.spacingMd) {
                ZStack {
                    Circle().fill(colors.primary.opacity(0.10)).frame(width: 32, height: 32)
                    Image(systemName: "doc")
                        .font(.system(size: 16))
                        .foregroundColor(colors.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.label)
                        .font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
                        .foregroundColor(colors.textPrimary)
                    Text(rowMeta(category))
                        .font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(colors.textSecondary)
                }
                Spacer(minLength: FlareSizes.spacingSm)
                if category.busy {
                    HStack(spacing: 5) {
                        ProgressView().controlSize(.small)
                        Text(clearingText)
                            .font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.textTertiary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(clearingText)
                } else if canClear {
                    clearButton(category, colors: colors)
                }
            }
            .frame(minHeight: FlareSizes.touchTarget)

            if let share {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(colors.bgSecondary)
                        Capsule().fill(colors.primary)
                            .frame(width: max(2, geo.size.width * share))
                    }
                }
                .frame(height: 4)
                .padding(.leading, 44)
                .accessibilityHidden(true)
            }

            if let error = category.error {
                rowError(category, message: error, canClear: canClear, colors: colors)
            }
        }
        .padding(.vertical, FlareSizes.spacingSm)
    }

    func rowMeta(_ category: FlareStorageCategory) -> String {
        let size = sizeText(category.bytes)
        guard let files = fileCountLabel(category.fileCount) else { return size }
        return "\(size) · \(files)"
    }

    /// Clearing is irreversible: danger colour **and** a trash icon, never colour
    /// alone. The confirmation belongs to the host, not to this row.
    private func clearButton(_ category: FlareStorageCategory, colors: FlareColors) -> some View {
        Button { onClear?(category.id) } label: {
            HStack(spacing: 4) {
                Image(systemName: "trash").font(.system(size: 12))
                Text(clearText).font(.system(size: FlareSizes.fontSizeMd))
            }
            .foregroundColor(colors.error)
            .padding(.horizontal, 10)
            .frame(minHeight: FlareSizes.touchTarget)
            .background(
                RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                    .fill(colors.error.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                            .stroke(colors.error.opacity(0.40), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(clearText) \(category.label)")
    }

    private func rowError(_ category: FlareStorageCategory, message: String,
                          canClear: Bool, colors: FlareColors) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 12))
                .foregroundColor(colors.error)
            Text(message)
                .font(.system(size: FlareSizes.fontSizeSm))
                .foregroundColor(colors.error)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if canClear, !category.busy {
                textButton(symbol: "arrow.clockwise", label: retryText,
                           enabled: true, colors: colors) { onClear?(category.id) }
            }
            if let onDismissError {
                Button { onDismissError(category.id) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundColor(colors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(dismissErrorText)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusSm).fill(colors.error.opacity(0.08)))
        .padding(.leading, 44)
    }

    private func textButton(symbol: String, label: String, enabled: Bool,
                            colors: FlareColors, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 11))
                Text(label).font(.system(size: FlareSizes.fontSizeSm))
            }
            .foregroundColor(colors.textPrimary)
            .opacity(enabled ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}
