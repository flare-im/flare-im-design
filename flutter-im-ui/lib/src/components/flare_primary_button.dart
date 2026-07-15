import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// The primary filled action — brand-violet pill, white label, radiusLg corners.
/// When [loading] the button is non-interactive and shows an inline spinner +
/// [loadingLabel] (falls back to [label]). Spec: General/PrimaryButton.
class FlarePrimaryButton extends StatelessWidget {
  const FlarePrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.disabled = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;
  final bool disabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final off = disabled || loading;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: Material(
          color: colors.primary,
          borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
          child: InkWell(
            borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
            onTap: off ? null : onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  else if (icon != null)
                    Icon(icon, size: 18, color: Colors.white),
                  if (loading || icon != null) const SizedBox(width: FlareSizes.spacingSm),
                  Text(
                    loading ? (loadingLabel ?? label) : label,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
