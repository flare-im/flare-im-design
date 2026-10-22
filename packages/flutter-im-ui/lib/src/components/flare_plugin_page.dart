import 'dart:async';

import 'package:flutter/material.dart';

import '../models/directory_data.dart' show FlareButtonVariant, FlareControlSize;
import '../models/plugin_view.dart';
import '../platform/flare_platform.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_icon_button.dart';
import 'flare_plugin_view.dart';
import 'flare_screen.dart';
import 'plugin_paging.dart';

/// Plugin page host — a full-screen page for a plugin's `page` contribution
/// (red packet v5's wallet, a list): the kit [FlareScreen] with the title and
/// back key, the resolved view drawn by an embedded [FlarePluginView] (the
/// same document renderer as `FlarePluginDetailSheet`, so blocks, menu
/// actions, forms and settling behave the same), pull to refresh on touch and
/// a refresh key in the header on pointer devices, and a full-width load-more
/// key under the view while it has a next page (asked once per cursor).
/// Spec: Layout/PluginPage (`FlarePluginPage`).
///
/// The host fetches: [onRefresh], [onRetry] and [onLoadMore] are requests and
/// the kit calls nothing. While [refreshing] is true the refresh indicator
/// stays. No placeholder buttons: whatever the view does not declare is not
/// drawn.
class FlarePluginPage extends StatefulWidget {
  const FlarePluginPage({
    super.key,
    this.title,
    this.view,
    this.loading = false,
    this.error,
    this.refreshing = false,
    this.loadingMore = false,
    this.resolveUser,
    this.viewerId,
    this.busyActionId,
    this.actionError,
    this.formErrors = const [],
    this.members = const [],
    this.settleToken = 0,
    this.onBack,
    this.onRefresh,
    this.onRetry,
    this.onLoadMore,
    this.onAction,
    this.onOpenDetail,
  });

  /// Page title while there is no view; the view's title wins.
  final String? title;

  /// The resolved page view; null while the first load runs.
  final FlarePluginViewModel? view;

  /// The first load runs: a spinner in place of the view.
  final bool loading;

  /// Loading failed with no view to show: the host's text and a retry key.
  final String? error;

  /// A refresh is running.
  final bool refreshing;

  /// The next page is loading: the load-more key spins and is disabled.
  final bool loadingMore;
  final FlarePluginResolveUser? resolveUser;

  /// The viewer's user id (the "我" tag in entries).
  final String? viewerId;

  /// The action in flight, passed to the view.
  final String? busyActionId;

  /// Failure text of an action run on the page (the view's error).
  final String? actionError;
  final List<FlarePluginFormError> formErrors;
  final List<FlarePluginMember> members;

  /// The host's settle signal for actions run on the page.
  final int settleToken;

  /// Draws the back key; the platform back does the same.
  final VoidCallback? onBack;

  /// A pull to refresh, or the header refresh key on pointer devices.
  final VoidCallback? onRefresh;
  final VoidCallback? onRetry;

  /// The page after the cursor (the view's next cursor).
  final ValueChanged<String>? onLoadMore;
  final FlarePluginActionCallback? onAction;

  /// "See all" of an entries block or a row on the page.
  final VoidCallback? onOpenDetail;

  static const Key loadingKey = ValueKey('flare-plugin-page-loading');
  static const Key errorKey = ValueKey('flare-plugin-page-error');
  static const Key retryKey = ValueKey('flare-plugin-page-retry');
  static const Key refreshKey = ValueKey('flare-plugin-page-refresh');
  static const Key loadMoreKey = ValueKey('flare-plugin-page-load-more');

  @override
  State<FlarePluginPage> createState() => _FlarePluginPageState();
}

class _FlarePluginPageState extends State<FlarePluginPage> {
  final _cursor = FlarePluginPageCursor();

  /// The pull the indicator is showing, until the host's refresh ends.
  Completer<void>? _pull;

  @override
  void didUpdateWidget(FlarePluginPage old) {
    super.didUpdateWidget(old);
    _cursor.update(
      wasLoadingMore: old.loadingMore,
      loadingMore: widget.loadingMore,
      oldSettleToken: old.settleToken,
      settleToken: widget.settleToken,
      oldError: old.actionError,
      error: widget.actionError,
    );
    if (old.refreshing && !widget.refreshing) _endPull();
  }

  @override
  void dispose() {
    _endPull();
    super.dispose();
  }

  void _endPull() {
    final pull = _pull;
    _pull = null;
    if (pull != null && !pull.isCompleted) pull.complete();
  }

  Future<void> _refresh() {
    final refresh = widget.onRefresh;
    if (refresh == null) return Future.value();
    _endPull();
    final pull = _pull = Completer<void>();
    refresh();
    // A host that never reports refreshing ends the pull after this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.refreshing && identical(_pull, pull)) _endPull();
    });
    return pull.future;
  }

  void _loadMore(String cursor) {
    if (!_cursor.ask(cursor, loadingMore: widget.loadingMore)) return;
    setState(() {});
    widget.onLoadMore?.call(cursor);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final view = widget.view;
    final error = widget.error;
    final pointer = flareCapabilitiesOf(context).hover;
    final title = (view?.title.isNotEmpty ?? false)
        ? view!.title
        : (widget.title ?? '');

    final Widget body;
    if (view == null && (error == null || error.isEmpty)) {
      body = Semantics(
        key: FlarePluginPage.loadingKey,
        label: strings.loading,
        liveRegion: true,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: FlareSizes.spacing2xl),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      );
    } else if (view == null) {
      body = Padding(
        key: FlarePluginPage.errorKey,
        padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeLg,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: FlareSizes.spacingMd),
            FlareButton(
              key: FlarePluginPage.retryKey,
              label: strings.retry,
              variant: FlareButtonVariant.secondary,
              onPressed: widget.onRetry,
            ),
          ],
        ),
      );
    } else {
      final cursor = view.nextPageCursor;
      final busy =
          cursor != null &&
          _cursor.busy(cursor, loadingMore: widget.loadingMore);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FlarePluginView(
            view: view,
            embedded: true,
            resolveUser: widget.resolveUser,
            viewerId: widget.viewerId,
            busyActionId: widget.busyActionId,
            error: widget.actionError,
            formErrors: widget.formErrors,
            members: widget.members,
            settleToken: widget.settleToken,
            onAction: widget.onAction,
            onOpenDetail: widget.onOpenDetail,
          ),
          if (cursor != null) ...[
            const SizedBox(height: FlareSizes.spacingMd),
            FlareButton(
              key: FlarePluginPage.loadMoreKey,
              label: strings.myInviteLoadMore,
              variant: FlareButtonVariant.ghost,
              size: FlareControlSize.sm,
              block: true,
              loading: busy,
              disabled: busy,
              onPressed: busy ? null : () => _loadMore(cursor),
            ),
          ],
        ],
      );
    }

    final scroll = SingleChildScrollView(
      // A short page still pulls.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(FlareSizes.spacingLg),
      child: body,
    );
    return Semantics(
      container: true,
      label: title,
      explicitChildNodes: true,
      child: FlareScreen(
        title: title,
        onBack: widget.onBack,
        scroll: false,
        surface: FlareScreenSurface.surface,
        actions: [
          if (pointer && widget.onRefresh != null)
            FlareIconButton(
              key: FlarePluginPage.refreshKey,
              icon: 'refresh',
              semanticLabel: strings.pluginPageRefresh,
              disabled: widget.refreshing,
              onPressed: widget.refreshing ? null : widget.onRefresh,
            ),
        ],
        child: widget.onRefresh == null || view == null
            ? scroll
            : RefreshIndicator.adaptive(onRefresh: _refresh, child: scroll),
      ),
    );
  }
}
