import 'package:flutter/material.dart';

import '../models/directory_data.dart' show FlareButtonVariant;
import '../models/plugin_layout.dart';
import '../models/plugin_view.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'call_stage.dart' show CallAnnouncer;
import 'flare_button.dart';
import 'flare_icon.dart';

/// The ink of a plugin tone (success, info, warning, danger; neutral is the
/// secondary text).
Color flarePluginToneColor(FlareColors colors, FlarePluginTone tone) =>
    switch (tone) {
      FlarePluginTone.success => colors.success,
      FlarePluginTone.info => colors.info,
      FlarePluginTone.warning => colors.warning,
      FlarePluginTone.danger => colors.error,
      FlarePluginTone.neutral => colors.textSecondary,
    };

/// The tone icon in its tinted circle: the result view's 56 / 32 and the
/// status card's 48 / 28.
class FlarePluginToneIcon extends StatelessWidget {
  const FlarePluginToneIcon({
    super.key,
    required this.tone,
    this.size = FlareSizes.componentResultIconSize,
    this.animate = false,
  });
  final FlarePluginTone tone;
  final double size;

  /// Scale 0.6 → 1 on appearing (none under reduced motion).
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final color = flarePluginToneColor(FlareColors.of(context), tone);
    final circle = ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: FlareOpacity.tintWeak),
        ),
        child: FlareIcon(
          flarePluginToneIcon(tone),
          size: size * 4 / 7,
          color: color,
        ),
      ),
    );
    if (!animate || MediaQuery.disableAnimationsOf(context)) return circle;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      // §7: transitions.spring.
      duration: FlareMotion.spring,
      curve: FlareMotion.springCurve,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: circle,
    );
  }
}

/// Result view — the one outcome layout of a money action, a verification
/// submit or a failed send (spec Plugin/ResultView; R7 of
/// docs/plugin-experience.md): tone icon, title, amount, description, the
/// details as label/value rows, the done key and an optional secondary key.
/// The title and description are announced politely when they appear.
class FlareResultView extends StatelessWidget {
  const FlareResultView({
    super.key,
    required this.title,
    this.tone = FlarePluginTone.info,
    this.amount,
    this.description,
    this.details = const [],
    this.doneLabel,
    this.secondaryLabel,
    this.busy = false,
    this.onDone,
    this.onSecondary,
    this.actions = const [],
  });

  final String title;
  final FlarePluginTone tone;
  final String? amount;
  final String? description;
  final List<FlarePluginField> details;

  /// pluginView.done when null.
  final String? doneLabel;
  final String? secondaryLabel;
  final bool busy;

  /// Without it no done key is drawn.
  final VoidCallback? onDone;
  final VoidCallback? onSecondary;

  /// The actions slot: more keys after [secondaryLabel] (a plugin's other
  /// actions).
  final List<Widget> actions;

  static const Key doneKey = ValueKey('flare-result-done');
  static const Key secondaryKey = ValueKey('flare-result-secondary');

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final pc =
        (MediaQuery.maybeSizeOf(context)?.width ?? 0) >=
        FlareSizes.appShellCompactMinWidth;
    Widget key(Widget child) => pc
        ? Center(
            child: SizedBox(
              width: FlareSizes.componentResultActionWidth,
              child: child,
            ),
          )
        : child;
    final words = [title, if (description?.isNotEmpty ?? false) description!];
    return CallAnnouncer(
      message: words.join(' '),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FlareSizes.componentFormColumnWidth,
          ),
          // R7: the announcer reads the title and description once; no live
          // region on top of it.
          child: Semantics(
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: FlareSizes.spacingXl),
                Center(child: FlarePluginToneIcon(tone: tone, animate: true)),
                const SizedBox(height: FlareSizes.spacingLg),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    key: const ValueKey('flare-result-title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: FlareTextRoles.title.fontSize,
                      height: FlareTextRoles.title.lineHeight,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (amount?.isNotEmpty ?? false) ...[
                  const SizedBox(height: FlareSizes.spacingSm),
                  Text(
                    amount!,
                    key: const ValueKey('flare-result-amount'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: FlareSizes.componentAmountHeroFontSize,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                if (description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: FlareSizes.spacingSm),
                  Text(
                    description!,
                    key: const ValueKey('flare-result-description'),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeLg,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                if (details.isNotEmpty) ...[
                  const SizedBox(height: FlareSizes.spacing2xl),
                  FlareDescriptionRows(fields: details),
                ],
                const SizedBox(height: FlareSizes.spacing2xl),
                if (onDone != null)
                  key(
                    FlareButton(
                      key: doneKey,
                      label: doneLabel ?? strings.pluginViewDone,
                      block: true,
                      loading: busy,
                      disabled: busy,
                      onPressed: onDone,
                    ),
                  ),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: FlareSizes.spacingSm),
                  key(
                    FlareButton(
                      key: secondaryKey,
                      label: secondaryLabel,
                      variant: FlareButtonVariant.secondary,
                      block: true,
                      disabled: busy,
                      onPressed: onSecondary,
                    ),
                  ),
                ],
                for (final widget in actions) ...[
                  const SizedBox(height: FlareSizes.spacingSm),
                  key(widget),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Label/value rows on a quiet card (the kit DescriptionList): the label 13
/// secondary at the start, the value 14 primary at the end, amounts in
/// tabular figures.
class FlareDescriptionRows extends StatelessWidget {
  const FlareDescriptionRows({super.key, required this.fields});
  final List<FlarePluginField> fields;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlareSizes.spacingLg,
        vertical: FlareSizes.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final field in fields)
            MergeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FlareSizes.spacingSm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: TextStyle(
                        fontSize: FlareSizes.fontSizeMd,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: FlareSizes.spacingLg),
                    Expanded(
                      child: Text(
                        flarePluginStatusText(
                          flarePluginFormatText(
                            field.value,
                            field.format,
                            strings,
                          ),
                          unmapped: field.unmapped,
                          strings: strings,
                          where: field.label,
                        ),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: FlareSizes.fontSizeLg,
                          color: colors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
