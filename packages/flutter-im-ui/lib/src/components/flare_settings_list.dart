import 'package:flutter/material.dart';

import '../models/count_badge.dart';
import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_icon.dart';
import 'flare_screen.dart';
import 'flare_status_banner.dart';
import 'flare_switch.dart';
import 'flare_tag.dart';

/// Settings list — grouped toggle / navigation / value rows. A generic settings
/// container. Spec: Profile/SettingsList (`FlareSettingsList`).
class FlareSettingsList extends StatelessWidget {
  const FlareSettingsList({
    super.key,
    required this.sections,
    this.onToggle,
    this.onSelect,
    this.shrinkWrap = false,
    this.flush = false,
  });

  final List<FlareSettingsSection> sections;

  /// Rows run edge to edge on the page's ground, with no card around them and
  /// no inset (Vue `surface="flush"`): entry rows at the top of a list.
  final bool flush;
  final void Function(FlareSettingsItem item, bool value)? onToggle;
  final ValueChanged<FlareSettingsItem>? onSelect;

  /// When true, sizes to its content and disables its own scrolling — so it can
  /// be embedded inside another scroll view (e.g. a profile / contact page).
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    // Vue `.flare-settings.is-detail`: the detail pane owns the gutter.
    final inset = FlareScreen.detailOf(context) ? 0.0 : FlareSizes.spacingMd;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: flush
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
      children: [
        for (final section in sections) ...[
          if (section.title != null)
            Padding(
              // Vue `.flare-settings__title`: inset past the card's edge.
              padding: EdgeInsets.fromLTRB(
                inset + FlareSizes.spacingSm,
                FlareSizes.spacingXs,
                inset + FlareSizes.spacingSm,
                FlareSizes.spacingSm,
              ),
              child: Text(
                section.title!,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: FlareSizes.fontSizeSm,
                  fontWeight: FontWeight.w500,
                  height: FlareSizes.lineHeightNormal,
                ),
              ),
            ),
          // Vue `.flare-settings__group`: quiet groups with one shared edge, no stacked shadows.
          Container(
            margin: flush
                ? EdgeInsets.zero
                : EdgeInsets.fromLTRB(
                    inset,
                    0,
                    inset,
                    _hasFooter(section)
                        ? FlareSizes.spacingXs
                        : FlareSizes.spacingLg,
                  ),
            decoration: flush
                ? BoxDecoration(color: colors.bgPrimary)
                : BoxDecoration(
                    color: colors.bgElevated,
                    borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
                    border: Border.all(color: colors.borderSecondary),
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
          if (_hasFooter(section)) _SectionFooter(text: section.footer!),
        ],
      ],
    );
  }

  static bool _hasFooter(FlareSettingsSection section) =>
      section.footer?.isNotEmpty ?? false;
}

/// The note under a settings section's card, in the section title's quiet
/// colour.
class _SectionFooter extends StatelessWidget {
  const _SectionFooter({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      FlareSizes.spacingLg,
      0,
      FlareSizes.spacingLg,
      FlareSizes.spacingLg,
    ),
    child: Text(
      text,
      style: TextStyle(
        color: FlareColors.of(context).textTertiary,
        fontSize: FlareSizes.fontSizeSm,
        height: FlareSizes.lineHeightNormal,
      ),
    ),
  );
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
    this.compact = false,
  });

  final FlareSettingsItem item;
  final void Function(FlareSettingsItem item, bool value)? onToggle;
  final ValueChanged<FlareSettingsItem>? onSelect;

  /// A row of a sidebar menu (Vue `.flare-profile--sidebar` rows): 40 high,
  /// 8 inset, 13px label, rounded.
  // shortcut: Vue also draws a 2px start bar on the current sidebar row; Flutter cannot round a one-sided border, so only the tint shows.
  final bool compact;

  /// Values longer than this many characters go under the label.
  static const stackAfterCharacters = 16;

  /// Whether [item]'s value goes under its label.
  static bool stacks(FlareSettingsItem item) =>
      (item.kind == FlareSettingKind.value ||
          item.kind == FlareSettingKind.action ||
          item.kind == FlareSettingKind.navigation) &&
      (item.detail?.runes.length ?? 0) > stackAfterCharacters;

  /// Whether [item] draws its red dot: every kind but a toggle, whose end is
  /// the switch.
  static bool drawsBadge(FlareSettingsItem item) =>
      item.badge && item.kind != FlareSettingKind.toggle;

  /// Whether [item] draws its count badge (which takes the dot's place): every
  /// kind but a toggle, when [flareCountBadgeDrawn] says so.
  static bool drawsCountBadge(FlareSettingsItem item) =>
      item.kind != FlareSettingKind.toggle &&
      flareCountBadgeDrawn(item.badgeCount, more: item.badgeMore);

  /// [item]'s tag when it draws one: every kind but a toggle, and only
  /// non-blank words.
  static String? tagText(FlareSettingsItem item) {
    final tag = item.tag?.trim() ?? '';
    return tag.isEmpty || item.kind == FlareSettingKind.toggle ? null : tag;
  }

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
        !item.busy &&
        !readOnly &&
        (isToggle ? onToggle != null : onSelect != null);
    final stacked = stacks(item);
    // A name outside the registry draws the plugin glyph; an empty one none.
    final icon = flareIconNameOrFallback(item.icon);
    final label = Text(
      item.label,
      style: TextStyle(
        color: item.danger ? colors.error : colors.textPrimary,
        fontSize: compact ? FlareSizes.fontSizeMd : FlareSizes.fontSizeLg,
        fontWeight: item.kind == FlareSettingKind.select && item.value
            ? FontWeight.w700
            : FontWeight.w400,
      ),
    );
    // §12.3: every list row ends in the kit's chevron-right 16.
    final chevron = FlareIcon(
      'chevron-right',
      color: colors.textTertiary,
      size: FlareSizes.iconSizeSm,
    );
    final detail = item.detail;
    final toggleDescription = isToggle && (detail?.trim().isNotEmpty ?? false)
        ? detail!.trim()
        : null;
    final badge = drawsCountBadge(item)
        ? _CountBadge(
            text: flareCountBadgeText(item.badgeCount, more: item.badgeMore),
          )
        : drawsBadge(item)
        ? const _Dot()
        : null;
    final tagLabel = tagText(item);
    final tag = tagLabel == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(left: FlareSizes.spacingXs),
            child: FlareTag(
              key: const ValueKey('flare-settings-row-tag'),
              label: tagLabel,
              tone: FlareStatusTone.warning,
            ),
          );
    Widget wrap(Widget body) {
      if (readOnly) {
        // "label, detail" as one element, with no control semantics at all.
        return MergeSemantics(
          child: Opacity(
            opacity: item.disabled ? FlareOpacity.disabled : 1,
            child: body,
          ),
        );
      }
      // R11: a row that does something reads "label, button"; a toggle is a
      // switch (its toggled state) instead.
      return Semantics(
        button: !isToggle,
        enabled: enabled,
        toggled: isToggle ? item.value : null,
        selected: item.current ? true : null,
        child: Opacity(
          opacity: item.disabled ? FlareOpacity.disabled : 1,
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

    final spinner = item.busy
        ? const SizedBox.square(
            key: ValueKey('flare-settings-row-busy'),
            dimension: FlareSizes.iconSizeSm,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : null;
    if (item.centered) {
      return wrap(
        Container(
          constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
          padding: const EdgeInsets.all(FlareSizes.spacingMd),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: label),
              if (spinner != null) ...[
                const SizedBox(width: FlareSizes.spacingSm),
                spinner,
              ],
            ],
          ),
        ),
      );
    }
    return wrap(
      Container(
        constraints: BoxConstraints(
          minHeight: compact
              ? FlareSizes.controlHeightMd
              : FlareSizes.touchTarget,
        ),
        padding: EdgeInsets.all(
          compact ? FlareSizes.spacingSm : FlareSizes.spacingMd,
        ),
        // The current row of an entry rail: its pane is the one beside the
        // list.
        decoration: BoxDecoration(
          color: item.current ? colors.bgSelected : null,
          borderRadius: compact
              ? BorderRadius.circular(FlareSizes.radiusMd)
              : null,
        ),
        child: stacked
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Icon(
                      flareIconMap[icon],
                      color: colors.textSecondary,
                      // Vue `.flare-settings__ico`: icon-size-md.
                      size: FlareSizes.iconSizeMd,
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
                            ?tag,
                            ?badge,
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
            // A toggle's detail is its description under the label, the
            // switch centred beside both and the icon at the top (Vue
            // `.has-toggle-description`).
            : toggleDescription != null
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (icon != null) ...[
                      Align(
                        alignment: Alignment.topCenter,
                        child: Icon(
                          flareIconMap[icon],
                          color: colors.textSecondary,
                          size: FlareSizes.iconSizeMd,
                        ),
                      ),
                      const SizedBox(width: FlareSizes.spacingMd),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          label,
                          const SizedBox(height: FlareSizes.spacingXs),
                          Text(
                            toggleDescription,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: FlareSizes.fontSizeSm,
                              height: FlareSizes.lineHeightNormal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: FlareSizes.spacingMd),
                    Center(
                      child: ExcludeSemantics(
                        child: IgnorePointer(
                          child: FlareSwitch(
                            value: item.value,
                            size: FlareControlSize.sm,
                            disabled: !enabled,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            // A short value keeps its own width up to 60% of the row, so the
            // label keeps the rest.
            : LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    if (icon != null) ...[
                      Icon(
                        flareIconMap[icon],
                        color: colors.textSecondary,
                        // Vue `.flare-settings__ico`: icon-size-md.
                        size: FlareSizes.iconSizeMd,
                      ),
                      const SizedBox(width: FlareSizes.spacingMd),
                    ],
                    Expanded(child: label),
                    switch (item.kind) {
                      FlareSettingKind.toggle => ExcludeSemantics(
                        child: IgnorePointer(
                          child: FlareSwitch(
                            value: item.value,
                            size: FlareControlSize.sm,
                            disabled: !enabled,
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
                          ?tag,
                          ?badge,
                          spinner ?? chevron,
                        ],
                      ),
                    },
                    if (item.kind != FlareSettingKind.navigation) ?spinner,
                    if (item.kind != FlareSettingKind.navigation) ?tag,
                    if (item.kind != FlareSettingKind.navigation) ?badge,
                  ],
                ),
              ),
      ),
    );
  }
}

/// The red dot of a [FlareSettingsItem.badge]. A screen reader hears it with
/// the row.
class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Semantics(
    label: FlareStrings.of(context).settingsRowBadge,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(start: FlareSizes.spacingSm),
      child: SizedBox.square(
        dimension: FlareSizes.spacingSm,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FlareColors.of(context).error,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}

/// The count of a [FlareSettingsItem.badgeCount]: the same red as the dot,
/// with the count written as every count badge writes it. A screen reader
/// hears the number with the row.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Padding(
      key: const ValueKey('flare-settings-row-count'),
      padding: const EdgeInsetsDirectional.only(start: FlareSizes.spacingSm),
      child: Container(
        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
        padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacing2xs,
          vertical: FlareSizes.spacingXs,
        ),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.messageOutgoingForeground,
            fontSize: FlareSizes.fontSizeXs,
            fontWeight: FontWeight.w600,
            height: 1,
            fontFeatures: const [FontFeature.tabularFigures()],
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
