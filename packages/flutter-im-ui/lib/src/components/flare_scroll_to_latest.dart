import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';

/// Scroll-to-latest pill — a floating back-to-bottom button with an unread
/// badge. Spec: Message/ScrollToLatest (`FlareScrollToLatest`).
///
/// Named [FlareStrings.scrollToLatest], with the count of new messages
/// ([FlareStrings.newMessages]) as its value; the pill keeps its size and the
/// touch target around it is the kit's.
class FlareScrollToLatest extends StatelessWidget {
  const FlareScrollToLatest({super.key, this.count = 0, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final hasCount = count > 0;
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      label: strings.scrollToLatest,
      value: hasCount ? strings.newMessages(count) : null,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: FlareSizes.touchTarget,
            minHeight: FlareSizes.touchTarget,
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Material(
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
                        Text(
                          count > 99 ? '99+' : '$count',
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: FlareSizes.fontSizeMd,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_downward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
