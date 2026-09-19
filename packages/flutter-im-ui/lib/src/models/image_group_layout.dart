/// How an image-group (album) body lays out its images: square tiles in
/// [columns] columns, [visible] of them drawn, and the last drawn tile reading
/// `+more` when there are more images than tiles. The rule is shared with the
/// other three kits (`spec/image-group-layout-vectors.json`).
library;

/// At most this many tiles are drawn.
const int flareImageGroupMaxVisible = 9;

class FlareImageGroupLayout {
  const FlareImageGroupLayout({
    required this.columns,
    required this.visible,
    required this.more,
  });

  final int columns;
  final int visible;
  final int more;

  /// Whether the tile at [index] is the covered last one.
  bool covers(int index) => more > 0 && index == visible - 1;

  @override
  bool operator ==(Object other) =>
      other is FlareImageGroupLayout &&
      other.columns == columns &&
      other.visible == visible &&
      other.more == more;

  @override
  int get hashCode => Object.hash(columns, visible, more);

  @override
  String toString() => 'FlareImageGroupLayout($columns, $visible, +$more)';
}

FlareImageGroupLayout flareImageGroupLayout(int count) {
  if (count <= 0) {
    return const FlareImageGroupLayout(columns: 0, visible: 0, more: 0);
  }
  return FlareImageGroupLayout(
    columns: count == 4 ? 2 : (count < 3 ? count : 3),
    visible: count < flareImageGroupMaxVisible
        ? count
        : flareImageGroupMaxVisible,
    more: count > flareImageGroupMaxVisible
        ? count - flareImageGroupMaxVisible + 1
        : 0,
  );
}
