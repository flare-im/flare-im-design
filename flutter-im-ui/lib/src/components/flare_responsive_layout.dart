import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Which pane shows when collapsed to a single column (phone).
enum FlarePane { list, chat, detail }

/// Adaptive conversation layout — phone single column (list ↔ chat), tablet two
/// columns (list + chat), desktop three columns (list + chat + detail). Spec:
/// Layout/ResponsiveLayout (`FlareResponsiveLayout`). Breakpoints via [LayoutBuilder].
class FlareResponsiveLayout extends StatelessWidget {
  const FlareResponsiveLayout({
    super.key,
    required this.list,
    required this.chat,
    this.detail,
    this.activePane = FlarePane.list,
    this.onPaneChange,
    this.listWidth = 300,
    this.detailWidth = 320,
  });

  final Widget list;
  final Widget chat;
  final Widget? detail;
  final FlarePane activePane;
  final ValueChanged<FlarePane>? onPaneChange;
  final double listWidth;
  final double detailWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        if (w >= 1100 && detail != null) {
          return Row(
            children: [
              SizedBox(width: listWidth, child: list),
              const VerticalDivider(width: 1),
              Expanded(child: chat),
              const VerticalDivider(width: 1),
              SizedBox(width: detailWidth, child: detail!),
            ],
          );
        }
        if (w >= 680) {
          return Row(
            children: [
              SizedBox(width: listWidth, child: list),
              const VerticalDivider(width: 1),
              Expanded(child: chat),
            ],
          );
        }
        if (activePane == FlarePane.list) return list;
        final colors = FlareColors.of(Theme.of(context).brightness);
        return Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => onPaneChange?.call(FlarePane.list),
                icon: const Icon(Icons.chevron_left),
                label: const Text('返回'),
                style: TextButton.styleFrom(foregroundColor: colors.primary),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: activePane == FlarePane.detail ? (detail ?? chat) : chat),
          ],
        );
      },
    );
  }
}
