import 'package:flutter/material.dart';

import '../models/workspace_layout.dart';
import '../tokens/flare_tokens.dart';
import 'flare_shell_scope.dart';
import 'workspace_presentation_report.dart';

/// Which pane shows when collapsed to a single column (phone).
enum FlarePane { list, chat, detail }

/// Adaptive conversation layout — one column (list ↔ chat), the list beside the
/// chat, or list + chat + detail. Spec: Layout/ResponsiveLayout
/// (`FlareResponsiveLayout`). How many columns fit is the kit's one pane rule
/// ([flarePaneModeForWidth]) on the width [LayoutBuilder] gives it.
class FlareResponsiveLayout extends StatelessWidget {
  const FlareResponsiveLayout({
    super.key,
    required this.list,
    required this.chat,
    this.detail,
    this.activePane = FlarePane.list,
    this.onPaneChange,
    this.listWidth = FlareSizes.primaryPaneDefaultWidth,
    this.detailWidth = FlareSizes.detailPaneDefaultWidth,
    this.hideMobileBar = false,
    this.backLabel = '返回',
    this.onLayoutChange,
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

  /// The panes in use, in the words the application frames report: reported
  /// after the first layout and on every change. `singlePane` means the chat or
  /// detail replaced the list, and the host owns the way back.
  final ValueChanged<FlareWorkspacePresentation>? onLayoutChange;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final paneMode = flarePaneModeForWidth(
          c.maxWidth,
          hasDetail: detail != null,
          textScale: MediaQuery.textScalerOf(context).scale(16) / 16,
          primaryWidth: listWidth,
          detailWidth: detailWidth,
        );
        // A detail that is not beside the chat takes a pane's place when opened.
        final presentation = FlareWorkspacePresentation(
          paneMode,
          paneMode == FlareWorkspacePaneMode.triplePane
              ? FlareWorkspaceDetailPresentation.inline
              : detail != null
              ? FlareWorkspaceDetailPresentation.route
              : FlareWorkspaceDetailPresentation.hidden,
        );
        // The chat or the detail in the list's place is a page beyond the
        // destination's root.
        return FlareDestinationDepth(
          active:
              paneMode == FlareWorkspacePaneMode.singlePane &&
              activePane != FlarePane.list,
          child: FlareWorkspacePresentationReport(
            presentation: presentation,
            onLayoutChange: onLayoutChange,
            child: _panes(context, paneMode),
          ),
        );
      },
    );
  }

  Widget _panes(BuildContext context, FlareWorkspacePaneMode paneMode) {
    if (paneMode == FlareWorkspacePaneMode.triplePane) {
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
    if (paneMode == FlareWorkspacePaneMode.dualPane) {
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
    final colors = FlareColors.of(context);
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
        if (!hideMobileBar && onPaneChange != null) const Divider(height: 1),
        Expanded(
          child: activePane == FlarePane.detail ? (detail ?? chat) : chat,
        ),
      ],
    );
  }
}
