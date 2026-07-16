import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// A labelled form-field wrapper: an optional [label] (with a red required
/// mark), the [child] control, and an [error] (which replaces the [hint]).
/// Spec: Form/FormField.
class FlareFormField extends StatelessWidget {
  const FlareFormField({
    super.key,
    this.label,
    this.required = false,
    this.hint,
    this.error,
    required this.child,
  });

  final String? label;
  final bool required;
  final String? hint;
  final String? error;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text.rich(
            TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
              children: [
                if (required)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: colors.error, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        child,
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error!, style: TextStyle(fontSize: 12, color: colors.error)),
        ] else if (hint != null) ...[
          const SizedBox(height: 6),
          Text(hint!, style: TextStyle(fontSize: 12, color: colors.textTertiary)),
        ],
      ],
    );
  }
}
