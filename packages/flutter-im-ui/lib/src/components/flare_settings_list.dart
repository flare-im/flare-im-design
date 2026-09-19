import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';

/// Settings list — grouped toggle / navigation / value rows. A generic settings
/// container. Spec: Profile/SettingsList (`FlareSettingsList`).
class FlareSettingsList extends StatelessWidget {
  const FlareSettingsList({
    super.key,
    required this.sections,
    this.onToggle,
    this.onSelect,
    this.shrinkWrap = false,
  });

  final List<FlareSettingsSection> sections;
  final void Function(FlareSettingsItem item, bool value)? onToggle;
  final ValueChanged<FlareSettingsItem>? onSelect;

  /// When true, sizes to its content and disables its own scrolling — so it can
  /// be embedded inside another scroll view (e.g. a profile / contact page).
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
      children: [
        for (final section in sections) ...[
          if (section.title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FlareSizes.spacingLg,
                FlareSizes.spacingXs,
                FlareSizes.spacingLg,
                FlareSizes.spacingXs,
              ),
              child: Text(
                section.title!,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: FlareSizes.fontSizeSm,
                ),
              ),
            ),
          // Rows float together on one elevated grouped card.
          Container(
            margin: const EdgeInsets.fromLTRB(
              FlareSizes.spacingMd,
              0,
              FlareSizes.spacingMd,
              FlareSizes.spacingLg,
            ),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? const Color(0x80000000)
                      : const Color(0x14151320),
                  blurRadius: isDark ? 24 : 22,
                  offset: const Offset(0, 8),
                ),
                if (isDark)
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.14),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < section.items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: FlareSizes.spacingMd,
                      color: colors.borderSecondary,
                    ),
                  FlareSettingsRow(
                    item: section.items[i],
                    onToggle: onToggle,
                    onSelect: onSelect,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One settings row — the single source of truth for how a [FlareSettingsItem]
/// renders (toggle / value / navigation). Shared by [FlareSettingsList] and
/// [FlareProfilePanel] so the two can't drift apart.
///
/// A value longer than [stackAfterCharacters] characters (a group
/// announcement, a signature) goes on up to three lines under the label in the
/// secondary text colour; beside the label it would squeeze the label to a
/// character per line. A shorter value stays at the end of the row on one line,
/// truncated when it runs out of room. Toggles never stack.
class FlareSettingsRow extends StatelessWidget {
  const FlareSettingsRow({
    super.key,
    required this.item,
    this.onToggle,
    this.onSelect,
  });

  final FlareSettingsItem item;
  final void Function(FlareSettingsItem item, bool value)? onToggle;
  final ValueChanged<FlareSettingsItem>? onSelect;

  /// Values longer than this many characters go under the label.
  static const stackAfterCharacters = 16;

  /// Whether [item]'s value goes under its label.
  static bool stacks(FlareSettingsItem item) =>
      (item.kind == FlareSettingKind.value ||
          item.kind == FlareSettingKind.action ||
          item.kind == FlareSettingKind.navigation) &&
      (item.detail?.runes.length ?? 0) > stackAfterCharacters;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final isToggle = item.kind == FlareSettingKind.toggle;
    // Read-only information is not a control: no button role, no pressed
    // state, no focus stop, and a tap does nothing. Announcing it as a button
    // promises an action the row does not have.
    final readOnly = item.kind == FlareSettingKind.value;
    final enabled =
        !item.disabled &&
        !readOnly &&
        (isToggle ? onToggle != null : onSelect != null);
    final stacked = stacks(item);
    final label = Text(
      item.label,
      style: TextStyle(
        color: item.danger ? colors.error : colors.textPrimary,
        fontSize: FlareSizes.fontSizeLg,
        fontWeight: item.kind == FlareSettingKind.select && item.value
            ? FontWeight.w700
            : FontWeight.w400,
      ),
    );
    final chevron = Icon(Icons.chevron_right, color: colors.textTertiary);
    final detail = item.detail;
    Widget wrap(Widget body) {
      if (readOnly) {
        // "label, detail" as one element, with no control semantics at all.
        return MergeSemantics(
          child: Opacity(opacity: item.disabled ? 0.45 : 1, child: body),
        );
      }
      return Semantics(
        enabled: enabled,
        toggled: isToggle ? item.value : null,
        child: Opacity(
          opacity: item.disabled ? 0.45 : 1,
          child: InkWell(
            onTap: !enabled
                ? null
                : () {
                    if (isToggle) {
                      onToggle?.call(item, !item.value);
                    } else {
                      onSelect?.call(item);
                    }
                  },
            child: body,
          ),
        ),
      );
    }

    return wrap(
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingMd,
          vertical: FlareSizes.spacingMd,
        ),
        child: stacked
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.icon != null) ...[
                    Icon(
                      flareIconGlyph(item.icon!),
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: FlareSizes.spacingMd),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(child: label),
                            if (item.kind == FlareSettingKind.navigation)
                              chevron,
                          ],
                        ),
                        const SizedBox(height: FlareSizes.spacingXs),
                        Text(
                          detail!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: FlareSizes.fontSizeMd,
                            height: FlareSizes.lineHeightNormal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            // A short value keeps its own width up to 60% of the row, so the
            // label keeps the rest.
            : LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        flareIconGlyph(item.icon!),
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: FlareSizes.spacingMd),
                    ],
                    Expanded(child: label),
                    switch (item.kind) {
                      FlareSettingKind.toggle => ExcludeSemantics(
                        child: IgnorePointer(
                          child: ExcludeFocus(
                            child: Switch(
                              value: item.value,
                              activeTrackColor: colors.primary,
                              onChanged: enabled ? (_) {} : null,
                            ),
                          ),
                        ),
                      ),
                      // Read-only information, and an action that runs in
                      // place: a detail with no chevron.
                      FlareSettingKind.value ||
                      FlareSettingKind.action => _EndValue(
                        detail ?? '',
                        maxWidth: constraints.maxWidth * 0.6,
                      ),
                      // Pick-one row: a trailing check when this item is the selected one.
                      FlareSettingKind.select =>
                        item.value
                            ? Icon(
                                Icons.check_circle,
                                color: colors.primaryText,
                              )
                            : const SizedBox.shrink(),
                      FlareSettingKind.navigation => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (detail != null)
                            _EndValue(
                              detail,
                              maxWidth: constraints.maxWidth * 0.6,
                            ),
                          chevron,
                        ],
                      ),
                    },
                  ],
                ),
              ),
      ),
    );
  }
}

/// A short value at the end of a row: one line, truncated when the row runs
/// out of room, never pushing the label into a column of single characters.
class _EndValue extends StatelessWidget {
  const _EndValue(this.text, {required this.maxWidth});

  final String text;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsetsDirectional.only(start: FlareSizes.spacingSm),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
        style: TextStyle(
          color: colors.textTertiary,
          fontSize: FlareSizes.fontSizeMd,
        ),
      ),
    );
  }
}
