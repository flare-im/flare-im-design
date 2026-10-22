import 'dart:async';

import 'package:flutter/material.dart';

import '../models/location.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_empty_state.dart';
import 'flare_icon.dart';
import 'flare_icon_button.dart';
import 'flare_location_map.dart';
import 'flare_search_bar.dart';
import 'flare_skeleton.dart';

/// The device position; throwing (permission denied, no fix) turns the picker
/// to manual search.
typedef FlareRequestCurrentLocation = Future<FlareLocationCoordinate> Function();

/// The name and address of a coordinate, for the current-location row.
typedef FlareReverseGeocode =
    Future<FlareLocationAddress> Function(double latitude, double longitude);

/// Places around a centre: `query` "" is the nearby list, anything else a
/// search. The coordinate is null when no position is known (denied without a
/// previous place): the host searches without a centre.
typedef FlareSearchNearby =
    Future<List<FlareLocationPlace>> Function(
      double? latitude,
      double? longitude,
      String query,
    );

/// A static map URL for the map area, in device pixels (the logical size
/// times the screen scale clamped to 1..2, rounded:
/// [flareLocationPreviewSize]); null or throwing draws "map unavailable".
typedef FlareLocationPreviewUrl =
    Future<String?> Function(
      double latitude,
      double longitude,
      int zoom,
      int width,
      int height,
    );

/// The picker's state, the same names on every platform (spec
/// LocationPicker `states`). The picker's root carries it as its key
/// (`ValueKey(state)`).
enum FlareLocationPickerState {
  locating,
  located,
  denied,
  searching,
  noResults,
  mapUnavailable,
}

/// The content of the "send a location" sheet: a static map of the chosen
/// place, a key that locates the device again, a search field and the places
/// around, the first of them the current location. The host answers four
/// questions through its callbacks (where am I, what is here, what is around,
/// what does the map look like) and gets the chosen place in [onSend]; the
/// kit owns the states in between. It paints at once: the place the host
/// remembers ([initialLocation]), or skeleton rows, until the device answers.
/// Present it with `FlareBottomSheet.show(fill: true, ...)`: it brings its own
/// header ([FlareSheetOwnHeader]), so the sheet draws no second title.
/// Spec: Composer/LocationPicker.
class FlareLocationPicker extends StatefulWidget
    implements FlareSheetOwnHeader {
  const FlareLocationPicker({
    super.key,
    required this.requestCurrentLocation,
    this.ensurePermission,
    required this.searchNearby,
    this.reverseGeocode,
    this.previewUrl,
    this.initialLocation,
    this.zoom = 16,
    this.locateTimeoutMs = 5000,
    this.provider = FlareLocationProvider.osm,
    this.sending = false,
    this.onSend,
    this.onCancel,
  });

  final FlareRequestCurrentLocation requestCurrentLocation;

  /// The host's permission step, awaited before each locate: the system
  /// prompt's wait is not counted into [locateTimeoutMs], which starts once it
  /// answers true. false (or throwing) is denied at once, without asking for
  /// the position.
  final Future<bool> Function()? ensurePermission;
  final FlareSearchNearby searchNearby;
  final FlareReverseGeocode? reverseGeocode;
  final FlareLocationPreviewUrl? previewUrl;

  /// The last place the host remembers: painted at once and used when
  /// locating times out.
  final FlareLocationPlace? initialLocation;

  /// Map zoom for the preview.
  final int zoom;

  /// The tenant's map service: OpenStreetMap's credit is drawn on its static
  /// map.
  final FlareLocationProvider provider;

  /// How long to wait for the device before falling back to
  /// [initialLocation] (or manual search), counted from when
  /// [ensurePermission] answers true.
  final int locateTimeoutMs;

  /// The host is sending the chosen place: Send spins and is disabled, so a
  /// second tap sends nothing.
  final bool sending;
  final ValueChanged<FlareLocationPlace>? onSend;
  final VoidCallback? onCancel;

  /// The map area's height.
  static const double mapHeight = 168;

  @override
  State<FlareLocationPicker> createState() => _FlareLocationPickerState();
}

enum _Locate { locating, located, denied }

enum _List { idle, searching, ready, noResults }

enum _Map { loading, ready, unavailable }

class _FlareLocationPickerState extends State<FlareLocationPicker> {
  _Locate _locate = _Locate.locating;
  late _List _list = widget.initialLocation == null ? _List.searching : _List.idle;
  _Map _map = _Map.loading;
  String? _mapUrl;
  FlareLocationCoordinate? _here;
  FlareLocationAddress? _hereAddress;
  List<FlareLocationPlace> _nearby = const [];
  List<FlareLocationPlace> _results = const [];
  String _selectedId = flareLocationCurrentId;
  final TextEditingController _query = TextEditingController();
  Timer? _debounce;
  Timer? _locateTimer;
  int _locateToken = 0;
  int _listToken = 0;
  int _mapToken = 0;
  Size _mapBox = const Size(360, FlareLocationPicker.mapHeight);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation;
    if (initial != null) {
      _here = FlareLocationCoordinate(
        latitude: initial.latitude,
        longitude: initial.longitude,
      );
      _hereAddress = FlareLocationAddress(
        title: initial.title,
        address: initial.address,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_here != null) {
        unawaited(_refreshMap());
        unawaited(_loadNearby());
      }
      unawaited(_locateDevice());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _locateTimer?.cancel();
    _query.dispose();
    super.dispose();
  }

  bool get _searching => _query.text.trim().isNotEmpty;

  FlareLocationPlace? _currentPlace(FlareStrings strings) {
    final here = _here;
    if (here == null) return null;
    final title = _hereAddress?.title.trim() ?? '';
    final address = _hereAddress?.address.trim() ?? '';
    return FlareLocationPlace(
      id: flareLocationCurrentId,
      latitude: here.latitude,
      longitude: here.longitude,
      title: title.isNotEmpty ? title : strings.locationCurrent,
      address: address.isNotEmpty
          ? address
          : (flareLocationCoordinateLabel(here.latitude, here.longitude) ?? ''),
    );
  }

  List<FlareLocationPlace> _rows(FlareStrings strings) {
    if (_searching) return _results;
    final current = _currentPlace(strings);
    final others = _nearby.where((place) => place.id != flareLocationCurrentId);
    return [?current, ...others];
  }

  FlareLocationPlace? _selected(FlareStrings strings) {
    for (final place in [..._rows(strings), ?_currentPlace(strings), ..._nearby, ..._results]) {
      if (place.id == _selectedId) return place;
    }
    return null;
  }

  FlareLocationPickerState get _state {
    if (_locate == _Locate.locating && _here == null) {
      return FlareLocationPickerState.locating;
    }
    if (_searching && _list == _List.searching) {
      return FlareLocationPickerState.searching;
    }
    if (_searching && _list == _List.noResults) {
      return FlareLocationPickerState.noResults;
    }
    if (_locate == _Locate.denied) return FlareLocationPickerState.denied;
    if (_map == _Map.unavailable) return FlareLocationPickerState.mapUnavailable;
    return FlareLocationPickerState.located;
  }

  Future<void> _refreshMap() async {
    final strings = FlareStrings.of(context);
    final place = _selected(strings) ?? _currentPlace(strings);
    final token = ++_mapToken;
    final preview = widget.previewUrl;
    if (place == null || preview == null) {
      setState(() {
        _map = place == null ? _Map.loading : _Map.unavailable;
        _mapUrl = null;
      });
      return;
    }
    setState(() => _map = _Map.loading);
    final size = flareLocationPreviewSize(
      _mapBox.width,
      _mapBox.height,
      MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0,
    );
    try {
      final url = await preview(
        place.latitude,
        place.longitude,
        widget.zoom,
        size.width,
        size.height,
      );
      if (!mounted || token != _mapToken) return;
      setState(() {
        _mapUrl = url;
        _map = url == null || url.isEmpty ? _Map.unavailable : _Map.ready;
      });
    } catch (_) {
      if (!mounted || token != _mapToken) return;
      setState(() {
        _mapUrl = null;
        _map = _Map.unavailable;
      });
    }
  }

  Future<void> _loadNearby() async {
    final token = ++_listToken;
    final here = _here;
    if (!_searching) {
      setState(() => _list = _nearby.isNotEmpty ? _List.ready : _List.searching);
    }
    try {
      final places = await widget.searchNearby(here?.latitude, here?.longitude, '');
      if (!mounted || token != _listToken || _searching) return;
      setState(() {
        _nearby = places;
        _list = _List.ready;
      });
    } catch (_) {
      if (!mounted || token != _listToken || _searching) return;
      setState(() {
        _nearby = const [];
        _list = _List.ready;
      });
    }
  }

  Future<void> _runSearch(String text) async {
    _debounce?.cancel();
    final value = text.trim();
    final token = ++_listToken;
    final strings = FlareStrings.of(context);
    if (value.isEmpty) {
      setState(() {
        _results = const [];
        _list = _List.ready;
        if (!_rows(strings).any((place) => place.id == _selectedId)) {
          _selectedId = flareLocationCurrentId;
        }
      });
      unawaited(_refreshMap());
      if (_nearby.isEmpty) unawaited(_loadNearby());
      return;
    }
    final centre = _selected(strings) ?? _currentPlace(strings);
    setState(() => _list = _List.searching);
    try {
      final places = await widget.searchNearby(centre?.latitude, centre?.longitude, value);
      if (!mounted || token != _listToken) return;
      setState(() {
        _results = places;
        _list = places.isEmpty ? _List.noResults : _List.ready;
      });
    } catch (_) {
      if (!mounted || token != _listToken) return;
      setState(() {
        _results = const [];
        _list = _List.noResults;
      });
    }
  }

  void _onQueryChanged(String text) {
    _debounce?.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(text));
  }

  Future<void> _describeHere() async {
    final point = _here;
    final reverse = widget.reverseGeocode;
    if (point == null || reverse == null) return;
    try {
      final address = await reverse(point.latitude, point.longitude);
      if (!mounted || _here != point) return;
      setState(() => _hereAddress = address);
    } catch (_) {
      // The row keeps the coordinate as its address.
    }
  }

  /// Nothing to centre on: the search field is the way in.
  void _deny() {
    setState(() {
      _locate = _Locate.denied;
      if (_here == null) {
        _map = _Map.unavailable;
        if (!_searching) _list = _List.ready;
      }
    });
  }

  /// Ask the device where it is. A late answer still lands while the person
  /// has not moved on.
  Future<void> _locateDevice() async {
    final token = ++_locateToken;
    setState(() => _locate = _Locate.locating);
    _locateTimer?.cancel();
    // The system prompt's wait is the host's: the timeout starts once
    // permission is there.
    final ensure = widget.ensurePermission;
    if (ensure != null) {
      bool granted;
      try {
        granted = await ensure();
      } catch (_) {
        granted = false;
      }
      if (!mounted || token != _locateToken) return;
      if (!granted) {
        _deny();
        return;
      }
    }
    final request = Future<FlareLocationCoordinate>.sync(widget.requestCurrentLocation);
    final timer = _locateTimer = Timer(Duration(milliseconds: widget.locateTimeoutMs), () {
      if (!mounted || token != _locateToken) return;
      setState(() => _locate = _here != null ? _Locate.located : _Locate.denied);
    });
    try {
      final point = await request;
      timer.cancel();
      if (!mounted || token != _locateToken) return;
      _arrive(point);
    } catch (_) {
      timer.cancel();
      if (!mounted || token != _locateToken) return;
      _deny();
    }
  }

  void _arrive(FlareLocationCoordinate point) {
    if (!isValidFlareLocation(point.latitude, point.longitude)) {
      setState(() => _locate = _here != null ? _Locate.located : _Locate.denied);
      return;
    }
    setState(() {
      _here = point;
      _hereAddress = null;
      _locate = _Locate.located;
      if (!_searching) _selectedId = flareLocationCurrentId;
    });
    unawaited(_describeHere());
    unawaited(_loadNearby());
    unawaited(_refreshMap());
  }

  void _choose(FlareLocationPlace place) {
    setState(() => _selectedId = place.id);
    unawaited(_refreshMap());
  }

  void _locateAgain() {
    _debounce?.cancel();
    _query.clear();
    setState(() => _results = const []);
    unawaited(_locateDevice());
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final rows = _rows(strings);
    final selected = _selected(strings);
    final mapPlace = selected ?? _currentPlace(strings);
    final canSend =
        selected != null &&
        isValidFlareLocation(selected.latitude, selected.longitude);
    final coordinateLine = mapPlace == null
        ? null
        : flareLocationCoordinateLabel(mapPlace.latitude, mapPlace.longitude);

    final Widget list;
    if (_list == _List.searching && rows.isEmpty) {
      list = const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingLg,
          vertical: FlareSizes.spacingSm,
        ),
        child: FlareSkeleton(variant: FlareSkeletonVariant.text),
      );
    } else if (_searching && _list == _List.noResults) {
      list = FlareEmptyState(title: strings.locationNoResults, icon: 'location');
    } else {
      list = ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: rows.length,
        itemBuilder: (context, index) => _PlaceRow(
          place: rows[index],
          selected: rows[index].id == _selectedId,
          onTap: () => _choose(rows[index]),
        ),
      );
    }

    return KeyedSubtree(
      key: ValueKey(_state),
      child: Semantics(
        container: true,
        label: strings.locationTitle,
        child: ColoredBox(
          color: colors.bgPrimary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: FlareSizes.controlHeightLg,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingMd),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            onPressed: widget.onCancel,
                            style: TextButton.styleFrom(
                              foregroundColor: colors.textSecondary,
                              minimumSize: const Size(FlareSizes.touchTargetMin, FlareSizes.touchTargetMin),
                              textStyle: const TextStyle(fontSize: FlareSizes.fontSizeXl),
                            ),
                            child: Text(strings.cancel),
                          ),
                        ),
                      ),
                      Semantics(
                        header: true,
                        child: Text(
                          strings.locationTitle,
                          style: TextStyle(
                            fontSize: FlareSizes.fontSize2xl,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: FlareLocationPicker.mapHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _mapBox = Size(
                      constraints.maxWidth.isFinite ? constraints.maxWidth : 360,
                      FlareLocationPicker.mapHeight,
                    );
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Semantics(
                          image: true,
                          label: [strings.locationTitle, ?mapPlace?.title].join(' · '),
                          child: FlareLocationMapSurface(
                            src: _map == _Map.unavailable ? null : _mapUrl,
                            attribution:
                                widget.provider == FlareLocationProvider.osm
                                ? strings.locationOsmAttribution
                                : null,
                            onError: () {
                              if (mounted) setState(() => _map = _Map.unavailable);
                            },
                          ),
                        ),
                        if (_map == _Map.unavailable && mapPlace != null)
                          PositionedDirectional(
                            start: FlareSizes.spacingMd,
                            bottom: FlareSizes.spacingMd,
                            end: 72,
                            child: Align(
                              alignment: AlignmentDirectional.bottomStart,
                              child: DecoratedBox(
                                key: const ValueKey('flare-location-map-unavailable'),
                                decoration: BoxDecoration(
                                  color: colors.bgElevated,
                                  borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: FlareSizes.spacingSm,
                                    vertical: FlareSizes.spacingXs,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        strings.locationMapUnavailable,
                                        style: TextStyle(
                                          fontSize: FlareSizes.fontSizeSm,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                      if (coordinateLine != null)
                                        Text(
                                          coordinateLine,
                                          style: TextStyle(
                                            fontSize: FlareSizes.fontSizeSm,
                                            color: colors.textTertiary,
                                            fontFeatures: const [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        PositionedDirectional(
                          end: FlareSizes.spacingMd,
                          bottom: FlareSizes.spacingMd,
                          child: FlareIconButton(
                            icon: 'locate',
                            semanticLabel: strings.locationLocateMe,
                            backgroundColor: colors.bgElevated,
                            disabled: _locate == _Locate.locating,
                            onPressed: _locateAgain,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FlareSizes.spacingMd,
                  FlareSizes.spacingSm,
                  FlareSizes.spacingMd,
                  FlareSizes.spacingXs,
                ),
                child: FlareSearchBar(
                  controller: _query,
                  placeholder: strings.locationSearchPlaceholder,
                  loading: _searching && _list == _List.searching,
                  onChanged: _onQueryChanged,
                  onSubmitted: _runSearch,
                ),
              ),
              if (_locate == _Locate.denied)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FlareSizes.spacingMd,
                    0,
                    FlareSizes.spacingMd,
                    FlareSizes.spacingXs,
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      strings.locationDenied,
                      style: TextStyle(
                        fontSize: FlareSizes.fontSizeMd,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              if (_locate == _Locate.locating && _here == null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FlareSizes.spacingLg,
                    vertical: FlareSizes.spacingSm,
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      children: [
                        FlareIcon('locate', size: FlareSizes.iconSizeSm, color: colors.textSecondary),
                        const SizedBox(width: FlareSizes.spacingXs),
                        Text(
                          strings.locationLocating,
                          style: TextStyle(
                            fontSize: FlareSizes.fontSizeMd,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(child: list),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.borderSecondary)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FlareSizes.spacingMd,
                      vertical: FlareSizes.spacingSm,
                    ),
                    child: FlareButton(
                      key: const ValueKey('flare-location-send'),
                      label: strings.locationSend,
                      block: true,
                      loading: widget.sending,
                      disabled: !canSend || widget.sending,
                      onPressed: canSend && !widget.sending
                          ? () => widget.onSend?.call(selected)
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final FlareLocationPlace place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final current = place.id == flareLocationCurrentId;
    final distance = flareLocationDistanceLabel(place.distanceM);
    return Semantics(
      key: ValueKey('flare-location-place-${place.id}'),
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: FlareSizes.spacingLg,
            vertical: FlareSizes.spacingSm,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.borderSecondary)),
          ),
          child: Row(
            children: [
              FlareIcon(
                current ? 'locate' : 'location',
                size: FlareSizes.iconSizeSm,
                color: current ? colors.primaryText : colors.textTertiary,
              ),
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      place.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: FlareSizes.fontSizeXl,
                        fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                        color: selected ? colors.primaryText : colors.textPrimary,
                      ),
                    ),
                    if (place.address.isNotEmpty)
                      Text(
                        place.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: FlareSizes.fontSizeSm,
                          color: colors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              if (distance != null) ...[
                const SizedBox(width: FlareSizes.spacingSm),
                Text(
                  distance,
                  style: TextStyle(
                    fontSize: FlareSizes.fontSizeSm,
                    color: colors.textTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              const SizedBox(width: FlareSizes.spacingSm),
              SizedBox(
                width: FlareSizes.iconSizeSm,
                child: selected
                    ? FlareIcon('check', size: FlareSizes.iconSizeSm, color: colors.primaryText)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
