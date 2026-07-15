import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Screen-level large-title header — the quiet top bar for a tab surface
/// (inbox / directory / me). Distinct from the chat header (conversation
/// chrome). Spec: Layout/ScreenHeader.
class FlareScreenHeader extends StatelessWidget {
  const FlareScreenHeader({
    super.key,
    required this.title,
    this.actions = const [],
  });

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Container(
      width: double.infinity,
      color: colors.bgPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
