import 'dart:async';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/components/flare_location_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _here = FlareLocationCoordinate(latitude: 39.9087, longitude: 116.3975);
const _cafe = FlareLocationPlace(
  id: 'p1',
  title: 'Mellow Brew',
  address: '前门大街 1 号',
  latitude: 39.9001,
  longitude: 116.398,
  distanceM: 240,
);
const _museum = FlareLocationPlace(
  id: 'p2',
  title: '国家博物馆',
  address: '东长安街 16 号',
  latitude: 39.9051,
  longitude: 116.4013,
  distanceM: 1240,
);

/// A 1x1 PNG: a picture the test binding can decode (it answers every HTTP
/// request with 400, so a network URL would turn the map unavailable).
const _png =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

class _Harness {
  final sends = <FlareLocationPlace>[];
  var cancels = 0;
  final previews = <String>[];
  final searches = <(double?, double?, String)>[];

  Widget build({
    required FlareRequestCurrentLocation locate,
    Future<bool> Function()? ensurePermission,
    FlareSearchNearby? search,
    FlareLocationPreviewUrl? preview,
    bool noPreview = false,
    FlareLocationPlace? initial,
    int timeoutMs = 5000,
    bool sending = false,
  }) => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 720,
        child: FlareLocationPicker(
          requestCurrentLocation: locate,
          ensurePermission: ensurePermission,
          sending: sending,
          searchNearby:
              search ??
              (lat, lng, query) async {
                searches.add((lat, lng, query));
                return query.isEmpty ? const [_cafe, _museum] : const [];
              },
          reverseGeocode: (lat, lng) async =>
              const FlareLocationAddress(title: '天安门广场', address: '北京市东城区'),
          previewUrl: noPreview
              ? null
              : preview ??
                    (lat, lng, zoom, w, h) async {
                      previews.add('https://geo.example/map?c=$lat,$lng&z=$zoom');
                      return _png;
                    },
          initialLocation: initial,
          locateTimeoutMs: timeoutMs,
          onSend: sends.add,
          onCancel: () => cancels += 1,
        ),
      ),
    ),
  );
}

Finder _row(String id) => find.byKey(ValueKey('flare-location-place-$id'));
Finder _state(FlareLocationPickerState state) => find.byKey(ValueKey(state));

Future<void> _send(WidgetTester tester) async {
  await tester.tap(find.text('发送'));
  await tester.pump();
}

void main() {
  testWidgets('paints skeleton rows while locating, then the current location first', (tester) async {
    final fix = Completer<FlareLocationCoordinate>();
    final harness = _Harness();
    await tester.pumpWidget(harness.build(locate: () => fix.future));
    expect(_state(FlareLocationPickerState.locating), findsOneWidget);
    expect(find.text('正在定位…'), findsOneWidget);
    expect(find.byType(FlareSkeleton), findsOneWidget);
    fix.complete(_here);
    await tester.pumpAndSettle();
    expect(_state(FlareLocationPickerState.located), findsOneWidget);
    expect(_row('current'), findsOneWidget);
    expect(find.descendant(of: _row('current'), matching: find.text('天安门广场')), findsOneWidget);
    expect(tester.getSemantics(_row('current')), isSemantics(isChecked: true));
    expect(find.text('240m'), findsOneWidget);
    expect(find.text('1.2km'), findsOneWidget);
    expect(harness.previews.last, 'https://geo.example/map?c=39.9087,116.3975&z=16');
  });

  testWidgets('shows the remembered place before the device answers', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(
      harness.build(
        locate: () => Completer<FlareLocationCoordinate>().future,
        initial: const FlareLocationPlace(
          id: 'last',
          title: '上次的位置',
          address: '朝阳区',
          latitude: 39.99,
          longitude: 116.48,
        ),
      ),
    );
    expect(find.text('上次的位置'), findsOneWidget);
    await tester.pump();
    await tester.pump();
    expect(harness.previews.last, contains('c=39.99,116.48'));
  });

  testWidgets("credits OpenStreetMap on the map preview, and not AMap's", (tester) async {
    for (final provider in FlareLocationProvider.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 720,
              child: FlareLocationPicker(
                key: ValueKey(provider),
                requestCurrentLocation: () async => _here,
                searchNearby: (lat, lng, query) async => const [_cafe],
                previewUrl: (lat, lng, zoom, w, h) async => _png,
                provider: provider,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
      expect(
        find.byKey(FlareLocationMapSurface.attributionKey),
        provider == FlareLocationProvider.osm ? findsOneWidget : findsNothing,
        reason: provider.name,
      );
    }
  });

  testWidgets('selecting a place moves the map, and send returns that place', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build(locate: () async => _here));
    await tester.pumpAndSettle();
    await tester.tap(_row('p2'));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(_row('p2')), isSemantics(isChecked: true));
    expect(harness.previews.last, contains('c=39.9051,116.4013'));
    await _send(tester);
    expect(harness.sends, [_museum]);
  });

  testWidgets('sends the current location with its reverse-geocoded name', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build(locate: () async => _here));
    await tester.pumpAndSettle();
    await _send(tester);
    expect(harness.sends, const [
      FlareLocationPlace(
        id: 'current',
        title: '天安门广场',
        address: '北京市东城区',
        latitude: 39.9087,
        longitude: 116.3975,
      ),
    ]);
  });

  testWidgets('turns to manual search when the device refuses', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(
      harness.build(
        locate: () async => throw StateError('denied'),
        search: (lat, lng, query) async {
          harness.searches.add((lat, lng, query));
          return query == '咖啡' ? const [_cafe] : const [];
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(_state(FlareLocationPickerState.denied), findsOneWidget);
    expect(find.text('无法获取定位，可以搜索地点'), findsOneWidget);
    await _send(tester);
    expect(harness.sends, isEmpty);
    await tester.enterText(find.byType(TextField), '咖啡');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(harness.searches.last, (null, null, '咖啡'));
    await tester.tap(_row('p1'));
    await tester.pump();
    await _send(tester);
    expect(harness.sends, [_cafe]);
  });

  testWidgets('says when a search finds nothing', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build(locate: () async => _here));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '不存在的地方');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(_state(FlareLocationPickerState.noResults), findsOneWidget);
    expect(find.text('附近没有找到地点'), findsOneWidget);
  });

  testWidgets('shows the coordinate when the map is unavailable, and still sends', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(
      harness.build(locate: () async => _here, preview: (lat, lng, z, w, h) async => null),
    );
    await tester.pumpAndSettle();
    expect(_state(FlareLocationPickerState.mapUnavailable), findsOneWidget);
    expect(find.text('地图暂不可用'), findsOneWidget);
    expect(find.text('39.90870, 116.39750'), findsOneWidget);
    await _send(tester);
    expect(harness.sends, hasLength(1));
  });

  testWidgets('a map picture that fails to load turns the map unavailable', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(
      harness.build(
        locate: () async => _here,
        preview: (lat, lng, z, w, h) async => 'https://geo.example/broken.png',
      ),
    );
    await tester.pumpAndSettle();
    expect(_state(FlareLocationPickerState.mapUnavailable), findsOneWidget);
    expect(find.text('地图暂不可用'), findsOneWidget);
  });

  testWidgets('falls back to the remembered place on timeout, and takes a late fix', (tester) async {
    final fix = Completer<FlareLocationCoordinate>();
    final harness = _Harness();
    await tester.pumpWidget(
      harness.build(
        locate: () => fix.future,
        initial: const FlareLocationPlace(
          id: 'last',
          title: '上次的位置',
          address: '朝阳区',
          latitude: 39.99,
          longitude: 116.48,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 5000));
    expect(_state(FlareLocationPickerState.located), findsOneWidget);
    expect(find.text('上次的位置'), findsOneWidget);
    fix.complete(_here);
    await tester.pumpAndSettle();
    expect(find.descendant(of: _row('current'), matching: find.text('天安门广场')), findsOneWidget);
  });

  testWidgets('does not count the permission prompt into the locate timeout', (tester) async {
    final permission = Completer<bool>();
    final fix = Completer<FlareLocationCoordinate>();
    var requests = 0;
    final harness = _Harness();
    await tester.pumpWidget(
      harness.build(
        ensurePermission: () => permission.future,
        locate: () {
          requests += 1;
          return fix.future;
        },
      ),
    );
    await tester.pump();
    // The person reads the system prompt for longer than the timeout.
    await tester.pump(const Duration(milliseconds: 8000));
    expect(_state(FlareLocationPickerState.locating), findsOneWidget);
    expect(requests, 0);
    permission.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4000));
    expect(requests, 1);
    expect(_state(FlareLocationPickerState.locating), findsOneWidget);
    // The clock started when permission came: 5 s after that it gives up.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(_state(FlareLocationPickerState.denied), findsOneWidget);
    fix.complete(_here);
    await tester.pumpAndSettle();
    expect(find.descendant(of: _row('current'), matching: find.text('天安门广场')), findsOneWidget);
  });

  testWidgets('goes straight to denied when the permission step says no', (tester) async {
    var requests = 0;
    for (final ensure in <Future<bool> Function()>[
      () async => false,
      () async => throw StateError('no'),
    ]) {
      final harness = _Harness();
      await tester.pumpWidget(
        harness.build(
          ensurePermission: ensure,
          locate: () async {
            requests += 1;
            return _here;
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(_state(FlareLocationPickerState.denied), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    expect(requests, 0);
  });

  testWidgets('locks Send while the host is sending', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build(locate: () async => _here, sending: true));
    // The spinner never settles: pump the locate through instead.
    for (var i = 0; i < 5; i += 1) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final send = tester.widget<FlareButton>(find.byKey(const ValueKey('flare-location-send')));
    expect(send.loading, isTrue);
    expect(send.disabled, isTrue);
    await tester.tap(find.byKey(const ValueKey('flare-location-send')));
    await tester.pump();
    expect(harness.sends, isEmpty);
  });

  testWidgets('asks previewUrl for device pixels, at most twice the logical size', (tester) async {
    for (final (ratio, expected) in [(1.0, (400, 168)), (3.0, (800, 336))]) {
      tester.view.physicalSize = Size(400 * ratio, 800 * ratio);
      tester.view.devicePixelRatio = ratio;
      final sizes = <(int, int)>[];
      final harness = _Harness();
      await tester.pumpWidget(
        harness.build(
          locate: () async => _here,
          preview: (lat, lng, zoom, w, h) async {
            sizes.add((w, h));
            return _png;
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(sizes.last, expected, reason: 'ratio $ratio');
      await tester.pumpWidget(const SizedBox.shrink());
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('declares its own header to a fill sheet, which draws no second title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareBottomSheet(
            title: '发送位置',
            fill: true,
            presentation: FlareSheetPresentation.sheet,
            maxHeight: 600,
            child: FlareLocationPicker(
              requestCurrentLocation: () async => _here,
              searchNearby: (lat, lng, query) async => const [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('发送位置'), findsNothing);
    expect(find.bySemanticsLabel('发送位置'), findsOneWidget);
    expect(tester.getSize(find.byType(FlareLocationPicker)).height, greaterThan(500));
  });

  testWidgets('locates again from the map key, and cancels', (tester) async {
    var requests = 0;
    final harness = _Harness();
    await tester.pumpWidget(
      harness.build(
        locate: () async {
          requests += 1;
          return _here;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('定位到当前位置'));
    await tester.pumpAndSettle();
    expect(requests, 2);
    await tester.tap(find.text('取消'));
    expect(harness.cancels, 1);
  });
}
