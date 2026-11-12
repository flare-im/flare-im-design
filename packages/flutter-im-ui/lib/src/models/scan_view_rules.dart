import 'scan_hit_gate.dart';

class FlareScanMarkerBounds {
  const FlareScanMarkerBounds(this.left, this.top, this.width, this.height);
  final double left, top, width, height;
}

/// Decoder coordinates are normalized to the preview before reaching the kit.
FlareScanMarkerBounds flareScanMarkerBounds(Iterable<FlareScanPoint> corners) {
  final points = corners.where((point) => point.x.isFinite && point.y.isFinite).toList();
  if (points.isEmpty) return const FlareScanMarkerBounds(0, 0, 1, 1);
  final left = points.map((point) => point.x).reduce((a, b) => a < b ? a : b).clamp(0.0, 1.0).toDouble();
  final top = points.map((point) => point.y).reduce((a, b) => a < b ? a : b).clamp(0.0, 1.0).toDouble();
  final right = points.map((point) => point.x).reduce((a, b) => a > b ? a : b).clamp(left, 1.0).toDouble();
  final bottom = points.map((point) => point.y).reduce((a, b) => a > b ? a : b).clamp(top, 1.0).toDouble();
  return FlareScanMarkerBounds(left, top, right - left, bottom - top);
}

bool flarePluginMayRefresh({required bool visible, required bool foreground, required bool loading, required bool refreshing, required bool busy, required bool interaction}) =>
  visible && foreground && !loading && !refreshing && !busy && !interaction;
