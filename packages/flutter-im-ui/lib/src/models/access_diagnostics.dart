import 'package:flutter/foundation.dart';

import '../components/flare_status_banner.dart' show FlareStatusTone;
import '../tokens/flare_strings.dart';

/// The connection diagnostics of `access.getStatus`: only what the page reads.
@immutable
class FlareAccessConnectAck {
  const FlareAccessConnectAck({
    this.accessPointId,
    this.accessPointMismatch = false,
  });

  /// The access point the server reports for the connection.
  final String? accessPointId;

  /// The server reports a different access point than the client chose.
  final bool accessPointMismatch;

  @override
  bool operator ==(Object other) =>
      other is FlareAccessConnectAck &&
      other.accessPointId == accessPointId &&
      other.accessPointMismatch == accessPointMismatch;

  @override
  int get hashCode => Object.hash(accessPointId, accessPointMismatch);
}

/// `access.getStatus.recovering`: there only while every line has failed.
@immutable
class FlareAccessRecovering {
  const FlareAccessRecovering({required this.rounds, this.nextRoundAtMs});

  /// Bootstrap rounds so far.
  final int rounds;

  /// When the next round starts; null while the device has no network.
  final int? nextRoundAtMs;

  @override
  bool operator ==(Object other) =>
      other is FlareAccessRecovering &&
      other.rounds == rounds &&
      other.nextRoundAtMs == nextRoundAtMs;

  @override
  int get hashCode => Object.hash(rounds, nextRoundAtMs);
}

/// What `access.getStatus` returns, as far as the page reads it (Vue
/// `FlareAccessStatus`).
@immutable
class FlareAccessStatus {
  const FlareAccessStatus({
    required this.loaded,
    this.serial,
    this.source,
    this.stale = false,
    this.developmentMode = false,
    this.regionId,
    this.accessPointId,
    this.protocol,
    this.connectAck,
    this.recovering,
  });

  /// The directory holds a usable manifest.
  final bool loaded;
  final int? serial;

  /// seed, https:<mirror base>, wellKnown:<apId>, recovery, development or
  /// none.
  final String? source;

  /// Past its expiry: still connectable.
  final bool stale;
  final bool developmentMode;
  final String? regionId;

  /// The access point of the current connection.
  final String? accessPointId;
  final String? protocol;
  final FlareAccessConnectAck? connectAck;
  final FlareAccessRecovering? recovering;

  @override
  bool operator ==(Object other) =>
      other is FlareAccessStatus &&
      other.loaded == loaded &&
      other.serial == serial &&
      other.source == source &&
      other.stale == stale &&
      other.developmentMode == developmentMode &&
      other.regionId == regionId &&
      other.accessPointId == accessPointId &&
      other.protocol == protocol &&
      other.connectAck == connectAck &&
      other.recovering == recovering;

  @override
  int get hashCode => Object.hash(
    loaded,
    serial,
    source,
    stale,
    developmentMode,
    regionId,
    accessPointId,
    protocol,
    connectAck,
    recovering,
  );
}

/// One line of `access.listAccessPoints`.
@immutable
class FlareAccessPoint {
  const FlareAccessPoint({
    required this.accessPointId,
    this.regionId,
    this.host,
    required this.status,
    this.rttMs,
    required this.breaker,
    this.pinned = false,
    this.current = false,
  });

  final String accessPointId;
  final String? regionId;
  final String? host;

  /// active, draining, disabled or unknown; any other string reads unknown.
  final String status;
  final double? rttMs;

  /// closed, open or halfOpen.
  final String breaker;
  final bool pinned;
  final bool current;
}

/// How the page stands as a whole.
enum FlareAccessDiagnosticsState { normal, recovering, warning }

enum FlareAccessManifestState { valid, stale, none }

enum FlareAccessRttGrade { good, fair, poor }

enum FlareAccessPointState { active, draining, disabled, unknown }

enum FlareAccessBreakerState { open, halfOpen }

enum FlareAccessPinAction { pin, unpin }

enum FlareAccessSourceKind {
  seed,
  mirror,
  wellKnown,
  recovery,
  development,
  none,
  unknown,
}

/// A line at the top of the page.
enum FlareAccessNoticeText {
  healthy,
  notConnected,
  serviceUnavailable,
  waitingForNetwork,
  accessPointMismatch,
  manifestStale,
}

enum FlareAccessRefreshText { adopted, upToDate, failed, skipped }

enum FlareAccessImportText {
  adopted,
  unchanged,
  rollback,
  expired,
  wrongApp,
  developmentMode,
  untrusted,
  malformed,
  rejected,
}

enum FlareAccessExportText { copied, failed }

@immutable
class FlareAccessNotice {
  const FlareAccessNotice({
    required this.text,
    required this.tone,
    this.pulse = false,
  });

  final FlareAccessNoticeText text;
  final FlareStatusTone tone;
  final bool pulse;
}

/// The latency to show and its grade; unknown has neither.
@immutable
class FlareAccessRtt {
  const FlareAccessRtt({this.shownMs, this.grade});

  /// Whole milliseconds to show; null when unknown.
  final int? shownMs;
  final FlareAccessRttGrade? grade;
}

@immutable
class FlareAccessSource {
  const FlareAccessSource({required this.kind, this.detail});

  final FlareAccessSourceKind kind;

  /// A mirror's host, a well-known access point, or an unknown source as it
  /// arrived.
  final String? detail;
}

/// One row of the line list.
@immutable
class FlareAccessPointRow {
  const FlareAccessPointRow({
    required this.accessPointId,
    this.host,
    required this.current,
    required this.pinned,
    required this.status,
    required this.statusTone,
    this.breaker,
    this.breakerTone,
    required this.rtt,
    this.pin,
  });

  final String accessPointId;
  final String? host;
  final bool current;
  final bool pinned;
  final FlareAccessPointState status;
  final FlareStatusTone statusTone;
  final FlareAccessBreakerState? breaker;
  final FlareStatusTone? breakerTone;
  final FlareAccessRtt rtt;
  final FlareAccessPinAction? pin;
}

@immutable
class FlareAccessRegion {
  const FlareAccessRegion({this.regionId, required this.accessPoints});

  /// Null for lines without a region: no heading.
  final String? regionId;
  final List<FlareAccessPointRow> accessPoints;
}

/// What the page shows for one status and list.
@immutable
class FlareAccessDiagnosticsModel {
  const FlareAccessDiagnosticsModel({
    required this.state,
    required this.notices,
    required this.manifest,
    required this.rtt,
    this.reportedAccessPointId,
    this.recoveryRounds,
    required this.regions,
  });

  final FlareAccessDiagnosticsState state;
  final List<FlareAccessNotice> notices;
  final FlareAccessManifestState manifest;

  /// The current line's latency, from its row.
  final FlareAccessRtt rtt;

  /// What the server reports while it disagrees with the client.
  final String? reportedAccessPointId;
  final int? recoveryRounds;
  final List<FlareAccessRegion> regions;
}

/// A one-line answer to one of the page's actions.
@immutable
class FlareAccessFeedback<T> {
  const FlareAccessFeedback(this.text, this.tone);

  final T text;
  final FlareStatusTone tone;
}

/// Where the latency grades change, in whole milliseconds (the shared table's
/// `thresholds`).
abstract final class FlareAccessRttThresholds {
  static const goodBelowMs = 150;
  static const poorAboveMs = 400;
}

/// The tone a latency grade is drawn in.
FlareStatusTone flareAccessRttTone(FlareAccessRttGrade grade) =>
    switch (grade) {
      FlareAccessRttGrade.good => FlareStatusTone.success,
      FlareAccessRttGrade.fair => FlareStatusTone.warning,
      FlareAccessRttGrade.poor => FlareStatusTone.danger,
    };

/// The latency to show and its grade; unknown (missing, negative, not finite)
/// has neither.
FlareAccessRtt flareAccessRtt(double? rttMs) {
  if (rttMs == null || !rttMs.isFinite || rttMs < 0) {
    return const FlareAccessRtt();
  }
  final shown = rttMs.round();
  if (shown < FlareAccessRttThresholds.goodBelowMs) {
    return FlareAccessRtt(shownMs: shown, grade: FlareAccessRttGrade.good);
  }
  return FlareAccessRtt(
    shownMs: shown,
    grade: shown > FlareAccessRttThresholds.poorAboveMs
        ? FlareAccessRttGrade.poor
        : FlareAccessRttGrade.fair,
  );
}

/// The protocol's name on screen; a protocol the kit does not know is shown as
/// it arrives.
String? flareAccessProtocolLabel(String? protocol) => switch (protocol) {
  'quic' => 'QUIC',
  'ws' => 'WebSocket',
  _ => protocol,
};

/// `https:<base>` and `wellKnown:<apId>` read apart; the plain sources are
/// their own kinds.
FlareAccessSource flareAccessSource(String? source) {
  switch (source) {
    case null || 'none':
      return const FlareAccessSource(kind: FlareAccessSourceKind.none);
    case 'seed':
      return const FlareAccessSource(kind: FlareAccessSourceKind.seed);
    case 'recovery':
      return const FlareAccessSource(kind: FlareAccessSourceKind.recovery);
    case 'development':
      return const FlareAccessSource(kind: FlareAccessSourceKind.development);
  }
  final text = source;
  if (text.startsWith('https:')) {
    final base = text.substring('https:'.length);
    final authority = base.substring(base.indexOf('://') + 3);
    return FlareAccessSource(
      kind: FlareAccessSourceKind.mirror,
      detail: authority.split('/').first,
    );
  }
  if (text.startsWith('wellKnown:')) {
    return FlareAccessSource(
      kind: FlareAccessSourceKind.wellKnown,
      detail: text.substring('wellKnown:'.length),
    );
  }
  return FlareAccessSource(kind: FlareAccessSourceKind.unknown, detail: text);
}

/// One line's row: a pin needs an active line that is not cooling down; a
/// pinned line can always be let go.
FlareAccessPointRow flareAccessPointRow(FlareAccessPoint point) {
  final (status, tone) = switch (point.status) {
    'active' => (FlareAccessPointState.active, FlareStatusTone.success),
    'draining' => (FlareAccessPointState.draining, FlareStatusTone.warning),
    'disabled' => (FlareAccessPointState.disabled, FlareStatusTone.neutral),
    _ => (FlareAccessPointState.unknown, FlareStatusTone.neutral),
  };
  final breaker = switch (point.breaker) {
    'open' => FlareAccessBreakerState.open,
    'halfOpen' => FlareAccessBreakerState.halfOpen,
    _ => null,
  };
  FlareAccessPinAction? pin;
  if (point.pinned) {
    pin = FlareAccessPinAction.unpin;
  } else if (status == FlareAccessPointState.active &&
      breaker != FlareAccessBreakerState.open) {
    pin = FlareAccessPinAction.pin;
  }
  return FlareAccessPointRow(
    accessPointId: point.accessPointId,
    host: point.host,
    current: point.current,
    pinned: point.pinned,
    status: status,
    statusTone: tone,
    breaker: breaker,
    breakerTone: switch (breaker) {
      FlareAccessBreakerState.open => FlareStatusTone.danger,
      FlareAccessBreakerState.halfOpen => FlareStatusTone.warning,
      null => null,
    },
    rtt: flareAccessRtt(point.rttMs),
    pin: pin,
  );
}

List<FlareAccessRegion> _regionsOf(List<FlareAccessPoint> accessPoints) {
  final regions = <String?, List<FlareAccessPointRow>>{};
  for (final point in accessPoints) {
    (regions[point.regionId] ??= []).add(flareAccessPointRow(point));
  }
  return [
    for (final entry in regions.entries)
      FlareAccessRegion(regionId: entry.key, accessPoints: entry.value),
  ];
}

/// What the page shows. [status] is null until the host has read one. Rules:
/// `spec/access-diagnostics-vectors.json`, run by all four kits.
FlareAccessDiagnosticsModel flareAccessDiagnostics(
  FlareAccessStatus? status,
  List<FlareAccessPoint> accessPoints,
) {
  final regions = _regionsOf(accessPoints);
  final current = accessPoints.where((point) => point.current).firstOrNull;
  final rtt = flareAccessRtt(current?.rttMs);
  if (status == null) {
    return FlareAccessDiagnosticsModel(
      state: FlareAccessDiagnosticsState.normal,
      notices: const [],
      manifest: FlareAccessManifestState.none,
      rtt: rtt,
      regions: regions,
    );
  }

  final mismatch = status.connectAck?.accessPointMismatch ?? false;
  final warnings = [
    if (mismatch)
      const FlareAccessNotice(
        text: FlareAccessNoticeText.accessPointMismatch,
        tone: FlareStatusTone.warning,
      ),
    if (status.stale)
      const FlareAccessNotice(
        text: FlareAccessNoticeText.manifestStale,
        tone: FlareStatusTone.warning,
      ),
  ];
  final recovering = status.recovering != null || !status.loaded;
  final state = recovering
      ? FlareAccessDiagnosticsState.recovering
      : warnings.isNotEmpty
      ? FlareAccessDiagnosticsState.warning
      : FlareAccessDiagnosticsState.normal;
  return FlareAccessDiagnosticsModel(
    state: state,
    notices: _noticesOf(status, state, warnings),
    manifest: !status.loaded
        ? FlareAccessManifestState.none
        : status.stale
        ? FlareAccessManifestState.stale
        : FlareAccessManifestState.valid,
    rtt: rtt,
    reportedAccessPointId: mismatch ? status.connectAck?.accessPointId : null,
    recoveryRounds: status.recovering?.rounds,
    regions: regions,
  );
}

List<FlareAccessNotice> _noticesOf(
  FlareAccessStatus status,
  FlareAccessDiagnosticsState state,
  List<FlareAccessNotice> warnings,
) {
  switch (state) {
    case FlareAccessDiagnosticsState.recovering:
      final recovering = status.recovering;
      final offline = recovering != null && recovering.nextRoundAtMs == null;
      return [
        offline
            ? const FlareAccessNotice(
                text: FlareAccessNoticeText.waitingForNetwork,
                tone: FlareStatusTone.warning,
              )
            : const FlareAccessNotice(
                text: FlareAccessNoticeText.serviceUnavailable,
                tone: FlareStatusTone.warning,
                pulse: true,
              ),
        ...warnings,
      ];
    case FlareAccessDiagnosticsState.warning:
      return warnings;
    case FlareAccessDiagnosticsState.normal:
      return [
        status.accessPointId != null && status.accessPointId!.isNotEmpty
            ? const FlareAccessNotice(
                text: FlareAccessNoticeText.healthy,
                tone: FlareStatusTone.success,
              )
            : const FlareAccessNotice(
                text: FlareAccessNoticeText.notConnected,
                tone: FlareStatusTone.neutral,
              ),
      ];
  }
}

/// What `access.refresh` answered, in the page's words; nothing for an outcome
/// the kit does not know.
FlareAccessFeedback<FlareAccessRefreshText>? flareAccessRefreshFeedback(
  String? outcome,
) => switch (outcome) {
  'adopted' => const FlareAccessFeedback(
    FlareAccessRefreshText.adopted,
    FlareStatusTone.success,
  ),
  'upToDate' => const FlareAccessFeedback(
    FlareAccessRefreshText.upToDate,
    FlareStatusTone.success,
  ),
  'failed' || 'oldValues' => const FlareAccessFeedback(
    FlareAccessRefreshText.failed,
    FlareStatusTone.warning,
  ),
  'skipped' => const FlareAccessFeedback(
    FlareAccessRefreshText.skipped,
    FlareStatusTone.neutral,
  ),
  _ => null,
};

FlareAccessImportText _rejectionText(String? code) => switch (code) {
  'rollback' => FlareAccessImportText.rollback,
  'expired' => FlareAccessImportText.expired,
  'wrongBootstrapId' => FlareAccessImportText.wrongApp,
  'developmentMode' => FlareAccessImportText.developmentMode,
  'badSignature' ||
  'unknownKey' ||
  'revoked' ||
  'wrongPayloadType' => FlareAccessImportText.untrusted,
  'malformedEnvelope' ||
  'invalidPayload' ||
  'tooLarge' => FlareAccessImportText.malformed,
  _ =>
    (code?.startsWith('keyCert.') ?? false)
        ? FlareAccessImportText.untrusted
        : FlareAccessImportText.rejected,
};

/// What `access.importRecovery` answered: its `outcome`, and its `code` when
/// rejected.
FlareAccessFeedback<FlareAccessImportText>? flareAccessImportFeedback(
  String? outcome,
  String? code,
) => switch (outcome) {
  'adopted' => const FlareAccessFeedback(
    FlareAccessImportText.adopted,
    FlareStatusTone.success,
  ),
  'unchanged' => const FlareAccessFeedback(
    FlareAccessImportText.unchanged,
    FlareStatusTone.neutral,
  ),
  'rejected' => FlareAccessFeedback(
    _rejectionText(code),
    FlareStatusTone.danger,
  ),
  _ => null,
};

/// The host's word on the clipboard: copied or failed.
FlareAccessFeedback<FlareAccessExportText>? flareAccessExportFeedback(
  String? outcome,
) => switch (outcome) {
  'copied' => const FlareAccessFeedback(
    FlareAccessExportText.copied,
    FlareStatusTone.success,
  ),
  'failed' => const FlareAccessFeedback(
    FlareAccessExportText.failed,
    FlareStatusTone.danger,
  ),
  _ => null,
};

/// The words of a top-of-page notice.
String flareAccessNoticeLabel(
  FlareAccessNoticeText text,
  FlareStrings strings,
) => switch (text) {
  FlareAccessNoticeText.healthy => strings.accessDiagnosticsHealthy,
  FlareAccessNoticeText.notConnected => strings.accessDiagnosticsNotConnected,
  FlareAccessNoticeText.serviceUnavailable =>
    strings.connectionServiceUnavailable,
  FlareAccessNoticeText.waitingForNetwork =>
    strings.connectionWaitingForNetwork,
  FlareAccessNoticeText.accessPointMismatch =>
    strings.accessDiagnosticsAccessPointMismatch,
  FlareAccessNoticeText.manifestStale =>
    strings.accessDiagnosticsManifestStaleNotice,
};

/// The answer to a refresh.
String flareAccessRefreshLabel(
  FlareAccessRefreshText text,
  FlareStrings strings,
) => switch (text) {
  FlareAccessRefreshText.adopted => strings.accessDiagnosticsRefreshAdopted,
  FlareAccessRefreshText.upToDate => strings.accessDiagnosticsRefreshUpToDate,
  FlareAccessRefreshText.failed => strings.accessDiagnosticsRefreshFailed,
  FlareAccessRefreshText.skipped => strings.accessDiagnosticsRefreshSkipped,
};

/// The answer to an import.
String flareAccessImportLabel(
  FlareAccessImportText text,
  FlareStrings strings,
) => switch (text) {
  FlareAccessImportText.adopted => strings.accessDiagnosticsImportAdopted,
  FlareAccessImportText.unchanged => strings.accessDiagnosticsImportUnchanged,
  FlareAccessImportText.rollback => strings.accessDiagnosticsImportRollback,
  FlareAccessImportText.expired => strings.accessDiagnosticsImportExpired,
  FlareAccessImportText.wrongApp => strings.accessDiagnosticsImportWrongApp,
  FlareAccessImportText.developmentMode =>
    strings.accessDiagnosticsImportDevelopmentMode,
  FlareAccessImportText.untrusted => strings.accessDiagnosticsImportUntrusted,
  FlareAccessImportText.malformed => strings.accessDiagnosticsImportMalformed,
  FlareAccessImportText.rejected => strings.accessDiagnosticsImportRejected,
};

/// The answer to an export.
String flareAccessExportLabel(
  FlareAccessExportText text,
  FlareStrings strings,
) => switch (text) {
  FlareAccessExportText.copied => strings.accessDiagnosticsExportCopied,
  FlareAccessExportText.failed => strings.accessDiagnosticsExportFailed,
};

/// A latency for the page: `86 ms · Good`.
String? flareAccessRttLabel(FlareAccessRtt rtt, FlareStrings strings) {
  final grade = rtt.grade;
  if (rtt.shownMs == null || grade == null) return null;
  final word = switch (grade) {
    FlareAccessRttGrade.good => strings.accessDiagnosticsRttGood,
    FlareAccessRttGrade.fair => strings.accessDiagnosticsRttFair,
    FlareAccessRttGrade.poor => strings.accessDiagnosticsRttPoor,
  };
  return '${rtt.shownMs} ms · $word';
}

/// Where the manifest came from, in words.
String? flareAccessSourceLabel(String? source, FlareStrings strings) {
  final read = flareAccessSource(source);
  return switch (read.kind) {
    FlareAccessSourceKind.seed => strings.accessDiagnosticsSourceSeed,
    FlareAccessSourceKind.mirror =>
      '${strings.accessDiagnosticsSourceMirror} ${read.detail}',
    FlareAccessSourceKind.wellKnown =>
      '${strings.accessDiagnosticsAccessPoint} ${read.detail}',
    FlareAccessSourceKind.recovery => strings.accessDiagnosticsSourceRecovery,
    FlareAccessSourceKind.development =>
      strings.accessDiagnosticsSourceDevelopment,
    FlareAccessSourceKind.none => strings.accessDiagnosticsSourceNone,
    FlareAccessSourceKind.unknown => read.detail,
  };
}
