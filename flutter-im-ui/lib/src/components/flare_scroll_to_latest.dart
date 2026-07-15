import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Scroll-to-latest pill — a floating back-to-bottom button with an unread
/// badge. Spec: Message/ScrollToLatest (`FlareScrollToLatest`).
class FlareScrollToLatest extends StatelessWidget {
  const FlareScrollToLatest({super.key, this.count = 0, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final hasCount = count > 0;
    return Material(
      color: colors.bgPrimary,
      elevation: 3,
      shadowColor: const Color(0x2915131C),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(hasCount ? 12 : 8, 6, 6, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasCount) ...[
                Text(count > 99 ? '99+' : '$count',
                    style: TextStyle(
                        color: colors.primary,
                        fontSize: FlareSizes.fontSizeMd,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
              ],
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_downward, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
