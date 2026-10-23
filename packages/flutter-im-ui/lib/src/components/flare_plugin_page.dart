import 'dart:async';

import 'package:flutter/material.dart';

import '../models/directory_data.dart'
    show FlareButtonVariant, FlareControlSize;
import '../models/plugin_view.dart';
import '../platform/flare_platform.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_empty_state.dart';
import 'flare_filter_tabs.dart';
import 'flare_icon_button.dart';
import 'flare_plugin_view.dart';
import 'flare_screen.dart';
import 'flare_status_banner.dart';
import 'plugin_paging.dart';

/// Plugin page host — a full-screen page for a plugin's `page` contribution
/// (red packet v5's wallet and its history, a list): the kit [FlareScreen]
/// with the heading and back key, the select filters of its rows as
/// [FlareFilterTabs], the resolved view drawn by an embedded
/// [FlarePluginView] (the same document renderer as `FlarePluginDetailSheet`,
/// so blocks, menu actions, forms and settling behave the same; rows draw as
/// a list with their badges, each key once), pull to refresh on touch and a
/// refresh key in the header on pointer devices, and a full-width load-more
/// key under the view while it has a next page (asked once per cursor).
/// Spec: Message/PluginPage (`FlarePluginPage`); facts in
/// spec/plugin-view-vectors.json (rules.page, pageRows, pagePaging,
/// pageFilters).
///
/// Every action run on the page — a view action, a menu action, a choices
/// submit or a row action, after its confirm and form — goes out through
/// [onAction] as the page action request ([FlarePluginPageActionPayload]:
/// [page], the view's data, and the row, selection or form values), so the
/// host passes it straight to invokePageAction.
///
/// The host fetches: [onRefresh], [onRetry], [onLoadMore] and [onFilter] are
/// requests and the kit calls nothing. While [refreshing] is true the refresh
/// indicator stays. An unavailable view shows its reason in the kit empty
/// state (a retry only when the catalog was unreachable) and nothing else.
/// No placeholder buttons: whatever the view does not declare is not drawn.
class FlarePluginPage extends StatefulWidget {
  const FlarePluginPage({
    super.key,
    required this.page,
    this.title,
    this.view,
    this.filters = const {},
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
    this.onFilter,
    this.onAction,
  });

  /// The page shown; every page action carries it.
  final FlarePluginPageRef page;

  /// Page title while there is no view (or the view has none, as an
  /// unavailable one); the view's title wins.
  final String? title;

  /// The resolved page view (the core SDK's pluginPage result, with data);
  /// null while the first load runs. Pass the merged view after load more and
  /// the re-read one after a refresh or a filter change.
  final FlarePluginPageViewModel? view;

  /// The applied filter values by input id (what the host passed to
  /// pluginPage as filters); the filter tabs show them.
  final Map<String, Object?> filters;

  /// The first load runs: a spinner in place of the view.
  final bool loading;

  /// Loading failed. Without a view: the host's text and a retry key; with
  /// one (a refresh failed): a danger banner above it.
  final String? error;

  /// A refresh is running: the indicator stays and the filter tabs wait.
  final bool refreshing;

  /// The next page is loading: the load-more key spins and is disabled, and
  /// the filter tabs wait.
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

  /// The first load failed, or the catalog was unreachable, and the reader
  /// asked again.
  final VoidCallback? onRetry;

  /// The page after the cursor (the view's next cursor); the host passes back
  /// the merged view.
  final ValueChanged<String>? onLoadMore;

  /// A filter tab was chosen: the host's [filters] with that input set to the
  /// choice's value, or without it for all. The host reads the first page
  /// with them and passes back the view and the filters.
  final ValueChanged<Map<String, Object?>>? onFilter;
  final FlarePluginPageActionCallback? onAction;

  static const Key loadingKey = ValueKey('flare-plugin-page-loading');
  static const Key errorKey = ValueKey('flare-plugin-page-error');
  static const Key unavailableKey = ValueKey('flare-plugin-page-unavailable');
  static const Key retryKey = ValueKey('flare-plugin-page-retry');
  static const Key refreshKey = ValueKey('flare-plugin-page-refresh');
  static const Key loadMoreKey = ValueKey('flare-plugin-page-load-more');
  static const Key bannerKey = ValueKey('flare-plugin-page-banner');

  /// The filter tabs of the input [inputId] (a test hook).
  static Key filterKey(String inputId) =>
      ValueKey('flare-plugin-page-filter:$inputId');

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
    if (old.refreshing && !widget.refreshing) {
      _cursor.release();
      _endPull();
    }
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

  bool get _filtersBusy => widget.refreshing || widget.loadingMore;

  void _choose(FlarePluginPageFilter filter, String key) {
    if (_filtersBusy) return;
    // All is the empty key: a choice's value is never empty.
    final value = key.isEmpty ? null : key;
    if (value == filter.selected) return;
    widget.onFilter?.call(
      flarePluginPageFilterValues(widget.filters, filter.input.id, value),
    );
  }

  void _runAction(String actionId, FlarePluginActionPayload payload) =>
      widget.onAction?.call(
        actionId,
        flarePluginPagePayload(widget.page, widget.view, payload),
      );

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final view = widget.view;
    final pointer = flareCapabilitiesOf(context).hover;
    final title = (view?.title.isNotEmpty ?? false)
        ? view!.title
        : (widget.title ?? '');
    final state = flarePluginPageState(
      view,
      loading: widget.loading,
      error: widget.error,
    );
    final canRefresh =
        widget.onRefresh != null && state == FlarePluginPageState.loaded;

    final Widget body = switch (state) {
      FlarePluginPageState.loading => Semantics(
        key: FlarePluginPage.loadingKey,
        label: strings.loading,
        liveRegion: true,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: FlareSizes.spacing2xl),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ),
      FlarePluginPageState.error => Padding(
        key: FlarePluginPage.errorKey,
        padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                widget.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeLg,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: FlareSizes.spacingMd),
            _retry(strings),
          ],
        ),
      ),
      FlarePluginPageState.unavailable => Semantics(
        liveRegion: true,
        child: FlareEmptyState(
          key: FlarePluginPage.unavailableKey,
          title: flarePluginPageUnavailableText(view!, strings),
          icon: 'info',
          actions: [
            // Only an unreachable catalog is worth asking again.
            if (view.unavailableReason ==
                FlarePluginUnavailableReason.catalogUnreachable)
              _retry(strings),
          ],
        ),
      ),
      FlarePluginPageState.loaded => _loaded(colors, strings, view!),
    };

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
          if (pointer && canRefresh)
            FlareIconButton(
              key: FlarePluginPage.refreshKey,
              icon: 'refresh',
              semanticLabel: strings.pluginPageRefresh,
              disabled: widget.refreshing,
              onPressed: widget.refreshing ? null : widget.onRefresh,
            ),
        ],
        child: canRefresh
            ? RefreshIndicator.adaptive(onRefresh: _refresh, child: scroll)
            : scroll,
      ),
    );
  }

  Widget _retry(FlareStrings strings) => FlareButton(
    key: FlarePluginPage.retryKey,
    label: strings.retry,
    variant: FlareButtonVariant.secondary,
    onPressed: widget.onRetry,
  );

  Widget _loaded(
    FlareColors colors,
    FlareStrings strings,
    FlarePluginPageViewModel view,
  ) {
    final cursor = view.nextPageCursor;
    final busy =
        cursor != null && _cursor.busy(cursor, loadingMore: widget.loadingMore);
    final error = widget.error;
    final filters = flarePluginPageFilters(
      view,
      widget.filters,
      strings.pluginViewAll,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // A refresh that failed keeps the shown view under the failure.
        if (error != null && error.isNotEmpty) ...[
          FlareStatusBanner(
            key: FlarePluginPage.bannerKey,
            text: error,
            tone: FlareStatusTone.danger,
          ),
          const SizedBox(height: FlareSizes.spacingMd),
        ],
        for (final filter in filters) ...[
          Semantics(
            container: true,
            label: filter.input.label,
            child: FlareFilterTabs(
              key: FlarePluginPage.filterKey(filter.input.id),
              options: [
                for (final tab in filter.tabs)
                  FlareFilterTabOption(
                    value: tab.value ?? '',
                    label: tab.label,
                  ),
              ],
              selected: filter.selected ?? '',
              enabled: !_filtersBusy,
              onSelect: (key) => _choose(filter, key),
            ),
          ),
          const SizedBox(height: FlareSizes.spacingXs),
        ],
        if (filters.isNotEmpty) const SizedBox(height: FlareSizes.spacingSm),
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
          onAction: widget.onAction == null ? null : _runAction,
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
}
