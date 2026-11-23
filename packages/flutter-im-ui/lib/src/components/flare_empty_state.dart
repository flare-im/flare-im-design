import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import '../models/directory_data.dart';
import 'action_icon.dart';
import 'flare_button.dart';

/// Visual tone for [FlareEmptyState].
///
/// [normal] is the default look; [error] tints the title and the default
/// icon/spinner with the danger color for surfacing failures.
enum FlareEmptyStateTone { normal, error }

/// Empty-state placeholder — icon + title + description + optional action.
/// Spec: General/EmptyState (`FlareEmptyState`).
class FlareEmptyState extends StatelessWidget {
  const FlareEmptyState({
    super.key,
    required this.title,
    this.description,
    this.actionText,
    this.icon = 'chats',
    this.onAction,
    this.loading = false,
    this.onTap,
    this.iconWidget,
    this.tone = FlareEmptyStateTone.normal,
    this.actions = const <Widget>[],
    this.compact = false,
  });

  final String title;

  /// The in-block empty state of a data block (R8 of
  /// docs/plugin-experience.md): icon 32, title 14/600, description 13, a
  /// tighter inset.
  final bool compact;
  final String? description;
  final String? actionText;

  /// A semantic icon name from [flareIconNames].
  final String icon;
  final VoidCallback? onAction;

  /// When true, a brand-tinted spinner renders in place of the icon.
  /// Title/description/action still render below as normal.
  final bool loading;

  /// When non-null, the whole placeholder becomes tappable. Distinct from the
  /// action button — if both are set, both work (the action button swallows
  /// the tap so it does not double-fire).
  final VoidCallback? onTap;

  /// Rendered instead of `Icon(icon)` (and instead of the spinner is NOT
  /// implied — [loading] still wins) when non-null.
  final Widget? iconWidget;

  /// Visual tone. When [FlareEmptyStateTone.error], the title and the default
  /// icon/spinner use the danger color. A caller-supplied [iconWidget] is
  /// never recolored.
  final FlareEmptyStateTone tone;

  /// Host controls under the text — what to do about the screen being empty.
  /// The kit owns the row (centred, wrapping, one gap); the host owns the
  /// controls. [actionText] stays the one-button shorthand; both may be set.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final bool isError = tone == FlareEmptyStateTone.error;

    final Widget leading;
    if (loading) {
      leading = SizedBox(
        width: compact ? 32 : FlareSizes.componentEmptyStateIconSize,
        height: compact ? 32 : FlareSizes.componentEmptyStateIconSize,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            isError ? colors.error : colors.primary,
          ),
        ),
      );
    } else if (iconWidget != null) {
      leading = iconWidget!;
    } else {
      leading = Icon(
        flareIconGlyph(icon),
        size: compact ? 32 : FlareSizes.componentEmptyStateIconSize,
        color: isError ? colors.error : colors.textTertiary,
      );
    }

    final content = Padding(
      padding: EdgeInsets.all(
        compact ? FlareSizes.spacingLg : FlareSizes.spacing2xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(height: FlareSizes.spacingSm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isError ? colors.error : colors.textPrimary,
              fontSize: compact
                  ? FlareSizes.fontSizeLg
                  : FlareSizes.fontSize2xl,
              fontWeight: compact ? FontWeight.w600 : null,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: FlareSizes.spacingSm),
            Text(
              description!,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: FlareSizes.fontSizeMd,
              ),
            ),
          ],
          // Vue: a small ghost key, the column's 8 gap plus 4.
          if (actionText != null) ...[
            const SizedBox(height: FlareSizes.spacingMd),
            FlareButton(
              variant: FlareButtonVariant.ghost,
              size: FlareControlSize.sm,
              label: actionText,
              onPressed: onAction,
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: FlareSizes.spacingLg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: FlareSizes.spacingSm,
              runSpacing: FlareSizes.spacingSm,
              children: actions,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}
