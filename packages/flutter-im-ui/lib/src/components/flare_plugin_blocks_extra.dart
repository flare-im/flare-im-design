import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../models/plugin_view.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_icon.dart';
import 'flare_icon_button.dart';
import 'flare_status_banner.dart';
import 'flare_tag.dart';
import 'qr/flare_qr_code_frame.dart';

/// What an image block asks the host for: a package asset path or the id of
/// a file the plugin uploaded privately.
typedef FlarePluginImageSource = ({String? asset, String? fileId});

/// Turns an image block's source into what the host fetched (a memory, file
/// or network image it already authorized); null when it has nothing.
typedef FlarePluginImageResolver =
    FutureOr<ImageProvider<Object>?> Function(FlarePluginImageSource source);

// The vocabulary 2 blocks of FlarePluginView (docs/plugin-components.md, spec
// plugin-view-vectors.json blocks2). Each draws an already resolved block from
// kit tokens; actions go back through the view's runner.

/// A section's heading: its label and the key that folds the blocks after it.
/// The view draws the children; a section without a label has no heading.
class FlarePluginSectionHeader extends StatelessWidget {
  const FlarePluginSectionHeader({
    super.key,
    required this.block,
    required this.collapsed,
    required this.onToggle,
  });
  final FlarePluginSectionBlock block;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final label = block.label;
    if (label == null || label.isEmpty) return const SizedBox.shrink();
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    // R1: the view puts 24 above a section; the heading adds none.
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              label,
              // R1: textRole.section in secondary text, never the brand.
              style: TextStyle(
                fontSize: FlareTextRoles.section.fontSize,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          expanded: !collapsed,
          child: InkWell(
            key: const ValueKey('flare-plugin-section-toggle'),
            borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: FlareSizes.touchTargetMin,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FlareSizes.spacingXs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      collapsed ? strings.expand : strings.collapse,
                      style: TextStyle(
                        fontSize: FlareSizes.fontSizeSm,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: FlareSizes.spacing3xs),
                    FlareIcon(
                      collapsed ? 'chevron-down' : 'chevron-up',
                      size: FlareSizes.iconSizeXs,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Color _toneInk(FlareColors colors, FlarePluginTone? tone) => switch (tone) {
  FlarePluginTone.info => colors.infoText,
  FlarePluginTone.success => colors.successText,
  FlarePluginTone.warning => colors.warningText,
  FlarePluginTone.danger => colors.errorText,
  _ => colors.textPrimary,
};

/// 2 to 6 figures side by side: label, the formatted value, the plugin's
/// trend with its direction (reported, never judged).
class FlarePluginStatsView extends StatelessWidget {
  const FlarePluginStatsView({super.key, required this.block});
  final FlarePluginStatsBlock block;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = block.items.length;
        final perRow = constraints.hasBoundedWidth
            ? math.max(1, math.min(count, (constraints.maxWidth / 104).floor()))
            : count;
        final width = constraints.hasBoundedWidth
            ? (constraints.maxWidth - FlareSizes.spacingMd * (perRow - 1)) /
                  perRow
            : 104.0;
        return Wrap(
          spacing: FlareSizes.spacingMd,
          runSpacing: FlareSizes.spacingMd,
          children: [
            for (final item in block.items)
              SizedBox(
                width: width,
                child: Semantics(
                  container: true,
                  label: item.label,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: FlareSizes.fontSizeSm,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: FlareSizes.spacingXs),
                      Text(
                        flarePluginFormatText(item.value, item.format, strings),
                        key: const ValueKey('flare-plugin-stat-value'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: FlareSizes.fontSize2xl,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: _toneInk(colors, item.tone),
                        ),
                      ),
                      if (item.trend case final trend?
                          when trend.text.trim().isNotEmpty) ...[
                        const SizedBox(height: FlareSizes.spacing3xs),
                        Semantics(
                          label: switch (trend.direction) {
                            FlarePluginTrendDirection.up =>
                              '${strings.pluginViewTrendUp} ${trend.text}',
                            FlarePluginTrendDirection.down =>
                              '${strings.pluginViewTrendDown} ${trend.text}',
                            FlarePluginTrendDirection.flat =>
                              '${strings.pluginViewTrendFlat} ${trend.text}',
                          },
                          excludeSemantics: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (trend.direction !=
                                  FlarePluginTrendDirection.flat)
                                FlareIcon(
                                  trend.direction ==
                                          FlarePluginTrendDirection.up
                                      ? 'chevron-up'
                                      : 'chevron-down',
                                  size: 12,
                                  color: colors.textSecondary,
                                ),
                              Text(
                                trend.text.trim(),
                                style: TextStyle(
                                  fontSize: FlareSizes.fontSizeSm,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The series colours in order, and a donut's slice colours: the chart tokens
/// (`colors.chart.series1..6`), never the status colours.
List<Color> _seriesColours(FlareColors colors) => [
  colors.chartSeries1,
  colors.chartSeries2,
  colors.chartSeries3,
];
List<Color> _sliceColours(FlareColors colors) => [
  colors.chartSeries1,
  colors.chartSeries2,
  colors.chartSeries3,
  colors.chartSeries4,
  colors.chartSeries5,
  colors.chartSeries6,
];

/// Bars, lines or a donut, painted with Canvas from kit colours (no chart
/// library); every point is also read by the screen reader. No point at all:
/// the empty text.
class FlarePluginChartView extends StatelessWidget {
  const FlarePluginChartView({super.key, required this.block});
  final FlarePluginChartBlock block;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    if (!flarePluginChartHasPoints(block.series)) {
      return Text(
        block.emptyText ?? strings.pluginViewEmpty,
        key: const ValueKey('flare-plugin-chart-empty'),
        style: TextStyle(
          fontSize: FlareSizes.fontSizeMd,
          color: colors.textTertiary,
        ),
      );
    }
    final donut = block.chartKind == FlarePluginChartKind.donut;
    final series = block.series.take(donut ? 1 : 3).toList();
    final summary = [
      for (final s in series)
        [
          if (s.label != null) s.label!,
          for (final p in s.points) '${p.label} ${p.text}',
        ].join(', '),
    ].join('; ');
    final labels = series.fold<List<String>>(
      const [],
      (longest, s) => s.points.length > longest.length
          ? [for (final p in s.points) p.label]
          : longest,
    );
    final legend = donut
        ? [
            for (final (i, p) in series.first.points.indexed)
              (
                label: p.label,
                text: p.text,
                colour: _sliceColours(colors)[i % 6],
              ),
          ]
        : series.length > 1
        ? [
            for (final (i, s) in series.indexed)
              (
                label: s.label ?? '',
                text: '',
                colour: _seriesColours(colors)[i],
              ),
          ]
        : <({String label, String text, Color colour})>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          image: true,
          label: summary,
          child: donut
              ? Center(
                  child: SizedBox.square(
                    dimension: FlareSizes.controlHeightLg * 4,
                    child: CustomPaint(
                      painter: _DonutPainter(
                        slices: flarePluginDonutSlices([
                          for (final p in series.first.points) p.value,
                        ]),
                        colours: _sliceColours(colors),
                        track: colors.bgTertiary,
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  height: FlareSizes.controlHeightLg * 3,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _PlotPainter(
                      kind: block.chartKind,
                      series: series,
                      count: labels.length,
                      colours: _seriesColours(colors),
                      grid: colors.borderSecondary,
                      zero: colors.borderPrimary,
                    ),
                  ),
                ),
        ),
        if (!donut && labels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: FlareSizes.spacing2xs),
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(labels.first, style: _axis(colors)),
                  if (labels.length > 1)
                    Text(labels.last, style: _axis(colors)),
                ],
              ),
            ),
          ),
        if (legend.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: FlareSizes.spacingSm),
            child: ExcludeSemantics(
              child: Wrap(
                spacing: FlareSizes.spacingMd,
                runSpacing: FlareSizes.spacingXs,
                children: [
                  for (final item in legend)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: FlareSizes.spacingSm,
                          height: FlareSizes.spacingSm,
                          decoration: BoxDecoration(
                            color: item.colour,
                            borderRadius: BorderRadius.circular(
                              FlareSizes.radiusXs,
                            ),
                          ),
                        ),
                        const SizedBox(width: FlareSizes.spacing2xs),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: FlareSizes.fontSizeSm,
                            color: colors.textSecondary,
                          ),
                        ),
                        if (item.text.isNotEmpty) ...[
                          const SizedBox(width: FlareSizes.spacingXs),
                          Text(
                            item.text,
                            style: TextStyle(
                              fontSize: FlareSizes.fontSizeSm,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  TextStyle _axis(FlareColors colors) =>
      TextStyle(fontSize: FlareSizes.fontSizeXs, color: colors.textTertiary);
}

class _PlotPainter extends CustomPainter {
  _PlotPainter({
    required this.kind,
    required this.series,
    required this.count,
    required this.colours,
    required this.grid,
    required this.zero,
  });
  final FlarePluginChartKind kind;
  final List<FlarePluginChartSeries> series;
  final int count;
  final List<Color> colours;
  final Color grid;
  final Color zero;

  @override
  void paint(Canvas canvas, Size size) {
    final domain = flarePluginChartDomain([
      for (final s in series)
        for (final p in s.points) p.value,
    ]);
    double y(double value) =>
        size.height * (domain.max - value) / (domain.max - domain.min);
    final ticks = domain.flat
        ? [0.0]
        : domain.min < 0
        ? [domain.max, 0.0, domain.min]
        : [domain.max, domain.max / 2, 0.0];
    for (final tick in ticks) {
      canvas.drawLine(
        Offset(0, y(tick)),
        Offset(size.width, y(tick)),
        Paint()
          ..color = tick == 0 ? zero : grid
          ..strokeWidth = 1,
      );
    }
    if (count == 0) return;
    final slot = size.width / count;
    if (kind == FlarePluginChartKind.bar) {
      final width = math.min(
        slot * 0.64 / series.length,
        12.0 * size.width / 100,
      );
      for (final (si, s) in series.indexed) {
        final paint = Paint()..color = colours[si % colours.length];
        for (final (i, p) in s.points.indexed) {
          if (i >= count) break;
          final center = slot * i + slot / 2;
          final left = center - width * series.length / 2 + width * si;
          final top = math.min(y(p.value), y(0));
          final bottom = math.max(y(p.value), y(0));
          canvas.drawRect(
            Rect.fromLTRB(left, top, left + width, bottom),
            paint,
          );
        }
      }
      return;
    }
    for (final (si, s) in series.indexed) {
      final paint = Paint()
        ..color = colours[si % colours.length]
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      final path = Path();
      for (final (i, p) in s.points.indexed) {
        if (i >= count) break;
        final point = Offset(slot * i + slot / 2, y(p.value));
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      if (s.points.length == 1) {
        canvas.drawCircle(
          Offset(slot / 2, y(s.points.first.value)),
          3,
          Paint()..color = colours[si % colours.length],
        );
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PlotPainter old) =>
      old.series != series ||
      old.kind != kind ||
      old.count != count ||
      old.grid != grid ||
      old.zero != zero ||
      old.colours != colours;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.colours,
    required this.track,
  });
  final List<({int index, double start, double sweep})> slices;
  final List<Color> colours;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 6 / 42;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - stroke) / 2,
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    for (final slice in slices) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + slice.start * math.pi * 2,
        slice.sweep * math.pi * 2,
        false,
        Paint()
          ..color = colours[slice.index % colours.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.slices != slices || old.colours != colours || old.track != track;
}

/// A picture at its declared aspect. The view holds no address: the host's
/// [resolve] turns the asset or file id into an image; until then, or when
/// it has nothing, the frame keeps its size and says so.
class FlarePluginImageView extends StatefulWidget {
  const FlarePluginImageView({super.key, required this.block, this.resolve});
  final FlarePluginImageBlock block;
  final FlarePluginImageResolver? resolve;

  @override
  State<FlarePluginImageView> createState() => _FlarePluginImageViewState();
}

class _FlarePluginImageViewState extends State<FlarePluginImageView> {
  ImageProvider<Object>? _image;
  bool _failed = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(FlarePluginImageView old) {
    super.didUpdateWidget(old);
    if (old.block.asset != widget.block.asset ||
        old.block.fileId != widget.block.fileId ||
        (old.resolve == null) != (widget.resolve == null)) {
      _load();
    }
  }

  void _load() {
    final request = ++_request;
    _image = null;
    _failed = false;
    final resolve = widget.resolve;
    final source = (asset: widget.block.asset, fileId: widget.block.fileId);
    if (resolve == null || (source.asset == null && source.fileId == null)) {
      _failed = true;
      return;
    }
    void settle(ImageProvider<Object>? image) {
      if (!mounted || request != _request) return;
      setState(() {
        _image = image;
        _failed = image == null;
      });
    }

    try {
      final answer = resolve(source);
      if (answer is Future<ImageProvider<Object>?>) {
        answer.then(settle, onError: (_) => settle(null));
      } else {
        _image = answer;
        _failed = answer == null;
      }
    } catch (_) {
      _failed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final image = _image;
    final placeholder = Semantics(
      image: true,
      label: widget.block.alt,
      child: Container(
        color: colors.bgTertiary,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlareIcon('image', size: 24, color: colors.textTertiary),
            if (_failed) ...[
              const SizedBox(height: FlareSizes.spacingXs),
              Text(
                strings.pluginViewImageUnavailable,
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeSm,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
      child: AspectRatio(
        aspectRatio: flarePluginImageRatio(widget.block.aspect),
        child: image == null
            ? placeholder
            : Image(
                image: image,
                fit: BoxFit.cover,
                semanticLabel: widget.block.alt,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

/// A QR code: label above, caption under. Once [FlarePluginQrBlock.expiresAtMs]
/// passes (the server's clock) the code is covered and, when the plugin
/// declared a refresh query and the host listens, offers to refresh.
class FlarePluginQrView extends StatefulWidget {
  const FlarePluginQrView({
    super.key,
    required this.block,
    this.onRefresh,
    this.busy = false,
  });
  final FlarePluginQrBlock block;
  final VoidCallback? onRefresh;
  final bool busy;

  @override
  State<FlarePluginQrView> createState() => _FlarePluginQrViewState();
}

class _FlarePluginQrViewState extends State<FlarePluginQrView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(FlarePluginQrView old) {
    super.didUpdateWidget(old);
    if (old.block.expiresAtMs != widget.block.expiresAtMs ||
        old.block.value != widget.block.value) {
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    final wait = flarePluginQrRefreshMs(
      widget.block.expiresAtMs,
      flarePluginNowMs(),
    );
    if (wait != null) {
      // Wake at least daily: a far-future expiry must not overflow the timer.
      _timer = Timer(Duration(milliseconds: wait.clamp(0, 86400000)), () {
        if (!mounted) return;
        setState(() {});
        _schedule();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final block = widget.block;
    final expired = flarePluginQrExpired(block.expiresAtMs, flarePluginNowMs());
    final refresh = block.refreshOperation != null ? widget.onRefresh : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (block.label case final label? when label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: FlareSizes.spacingSm),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: FlareSizes.fontSizeMd,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: expired ? 0.12 : 1,
                child: ExcludeSemantics(
                  excluding: expired,
                  child: FlareQrCodeFrame(
                    payload: block.value,
                    name: block.label ?? block.caption ?? '',
                    hint: block.caption ?? '',
                  ),
                ),
              ),
              if (expired)
                Positioned.fill(
                  child: Semantics(
                    liveRegion: true,
                    child: Column(
                      key: const ValueKey('flare-plugin-qr-expired'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          strings.pluginViewQrExpired,
                          style: TextStyle(
                            fontSize: FlareSizes.fontSizeMd,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (refresh != null) ...[
                          const SizedBox(height: FlareSizes.spacingSm),
                          FlareButton(
                            key: const ValueKey('flare-plugin-qr-refresh'),
                            label: strings.pluginViewQrRefresh,
                            variant: FlareButtonVariant.secondary,
                            size: FlareControlSize.sm,
                            disabled: widget.busy,
                            onPressed: refresh,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The page's lead figure: label, the formatted value, subtitle and up to
/// three owned actions, on a surface tinted by its tone.
class FlarePluginHeroView extends StatefulWidget {
  const FlarePluginHeroView({
    super.key,
    required this.block,
    this.onAction,
    this.busy = false,
    this.busyActionId,
    this.footer,
  });
  final FlarePluginHeroBlock block;
  final ValueChanged<FlarePluginAction>? onAction;
  final bool busy;
  final String? busyActionId;

  /// The page's quick keys at the bottom of the overview card (R2.1).
  final Widget? footer;

  /// The eye toggle of a maskable hero (rules.heroMask).
  static const maskKey = ValueKey('flare-plugin-hero-mask');

  @override
  State<FlarePluginHeroView> createState() => _FlarePluginHeroViewState();
}

class _FlarePluginHeroViewState extends State<FlarePluginHeroView> {
  // A maskable hero starts shown; the eye hides it for this view only.
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final onAction = widget.onAction;
    final busy = widget.busy;
    final busyActionId = widget.busyActionId;
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final (surface, ink) = switch (block.tone) {
      // R10: the lead amount is never brand-coloured; §5.1 / R2.1: the
      // overview card is bg.primary like the list cards.
      FlarePluginHeroTone.neutral ||
      FlarePluginHeroTone.brand => (colors.bgPrimary, colors.textPrimary),
      FlarePluginHeroTone.positive => (
        Color.lerp(colors.bgPrimary, colors.success, 0.08)!,
        colors.successText,
      ),
      FlarePluginHeroTone.warning => (
        Color.lerp(colors.bgPrimary, colors.warning, 0.08)!,
        colors.warningText,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(FlareSizes.spacingLg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
        border: Border.all(color: colors.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (block.label case final label? when label.isNotEmpty)
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeMd,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              if (block.maskable)
                FlareIconButton(
                  key: FlarePluginHeroView.maskKey,
                  icon: _hidden ? 'eye-off' : 'eye',
                  semanticLabel: _hidden
                      ? strings.accountShowBalance
                      : strings.accountHideBalance,
                  // R10 / §12.4: the eye is a toggle (pressed = hidden).
                  toggled: _hidden,
                  onPressed: () => setState(() => _hidden = !_hidden),
                ),
            ],
          ),
          const SizedBox(height: FlareSizes.spacingXs),
          Semantics(
            label: block.maskable && _hidden
                ? strings.accountBalanceHidden
                : null,
            excludeSemantics: block.maskable && _hidden,
            child: Text(
              block.maskable && _hidden
                  ? flarePluginMaskedValue
                  : flarePluginFormatText(block.value, block.format, strings),
              key: const ValueKey('flare-plugin-hero-value'),
              style: TextStyle(
                fontSize: block.amount
                    ? FlareSizes.componentAmountHeroFontSize
                    : FlareSizes.fontSize5xl,
                fontWeight: block.amount ? FontWeight.w700 : FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: ink,
              ),
            ),
          ),
          if (block.subtitle case final subtitle? when subtitle.isNotEmpty) ...[
            const SizedBox(height: FlareSizes.spacingXs),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: FlareSizes.fontSizeSm,
                color: colors.textSecondary,
              ),
            ),
          ],
          if (block.actions.isNotEmpty) ...[
            const SizedBox(height: FlareSizes.spacingMd),
            Wrap(
              spacing: FlareSizes.spacingSm,
              runSpacing: FlareSizes.spacingSm,
              children: [
                for (final (i, action) in block.actions.indexed)
                  FlareButton(
                    key: ValueKey('flare-plugin-action-${action.id}'),
                    label: action.label,
                    variant: action.style == FlarePluginActionStyle.danger
                        ? FlareButtonVariant.danger
                        : action.style == FlarePluginActionStyle.primary ||
                              i == 0
                        ? FlareButtonVariant.primary
                        : FlareButtonVariant.secondary,
                    size: FlareControlSize.sm,
                    maintainTouchTarget: true,
                    loading: busyActionId == action.id,
                    disabled: busy || onAction == null,
                    onPressed: () => onAction?.call(action),
                  ),
              ],
            ),
          ],
          if (widget.footer case final footer?) ...[
            const SizedBox(height: FlareSizes.spacingLg),
            footer,
          ],
        ],
      ),
    );
  }
}

/// 2 to 6 steps on a line: done (a check), failed (a cross), current (the
/// brand ring) or pending (its number), the state also said in words.
class FlarePluginStepsView extends StatelessWidget {
  const FlarePluginStepsView({super.key, required this.block});
  final FlarePluginStepsBlock block;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    const marker = FlareSizes.spacingXl;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, step) in block.items.indexed)
          Expanded(
            child: Semantics(
              key: ValueKey('flare-plugin-step-${step.state.name}'),
              // §12.5: 第 N 步，共 M 步：label, state.
              label:
                  '${strings.pluginViewStepPosition.replaceAll('{index}', '${i + 1}').replaceAll('{count}', '${block.items.length}')}: '
                  '${step.label}, ${_stepText(strings, step.state)}',
              excludeSemantics: true,
              child: Column(
                children: [
                  SizedBox(
                    height: marker,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (i > 0)
                          Positioned(
                            left: 0,
                            right: 0,
                            child: FractionallySizedBox(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: 0.5,
                              child: Container(
                                height: 2,
                                color:
                                    block.items[i - 1].state ==
                                        FlarePluginStepState.done
                                    ? colors.primary
                                    : colors.borderSecondary,
                              ),
                            ),
                          ),
                        if (i < block.items.length - 1)
                          Positioned(
                            left: 0,
                            right: 0,
                            child: FractionallySizedBox(
                              alignment: AlignmentDirectional.centerEnd,
                              widthFactor: 0.5,
                              child: Container(
                                height: 2,
                                color: step.state == FlarePluginStepState.done
                                    ? colors.primary
                                    : colors.borderSecondary,
                              ),
                            ),
                          ),
                        Container(
                          width: marker,
                          height: marker,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: switch (step.state) {
                              FlarePluginStepState.done => colors.primary,
                              FlarePluginStepState.failed => colors.error,
                              _ => colors.bgPrimary,
                            },
                            border: Border.all(
                              width: 2,
                              color: switch (step.state) {
                                FlarePluginStepState.done ||
                                FlarePluginStepState.current => colors.primary,
                                FlarePluginStepState.failed => colors.error,
                                FlarePluginStepState.pending =>
                                  colors.borderSecondary,
                              },
                            ),
                          ),
                          child: switch (step.state) {
                            FlarePluginStepState.done => FlareIcon(
                              'check',
                              size: 12,
                              color: colors.bgPrimary,
                            ),
                            FlarePluginStepState.failed => FlareIcon(
                              'close',
                              size: 12,
                              color: colors.bgPrimary,
                            ),
                            _ => Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: FlareSizes.fontSizeXs,
                                color:
                                    step.state == FlarePluginStepState.current
                                    ? colors.primaryText
                                    : colors.textTertiary,
                              ),
                            ),
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: FlareSizes.spacingXs),
                  Text(
                    step.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeSm,
                      fontWeight: step.state == FlarePluginStepState.current
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: switch (step.state) {
                        FlarePluginStepState.current => colors.textPrimary,
                        FlarePluginStepState.failed => colors.errorText,
                        _ => colors.textSecondary,
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String _stepText(FlareStrings strings, FlarePluginStepState state) =>
    switch (state) {
      FlarePluginStepState.pending => strings.pluginViewStepPending,
      FlarePluginStepState.current => strings.pluginViewStepCurrent,
      FlarePluginStepState.done => strings.pluginViewStepDone,
      FlarePluginStepState.failed => strings.pluginViewStepFailed,
    };

/// A prominent notice as the kit status banner, with the action it owns.
class FlarePluginBannerView extends StatelessWidget {
  const FlarePluginBannerView({
    super.key,
    required this.block,
    this.onAction,
    this.busy = false,
  });
  final FlarePluginBannerBlock block;
  final ValueChanged<FlarePluginAction>? onAction;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final action = block.action;
    return FlareStatusBanner(
      text: block.text,
      tone: FlareStatusTone.values.byName(block.tone.name),
      actionText: action?.label,
      onAction: action == null || busy || onAction == null
          ? null
          : () => onAction!(action),
    );
  }
}

/// Dated items on a rail: time (as the time block writes it), title, detail
/// and status tag. No item: the empty text.
class FlarePluginTimelineView extends StatelessWidget {
  const FlarePluginTimelineView({super.key, required this.block});
  final FlarePluginTimelineBlock block;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    if (block.items.isEmpty) {
      return Text(
        block.emptyText ?? strings.pluginViewEmpty,
        key: const ValueKey('flare-plugin-timeline-empty'),
        style: TextStyle(
          fontSize: FlareSizes.fontSizeMd,
          color: colors.textTertiary,
        ),
      );
    }
    final now = flarePluginNowMs();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, item) in block.items.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: FlareSizes.spacingMd,
                  child: Column(
                    children: [
                      const SizedBox(height: FlareSizes.spacingXs),
                      Container(
                        width: FlareSizes.spacingSm,
                        height: FlareSizes.spacingSm,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary,
                        ),
                      ),
                      if (i < block.items.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: colors.borderSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: FlareSizes.spacingSm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: FlareSizes.spacingMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: FlareSizes.spacingXs,
                          runSpacing: FlareSizes.spacing3xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: FlareSizes.fontSizeMd,
                                color: colors.textPrimary,
                              ),
                            ),
                            if (item.status case final status?)
                              FlareTag(
                                label: status.text,
                                tone: FlareStatusTone.values.byName(
                                  status.tone.name,
                                ),
                              ),
                          ],
                        ),
                        if (item.detail case final detail?
                            when detail.isNotEmpty)
                          Text(
                            detail,
                            style: TextStyle(
                              fontSize: FlareSizes.fontSizeSm,
                              color: colors.textSecondary,
                            ),
                          ),
                        Text(
                          flarePluginDateTime(item.atMs, now, strings),
                          style: TextStyle(
                            fontSize: FlareSizes.fontSizeXs,
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
