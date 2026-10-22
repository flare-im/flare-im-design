import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Location presentation contracts (spec LocationMessage / LocationPicker).
///
/// Coordinates are WGS-84 as the message stores them. Geocoding, nearby
/// search and the static map belong to the host (the Social geo proxy), which
/// [FlareLocationPicker] reaches through its callbacks. The link, coordinate
/// and distance rules are the shared table in `spec/location-vectors.json`,
/// read by all four kits' tests.

/// The map service a tenant configured; it decides which web map a card
/// opens.
enum FlareLocationProvider { osm, amap }

@immutable
class FlareLocationCoordinate {
  const FlareLocationCoordinate({
    required this.latitude,
    required this.longitude,
  });
  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is FlareLocationCoordinate &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// What a reverse geocode answers for a coordinate.
@immutable
class FlareLocationAddress {
  const FlareLocationAddress({required this.title, required this.address});
  final String title;
  final String address;
}

/// A place the picker lists and sends: a nearby POI, a search result or the
/// current location ([flareLocationCurrentId]).
@immutable
class FlareLocationPlace {
  const FlareLocationPlace({
    required this.id,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distanceM,
  });
  final String id;
  final String title;
  final String address;
  final double latitude;
  final double longitude;

  /// Distance from the centre the search was made around, in metres, when
  /// the host knows it.
  final double? distanceM;

  @override
  bool operator ==(Object other) =>
      other is FlareLocationPlace &&
      other.id == id &&
      other.title == title &&
      other.address == address &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.distanceM == distanceM;

  @override
  int get hashCode =>
      Object.hash(id, title, address, latitude, longitude, distanceM);

  @override
  String toString() =>
      'FlareLocationPlace($id, $title, $latitude, $longitude)';
}

/// The id of the picker's first row: the coordinate the device reported.
const String flareLocationCurrentId = 'current';

/// Zoom of the web map a card opens on OpenStreetMap.
const int flareLocationOsmZoom = 17;

/// The three default places a card can open: by provider on the web, Apple
/// Maps, and a `geo:` URI.
@immutable
class FlareLocationMapLinks {
  const FlareLocationMapLinks({
    required this.web,
    required this.apple,
    required this.geo,
  });
  final String web;
  final String apple;
  final String geo;

  /// The link this platform opens: Apple Maps on iOS and macOS, the `geo:`
  /// URI on Android, the provider's web map elsewhere and on the web
  /// (`flutterTargets` in the vectors).
  String forPlatform(TargetPlatform platform, {bool isWeb = kIsWeb}) {
    if (isWeb) return web;
    return switch (platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => apple,
      TargetPlatform.android => geo,
      _ => web,
    };
  }
}

/// Whether a coordinate can be drawn and opened: finite, latitude -90..90,
/// longitude -180..180.
bool isValidFlareLocation(double latitude, double longitude) =>
    latitude.isFinite &&
    longitude.isFinite &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;

/// One coordinate in a link: 6 decimals, trailing zeros and a trailing point
/// dropped, never "-0".
String formatFlareLocationCoordinate(double value) {
  var text = value.toStringAsFixed(6);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return text == '-0' ? '0' : text;
}

/// UTF-8 percent-encoding that keeps only A-Z a-z 0-9 - . _ ~, with capital
/// hex digits.
String encodeFlareLocationTitle(String title) {
  final out = StringBuffer();
  for (final byte in utf8.encode(title)) {
    final unreserved =
        (byte >= 0x30 && byte <= 0x39) ||
        (byte >= 0x41 && byte <= 0x5A) ||
        (byte >= 0x61 && byte <= 0x7A) ||
        byte == 0x2D ||
        byte == 0x2E ||
        byte == 0x5F ||
        byte == 0x7E;
    if (unreserved) {
      out.writeCharCode(byte);
    } else {
      out
        ..write('%')
        ..write(byte.toRadixString(16).toUpperCase().padLeft(2, '0'));
    }
  }
  return out.toString();
}

/// The default places a card opens when the host takes no open: `web` by
/// [provider], `apple` and `geo`. Null for a coordinate that is not valid.
FlareLocationMapLinks? flareLocationMapLinks({
  required double latitude,
  required double longitude,
  String? title,
  FlareLocationProvider provider = FlareLocationProvider.osm,
}) {
  if (!isValidFlareLocation(latitude, longitude)) return null;
  final lat = formatFlareLocationCoordinate(latitude);
  final lng = formatFlareLocationCoordinate(longitude);
  final trimmed = (title ?? '').trim();
  final name = trimmed.isEmpty ? '' : encodeFlareLocationTitle(trimmed);
  final web = provider == FlareLocationProvider.amap
      ? 'https://uri.amap.com/marker?position=$lng,$lat'
            '${name.isEmpty ? '' : '&name=$name'}&coordinate=wgs84&callnative=0'
      : 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng'
            '#map=$flareLocationOsmZoom/$lat/$lng';
  return FlareLocationMapLinks(
    web: web,
    apple: 'http://maps.apple.com/?ll=$lat,$lng&q=${name.isEmpty ? '$lat,$lng' : name}',
    geo: 'geo:$lat,$lng?q=$lat,$lng${name.isEmpty ? '' : '($name)'}',
  );
}

String _fixed5(double value) {
  final text = value.toStringAsFixed(5);
  return text == '-0.00000' ? '0.00000' : text;
}

/// The coordinate line shown where there is no map: "39.90870, 116.39750";
/// null when not valid.
String? flareLocationCoordinateLabel(double latitude, double longitude) =>
    isValidFlareLocation(latitude, longitude)
    ? '${_fixed5(latitude)}, ${_fixed5(longitude)}'
    : null;

/// The size LocationPicker asks `previewUrl` for, in device pixels: the map
/// area's logical [width] and [height] times the screen [scale] clamped to
/// 1..2, each rounded (spec/location-vectors.json `previewSize`; the same on
/// all four platforms).
({int width, int height}) flareLocationPreviewSize(
  double width,
  double height,
  double scale,
) {
  final factor = scale.isFinite ? scale.clamp(1.0, 2.0).toDouble() : 1.0;
  return (width: (width * factor).round(), height: (height * factor).round());
}

/// A POI row's distance: "120m" below a kilometre, else "1.2km"; null when
/// missing, negative or not finite.
String? flareLocationDistanceLabel(double? distanceM) {
  if (distanceM == null || !distanceM.isFinite || distanceM < 0) return null;
  final metres = distanceM.round();
  return metres < 1000
      ? '${metres}m'
      : '${(distanceM / 1000).toStringAsFixed(1)}km';
}
