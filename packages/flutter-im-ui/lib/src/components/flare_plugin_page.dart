import 'dart:async';

import 'package:flutter/material.dart';

import '../models/directory_data.dart'
    show FlareButtonVariant, FlareControlSize;
import '../models/plugin_view.dart';
import '../models/plugin_refresh.dart';
import '../platform/flare_platform.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_account_view.dart';
import 'flare_button.dart';
import 'flare_empty_state.dart';
import 'flare_filter_tabs.dart';
import 'flare_icon_button.dart';
import 'flare_plugin_blocks_extra.dart';
import 'flare_plugin_upgrade_notice.dart';
import 'flare_plugin_view.dart';
import 'flare_screen.dart';
import 'flare_status_banner.dart';
import 'plugin_paging.dart';
import 'flare_plugin_qr.dart';

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
    this.providerName,
    this.visible = true,
    this.encodePluginCode,
    this.onSurfaceHints,
    this.appearance = FlarePluginPageAppearance.document,
    this.contentMaxWidth = FlareSizes.directoryContentMaxWidth,
    this.view,
    this.filters = const {},
    this.loading = false,
    this.error,
    this.refreshing = false,
    this.loadingMore = false,
    this.pagingToken = 0,
    this.resolveUser,
    this.viewerId,
    this.busyActionId,
    this.actionError,
    this.formErrors = const [],
    this.fileStates = const {},
    this.onFileAction,
    this.locationStates = const {},
    this.onLocationAction,
    this.protectedMedia = const {},
    this.onProtectedMediaRead,
    this.members = const [],
    this.membersLoading = false,
    this.membersRevision = 0,
    this.membersError,
    this.onMemberSearch,
    this.onMembersRetry,
    this.settleToken = 0,
    this.onBack,
    this.onRefresh,
    this.onRetry,
    this.onLoadMore,
    this.onFilter,
    this.onAction,
    this.resolveImage,
    this.onQrRefresh,
    this.upgradeStatus,
    this.onUpdate,
    this.upgradeBusy = false,
  });

  /// Image blocks: what the host fetched for an asset path or private file id
  /// (FlarePluginView.resolveImage).
  final FlarePluginImageResolver? resolveImage;

  /// An expired QR code on the page asks for a fresh one
  /// (FlarePluginView.onQrRefresh).
  final ValueChanged<FlarePluginQrRefresh>? onQrRefresh;

  /// An upgrade_required page: update.plugin_upgrade_status for its minBuild.
  final FlarePluginUpgradeStatus? upgradeStatus;

  /// An upgrade_required page: opens the update flow; without it the page has
  /// no update key.
  final VoidCallback? onUpdate;

  /// The update flow is opening.
  final bool upgradeBusy;

  /// The page shown; every page action carries it.
  final FlarePluginPageRef page;

  /// Page title while there is no view (or the view has none, as an
  /// unavailable one); the view's title wins.
  final String? title;
  final String? providerName;
  final bool visible;
  final Future<String> Function(String pluginId, String token)? encodePluginCode;
  final ValueChanged<FlareScanSurfaceHints>? onSurfaceHints;
  final FlarePluginPageAppearance appearance;

  /// Shared header/body column, including page gutters. Null or a nonpositive
  /// or nonfinite value leaves the page unconstrained.
  final double? contentMaxWidth;

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

  /// Pagination completion/invalidation only; never settles a financial form.
  final int pagingToken;
  final FlarePluginResolveUser? resolveUser;

  /// The viewer's user id (the "我" tag in entries).
  final String? viewerId;

  /// The action in flight, passed to the view.
  final String? busyActionId;

  /// Failure text of an action run on the page (the view's error).
  final String? actionError;
  final List<FlarePluginFormError> formErrors;
  final Map<String, FlarePluginFileState> fileStates;
  final ValueChanged<FlarePluginFileAction>? onFileAction;

  /// Location inputs: the host's fix, a running locate or a failure, by input
  /// id ([FlarePluginForm.locationStates]).
  final Map<String, FlarePluginLocationState> locationStates;

  /// A location input's locate or clear key: the host runs the page's
  /// locationOnce action into the input ([FlarePluginForm.onLocationAction]).
  final ValueChanged<FlarePluginLocationAction>? onLocationAction;

  /// What the host has for each protected media item, by item id: the read's
  /// address (the server's https grant address), a running read or a failure.
  final Map<String, FlarePluginProtectedMediaState> protectedMedia;

  /// A protected media read (with its reason when the block asks one): the
  /// host runs and audits it, then fills [protectedMedia] with
  /// [flarePluginProtectedMediaUrl] of the result.
  final ValueChanged<FlarePluginProtectedMediaRead>? onProtectedMediaRead;
  final List<FlarePluginMember> members;

  /// Server member-search state; without onMemberSearch the picker filters locally.
  final bool membersLoading;

  /// An authoritative roster/permission invalidation, never an ordinary search result.
  final int membersRevision;
  final String? membersError;
  final ValueChanged<String>? onMemberSearch;
  final VoidCallback? onMembersRetry;

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

class _FlarePluginPageState extends State<FlarePluginPage> with WidgetsBindingObserver {
  Timer? _scanRefresh;
  int? _lastRefreshMs;
  bool _automaticRefresh = false, _interacting = false, _foreground = true, _routeVisible = true;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _configureScanRefresh(); WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _publishSurface(); }); }
  @override
  void didChangeDependencies() { super.didChangeDependencies(); _routeVisible = ModalRoute.isCurrentOf(context) ?? true; WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _publishSurface(); }); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { _foreground = state == AppLifecycleState.resumed; _publishSurface(); }
  void _configureScanRefresh() {
    final interval = widget.view?.refreshMs;
    if (interval != null && interval >= 3000 && interval <= 60000 && interval != _lastRefreshMs) { _lastRefreshMs = interval; _scanRefresh?.cancel(); _scanRefresh = Timer.periodic(Duration(milliseconds: interval), (_) {
      if (!mounted || !flarePluginMayRefresh(visible: widget.visible && _routeVisible, foreground: _foreground, loading: widget.loading, refreshing: widget.refreshing, busy: widget.loadingMore || widget.busyActionId != null, interaction: _interacting)) return;
      _automaticRefresh = true; widget.onRefresh?.call();
    }); }
  }
  void _publishSurface() {
    final qr = widget.visible && _foreground && _routeVisible && widget.view?.available == true && widget.view?.presentation?['renderer'] == 'flare.qr';
    final presentation = widget.view?.presentation?['props'];
    widget.onSurfaceHints?.call(FlareScanSurfaceHints(secure: qr && presentation is Map && presentation['ttlMs'] is num, maxBrightness: qr));
  }

  final _cursor = FlarePluginPageCursor();

  /// The pull the indicator is showing, until the host's refresh ends.
  Completer<void>? _pull;

  @override
  void didUpdateWidget(FlarePluginPage old) {
    super.didUpdateWidget(old);
    if (old.page.pluginId != widget.page.pluginId || old.page.page != widget.page.page) { _scanRefresh?.cancel(); _lastRefreshMs = null; _automaticRefresh = false; }
    _configureScanRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _publishSurface(); });
    _cursor.update(
      wasLoadingMore: old.loadingMore,
      loadingMore: widget.loadingMore,
      oldSettleToken: old.settleToken,
      settleToken: widget.settleToken,
      oldError: old.actionError,
      error: widget.actionError,
    );
    if (old.pagingToken != widget.pagingToken) _cursor.release();
    // Query/pagination failures release only the cursor guard. They never
    // settle a financial action or an open form.
    // Fast retries can fail with identical copy before a loading frame paints.
    if (!widget.loadingMore && (widget.error?.isNotEmpty ?? false)) {
      _cursor.release();
    }
    if (old.refreshing && !widget.refreshing) {
      _automaticRefresh = false;
      _cursor.release();
      _endPull();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); _scanRefresh?.cancel(); widget.onSurfaceHints?.call(const FlareScanSurfaceHints(secure: false, maxBrightness: false));
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
    if (_filtersBusy || widget.onLoadMore == null) return;
    if (!_cursor.ask(cursor, loadingMore: widget.loadingMore)) return;
    setState(() {});
    widget.onLoadMore?.call(cursor);
  }

  bool get _filtersBusy =>
      widget.loading || (widget.refreshing && !_automaticRefresh) || widget.loadingMore;

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

  Widget _qr(FlarePluginPageViewModel view) {
    final raw = view.presentation?['props'];
    final props = raw is Map ? raw : const <String, Object?>{};
    return FlarePluginQr(token: props['token'] as String?, ttlMs: (props['ttlMs'] as num?)?.toInt(), caption: props['caption'] as String?, encodeQr: widget.encodePluginCode == null ? null : (token) => widget.encodePluginCode!(widget.page.pluginId, token));
  }

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
      FlarePluginPageState.unavailable
          when view?.unavailableReason ==
              FlarePluginUnavailableReason.upgradeRequired =>
        FlarePluginUpgradeNotice(
          key: FlarePluginPage.unavailableKey,
          variant: FlarePluginUpgradeVariant.page,
          title: view!.title.isEmpty ? null : view.title,
          status: widget.upgradeStatus,
          onUpdate: widget.onUpdate,
          busy: widget.upgradeBusy,
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
      padding: const EdgeInsets.fromLTRB(
        FlareSizes.spacingLg,
        FlareSizes.spacingMd,
        FlareSizes.spacingLg,
        FlareSizes.spacingXl,
      ),
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
        contentMaxWidth: widget.contentMaxWidth,
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
    final pagingDisabled = busy || _filtersBusy || widget.onLoadMore == null;
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
            actionText: widget.onRefresh != null && !widget.refreshing
                ? strings.retry
                : null,
            onAction: widget.refreshing ? null : widget.onRefresh,
          ),
          const SizedBox(height: FlareSizes.spacingMd),
        ],
        for (final filter in filters) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: FlareSizes.spacingXs),
            child: Text(
              filter.input.label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: FlareSizes.fontSizeSm,
              ),
            ),
          ),
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
        if (widget.providerName?.isNotEmpty == true) Text(strings.scanProvidedBy.replaceAll('{name}', widget.providerName!)),
        if (view.presentation?['renderer'] == 'flare.qr') _qr(view),
        // The host picks the account layout; a view no longer selects it
        // through a renderer (vocabulary 2 draws accounts from blocks).
        if (widget.appearance == FlarePluginPageAppearance.account)
          FlareAccountView(
            fileStates: widget.fileStates,
            onFileAction: widget.onFileAction,
            view: view,
            busyActionId: widget.busyActionId,
            error: widget.actionError,
            formErrors: widget.formErrors,
            members: widget.members,
            membersLoading: widget.membersLoading,
            membersRevision: widget.membersRevision,
            membersError: widget.membersError,
            onMemberSearch: widget.onMemberSearch,
            onMembersRetry: widget.onMembersRetry,
            settleToken: widget.settleToken,
            onAction: widget.onAction == null ? null : _runAction,
          )
        else
          FlarePluginView(
            onInteractionChanged: (active) => _interacting = active,
            fileStates: widget.fileStates,
            protectedMedia: widget.protectedMedia,
            onProtectedMediaRead: widget.onProtectedMediaRead,
            onFileAction: widget.onFileAction,
            locationStates: widget.locationStates,
            onLocationAction: widget.onLocationAction,
            view: view,
            embedded: true,
            resolveUser: widget.resolveUser,
            viewerId: widget.viewerId,
            busyActionId: widget.busyActionId,
            error: widget.actionError,
            formErrors: widget.formErrors,
            members: widget.members,
            membersLoading: widget.membersLoading,
            membersRevision: widget.membersRevision,
            membersError: widget.membersError,
            onMemberSearch: widget.onMemberSearch,
            onMembersRetry: widget.onMembersRetry,
            settleToken: widget.settleToken,
            resolveImage: widget.resolveImage,
            onQrRefresh: widget.onQrRefresh,
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
            disabled: pagingDisabled,
            onPressed: pagingDisabled ? null : () => _loadMore(cursor),
          ),
        ],
      ],
    );
  }
}
