import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// A `#topic` hashtag chip inside a moment — brand-tinted inline text, tappable.
/// Rendered as a bare [Text] wrapped in a [GestureDetector] so it can be dropped
/// into a [Wrap] alongside body text. Spec: Moments/TopicChip (`FlareTopicChip`).
class FlareTopicChip extends StatelessWidget {
  const FlareTopicChip({super.key, required this.topic, this.onTap});

  final String topic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return GestureDetector(
      onTap: onTap,
      child: Text(
        '#$topic',
        style: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
