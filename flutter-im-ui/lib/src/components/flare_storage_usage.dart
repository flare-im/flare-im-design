import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// One storage category as the host measured it. [id] must be stable — it is
/// echoed in every callback.
@immutable
class FlareStorageCategory {
  const FlareStorageCategory({
    required this.id,
    required this.label,
    this.bytes,
    this.fileCount,
    this.clearable = false,
    this.busy = false,
    this.error,
  });

  final String id;
  final String label;

  /// Bytes this category occupies. `null` (or any non-finite or negative
  /// number) means "not measured yet" — the row says so instead of printing
  /// 0 B, and draws no share bar.
  final num? bytes;

  /// How many files make up the category; omitted when the host does not count them.
  final int? fileCount;

  /// Host can clear this category. `false` hides the clear button entirely.
  final bool clearable;

  /// This category's clear command is in flight — that row alone locks.
  final bool busy;

  /// Why this category's last clear failed; kept until the host dismisses it.
  final String? error;
}

/// Result of [storageTotals].
@immutable
class FlareStorageTotals {
  const FlareStorageTotals({
    required this.knownBytes,
    required this.hasUnknown,
    required this.total,
  });

  /// Sum of the categories whose size is actually known.
  final double knownBytes;

  /// At least one category has no measured size, so [knownBytes] is a floor.
  final bool hasUnknown;

  /// What to display as the total: the host's `totalBytes` when usable, else [knownBytes].
  final double total;
}

const List<String> _storageUnits = ['KB', 'MB', 'GB', 'TB'];

bool _isKnownBytes(num? value) =>
    value != null && value.isFinite && value >= 0;

/// Human byte size, or `null` when the size is not known.
///
/// The rules are identical on all four platforms and deliberately
/// locale-invariant, so one snapshot reads the same on web, Flutter, iOS and
/// Android: unknown (`null` / NaN / infinite / negative) → `null`; below 1024 →
/// `"N B"`; then 1024 per step through KB, MB, GB, TB with one decimal. TB is
/// the last unit, matching the existing attachment formatters.
///
/// [locale] is accepted so hosts can thread their locale through; digits and
/// unit suffixes are the same in every locale on purpose — the same storage
/// snapshot must never read differently on two of the user's devices.
String? formatBytes(num? bytes, [String? locale]) {
  if (!_isKnownBytes(bytes)) return null;
  final value = bytes!.toDouble();
  final rounded = value.round();
  if (rounded < 1024) return '$rounded B';
  var scaled = value / 1024;
  var unit = 0;
  while (scaled >= 1024 && unit < _storageUnits.length - 1) {
    scaled /= 1024;
    unit += 1;
  }
  return '${scaled.toStringAsFixed(1)} ${_storageUnits[unit]}';
}

/// What to show as the overall footprint — same rule set as the other platforms.
///
/// [FlareStorageTotals.knownBytes] only sums the categories that actually have a
/// size and [FlareStorageTotals.hasUnknown] says whether anything was left out,
/// so the component can label its own sum "at least" instead of passing a
/// partial sum off as the truth. A usable host `totalBytes` wins; an unusable
/// one falls back to the sum.
FlareStorageTotals storageTotals(
  List<FlareStorageCategory> categories, [
  num? totalBytes,
]) {
  var knownBytes = 0.0;
  var hasUnknown = false;
  for (final category in categories) {
    if (_isKnownBytes(category.bytes)) {
      knownBytes += category.bytes!.toDouble();
    } else {
      hasUnknown = true;
    }
  }
  return FlareStorageTotals(
    knownBytes: knownBytes,
    hasUnknown: hasUnknown,
    total: _isKnownBytes(totalBytes) ? totalBytes!.toDouble() : knownBytes,
  );
}

/// This category's share of [total], in 0..1, or `null` when it cannot be drawn:
/// the size is unknown, or the total is zero/unknown. A missing bar is the
/// honest answer — a zero-width bar would read as "this category is empty".
double? storageShare(num? bytes, num? total) {
  if (!_isKnownBytes(bytes) || !_isKnownBytes(total) || total! <= 0) return null;
  final share = bytes!.toDouble() / total.toDouble();
  return share > 1 ? 1 : share;
}

/// Whether to offer a clear button at all. The host must say the category is
/// clearable, and a category measured at exactly 0 bytes offers nothing to
/// clear. An unknown size keeps the button: not having measured it is not
/// evidence that it is empty.
bool canClearStorage(FlareStorageCategory? category) {
  if (category == null || !category.clearable) return false;
  return category.bytes != 0;
}

/// Storage management — the "storage space" section of the settings page.
///
/// The host measures the categories and says which ones it can clear; this
/// widget only shows the snapshot and dispatches the intent. Clearing is
/// irreversible, so the button carries danger colour + icon, but the second
/// confirmation is **not** here: the host wraps [onClear] in DangerConfirm.
/// A category whose size the host has not measured reads [unknownText], never
/// 0 B. Spec: Profile/StorageUsage.
class FlareStorageUsage extends StatelessWidget {
  const FlareStorageUsage({
    super.key,
    required this.categories,
    this.totalBytes,
    this.deviceFreeBytes,
    this.loading = false,
    this.error,
    this.locale,
    this.title = '存储空间',
    this.unknownText = '未知',
    this.atLeastText = '至少',
    this.clearText = '清理',
    this.clearingText = '清理中',
    this.totalText = '总计',
    this.deviceFreeText = '可用空间',
    this.reloadText = '重新统计',
    this.retryText = '失败重试',
    this.dismissErrorText = '忽略此错误',
    this.loadingText = '正在统计存储占用',
    this.emptyText = '没有可统计的存储分类',
    this.fileCountText = '{count} 个文件',
    this.onClear,
    this.onReload,
    this.onDismissError,
  });

  /// Per-category snapshot; ids must be stable and are echoed in every callback.
  final List<FlareStorageCategory> categories;

  /// Host-measured overall footprint; omitted, the widget sums what it knows.
  final num? totalBytes;

  /// Free space left on the device, when the host can read it.
  final num? deviceFreeBytes;

  /// First measurement in flight — renders a skeleton, never a fake empty list.
  final bool loading;

  /// Whole-snapshot failure; already-known categories stay on screen.
  final String? error;

  /// BCP-47 tag threaded through to [formatBytes]; sizes read the same in every locale.
  final String? locale;

  final String title,
      unknownText,
      atLeastText,
      clearText,
      clearingText,
      totalText,
      deviceFreeText,
      reloadText,
      retryText,
      dismissErrorText,
      loadingText,
      emptyText,
      fileCountText;

  final void Function(String categoryId)? onClear;
  final VoidCallback? onReload;

  /// `null` dismisses the whole-snapshot error; a String dismisses that category's.
  final void Function(String? categoryId)? onDismissError;

  String _sizeText(num? bytes) => formatBytes(bytes, locale) ?? unknownText;

  String? _fileCountLabel(int? count) {
    if (count == null || count < 0) return null;
    return fileCountText.replaceAll('{count}', '$count');
  }

  /// The sum is only a floor when this widget computed it and something is unmeasured.
  bool _totalIsFloor(FlareStorageTotals totals) =>
      totals.hasUnknown && !_isKnownBytes(totalBytes);

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final totals = storageTotals(categories, totalBytes);
    final totalValue = _sizeText(totals.total);
    final totalLabel = _totalIsFloor(totals) ? '$atLeastText $totalValue' : totalValue;
    final freeLabel = formatBytes(deviceFreeBytes, locale);
    final showSkeleton = loading && categories.isEmpty;
    final showEmpty = !loading && error == null && categories.isEmpty;

    return Semantics(
      container: true,
      label: title,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgPrimary,
          border: Border.all(color: colors.borderPrimary),
          borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        ),
        padding: const EdgeInsets.all(FlareSizes.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _head(colors, totalLabel, freeLabel),
            if (loading) _loading(colors),
            if (error != null) _globalError(colors, error!),
            if (showSkeleton)
              _skeleton(colors)
            else if (showEmpty)
              _empty(colors)
            else
              ListView.builder(
                shrinkWrap: true,
                primary: false,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) => _row(
                  categories[index],
                  colors,
                  totals,
                  isLast: index == categories.length - 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _head(FlareColors colors, String totalLabel, String? freeLabel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FlareSizes.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: FlareSizes.fontSizeLg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  freeLabel == null
                      ? '$totalText $totalLabel'
                      : '$totalText $totalLabel · $deviceFreeText $freeLabel',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: FlareSizes.fontSizeSm,
                  ),
                ),
              ],
            ),
          ),
          if (onReload != null)
            _textButton(
              colors,
              icon: Icons.refresh,
              label: reloadText,
              enabled: !loading,
              onTap: onReload!,
            ),
        ],
      ),
    );
  }

  Widget _loading(FlareColors colors) {
    return Semantics(
      liveRegion: true,
      label: loadingText,
      child: Padding(
        padding: const EdgeInsets.only(bottom: FlareSizes.spacingSm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.textTertiary),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                loadingText,
                style: TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The whole snapshot failed: the categories already known stay on screen and
  /// the banner offers a re-measure.
  Widget _globalError(FlareColors colors, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: FlareSizes.spacingSm),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: colors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.error, fontSize: FlareSizes.fontSizeSm),
            ),
          ),
          if (onReload != null)
            _textButton(
              colors,
              icon: Icons.refresh,
              label: reloadText,
              enabled: !loading,
              onTap: onReload!,
            ),
          if (onDismissError != null)
            IconButton(
              onPressed: () => onDismissError!(null),
              tooltip: dismissErrorText,
              icon: Icon(Icons.close, size: 14, color: colors.textSecondary),
            ),
        ],
      ),
    );
  }

  /// A first measurement in progress — bounded placeholder rows, never an
  /// empty-list message.
  Widget _skeleton(FlareColors colors) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colors.bgSecondary,
                    borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.bgSecondary,
                    borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _empty(FlareColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingMd),
      child: Text(
        emptyText,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.textSecondary, fontSize: FlareSizes.fontSizeMd),
      ),
    );
  }

  Widget _row(
    FlareStorageCategory category,
    FlareColors colors,
    FlareStorageTotals totals, {
    required bool isLast,
  }) {
    final share = storageShare(category.bytes, totals.total);
    final files = _fileCountLabel(category.fileCount);
    final canClear = canClearStorage(category) && onClear != null;
    final error = category.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.insert_drive_file_outlined,
                          size: 18, color: colors.primary),
                    ),
                    const SizedBox(width: FlareSizes.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category.label,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: FlareSizes.fontSizeLg,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            files == null
                                ? _sizeText(category.bytes)
                                : '${_sizeText(category.bytes)} · $files',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: FlareSizes.fontSizeSm,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: FlareSizes.spacingSm),
                    if (category.busy)
                      Semantics(
                        liveRegion: true,
                        label: clearingText,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: colors.textTertiary),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              clearingText,
                              style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: FlareSizes.fontSizeSm,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (canClear)
                      _clearButton(colors, category),
                  ],
                ),
              ),
              if (share != null)
                Padding(
                  padding: const EdgeInsets.only(left: 44, top: FlareSizes.spacingXs),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
                    child: LinearProgressIndicator(
                      value: share,
                      minHeight: 4,
                      backgroundColor: colors.bgSecondary,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  ),
                ),
              if (error != null) _rowError(colors, category, error, canClear),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: colors.borderSecondary),
      ],
    );
  }

  /// Clearing is irreversible: danger colour **and** a trash icon, never colour
  /// alone. The confirmation belongs to the host, not to this row.
  Widget _clearButton(FlareColors colors, FlareStorageCategory category) {
    return Semantics(
      button: true,
      label: '$clearText ${category.label}',
      child: InkWell(
        onTap: () => onClear!(category.id),
        borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.08),
            border: Border.all(color: colors.error.withValues(alpha: 0.40)),
            borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 14, color: colors.error),
              const SizedBox(width: 4),
              Text(
                clearText,
                style: TextStyle(color: colors.error, fontSize: FlareSizes.fontSizeMd),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowError(
    FlareColors colors,
    FlareStorageCategory category,
    String message,
    bool canClear,
  ) {
    return Container(
      margin: const EdgeInsets.only(left: 44, top: FlareSizes.spacingXs),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: colors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.error, fontSize: FlareSizes.fontSizeSm),
            ),
          ),
          if (canClear && !category.busy)
            _textButton(
              colors,
              icon: Icons.refresh,
              label: retryText,
              enabled: true,
              onTap: () => onClear!(category.id),
            ),
          if (onDismissError != null)
            IconButton(
              onPressed: () => onDismissError!(category.id),
              tooltip: dismissErrorText,
              icon: Icon(Icons.close, size: 14, color: colors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _textButton(
    FlareColors colors, {
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: colors.textPrimary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(color: colors.textPrimary, fontSize: FlareSizes.fontSizeSm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
