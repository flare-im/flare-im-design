import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/components/flare_location_map.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared location table (`spec/location-vectors.json`): the default map
/// links, the coordinate line and the distance label, the same rows the Vue,
/// SwiftUI and Compose kits read.
final Map<String, dynamic> _vectors =
    jsonDecode(File('../../spec/location-vectors.json').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> _rows(String key) =>
    (_vectors[key] as List).cast<Map<String, dynamic>>();

FlareLocationProvider _provider(Object? value) =>
    value == 'amap' ? FlareLocationProvider.amap : FlareLocationProvider.osm;

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('spec/location-vectors.json', () {
    for (final row in _rows('links')) {
      test('links: ${row['id']}', () {
        final input = row['input'] as Map<String, dynamic>;
        final links = flareLocationMapLinks(
          latitude: (input['latitude'] as num).toDouble(),
          longitude: (input['longitude'] as num).toDouble(),
          title: input['title'] as String?,
          provider: _provider(input['provider']),
        );
        expect(links?.web, row['web']);
        expect(links?.apple, row['apple']);
        expect(links?.geo, row['geo']);
      });
    }

    for (final row in _rows('label')) {
      test('label: ${row['id']}', () {
        final input = row['input'] as Map<String, dynamic>;
        expect(
          flareLocationCoordinateLabel(
            (input['latitude'] as num).toDouble(),
            (input['longitude'] as num).toDouble(),
          ),
          row['output'],
        );
      });
    }

    for (final row in _rows('distance')) {
      test('distance: ${row['id']}', () {
        expect(
          flareLocationDistanceLabel((row['input'] as num?)?.toDouble()),
          row['output'],
        );
      });
    }

    for (final row in _rows('previewSize')) {
      test('previewSize: ${row['id']}', () {
        final input = row['input'] as Map<String, dynamic>;
        final output = row['output'] as Map<String, dynamic>;
        final size = flareLocationPreviewSize(
          (input['width'] as num).toDouble(),
          (input['height'] as num).toDouble(),
          (input['scale'] as num).toDouble(),
        );
        expect(size.width, output['width']);
        expect(size.height, output['height']);
      });
    }

    test('each Flutter target opens the column the table names', () {
      final links = flareLocationMapLinks(latitude: 39.9087, longitude: 116.3975, title: '天安门广场')!;
      final targets = (_vectors['flutterTargets'] as Map<String, dynamic>).cast<String, String>();
      String column(String name) => switch (name) {
        'apple' => links.apple,
        'geo' => links.geo,
        _ => links.web,
      };
      for (final platform in TargetPlatform.values) {
        expect(
          links.forPlatform(platform, isWeb: false),
          column(targets[platform.name]!),
          reason: platform.name,
        );
      }
      expect(links.forPlatform(TargetPlatform.android, isWeb: true), column(targets['web']!));
    });

    test('a coordinate JSON cannot carry opens nothing', () {
      expect(flareLocationMapLinks(latitude: double.nan, longitude: 10), isNull);
      expect(flareLocationMapLinks(latitude: 10, longitude: double.infinity), isNull);
      expect(flareLocationDistanceLabel(double.nan), isNull);
    });
  });

  group('FlareLocationMessage', () {
    testWidgets('draws the map texture and the coordinate line without a picture', (tester) async {
      await tester.pumpWidget(
        _host(const FlareLocationMessage(title: 'HQ', latitude: 39.9087, longitude: 116.3975)),
      );
      expect(find.byKey(FlareLocationMapSurface.placeholderKey), findsOneWidget);
      expect(find.text('HQ'), findsOneWidget);
      expect(find.text('39.90870, 116.39750'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('draws the static map when there is one', (tester) async {
      await tester.pumpWidget(
        _host(
          const FlareLocationMessage(
            title: 'HQ',
            address: 'Beijing',
            latitude: 39.9087,
            longitude: 116.3975,
            snapshotUrl: 'https://geo.example/map.png',
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as NetworkImage).url, 'https://geo.example/map.png');
      expect(find.text('Beijing'), findsOneWidget);
    });

    testWidgets("credits OpenStreetMap on its static map, and not AMap's", (tester) async {
      // A 1x1 PNG the test binding can decode (it answers HTTP with 400).
      const png =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
      Future<void> pumpCard(FlareLocationProvider provider, {String? snapshot = png}) async {
        await tester.pumpWidget(
          _host(
            FlareLocationMessage(
              title: 'HQ',
              latitude: 39.9087,
              longitude: 116.3975,
              snapshotUrl: snapshot,
              provider: provider,
            ),
          ),
        );
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
      }

      await pumpCard(FlareLocationProvider.osm);
      expect(find.byKey(FlareLocationMapSurface.attributionKey), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      await pumpCard(FlareLocationProvider.amap);
      expect(find.byKey(FlareLocationMapSurface.attributionKey), findsNothing);
      // The drawn texture is not OpenStreetMap data: no credit on it.
      await pumpCard(FlareLocationProvider.osm, snapshot: null);
      expect(find.byKey(FlareLocationMapSurface.attributionKey), findsNothing);
    });

    testWidgets('is a control only with onOpen', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        _host(
          FlareLocationMessage(
            title: 'HQ',
            address: 'Beijing',
            latitude: 39.9087,
            longitude: 116.3975,
            onOpen: () => opened += 1,
          ),
        ),
      );
      await tester.tap(find.text('HQ'));
      expect(opened, 1);
    });
  });

  group('FlareMessageContentView location and card', () {
    testWidgets('a location goes to onLocationOpen first', (tester) async {
      FlareLocationContent? opened;
      final links = <String>[];
      await tester.pumpWidget(
        _host(
          FlareMessageContentView(
            content: const FlareLocationContent(name: 'HQ', latitude: 39.9087, longitude: 116.3975),
            onLocationOpen: (location) => opened = location,
            onOpenLink: links.add,
          ),
        ),
      );
      await tester.tap(find.text('HQ'));
      expect(opened?.name, 'HQ');
      expect(links, isEmpty);
    });

    testWidgets('without onLocationOpen the platform map link goes to onOpenLink', (tester) async {
      final links = <String>[];
      Future<void> tapOn(TargetPlatform platform, FlareLocationProvider provider) async {
        debugDefaultTargetPlatformOverride = platform;
        await tester.pumpWidget(
          _host(
            FlareMessageContentView(
              content: FlareLocationContent(
                name: '天安门广场',
                latitude: 39.9087,
                longitude: 116.3975,
                provider: provider,
              ),
              onOpenLink: links.add,
            ),
          ),
        );
        await tester.tap(find.text('天安门广场'));
      }

      await tapOn(TargetPlatform.android, FlareLocationProvider.osm);
      await tapOn(TargetPlatform.iOS, FlareLocationProvider.osm);
      await tapOn(TargetPlatform.windows, FlareLocationProvider.amap);
      debugDefaultTargetPlatformOverride = null;
      final row = _rows('links').firstWhere((row) => row['id'] == 'osm-titled');
      expect(links[0], row['geo']);
      expect(links[1], row['apple']);
      expect(links[2], startsWith('https://uri.amap.com/marker?position=116.3975,39.9087&name='));
    });

    testWidgets('a 0,0 wire coordinate opens nothing', (tester) async {
      final links = <String>[];
      await tester.pumpWidget(
        _host(
          FlareMessageContentView(
            content: const FlareLocationContent(name: 'Somewhere', latitude: 0, longitude: 0),
            onOpenLink: links.add,
          ),
        ),
      );
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets("a person's card reports its user id", (tester) async {
      final ids = <String>[];
      await tester.pumpWidget(
        _host(
          FlareMessageContentView(
            content: const FlareCardContent(title: 'Ivy Chen', userId: 'u2'),
            onCardOpen: ids.add,
          ),
        ),
      );
      await tester.tap(find.text('Ivy Chen'));
      expect(ids, ['u2']);
      await tester.pumpWidget(
        _host(
          FlareMessageContentView(
            content: const FlareCardContent(title: 'Design team'),
            onCardOpen: ids.add,
          ),
        ),
      );
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('the list hands card and location taps over with the message', (tester) async {
      final events = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareMessageList(
              currentUserId: 'me',
              messages: const [
                FlareMessageData(
                  id: 'm1',
                  senderId: 'u9',
                  senderName: 'Zhou',
                  content: FlareCardContent(title: 'Ivy Chen', userId: 'u2'),
                ),
                FlareMessageData(
                  id: 'm2',
                  senderId: 'u9',
                  senderName: 'Zhou',
                  content: FlareLocationContent(name: 'HQ', latitude: 39.9087, longitude: 116.3975),
                ),
              ],
              onCardOpen: (message, userId) => events.add('${message.id}:$userId'),
              onLocationOpen: (message, location) => events.add('${message.id}:${location.name}'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ivy Chen'));
      await tester.tap(find.text('HQ'));
      expect(events, ['m1:u2', 'm2:HQ']);
    });
  });

  group('FlareContactMessage', () {
    testWidgets('reports the user id with onOpen, and displays without it', (tester) async {
      final ids = <String>[];
      await tester.pumpWidget(
        _host(FlareContactMessage(name: 'Ivy Chen', userId: 'u2', onOpen: ids.add)),
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(find.text('Ivy Chen'));
      expect(ids, ['u2']);
      await tester.pumpWidget(_host(const FlareContactMessage(name: 'Ivy Chen', userId: 'u2')));
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });
}
