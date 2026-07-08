import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

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
  });

  final String title;
  final String? description;
  final String? actionText;
  final IconData icon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.all(FlareSizes.spacing2xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: colors.textTertiary),
          const SizedBox(height: FlareSizes.spacingMd),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colors.textPrimary, fontSize: FlareSizes.fontSize2xl)),
          if (description != null) ...[
            const SizedBox(height: FlareSizes.spacingXs),
            Text(description!,
                textAlign: TextAlign.center,
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
  }
}
