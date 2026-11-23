import 'dart:async';

import 'package:flutter/material.dart';

import '../models/directory_data.dart'
    show FlareButtonVariant, FlareControlSize;
import '../models/plugin_layout.dart';
import '../models/plugin_view.dart';
import '../models/plugin_refresh.dart';
import '../models/red_packet_page.dart';
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
import 'flare_red_packet_page.dart';
import 'flare_result_view.dart';
import 'flare_screen.dart';
import 'flare_segmented_control.dart';
import 'flare_skeleton.dart';
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
/// Actions are placed by role (docs/plugin-experience.md R2,
/// rules.actionRoles): the overview's quick keys and grouped list cards, a
/// task's action row (pinned to the bottom on a phone), a records page's
/// header key, command keys and "more actions" card, the danger card last.
/// The refresh key shows on data pages only (R1); after an action settles
/// cleanly the page asks [onRefresh] with [FlarePluginRefreshReason.action]
/// (R4); a pending result asks every 3 s for up to a minute (R7). Without
/// [appearance] the account layout is derived from the view (R12).
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
    this.appearance,
    this.offline = false,
    this.onDone,
    this.onTab,
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
    this.memberCount,
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
  final Future<String> Function(String pluginId, String token)?
  encodePluginCode;
  final ValueChanged<FlareScanSurfaceHints>? onSurfaceHints;

  /// null (the default) derives it from the view
  /// ([flarePluginDerivesAccount]); [FlarePluginPageAppearance.document]
  /// turns the derivation off. Hosts never choose it by plugin id.
  final FlarePluginPageAppearance? appearance;

  /// The host is offline: a warning banner under the header, the last view
  /// stays, every action is disabled (R8).
  final bool offline;

  /// A result page's done key (R7): the host pops to the page that started
  /// the flow and refreshes it, or closes the page. Without it done is back.
  final VoidCallback? onDone;

  /// A tab of the view's sibling pages was chosen (§4.7, rules.pageTabs):
  /// the host replaces the shown page on its stack with that page (same
  /// arguments and conversation, no new back step) and reads it.
  final ValueChanged<String>? onTab;

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

  /// The conversation's group size counting the viewer, from the host's own
  /// group data: the red packet page's 「本群共 N 人」.
  final int? memberCount;
  final ValueChanged<String>? onMemberSearch;
  final VoidCallback? onMembersRetry;

  /// The host's settle signal for actions run on the page.
  final int settleToken;

  /// Draws the back key; the platform back does the same.
  final VoidCallback? onBack;

  /// Read the page again, and why: a pull, the header key, a timer
  /// (refreshMs or a pending result) or a cleanly settled action.
  final ValueChanged<FlarePluginRefreshReason>? onRefresh;

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
  static const Key offlineKey = ValueKey('flare-plugin-page-offline');
  static const Key actionErrorKey = ValueKey('flare-plugin-page-action-error');
  static const Key refreshBarKey = ValueKey('flare-plugin-page-refresh-bar');
  static const Key skeletonKey = ValueKey('flare-plugin-page-skeleton');
  static const Key headerActionKey = ValueKey(
    'flare-plugin-page-header-action',
  );
  static const Key barKey = ValueKey('flare-plugin-page-bar');
  static const Key tabsKey = ValueKey('flare-plugin-page-tabs');

  /// The filter tabs of the input [inputId] (a test hook).
  static Key filterKey(String inputId) =>
      ValueKey('flare-plugin-page-filter:$inputId');

  @override
  State<FlarePluginPage> createState() => _FlarePluginPageState();
}

class _FlarePluginPageState extends State<FlarePluginPage>
    with WidgetsBindingObserver {
  Timer? _scanRefresh;
  int? _lastRefreshMs;
  bool _automaticRefresh = false,
      _interacting = false,
      _foreground = true,
      _routeVisible = true;
  @override
  void initState() {
    super.initState();
    _keepTabs();
    _scrollController.addListener(_pinDay);
    WidgetsBinding.instance.addObserver(this);
    _configureScanRefresh();
    _configureSkeleton();
    _configureResultPoll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publishSurface();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeVisible = ModalRoute.isCurrentOf(context) ?? true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publishSurface();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _publishSurface();
  }

  void _configureScanRefresh() {
    final interval = widget.view?.refreshMs;
    if (interval != null &&
        interval >= 3000 &&
        interval <= 60000 &&
        interval != _lastRefreshMs) {
      _lastRefreshMs = interval;
      _scanRefresh?.cancel();
      _scanRefresh = Timer.periodic(Duration(milliseconds: interval), (_) {
        if (!mounted ||
            !flarePluginMayRefresh(
              visible: widget.visible && _routeVisible,
              foreground: _foreground,
              loading: widget.loading,
              refreshing: widget.refreshing,
              busy: widget.loadingMore || widget.busyActionId != null,
              interaction: _interacting,
            ))
          return;
        _automaticRefresh = true;
        widget.onRefresh?.call(FlarePluginRefreshReason.timer);
      });
    }
  }

  final _viewKey = GlobalKey<FlarePluginViewState>();

  // R8: the first 300 ms of a first load draw nothing.
  Timer? _skeletonDelay;
  bool _skeleton = false;
  void _configureSkeleton() {
    final first = widget.loading && widget.view == null;
    if (!first) {
      _skeletonDelay?.cancel();
      _skeletonDelay = null;
      _skeleton = false;
    } else if (_skeletonDelay == null && !_skeleton) {
      _skeletonDelay = Timer(
        const Duration(milliseconds: flarePluginSkeletonDelayMs),
        () {
          if (mounted) setState(() => _skeleton = true);
        },
      );
    }
  }

  // R7: a pending result asks again every 3 s for at most a minute.
  Timer? _resultPoll;
  DateTime? _pendingSince;
  void _configureResultPoll() {
    final result = widget.view == null
        ? null
        : flarePluginResultOf(widget.view!);
    if (result == null || !flarePluginResultPolls(result)) {
      _resultPoll?.cancel();
      _resultPoll = null;
      _pendingSince = null;
      return;
    }
    final since = _pendingSince ??= DateTime.now();
    if (_resultPoll != null) return;
    _resultPoll = Timer.periodic(
      const Duration(milliseconds: flarePluginResultPollMs),
      (timer) {
        if (!mounted ||
            DateTime.now().difference(since).inMilliseconds >=
                flarePluginResultPollForMs) {
          timer.cancel();
          return;
        }
        if (!flarePluginMayRefresh(
          visible: widget.visible && _routeVisible,
          foreground: _foreground,
          loading: widget.loading,
          refreshing: widget.refreshing,
          busy: widget.loadingMore || widget.busyActionId != null,
          interaction: _interacting,
        ))
          return;
        _automaticRefresh = true;
        widget.onRefresh?.call(FlarePluginRefreshReason.timer);
      },
    );
  }

  /// The action failure the reader closed (R8).
  String? _dismissedError;

  /// The tabs last drawn: kept, with the chosen page selected, until that
  /// page has a view (rules.pageTabs).
  List<FlarePluginPageTab> _lastTabs = const [];
  void _keepTabs() {
    final tabs = flarePluginPageTabs(widget.view, widget.page.page, const []);
    if (tabs.isNotEmpty) _lastTabs = tabs;
  }

  // §5.8: the records' day heading scrolled past stays pinned on top.
  final _dayKeys = <String, GlobalKey>{};
  final _scrollKey = GlobalKey();
  final _scrollController = ScrollController();
  String? _pinnedDay;

  void _pinDay() {
    final viewport = _scrollKey.currentContext?.findRenderObject();
    String? pinned;
    var best = double.negativeInfinity;
    if (viewport is RenderBox) {
      for (final MapEntry(key: day, value: key) in _dayKeys.entries) {
        final box = key.currentContext?.findRenderObject();
        if (box is! RenderBox || !box.attached) continue;
        final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
        if (top <= 0 && top > best) {
          best = top;
          pinned = day;
        }
      }
    }
    if (pinned != _pinnedDay && mounted) setState(() => _pinnedDay = pinned);
  }

  void _publishSurface() {
    final qr =
        widget.visible &&
        _foreground &&
        _routeVisible &&
        widget.view?.available == true &&
        widget.view?.presentation?['renderer'] == 'flare.qr';
    final presentation = widget.view?.presentation?['props'];
    widget.onSurfaceHints?.call(
      FlareScanSurfaceHints(
        secure: qr && presentation is Map && presentation['ttlMs'] is num,
        maxBrightness: qr,
      ),
    );
  }

  final _cursor = FlarePluginPageCursor();

  /// The pull the indicator is showing, until the host's refresh ends.
  Completer<void>? _pull;

  @override
  void didUpdateWidget(FlarePluginPage old) {
    super.didUpdateWidget(old);
    if (old.page.pluginId != widget.page.pluginId ||
        old.page.page != widget.page.page) {
      _scanRefresh?.cancel();
      _lastRefreshMs = null;
      _automaticRefresh = false;
    }
    _configureScanRefresh();
    _configureSkeleton();
    _configureResultPoll();
    _keepTabs();
    if (widget.actionError != old.actionError) _dismissedError = null;
    // R4: an action that settled with no error and no form errors while the
    // page is on screen asks for the page again.
    if (old.settleToken != widget.settleToken) {
      final ok =
          (widget.actionError ?? '').isEmpty && widget.formErrors.isEmpty;
      // Visibility is read after the frame: an action that opened the next
      // page has covered this one by then.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            flarePluginRefreshAfterAction(
              ok: ok,
              visible:
                  widget.visible && (ModalRoute.isCurrentOf(context) ?? true),
            )) {
          widget.onRefresh?.call(FlarePluginRefreshReason.action);
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publishSurface();
    });
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
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _scanRefresh?.cancel();
    _skeletonDelay?.cancel();
    _resultPoll?.cancel();
    widget.onSurfaceHints?.call(
      const FlareScanSurfaceHints(secure: false, maxBrightness: false),
    );
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
    refresh(FlarePluginRefreshReason.pull);
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
      widget.loading ||
      (widget.refreshing && !_automaticRefresh) ||
      widget.loadingMore;

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
    return FlarePluginQr(
      token: props['token'] as String?,
      ttlMs: (props['ttlMs'] as num?)?.toInt(),
      caption: props['caption'] as String?,
      encodeQr: widget.encodePluginCode == null
          ? null
          : (token) => widget.encodePluginCode!(widget.page.pluginId, token),
    );
  }

  FlarePluginPageAppearance _appearance(FlarePluginPageViewModel view) =>
      widget.appearance ??
      (flarePluginDerivesAccount(view)
          ? FlarePluginPageAppearance.account
          : FlarePluginPageAppearance.document);

  /// The page's own form (R6), drawn inline by the view.
  String? _inlineFormId(FlarePluginPageViewModel view) =>
      flarePluginPageInlineFormActionId(
        view,
        interactive: widget.onAction != null,
      );

  bool get _keysOff =>
      widget.offline || widget.onAction == null || widget.busyActionId != null;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final view = widget.view;
    final pointer = flareCapabilitiesOf(context).hover;
    final width = MediaQuery.maybeSizeOf(context)?.width ?? 0;
    // The kit's one PC breakpoint (breakpoints.md), as the view, the task
    // bar, the result and the radio cards read it.
    final phone = width < FlareSizes.appShellCompactMinWidth;
    final title = (view?.title.isNotEmpty ?? false)
        ? view!.title
        : (widget.title ?? '');
    final state = flarePluginPageState(
      view,
      loading: widget.loading,
      error: widget.error,
    );
    final loaded = state == FlarePluginPageState.loaded ? view! : null;
    // §11: a red packet renderer draws the kit's red packet page.
    final redPacket = loaded != null && flareRedPacketPageDraws(loaded);
    final account =
        loaded != null &&
        !redPacket &&
        _appearance(loaded) == FlarePluginPageAppearance.account;
    final inline = loaded == null || account || redPacket
        ? null
        : _inlineFormId(loaded);
    // R1: the refresh key and the pull belong to data pages only.
    final canRefresh =
        widget.onRefresh != null &&
        loaded != null &&
        (account ||
            flarePluginShowsRefreshKey(loaded, inlineFormActionId: inline));
    // A result view and a status card draw their own keys (R7, §6.1).
    final places =
        loaded == null ||
            account ||
            redPacket ||
            !loaded.available ||
            flarePluginResultOf(loaded) != null ||
            flarePluginShowsStatusCard(loaded)
        ? null
        : flarePluginActionPlaces(
            loaded,
            embedded: true,
            inlineFormActionId: inline,
          );
    final header = places?.header.firstOrNull;
    final result = loaded == null ? null : flarePluginResultOf(loaded);
    final done = widget.onDone ?? widget.onBack;
    // R7: a phone pins the result's done key to the bottom.
    final pinDone = phone && result != null && done != null;
    final phoneTask =
        phone && places?.archetype == FlarePluginPageArchetype.task;
    // R2.2 / R6: a phone pins a task's primary; the page's own form pins
    // its submit through the form itself.
    final pinInline = phoneTask && inline != null;
    final pinBar =
        phoneTask &&
        inline == null &&
        (places!.bar.isNotEmpty || places.barSecondary.isNotEmpty);

    final Widget body = switch (state) {
      FlarePluginPageState.loading => Semantics(
        key: FlarePluginPage.loadingKey,
        label: strings.pluginViewLoading,
        liveRegion: true,
        // R8: nothing for 300 ms, then the records skeleton (no view yet).
        child: _skeleton
            ? FlareSkeleton(
                key: FlarePluginPage.skeletonKey,
                variant: FlareSkeletonVariant.list,
                rows: 6,
              )
            : const SizedBox(height: FlareSizes.touchTarget),
      ),
      FlarePluginPageState.error => FlareEmptyState(
        key: FlarePluginPage.errorKey,
        icon: 'error',
        title: strings.pluginViewLoadFailedTitle,
        description: widget.error,
        actions: [_retry(strings)],
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
      FlarePluginPageState.loaded => _loaded(
        colors,
        strings,
        view!,
        account: account,
        redPacket: redPacket,
        inline: inline,
        pinBar: pinBar || pinDone || pinInline,
      ),
    };

    final scroll = SingleChildScrollView(
      key: _scrollKey,
      controller: _scrollController,
      // A short page still pulls.
      physics: const AlwaysScrollableScrollPhysics(),
      // R1: 24 at the sides on PC, 16 on a phone.
      padding: EdgeInsets.fromLTRB(
        phone ? FlareSizes.spacingLg : FlareSizes.spacing2xl,
        FlareSizes.spacingMd,
        phone ? FlareSizes.spacingLg : FlareSizes.spacing2xl,
        FlareSizes.spacingXl,
      ),
      child: FlarePluginDayHeadings(
        keys: _dayKeys,
        child: switch (flarePluginPageTabs(view, widget.page.page, _lastTabs)) {
          final tabs when tabs.isNotEmpty => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // §4.7: sibling pages as a tablist above everything else.
              Semantics(
                container: true,
                label: title,
                child: FlareSegmentedControl(
                  key: FlarePluginPage.tabsKey,
                  options: [for (final tab in tabs) tab.label],
                  selectedIndex: tabs.indexWhere((tab) => tab.selected),
                  onSelect: (index) {
                    final page = flarePluginPageTabChoice(tabs, index);
                    if (page != null) widget.onTab?.call(page);
                  },
                ),
              ),
              const SizedBox(height: FlareSizes.spacingLg),
              body,
            ],
          ),
          _ => body,
        },
      ),
    );
    final still = MediaQuery.disableAnimationsOf(context);
    final pinnedDay = loaded == null ? null : _pinnedDay;
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
          // R2.3: a records page's primary sits in the header.
          if (header != null)
            FlareButton(
              key: FlarePluginPage.headerActionKey,
              label: header.label,
              variant: phone
                  ? FlareButtonVariant.primary
                  : FlareButtonVariant.secondary,
              appearance: phone
                  ? FlareButtonAppearance.text
                  : FlareButtonAppearance.standard,
              size: FlareControlSize.sm,
              maintainTouchTarget: true,
              loading: widget.busyActionId == header.id,
              disabled: _keysOff,
              onPressed: () => _viewKey.currentState?.runAction(header.id),
            ),
          if (pointer && canRefresh)
            FlareIconButton(
              key: FlarePluginPage.refreshKey,
              icon: 'refresh',
              semanticLabel: strings.pluginPageRefresh,
              disabled: widget.refreshing,
              onPressed: widget.refreshing
                  ? null
                  : () => widget.onRefresh!(FlarePluginRefreshReason.key),
            ),
        ],
        footer: pinDone
            ? FlarePluginPinnedBar(
                child: FlareButton(
                  key: FlareResultView.doneKey,
                  label: strings.pluginViewDone,
                  size: FlareControlSize.lg,
                  block: true,
                  loading: widget.busyActionId != null,
                  disabled: widget.busyActionId != null,
                  onPressed: done,
                ),
              )
            : pinBar
            ? FlarePluginTaskBar(
                key: FlarePluginPage.barKey,
                primary: places.bar.firstOrNull,
                secondary: places.barSecondary,
                pinned: true,
                busyActionId: widget.busyActionId,
                disabled:
                    widget.onAction == null || widget.busyActionId != null,
                offline: widget.offline,
                onRun: (action) => _viewKey.currentState?.runAction(action.id),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // R1: a 2-high bar under the header while a refresh runs; the
            // body stays. A pull shows its own spinner instead.
            if (widget.refreshing &&
                !_automaticRefresh &&
                _pull == null &&
                loaded != null)
              _RefreshBar(
                key: FlarePluginPage.refreshBarKey,
                color: colors.primary,
                still: still,
              ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    // R1: a touch page pulls; a pointer has the header key.
                    child: canRefresh && !pointer
                        ? RefreshIndicator.adaptive(
                            onRefresh: _refresh,
                            child: scroll,
                          )
                        : scroll,
                  ),
                  if (pinnedDay != null)
                    Positioned(
                      key: const ValueKey('flare-plugin-page-pinned-day'),
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ExcludeSemantics(
                        child: ColoredBox(
                          color: colors.bgPrimary,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: phone
                                  ? FlareSizes.spacingLg
                                  : FlareSizes.spacing2xl,
                              vertical: FlareSizes.spacingXs,
                            ),
                            child: Text(
                              pinnedDay,
                              style: TextStyle(
                                fontSize: FlareSizes.fontSizeSm,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
    FlarePluginPageViewModel view, {
    required bool account,
    bool redPacket = false,
    required String? inline,
    required bool pinBar,
  }) {
    final cursor = view.nextPageCursor;
    final busy =
        cursor != null && _cursor.busy(cursor, loadingMore: widget.loadingMore);
    final pagingDisabled = busy || _filtersBusy || widget.onLoadMore == null;
    final error = widget.error;
    final actionError = widget.actionError;
    final filters = flarePluginPageFilters(
      view,
      widget.filters,
      strings.pluginViewAll,
    );
    final empty =
        view.fields.isEmpty &&
        view.blocks.isEmpty &&
        view.actions.isEmpty &&
        view.presentation == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // R8: offline keeps the last view under a warning.
        if (widget.offline) ...[
          FlareStatusBanner(
            key: FlarePluginPage.offlineKey,
            text: strings.pluginViewOffline,
            tone: FlareStatusTone.warning,
          ),
          const SizedBox(height: FlareSizes.spacingMd),
        ],
        // A refresh that failed keeps the shown view under the failure.
        if (error != null && error.isNotEmpty) ...[
          FlareStatusBanner(
            key: FlarePluginPage.bannerKey,
            text: error,
            tone: FlareStatusTone.danger,
            actionText: widget.onRefresh != null && !widget.refreshing
                ? strings.retry
                : null,
            onAction: widget.refreshing || widget.onRefresh == null
                ? null
                : () => widget.onRefresh!(FlarePluginRefreshReason.key),
          ),
          const SizedBox(height: FlareSizes.spacingMd),
        ],
        // R8: an action failure, at the top, with a close key (the account
        // layout and the red packet page draw their own).
        if (!account &&
            !redPacket &&
            actionError != null &&
            actionError.isNotEmpty &&
            actionError != _dismissedError) ...[
          FlareStatusBanner(
            key: FlarePluginPage.actionErrorKey,
            text: actionError,
            tone: FlareStatusTone.danger,
            dismissible: true,
            onDismiss: () => setState(() => _dismissedError = actionError),
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
        if (widget.providerName?.isNotEmpty == true)
          Text(
            strings.scanProvidedBy.replaceAll('{name}', widget.providerName!),
          ),
        if (view.presentation?['renderer'] == 'flare.qr') _qr(view),
        if (empty)
          FlareEmptyState(title: strings.pluginViewEmpty, icon: 'info')
        else if (redPacket)
          FlareRedPacketPage(
            key: ValueKey(widget.page),
            view: view,
            busyActionId: widget.busyActionId,
            refreshing: widget.refreshing,
            error: widget.actionError,
            formErrors: widget.formErrors,
            settleToken: widget.settleToken,
            members: widget.members,
            memberCount: widget.memberCount,
            membersLoading: widget.membersLoading,
            membersError: widget.membersError,
            membersRevision: widget.membersRevision,
            onMemberSearch: widget.onMemberSearch,
            onMembersRetry: widget.onMembersRetry,
            resolveUser: widget.resolveUser,
            viewerId: widget.viewerId,
            onAction: widget.onAction == null || widget.offline
                ? null
                : _runAction,
            onRefresh: widget.onRefresh == null
                ? null
                : () => widget.onRefresh!(FlarePluginRefreshReason.key),
            onBack: widget.onBack,
          )
        else if (account)
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
            offline: widget.offline,
            resolveUser: widget.resolveUser,
            viewerId: widget.viewerId,
            onAction: widget.onAction == null ? null : _runAction,
          )
        else
          FlarePluginView(
            key: _viewKey,
            onInteractionChanged: (active) => _interacting = active,
            fileStates: widget.fileStates,
            protectedMedia: widget.protectedMedia,
            onProtectedMediaRead: widget.onProtectedMediaRead,
            onFileAction: widget.onFileAction,
            locationStates: widget.locationStates,
            onLocationAction: widget.onLocationAction,
            view: view,
            embedded: true,
            actionLayout: FlarePluginActionLayout.roles,
            inlineFormActionId: inline,
            pinBar: pinBar,
            offline: widget.offline,
            showError: false,
            onDone: widget.onDone ?? widget.onBack,
            // §5.8: an empty list under a chosen filter offers "all" again.
            onClearFilters:
                widget.onFilter == null ||
                    _filtersBusy ||
                    filters.every((filter) => filter.selected == null)
                ? null
                : () => widget.onFilter!({
                    for (final MapEntry(:key, :value) in widget.filters.entries)
                      if (!filters.any((filter) => filter.input.id == key))
                        key: value,
                  }),
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
            label: strings.pluginViewLoadMore,
            variant: FlareButtonVariant.secondary,
            size: FlareControlSize.md,
            block: true,
            loading: busy,
            disabled: pagingDisabled,
            onPressed: pagingDisabled ? null : () => _loadMore(cursor),
          ),
        ] else if (view.blocks.any(
              (b) => b is FlarePluginRowsBlock && b.rows.isNotEmpty,
            ) &&
            widget.pagingToken > 0) ...[
          // §5.8: the end of a paged list says so.
          const SizedBox(height: FlareSizes.spacingMd),
          Text(
            strings.pluginViewEndOfList,
            key: const ValueKey('flare-plugin-page-end'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: FlareTextRoles.caption.fontSize,
              color: colors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

/// The refresh bar (R1, §7): 2 high, an indeterminate segment on a 1.2 s
/// loop; [still] (reduced motion) draws a half bar that does not move.
class _RefreshBar extends StatefulWidget {
  const _RefreshBar({super.key, required this.color, required this.still});
  final Color color;
  final bool still;

  @override
  State<_RefreshBar> createState() => _RefreshBarState();
}

class _RefreshBarState extends State<_RefreshBar>
    with SingleTickerProviderStateMixin {
  // Made in initState: a lazy one would first be built by dispose for a
  // still bar, after its ancestors are gone.
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(vsync: this, duration: FlareMotion.refreshLoop);
    if (!widget.still) _loop.repeat();
  }

  @override
  void didUpdateWidget(_RefreshBar old) {
    super.didUpdateWidget(old);
    if (widget.still) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 2,
    width: double.infinity,
    child: ClipRect(
      child: CustomPaint(
        painter: _RefreshBarPainter(
          widget.still ? null : _loop,
          widget.color,
          Directionality.of(context),
        ),
      ),
    ),
  );
}

class _RefreshBarPainter extends CustomPainter {
  _RefreshBarPainter(this.loop, this.color, this.direction)
    : super(repaint: loop);
  final Animation<double>? loop;
  final Color color;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    // A segment 40% wide slides across; a still bar is the leading half.
    final t = loop?.value;
    final width = size.width * (t == null ? 0.5 : 0.4);
    var left = t == null ? 0.0 : (t * 1.4 - 0.4) * size.width;
    if (direction == TextDirection.rtl) left = size.width - left - width;
    canvas.drawRect(
      Rect.fromLTWH(left, 0, width, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_RefreshBarPainter old) =>
      old.loop != loop || old.color != color || old.direction != direction;
}
