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
    this.listWidth = FlareSizes.leftPanel,
    this.detailWidth = FlareSizes.rightPanel,
    this.hideMobileBar = false,
    this.backLabel = '返回',
  }) : assert(listWidth >= 0),
       assert(detailWidth >= 0);

  final Widget list;
  final Widget chat;
  final Widget? detail;
  final FlarePane activePane;
  final ValueChanged<FlarePane>? onPaneChange;
  final double listWidth;
  final double detailWidth;
  final String backLabel;
  final bool hideMobileBar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final panes = FlareLayoutPolicy.paneCount(
          w,
          hasDetail: detail != null,
          textScale: MediaQuery.textScalerOf(context).scale(16) / 16,
          listWidth: listWidth,
          detailWidth: detailWidth,
        );
        if (panes == 3) {
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
        if (panes == 2) {
          return Row(
            children: [
              SizedBox(width: listWidth, child: list),
              const VerticalDivider(width: 1),
              Expanded(
                child: activePane == FlarePane.detail ? (detail ?? chat) : chat,
              ),
            ],
          );
        }
        if (activePane == FlarePane.list) return list;
        final colors = FlareColors.of(Theme.of(context).brightness);
        return Column(
          children: [
            if (!hideMobileBar && onPaneChange != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => onPaneChange?.call(
                    activePane == FlarePane.detail
                        ? FlarePane.chat
                        : FlarePane.list,
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(backLabel),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                    minimumSize: const Size(
                      FlareSizes.touchTarget,
                      FlareSizes.touchTarget,
                    ),
                  ),
                ),
              ),
            if (!hideMobileBar && onPaneChange != null)
              const Divider(height: 1),
            Expanded(
              child: activePane == FlarePane.detail ? (detail ?? chat) : chat,
            ),
          ],
        );
      },
    );
  }
}
