import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_empty_state.dart';
import 'flare_responsive_layout.dart';
import 'flare_skeleton.dart';
import 'flare_status_banner.dart';

/// Which pane a state / retry belongs to.
enum FlareWorkspacePaneKey { list, chat, detail }

/// Host-reported load status of a single pane. Panes are independent: a failing
/// timeline never degrades an inbox that already loaded.
enum FlareWorkspacePaneStatus { ready, loading, empty, failure }

/// What a pane actually renders.
enum FlareWorkspacePaneRender { content, skeleton, empty, failure }

/// Tone of the workspace-wide banner (offline / reconnecting / session expired).
enum FlareWorkspaceBannerTone { info, warning, error, success }

/// One pane's host-reported state.
@immutable
class FlareWorkspacePaneState {
  const FlareWorkspacePaneState({
    this.status = FlareWorkspacePaneStatus.ready,
    this.message,
    this.actionLabel,
  });

  /// Defaults to [FlareWorkspacePaneStatus.ready].
  final FlareWorkspacePaneStatus status;

  /// User-facing text: the empty explanation, or the failure cause.
  final String? message;

  /// Recovery action label. Without it no button is offered, only the reason.
  final String? actionLabel;

  @override
  bool operator ==(Object other) =>
      other is FlareWorkspacePaneState &&
      other.status == status &&
      other.message == message &&
      other.actionLabel == actionLabel;

  @override
  int get hashCode => Object.hash(status, message, actionLabel);

  @override
  String toString() =>
      'FlareWorkspacePaneState(status: $status, message: $message, actionLabel: $actionLabel)';
}

/// Cross-pane notice rendered above all three panes.
@immutable
class FlareWorkspaceBanner {
  const FlareWorkspaceBanner({
    required this.message,
    this.tone = FlareWorkspaceBannerTone.info,
    this.actionLabel,
  });

  final String message;
  final FlareWorkspaceBannerTone tone;
  final String? actionLabel;

  @override
  bool operator ==(Object other) =>
      other is FlareWorkspaceBanner &&
      other.message == message &&
      other.tone == tone &&
      other.actionLabel == actionLabel;

  @override
  int get hashCode => Object.hash(message, tone, actionLabel);
}

/// Map a host pane state onto what to render. A missing state and
/// [FlareWorkspacePaneStatus.ready] both fall back to the host content: an
/// unresolved status must never blank a pane or fake an empty list.
FlareWorkspacePaneRender paneRender(FlareWorkspacePaneState? state) =>
    switch (state?.status) {
      FlareWorkspacePaneStatus.loading => FlareWorkspacePaneRender.skeleton,
      FlareWorkspacePaneStatus.empty => FlareWorkspacePaneRender.empty,
      FlareWorkspacePaneStatus.failure => FlareWorkspacePaneRender.failure,
      _ => FlareWorkspacePaneRender.content,
    };

/// Whether the pane failure offers a recovery button. Needs all three: an actual
/// failure, a non-blank label, and a host handler — a button the host cannot
/// service is worse than no button.
bool paneRetryVisible(FlareWorkspacePaneState? state, bool hasRetry) {
  if (!hasRetry) return false;
  if (paneRender(state) != FlareWorkspacePaneRender.failure) return false;
  final label = state?.actionLabel;
  return label != null && label.trim().isNotEmpty;
}

/// Whether the cross-pane banner shows at all. Blank or whitespace-only messages
/// are not a banner. Independent of pane state: an offline banner can sit above
/// a list that still reads fine from cache.
bool workspaceBannerVisible(FlareWorkspaceBanner? banner) =>
    banner != null && banner.message.trim().isNotEmpty;

/// Whether the banner's inline action renders (non-blank label + host handler).
bool workspaceBannerActionVisible(FlareWorkspaceBanner? banner, bool hasAction) {
  if (!hasAction || !workspaceBannerVisible(banner)) return false;
  final label = banner?.actionLabel;
  return label != null && label.trim().isNotEmpty;
}

/// StatusBanner tone for a workspace tone; `error` is StatusBanner's `danger`.
FlareStatusTone workspaceBannerTone(FlareWorkspaceBannerTone? tone) =>
    switch (tone) {
      FlareWorkspaceBannerTone.warning => FlareStatusTone.warning,
      FlareWorkspaceBannerTone.error => FlareStatusTone.danger,
      FlareWorkspaceBannerTone.success => FlareStatusTone.success,
      _ => FlareStatusTone.info,
    };

/// Skeleton shape per pane: rows for the inbox, bubbles for the timeline, a card
/// for details.
FlareSkeletonVariant paneSkeletonVariant(FlareWorkspacePaneKey pane) =>
    switch (pane) {
      FlareWorkspacePaneKey.chat => FlareSkeletonVariant.message,
      FlareWorkspacePaneKey.detail => FlareSkeletonVariant.profile,
      FlareWorkspacePaneKey.list => FlareSkeletonVariant.conversation,
    };

/// The conversation workspace: [FlareResponsiveLayout] plus ONE place where every
/// pane resolves loading / empty / failure, so hosts stop re-writing a skeleton,
/// an empty card and an error card per app and per pane.
///
/// It owns no data and performs no side effect: pane content stays in [list] /
/// [chat] / [detail], splitting and breakpoints stay in [FlareResponsiveLayout],
/// recovery stays with the host via [onRetry]. Spec: Layout/ConversationWorkspace
/// (`FlareConversationWorkspace`).
class FlareConversationWorkspace extends StatelessWidget {
  const FlareConversationWorkspace({
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
    this.listState = const FlareWorkspacePaneState(),
    this.chatState = const FlareWorkspacePaneState(),
    this.detailState = const FlareWorkspacePaneState(),
    this.banner,
    this.onRetry,
    this.onBannerAction,
    this.listEmptyText = '暂无会话',
    this.chatEmptyText = '选择一个会话开始聊天',
    this.detailEmptyText = '暂无详情',
    this.listFailureText = '会话列表加载失败',
    this.chatFailureText = '消息加载失败',
    this.detailFailureText = '详情加载失败',
    this.listLoadingText = '正在加载会话列表',
    this.chatLoadingText = '正在加载消息',
    this.detailLoadingText = '正在加载详情',
  });

  // Forwarded verbatim to FlareResponsiveLayout.
  final Widget list;
  final Widget chat;
  final Widget? detail;
  final FlarePane activePane;
  final ValueChanged<FlarePane>? onPaneChange;
  final double listWidth;
  final double detailWidth;
  final bool hideMobileBar;
  final String backLabel;

  /// Per-pane status; independent of each other.
  final FlareWorkspacePaneState listState;
  final FlareWorkspacePaneState chatState;
  final FlareWorkspacePaneState detailState;

  /// Cross-pane notice; can coexist with any pane state.
  final FlareWorkspaceBanner? banner;

  /// Recovery for one pane. Without it a failure shows the reason only.
  final ValueChanged<FlareWorkspacePaneKey>? onRetry;
  final VoidCallback? onBannerAction;

  final String listEmptyText;
  final String chatEmptyText;
  final String detailEmptyText;
  final String listFailureText;
  final String chatFailureText;
  final String detailFailureText;

  /// Screen-reader text announced while the pane skeleton shows.
  final String listLoadingText;
  final String chatLoadingText;
  final String detailLoadingText;

  static String _text(String? value, String fallback) =>
      (value != null && value.trim().isNotEmpty) ? value : fallback;

  IconData _emptyIcon(FlareWorkspacePaneKey pane) => switch (pane) {
        FlareWorkspacePaneKey.chat => Icons.chat_bubble_outline,
        FlareWorkspacePaneKey.detail => Icons.info_outline,
        FlareWorkspacePaneKey.list => Icons.forum_outlined,
      };

  Widget _pane({
    required FlareWorkspacePaneKey key,
    required Widget content,
    required FlareWorkspacePaneState state,
    required String emptyText,
    required String failureText,
    required String loadingText,
    required int skeletonRows,
  }) {
    switch (paneRender(state)) {
      case FlareWorkspacePaneRender.content:
        return content;
      case FlareWorkspacePaneRender.skeleton:
        // A skeleton with an accessible label — never an empty list pretending
        // there is nothing to show.
        return Semantics(
          container: true,
          liveRegion: true,
          label: loadingText,
          child: Padding(
            padding: const EdgeInsets.all(FlareSizes.spacingLg),
            child: Align(
              alignment: Alignment.topCenter,
              child: FlareSkeleton(
                variant: paneSkeletonVariant(key),
                rows: skeletonRows,
              ),
            ),
          ),
        );
      case FlareWorkspacePaneRender.empty:
        return Center(
          child: SingleChildScrollView(
            child: FlareEmptyState(
              title: _text(state.message, emptyText),
              icon: _emptyIcon(key),
            ),
          ),
        );
      case FlareWorkspacePaneRender.failure:
        final retry = paneRetryVisible(state, onRetry != null);
        return Padding(
          padding: const EdgeInsets.all(FlareSizes.spacingLg),
          child: Align(
            alignment: Alignment.topCenter,
            child: FlareStatusBanner(
              text: _text(state.message, failureText),
              tone: FlareStatusTone.danger,
              actionText: retry ? state.actionLabel : null,
              onAction: retry ? () => onRetry?.call(key) : null,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBanner = workspaceBannerVisible(banner);
    final bannerAction =
        workspaceBannerActionVisible(banner, onBannerAction != null);
    return Column(
      children: [
        if (showBanner) ...[
          Padding(
            padding: const EdgeInsets.all(FlareSizes.spacingSm),
            child: FlareStatusBanner(
              text: banner!.message,
              tone: workspaceBannerTone(banner!.tone),
              actionText: bannerAction ? banner!.actionLabel : null,
              onAction: bannerAction ? onBannerAction : null,
            ),
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: FlareResponsiveLayout(
            activePane: activePane,
            onPaneChange: onPaneChange,
            listWidth: listWidth,
            detailWidth: detailWidth,
            hideMobileBar: hideMobileBar,
            backLabel: backLabel,
            list: _pane(
              key: FlareWorkspacePaneKey.list,
              content: list,
              state: listState,
              emptyText: listEmptyText,
              failureText: listFailureText,
              loadingText: listLoadingText,
              skeletonRows: 6,
            ),
            chat: _pane(
              key: FlareWorkspacePaneKey.chat,
              content: chat,
              state: chatState,
              emptyText: chatEmptyText,
              failureText: chatFailureText,
              loadingText: chatLoadingText,
              skeletonRows: 5,
            ),
            // The detail pane must exist whenever it has something to say: with a
            // null slot but a non-ready state the host has no content yet — which is
            // exactly when the loading / empty / failure panel is the point.
            detail: detail == null &&
                    detailState.status == FlareWorkspacePaneStatus.ready
                ? null
                : _pane(
                    key: FlareWorkspacePaneKey.detail,
                    content: detail ?? const SizedBox.shrink(),
                    state: detailState,
                    emptyText: detailEmptyText,
                    failureText: detailFailureText,
                    loadingText: detailLoadingText,
                    skeletonRows: 1,
                  ),
          ),
        ),
      ],
    );
  }
}
