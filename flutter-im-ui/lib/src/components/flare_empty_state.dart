import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

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
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.loading = false,
    this.onTap,
    this.iconWidget,
    this.tone = FlareEmptyStateTone.normal,
  });

  final String title;
  final String? description;
  final String? actionText;
  final IconData icon;
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

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final bool isError = tone == FlareEmptyStateTone.error;

    final Widget leading;
    if (loading) {
      leading = SizedBox(
        width: 44,
        height: 44,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
              isError ? colors.error : colors.primary),
        ),
      );
    } else if (iconWidget != null) {
      leading = iconWidget!;
    } else {
      leading = Icon(icon,
          size: 56, color: isError ? colors.error : colors.textTertiary);
    }

    final content = Padding(
      padding: const EdgeInsets.all(FlareSizes.spacing2xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(height: FlareSizes.spacingMd),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isError ? colors.error : colors.textPrimary,
                  fontSize: FlareSizes.fontSize2xl)),
          if (description != null) ...[
            const SizedBox(height: FlareSizes.spacingXs),
            Text(description!,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                    color: colors.textTertiary, fontSize: FlareSizes.fontSizeMd)),
          ],
          if (actionText != null) ...[
            const SizedBox(height: FlareSizes.spacingLg),
            OutlinedButton(onPressed: onAction, child: Text(actionText!)),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      child: content,
    );
  }
}
