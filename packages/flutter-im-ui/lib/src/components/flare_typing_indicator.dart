import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// Typing indicator — bouncing dots, single / multi-typer copy. Renders as a
/// received-style bubble (`bubble`) or dots + text (`inline`).
/// Spec: Message/TypingIndicator (`FlareTypingIndicator`).
class FlareTypingIndicator extends StatefulWidget {
  const FlareTypingIndicator({
    super.key,
    this.names = const [],
    this.userId,
    this.avatarUrl,
    this.variant = FlareTypingVariant.bubble,
  });

  final List<String> names;
  final String? userId;
  final String? avatarUrl;
  final FlareTypingVariant variant;

  @override
  State<FlareTypingIndicator> createState() => _FlareTypingIndicatorState();
}

enum FlareTypingVariant { bubble, inline }

class _FlareTypingIndicatorState extends State<FlareTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _labelFor(FlareStrings strings) {
    final names = widget.names.where((n) => n.isNotEmpty).toList();
    if (names.isEmpty) return strings.typing;
    if (names.length == 1) return strings.typingOne(names[0]);
    return strings.typingMany(names.length);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    // Reduced motion: keep the dots still instead of bouncing (MediaQuery.disableAnimations).
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_c.isAnimating) _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
    final isBubble = widget.variant == FlareTypingVariant.bubble;
    final dotColor = isBubble
        ? colors.primary.withValues(alpha: 0.65)
        : colors.textTertiary;

    final dots = AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = ((_c.value - i * 0.14) % 1.0);
          final lift = t < 0.3
              ? (t / 0.3)
              : (t < 0.6 ? (1 - (t - 0.3) / 0.3) : 0.0);
          return Padding(
            padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
            child: Transform.translate(
              offset: Offset(0, -4 * lift),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor.withValues(alpha: 0.55 + 0.45 * lift),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );

    final body = Container(
      padding: isBubble
          ? const EdgeInsets.symmetric(horizontal: FlareSizes.spacing2md, vertical: FlareSizes.spacing2sm)
          : EdgeInsets.zero,
      decoration: isBubble
          ? BoxDecoration(
              color: colors.bgPrimary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: colors.borderPrimary),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.variant == FlareTypingVariant.inline ||
              widget.names.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _labelFor(strings),
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: FlareSizes.fontSizeLg,
                ),
              ),
            ),
          dots,
        ],
      ),
    );

    if (!isBubble) return body;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FlareAvatar(
          userId: widget.names.isNotEmpty
              ? widget.names.first
              : (widget.userId ?? 'typing'),
          displayName: widget.names.isNotEmpty
              ? widget.names.first
              : (widget.userId ?? 'typing'),
          avatarUrl: widget.avatarUrl,
          size: 32,
        ),
        const SizedBox(width: FlareSizes.spacingSm),
        body,
      ],
    );
  }
}
