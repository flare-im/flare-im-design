import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../models/plugin_view.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_plugin_view.dart';
import 'plugin_paging.dart';

/// "See all" of a plugin card (spec Overlay/PluginDetailSheet): the detail
/// view (core SDK plugin_detail) as an embedded [FlarePluginView], a spinner
/// while it loads, and the host's error with a retry key when it fails.
///
/// This is the sheet's content; [FlarePluginDetailSheet.show] presents what
/// its builder returns — normally a [FlarePluginDetailSheet] the host rebuilds
/// as the detail loads — on the kit sheet under [title] (the card's title
/// until the view arrives; a host that has the view passes its title).
///
/// Actions run from the detail spin, fail, collect their forms and settle
/// inside the sheet: [busyActionId], [actionError] (the view's error),
/// [formErrors], [members] and [settleToken] go to the embedded view
/// unchanged, so a failure never lands on the card below.
///
/// A detail with a next page ([FlarePluginViewModel.nextPageCursor]) shows a
/// full-width load-more key under the view; a tap reports [onLoadMore] with
/// the cursor and the host passes back the merged view (the core SDK appends
/// pages). The key spins while [loadingMore] is true or while the page the
/// sheet asked for is still the view's next one, so a page is never asked
/// for twice; [loadingMore] going false, [settleToken] changing or a new
/// [actionError] allows a retry.
class FlarePluginDetailSheet extends StatefulWidget {
  const FlarePluginDetailSheet({
    super.key,
    this.title,
    this.view,
    this.loading = false,
    this.error,
    this.resolveUser,
    this.viewerId,
    this.busyActionId,
    this.actionError,
    this.formErrors = const [],
    this.members = const [],
    this.settleToken = 0,
    this.loadingMore = false,
    this.onRetry,
    this.onAction,
    this.onLoadMore,
  });

  /// Title while there is no view; the view's title wins.
  final String? title;
  final FlarePluginViewModel? view;
  final bool loading;

  /// Loading failed: the host's text, with a retry key.
  final String? error;
  final FlarePluginResolveUser? resolveUser;

  /// The viewer's user id, for the "我" tag in grouped entries.
  final String? viewerId;
  final String? busyActionId;

  /// Failure of an action run from the detail, shown inside the sheet under
  /// the view (the embedded view's error). Loading failure is [error].
  final String? actionError;

  /// The host's validation errors for a form opened from the detail.
  final List<FlarePluginFormError> formErrors;

  /// Candidates for members inputs in the detail's action forms.
  final List<FlarePluginMember> members;

  /// The host's settle signal for actions run from the detail
  /// ([FlarePluginView.settleToken]).
  final int settleToken;

  /// The host is fetching the next page: the load-more key spins and is
  /// disabled.
  final bool loadingMore;
  final VoidCallback? onRetry;
  final FlarePluginActionCallback? onAction;

  /// The next page after the cursor (the view's next cursor).
  final ValueChanged<String>? onLoadMore;

  /// The key of the load-more key.
  static const Key loadMoreKey = ValueKey('flare-plugin-detail-load-more');

  /// The key of the loading state, for tests and hosts' tests.
  static const Key loadingKey = ValueKey('flare-plugin-detail-loading');

  /// The key of the error state.
  static const Key errorKey = ValueKey('flare-plugin-detail-error');

  /// Shows what [builder] returns on the kit sheet titled [title].
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required WidgetBuilder builder,
  }) => FlareBottomSheet.show<T>(context, title: title, builder: builder);

  @override
  State<FlarePluginDetailSheet> createState() => _FlarePluginDetailSheetState();
}

class _FlarePluginDetailSheetState extends State<FlarePluginDetailSheet> {
  /// The cursor the sheet last asked for: while it is still the view's, that
  /// page is on its way.
  final _cursor = FlarePluginPageCursor();

  @override
  void didUpdateWidget(FlarePluginDetailSheet old) {
    super.didUpdateWidget(old);
    // A retry is allowed once the host is done, settles, or reports a failure.
    _cursor.update(
      wasLoadingMore: old.loadingMore,
      loadingMore: widget.loadingMore,
      oldSettleToken: old.settleToken,
      settleToken: widget.settleToken,
      oldError: old.actionError,
      error: widget.actionError,
    );
  }

  void _loadMore(String cursor) {
    if (!_cursor.ask(cursor, loadingMore: widget.loadingMore)) return;
    setState(() {});
    widget.onLoadMore?.call(cursor);
  }

  bool _pageBusy(String cursor) =>
      _cursor.busy(cursor, loadingMore: widget.loadingMore);

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final view = widget.view;
    final error = widget.error;
    final loading = widget.loading;
    final title = widget.title;
    final Widget body;
    if (loading || (view == null && (error == null || error.isEmpty))) {
      body = Semantics(
        key: FlarePluginDetailSheet.loadingKey,
        label: strings.loading,
        liveRegion: true,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: FlareSizes.spacing2xl),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      );
    } else if (error != null && error.isNotEmpty) {
      body = Padding(
        key: FlarePluginDetailSheet.errorKey,
        padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeLg,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: FlareSizes.spacingMd),
            FlareButton(
              key: const ValueKey('flare-plugin-detail-retry'),
              label: strings.retry,
              variant: FlareButtonVariant.secondary,
              onPressed: widget.onRetry,
            ),
          ],
        ),
      );
    } else {
      final detail = FlarePluginView(
        view: view!,
        embedded: true,
        resolveUser: widget.resolveUser,
        viewerId: widget.viewerId,
        busyActionId: widget.busyActionId,
        error: widget.actionError,
        formErrors: widget.formErrors,
        members: widget.members,
        settleToken: widget.settleToken,
        onAction: widget.onAction,
      );
      final cursor = view.nextPageCursor;
      if (cursor == null) {
        body = detail;
      } else {
        final busy = _pageBusy(cursor);
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            detail,
            const SizedBox(height: FlareSizes.spacingMd),
            FlareButton(
              key: FlarePluginDetailSheet.loadMoreKey,
              label: strings.myInviteLoadMore,
              variant: FlareButtonVariant.ghost,
              size: FlareControlSize.sm,
              block: true,
              loading: busy,
              disabled: busy,
              onPressed: busy ? null : () => _loadMore(cursor),
            ),
          ],
        );
      }
    }
    return Semantics(
      container: true,
      label: (view?.title.isNotEmpty ?? false) ? view!.title : title,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FlareSizes.spacingLg,
          FlareSizes.spacingMd,
          FlareSizes.spacingLg,
          FlareSizes.spacingXl,
        ),
        child: SingleChildScrollView(child: body),
      ),
    );
  }
}
