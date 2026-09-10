import 'package:flutter/material.dart';
import '../tokens/flare_tokens.dart';

/// Shared dialog surface. Present using showDialog so focus trapping, barriers,
/// restoration and platform back navigation stay owned by the host route.
/// Contents and actions are composed kit controls; business callbacks stay outside.
class FlareDialog extends StatelessWidget {
  const FlareDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.busy = false,
  });
  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return PopScope(
      canPop: !busy,
      child: Dialog(
        backgroundColor: colors.bgPrimary,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
          side: BorderSide(color: colors.borderPrimary),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(FlareSizes.spacingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeXl,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    child: title,
                  ),
                ),
                const SizedBox(height: FlareSizes.spacingLg),
                Flexible(
                  child: SingleChildScrollView(
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        fontSize: FlareSizes.fontSizeLg,
                        color: colors.textSecondary,
                      ),
                      child: content,
                    ),
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: FlareSizes.spacingXl),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: FlareSizes.spacingSm,
                    runSpacing: FlareSizes.spacingSm,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
