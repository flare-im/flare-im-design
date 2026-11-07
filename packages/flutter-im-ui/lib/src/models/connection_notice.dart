import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../components/flare_status_banner.dart' show FlareStatusTone;
import '../tokens/flare_strings.dart';

/// Where the IM connection stands: the core SDK's `connection://status` phase
/// (Vue `FlareConnectionPhase`).
enum FlareConnectionPhase {
  idle,
  connecting,
  syncing,
  online,
  switching,
  reconnecting,
  waitingForNetwork,
  serviceUnavailable,
  actionRequired,
}

/// The line's quality while online. Neither value shows a banner.
enum FlareConnectionQuality { good, poor }

/// Why the core stopped and waits for the user (actionRequired): the four
/// reasons the notice words.
enum FlareConnectionActionReason {
  kicked,
  expired,
  upgradeRequired,
  tenantUnavailable;

  /// The reason named [wire]; null for a missing or unknown one.
  static FlareConnectionActionReason? parse(String? wire) {
    for (final reason in values) {
      if (reason.name == wire) return reason;
    }
    return null;
  }
}

/// The core SDK's connection status as the host receives it from
/// `connection://status`.
@immutable
class FlareConnectionStatus {
  const FlareConnectionStatus({
    required this.phase,
    this.quality,
    this.progress,
    this.nextRetryAt,
    this.attempt,
    this.reason,
    this.developmentMode = false,
  });

  final FlareConnectionPhase phase;

  /// online: the line's quality.
  final FlareConnectionQuality? quality;

  /// syncing: how far the catch-up has come, 0 to 1.
  final double? progress;

  /// reconnecting: when the next attempt starts, epoch milliseconds on the
  /// device clock.
  final int? nextRetryAt;

  /// reconnecting: which attempt this is. Not shown.
  final int? attempt;

  /// The engine's reason as it arrives: actionRequired carries kicked,
  /// expired, upgradeRequired or tenantUnavailable, switching carries failure,
  /// drain, failback, manual or manifest. Any string is accepted; only the
  /// four actionRequired reasons are worded ([actionReason]).
  final String? reason;

  /// actionRequired: why, as the notice words it. A missing or unknown reason
  /// reads as expired.
  FlareConnectionActionReason? get actionReason =>
      FlareConnectionActionReason.parse(reason);

  /// The SDK runs on development endpoints: the notice wears a 开发模式
  /// badge in every phase.
  final bool developmentMode;

  @override
  bool operator ==(Object other) =>
      other is FlareConnectionStatus &&
      other.phase == phase &&
      other.quality == quality &&
      other.progress == progress &&
      other.nextRetryAt == nextRetryAt &&
      other.attempt == attempt &&
      other.reason == reason &&
      other.developmentMode == developmentMode;

  @override
  int get hashCode => Object.hash(
    phase,
    quality,
    progress,
    nextRetryAt,
    attempt,
    reason,
    developmentMode,
  );
}

/// The message a visible connection notice says.
enum FlareConnectionNoticeText {
  connecting,
  syncing,
  switching,
  reconnecting,
  waitingForNetwork,
  serviceUnavailable,
  kicked,
  expired,
  upgradeRequired,
  tenantUnavailable,
}

/// The action a visible connection notice offers; the host performs it.
enum FlareConnectionNoticeAction { retry, signIn, update, diagnose }

/// What the connection notice shows at one moment.
@immutable
class FlareConnectionNoticeModel {
  const FlareConnectionNoticeModel({
    required this.visible,
    this.text,
    this.tone,
    this.pulse = false,
    this.countdown,
    this.progress,
    this.action,
    this.badge = false,
  });

  static const hidden = FlareConnectionNoticeModel(visible: false);

  final bool visible;
  final FlareConnectionNoticeText? text;
  final FlareStatusTone? tone;

  /// An attempt or a recovery is under way.
  final bool pulse;

  /// reconnecting: whole seconds to the next attempt, rounded up.
  final int? countdown;

  /// syncing: 0 to 1.
  final double? progress;
  final FlareConnectionNoticeAction? action;

  /// Draw the development mode badge.
  final bool badge;

  FlareConnectionNoticeModel withBadge(bool badge) =>
      FlareConnectionNoticeModel(
        visible: visible,
        text: text,
        tone: tone,
        pulse: pulse,
        countdown: countdown,
        progress: progress,
        action: action,
        badge: badge,
      );

  /// The message alone, as a screen reader is told it (the countdown is not
  /// re-announced every second).
  String? message(FlareStrings strings) => switch (text) {
    FlareConnectionNoticeText.connecting => strings.connectionConnecting,
    FlareConnectionNoticeText.syncing => strings.connectionSyncing,
    FlareConnectionNoticeText.switching => strings.connectionSwitching,
    FlareConnectionNoticeText.reconnecting => strings.connectionReconnecting,
    FlareConnectionNoticeText.waitingForNetwork =>
      strings.connectionWaitingForNetwork,
    FlareConnectionNoticeText.serviceUnavailable =>
      strings.connectionServiceUnavailable,
    FlareConnectionNoticeText.kicked => strings.connectionKicked,
    FlareConnectionNoticeText.expired => strings.connectionExpired,
    FlareConnectionNoticeText.upgradeRequired =>
      strings.connectionUpgradeRequired,
    FlareConnectionNoticeText.tenantUnavailable =>
      strings.connectionTenantUnavailable,
    null => null,
  };

  /// The banner's words: the message, then the countdown or the sync
  /// progress.
  String bannerText(FlareStrings strings) {
    final said = message(strings);
    if (said == null) return '';
    if (countdown != null)
      return '$said ${strings.connectionRetryIn(countdown!)}';
    if (progress != null) return '$said ${(progress! * 100).round()}%';
    return said;
  }

  @override
  bool operator ==(Object other) =>
      other is FlareConnectionNoticeModel &&
      other.visible == visible &&
      other.text == text &&
      other.tone == tone &&
      other.pulse == pulse &&
      other.countdown == countdown &&
      other.progress == progress &&
      other.action == action &&
      other.badge == badge;

  @override
  int get hashCode => Object.hash(
    visible,
    text,
    tone,
    pulse,
    countdown,
    progress,
    action,
    badge,
  );
}

/// The action's label in [strings].
String flareConnectionActionLabel(
  FlareConnectionNoticeAction action,
  FlareStrings strings,
) => switch (action) {
  FlareConnectionNoticeAction.retry => strings.connectionRetry,
  FlareConnectionNoticeAction.signIn => strings.connectionSignIn,
  FlareConnectionNoticeAction.update => strings.connectionUpdate,
  FlareConnectionNoticeAction.diagnose => strings.connectionDiagnose,
};

/// Whole seconds to [nextRetryAt], rounded up; null once it has passed.
int? flareConnectionCountdown(int nextRetryAt, int nowMs) {
  final remaining = nextRetryAt - nowMs;
  return remaining > 0 ? (remaining + 999) ~/ 1000 : null;
}

/// Tracks the connection status over time and answers what the notice shows,
/// the same as the Vue, SwiftUI and Compose kits
/// (`spec/connection-notice-vectors.json`):
///
/// - idle and online show nothing; connecting, reconnecting,
///   waitingForNetwork, serviceUnavailable and actionRequired show at once;
/// - syncing shows once it has lasted [syncingDelayMs] and switching once it
///   has lasted [switchingDelayMs]; until then a banner that was already up
///   keeps what it showed;
/// - a reconnecting banner stays up at least [reconnectingMinShownMs];
/// - reconnecting counts down and offers retry, serviceUnavailable offers
///   diagnose, actionRequired offers sign in (kicked, expired) or update
///   (upgradeRequired).
class FlareConnectionNoticeTracker {
  static const syncingDelayMs = 1000;
  static const switchingDelayMs = 2000;
  static const reconnectingMinShownMs = 1500;

  FlareConnectionStatus? _status;
  int _phaseSince = 0;
  ({FlareConnectionNoticeText? text, FlareStatusTone? tone, bool pulse})?
  _lastShown;
  int? _holdUntil;

  /// A status arrived at [nowMs]. The same phase again replaces its fields
  /// without restarting its clock.
  void observe(FlareConnectionStatus status, int nowMs) {
    if (_status?.phase != status.phase) {
      final outgoing = present(nowMs);
      _lastShown = outgoing.visible
          ? (text: outgoing.text, tone: outgoing.tone, pulse: outgoing.pulse)
          : null;
      _phaseSince = nowMs;
      switch (status.phase) {
        case FlareConnectionPhase.reconnecting:
          _holdUntil = nowMs + reconnectingMinShownMs;
        case FlareConnectionPhase.idle:
        case FlareConnectionPhase.actionRequired:
          _holdUntil = null;
        default:
          break;
      }
    }
    _status = status;
  }

  /// What the notice shows at [nowMs].
  FlareConnectionNoticeModel present(int nowMs) {
    final status = _status;
    if (status == null) return FlareConnectionNoticeModel.hidden;
    final badge = status.developmentMode;
    if (status.phase == FlareConnectionPhase.idle) {
      return FlareConnectionNoticeModel(visible: false, badge: badge);
    }
    final base = _base(status, nowMs);
    if (base.visible) return base.withBadge(badge);
    final shown = _lastShown;
    if (shown != null && (_belowDelay(status, nowMs) || _held(nowMs))) {
      return FlareConnectionNoticeModel(
        visible: true,
        text: shown.text,
        tone: shown.tone,
        pulse: shown.pulse,
        badge: badge,
      );
    }
    return FlareConnectionNoticeModel(visible: false, badge: badge);
  }

  /// The next moment the presentation can change without a new status; null
  /// when it cannot.
  int? nextChangeAt(int nowMs) {
    final status = _status;
    if (status == null || status.phase == FlareConnectionPhase.idle) {
      return null;
    }
    final candidates = <int>[];
    final delay = _delayOf(status.phase);
    if (delay != null && nowMs < _phaseSince + delay) {
      candidates.add(_phaseSince + delay);
    }
    final at = status.nextRetryAt;
    if (status.phase == FlareConnectionPhase.reconnecting && at != null) {
      final countdown = flareConnectionCountdown(at, nowMs);
      if (countdown != null) candidates.add(at - (countdown - 1) * 1000);
    }
    final hold = _holdUntil;
    if (_lastShown != null &&
        hold != null &&
        nowMs < hold &&
        !_base(status, nowMs).visible) {
      candidates.add(hold);
    }
    return candidates.isEmpty ? null : candidates.reduce(math.min);
  }

  static int? _delayOf(FlareConnectionPhase phase) => switch (phase) {
    FlareConnectionPhase.syncing => syncingDelayMs,
    FlareConnectionPhase.switching => switchingDelayMs,
    _ => null,
  };

  bool _belowDelay(FlareConnectionStatus status, int nowMs) {
    final delay = _delayOf(status.phase);
    return delay != null && nowMs - _phaseSince < delay;
  }

  bool _held(int nowMs) => _holdUntil != null && nowMs < _holdUntil!;

  FlareConnectionNoticeModel _base(FlareConnectionStatus status, int nowMs) {
    switch (status.phase) {
      case FlareConnectionPhase.idle:
      case FlareConnectionPhase.online:
        return FlareConnectionNoticeModel.hidden;
      case FlareConnectionPhase.connecting:
        return const FlareConnectionNoticeModel(
          visible: true,
          text: FlareConnectionNoticeText.connecting,
          tone: FlareStatusTone.info,
          pulse: true,
        );
      case FlareConnectionPhase.syncing:
        if (_belowDelay(status, nowMs))
          return FlareConnectionNoticeModel.hidden;
        return FlareConnectionNoticeModel(
          visible: true,
          text: FlareConnectionNoticeText.syncing,
          tone: FlareStatusTone.info,
          pulse: true,
          progress: status.progress?.clamp(0.0, 1.0).toDouble(),
        );
      case FlareConnectionPhase.switching:
        if (_belowDelay(status, nowMs))
          return FlareConnectionNoticeModel.hidden;
        return const FlareConnectionNoticeModel(
          visible: true,
          text: FlareConnectionNoticeText.switching,
          tone: FlareStatusTone.info,
          pulse: true,
        );
      case FlareConnectionPhase.reconnecting:
        final at = status.nextRetryAt;
        return FlareConnectionNoticeModel(
          visible: true,
          text: FlareConnectionNoticeText.reconnecting,
          tone: FlareStatusTone.warning,
          pulse: true,
          countdown: at == null ? null : flareConnectionCountdown(at, nowMs),
          action: FlareConnectionNoticeAction.retry,
        );
      case FlareConnectionPhase.waitingForNetwork:
        return const FlareConnectionNoticeModel(
          visible: true,
          text: FlareConnectionNoticeText.waitingForNetwork,
          tone: FlareStatusTone.warning,
        );
      case FlareConnectionPhase.serviceUnavailable:
        return const FlareConnectionNoticeModel(
          visible: true,
          text: FlareConnectionNoticeText.serviceUnavailable,
          tone: FlareStatusTone.warning,
          pulse: true,
          action: FlareConnectionNoticeAction.diagnose,
        );
      case FlareConnectionPhase.actionRequired:
        final reason =
            status.actionReason ?? FlareConnectionActionReason.expired;
        return FlareConnectionNoticeModel(
          visible: true,
          text: switch (reason) {
            FlareConnectionActionReason.kicked =>
              FlareConnectionNoticeText.kicked,
            FlareConnectionActionReason.expired =>
              FlareConnectionNoticeText.expired,
            FlareConnectionActionReason.upgradeRequired =>
              FlareConnectionNoticeText.upgradeRequired,
            FlareConnectionActionReason.tenantUnavailable =>
              FlareConnectionNoticeText.tenantUnavailable,
          },
          tone: FlareStatusTone.danger,
          action: switch (reason) {
            FlareConnectionActionReason.kicked ||
            FlareConnectionActionReason.expired =>
              FlareConnectionNoticeAction.signIn,
            FlareConnectionActionReason.upgradeRequired =>
              FlareConnectionNoticeAction.update,
            FlareConnectionActionReason.tenantUnavailable => null,
          },
        );
    }
  }
}
