import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_icon.dart';

/// A labelled form-field wrapper: an optional [label] (with a required mark
/// read as "required"), the [child] control, and one line under it — the
/// [error] (error icon + text, replacing the [hint]) or the [hint], with the
/// [counter] at its end. Spec: Form/FormField.
class FlareFormField extends StatelessWidget {
  const FlareFormField({
    super.key,
    this.label,
    this.required = false,
    this.hint,
    this.error,
    this.counter,
    this.labelColor,
    required this.child,
  });

  final String? label;
  final bool required;
  final String? hint;
  final String? error;

  /// A count under the control at its end ("3/24").
  final String? counter;

  /// The label's colour; text.secondary when null (the Vue form-label seam).
  /// A plugin form passes text.primary (R6).
  final Color? labelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final note = error ?? hint;
    final caption = TextStyle(
      fontSize: FlareTextRoles.caption.fontSize,
      height: FlareTextRoles.caption.lineHeight,
      color: colors.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          // The `*` is drawn, "required" is read.
          Semantics(
            container: required,
            label: required
                ? '$label ${FlareStrings.of(context).pluginFormRequired}'
                : null,
            excludeSemantics: required,
            child: Text.rich(
              TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeMd,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? colors.textSecondary,
                ),
                children: [
                  if (required)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: colors.errorText),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: FlareSizes.spacing2xs),
        ],
        child,
        if (note != null || counter != null) ...[
          const SizedBox(height: FlareSizes.spacing2xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error != null) ...[
                FlareIcon(
                  'error',
                  size: FlareSizes.iconSizeSm,
                  color: colors.errorText,
                ),
                const SizedBox(width: FlareSizes.spacingXs),
              ],
              Expanded(
                child: note == null
                    ? const SizedBox.shrink()
                    : Text(
                        note,
                        style: error != null
                            ? caption.copyWith(color: colors.errorText)
                            : caption,
                      ),
              ),
              if (counter != null) ...[
                const SizedBox(width: FlareSizes.spacingSm),
                Text(counter!, style: caption),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
