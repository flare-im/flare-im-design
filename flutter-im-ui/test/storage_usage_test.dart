import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/src/components/flare_storage_usage.dart';

void main() {
  const kb = 1024;
  const mb = 1024 * 1024;
  const gb = 1024 * 1024 * 1024;
  const tb = 1024 * 1024 * 1024 * 1024;

  FlareStorageCategory category({
    String id = 'images',
    String label = '图片',
    num? bytes = 12 * mb,
    int? fileCount,
    bool clearable = true,
    bool busy = false,
    String? error,
  }) =>
      FlareStorageCategory(
        id: id,
        label: label,
        bytes: bytes,
        fileCount: fileCount,
        clearable: clearable,
        busy: busy,
        error: error,
      );

  group('formatBytes', () {
    test('prints whole bytes below 1 KB, zero included', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(1), '1 B');
      expect(formatBytes(1023), '1023 B');
    });

    test('steps by 1024 through KB, MB, GB and TB with one decimal', () {
      expect(formatBytes(kb), '1.0 KB');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(2 * kb), '2.0 KB');
      expect(formatBytes(mb), '1.0 MB');
      expect(formatBytes(gb), '1.0 GB');
      expect(formatBytes(1.5 * gb), '1.5 GB');
      expect(formatBytes(tb), '1.0 TB');
    });

    test('never goes above TB', () {
      expect(formatBytes(2048.0 * tb), '2048.0 TB');
    });

    test('returns null — not 0 B — for every size it does not know', () {
      expect(formatBytes(null), isNull);
      expect(formatBytes(double.nan), isNull);
      expect(formatBytes(double.infinity), isNull);
      expect(formatBytes(double.negativeInfinity), isNull);
      expect(formatBytes(-1), isNull);
      expect(formatBytes(-1.0 * gb), isNull);
    });

    test('reads the same in every locale', () {
      expect(formatBytes(1536, 'de-DE'), formatBytes(1536));
      expect(formatBytes(1536, 'zh-CN'), '1.5 KB');
    });
  });

  group('storageTotals', () {
    test('sums the known categories and reports nothing missing', () {
      final totals = storageTotals([
        category(bytes: mb),
        category(id: 'files', bytes: 2 * mb),
      ]);
      expect(totals.knownBytes, 3.0 * mb);
      expect(totals.hasUnknown, isFalse);
      expect(totals.total, 3.0 * mb);
    });

    test('flags hasUnknown and leaves unmeasured categories out of the sum', () {
      final totals = storageTotals([
        category(bytes: mb),
        category(id: 'video', bytes: null),
        category(id: 'broken', bytes: double.nan),
        category(id: 'negative', bytes: -5),
      ]);
      expect(totals.knownBytes, 1.0 * mb);
      expect(totals.hasUnknown, isTrue);
      expect(totals.total, 1.0 * mb);
    });

    test('prefers a usable host total over its own sum', () {
      final rows = [category(bytes: mb)];
      expect(storageTotals(rows, 9 * mb).total, 9.0 * mb);
      expect(storageTotals(rows, 9 * mb).knownBytes, 1.0 * mb);
      expect(storageTotals(rows, 0).total, 0);
    });

    test('falls back to its own sum when the host total is unusable', () {
      final rows = [category(bytes: mb)];
      expect(storageTotals(rows, null).total, 1.0 * mb);
      expect(storageTotals(rows, double.nan).total, 1.0 * mb);
      expect(storageTotals(rows, -1).total, 1.0 * mb);
    });

    test('treats an empty list as zero, with nothing unknown', () {
      final totals = storageTotals(const []);
      expect(totals.knownBytes, 0);
      expect(totals.hasUnknown, isFalse);
      expect(totals.total, 0);
    });
  });

  group('storageShare', () {
    test('is the plain ratio when both sides are known', () {
      expect(storageShare(mb, 4 * mb), closeTo(0.25, 1e-10));
      expect(storageShare(0, 4 * mb), 0);
      expect(storageShare(4 * mb, 4 * mb), 1);
    });

    test('clamps a category larger than the host total', () {
      expect(storageShare(8 * mb, 4 * mb), 1);
    });

    test('returns null when the total is zero, so nothing draws a bar', () {
      expect(storageShare(0, 0), isNull);
      expect(storageShare(mb, 0), isNull);
      expect(storageShare(mb, -1), isNull);
    });

    test('returns null for an unknown size rather than a zero-width bar', () {
      expect(storageShare(null, 4 * mb), isNull);
      expect(storageShare(double.nan, 4 * mb), isNull);
      expect(storageShare(-1, 4 * mb), isNull);
      expect(storageShare(mb, null), isNull);
      expect(storageShare(mb, double.nan), isNull);
    });
  });

  group('canClearStorage', () {
    test('needs the host to declare the category clearable', () {
      expect(canClearStorage(category(clearable: true)), isTrue);
      expect(canClearStorage(category(clearable: false)), isFalse);
      expect(canClearStorage(null), isFalse);
    });

    test('offers nothing to clear on a category measured at exactly zero', () {
      expect(canClearStorage(category(bytes: 0)), isFalse);
    });

    test('keeps the button while the size is unknown — unmeasured is not empty', () {
      expect(canClearStorage(category(bytes: null)), isTrue);
      expect(canClearStorage(category(bytes: double.nan)), isTrue);
    });

    test('is independent of busy and error', () {
      expect(canClearStorage(category(busy: true)), isTrue);
      expect(canClearStorage(category(error: '清理失败')), isTrue);
    });
  });
}
