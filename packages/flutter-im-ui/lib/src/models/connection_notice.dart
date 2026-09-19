import 'package:flutter/foundation.dart';

import '../components/flare_status_banner.dart' show FlareStatusTone;
import '../tokens/flare_strings.dart';

/// Where the IM connection stands, as an app shell reports it.
enum FlareConnectionPhase {
  connected,
  connecting,
  reconnecting,
  offline,
  disconnected,
  kicked,
  expired,
}

/// The way back a [FlareConnectionNotice] offers.
enum FlareConnectionRecovery { reconnect, signIn }

/// What an app shell tells the user about its IM connection: the words, the
/// tone and the way back, the same on every app. Render it with
/// `FlareStatusBanner` (text, tone, pulse, and the recovery as its action).
@immutable
class FlareConnectionNotice {
  const FlareConnectionNotice({
    required this.phase,
    required this.text,
    required this.tone,
    this.pulse = false,
    this.recovery,
    this.recoveryText,
  });

  final FlareConnectionPhase phase;
  final String text;

  /// [FlareStatusTone.warning] while the connection can come back on its own
  /// or with a reconnect, [FlareStatusTone.danger] when only signing in again
  /// helps.
  final FlareStatusTone tone;

  /// A connection attempt is under way (the banner's dot pulses).
  final bool pulse;

  /// The action the banner offers, with [recoveryText] as its label; null
  /// offers none.
  final FlareConnectionRecovery? recovery;
  final String? recoveryText;
}

/// The notice for [phase], in [strings]' words; null when connected.
///
/// - connecting and reconnecting say so (the core retries on its own);
/// - offline waits for the network;
/// - disconnected names [reason] when there is one, and offers 重新连接 only
///   when the host [canReconnect];
/// - kicked and expired are final (the core does not reconnect from them), so
///   they always offer 重新登录; a [reason] replaces the kicked text.
FlareConnectionNotice? flareConnectionNotice(
  FlareConnectionPhase phase,
  FlareStrings strings, {
  String? reason,
  bool canReconnect = false,
}) {
  final why = reason?.trim() ?? '';
  return switch (phase) {
    FlareConnectionPhase.connected => null,
    FlareConnectionPhase.connecting => FlareConnectionNotice(
      phase: phase,
      text: strings.connectionConnecting,
      tone: FlareStatusTone.warning,
      pulse: true,
    ),
    FlareConnectionPhase.reconnecting => FlareConnectionNotice(
      phase: phase,
      text: strings.connectionReconnecting,
      tone: FlareStatusTone.warning,
      pulse: true,
    ),
    FlareConnectionPhase.offline => FlareConnectionNotice(
      phase: phase,
      text: strings.connectionOffline,
      tone: FlareStatusTone.warning,
    ),
    FlareConnectionPhase.disconnected => FlareConnectionNotice(
      phase: phase,
      text: why.isEmpty
          ? strings.connectionDisconnected
          : strings.connectionDisconnectedReason(why),
      tone: FlareStatusTone.warning,
      recovery: canReconnect ? FlareConnectionRecovery.reconnect : null,
      recoveryText: canReconnect ? strings.connectionReconnect : null,
    ),
    FlareConnectionPhase.kicked => FlareConnectionNotice(
      phase: phase,
      text: why.isEmpty ? strings.connectionKicked : why,
      tone: FlareStatusTone.danger,
      recovery: FlareConnectionRecovery.signIn,
      recoveryText: strings.connectionSignIn,
    ),
    FlareConnectionPhase.expired => FlareConnectionNotice(
      phase: phase,
      text: strings.connectionExpired,
      tone: FlareStatusTone.danger,
      recovery: FlareConnectionRecovery.signIn,
      recoveryText: strings.connectionSignIn,
    ),
  };
}
