/// The load-more guard shared by `FlarePluginDetailSheet` and
/// `FlarePluginPage` (spec/plugin-view-vectors.json rules.detail): the cursor
/// the kit last asked for, so a page is never asked for twice. It is
/// forgotten — a retry allowed — when the host stops loading, settles, or
/// reports a failure.
class FlarePluginPageCursor {
  String? _asked;

  /// Whether the page after [cursor] is on its way.
  bool busy(String cursor, {required bool loadingMore}) =>
      loadingMore || _asked == cursor;

  /// Records that the page after [cursor] was asked for; false when it
  /// already is on its way.
  bool ask(String cursor, {required bool loadingMore}) {
    if (busy(cursor, loadingMore: loadingMore)) return false;
    _asked = cursor;
    return true;
  }

  /// The host's update: loading finished, an action settled, or a new error.
  void update({
    required bool wasLoadingMore,
    required bool loadingMore,
    required int oldSettleToken,
    required int settleToken,
    required String? oldError,
    required String? error,
  }) {
    final failed = (error ?? '').isNotEmpty && error != oldError;
    if ((wasLoadingMore && !loadingMore) ||
        settleToken != oldSettleToken ||
        failed) {
      _asked = null;
    }
  }
}
