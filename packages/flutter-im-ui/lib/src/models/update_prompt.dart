import 'package:flutter/foundation.dart';

import '../tokens/flare_strings.dart';

/// The update prompt, the progress bar and the version panel: what a person
/// sees about a new version. The host hands in the SDK's update status as plain
/// values; these rules turn it into the prompt's phase, words and actions, so
/// every app offers an update the same way. Rules and their table:
/// `spec/update-prompt-vectors.json`, run by all four kits.
///
/// - forced: mandatory, the required state or the fullscreen form; it has no
///   later, no skip and no way to the background;
/// - a forced offer says the host's reason, when there is one, in place of its
///   fixed words;
/// - work under way (downloading, verifying, ready, installing) outranks a
///   leftover error;
/// - the first action drawn is the primary one, and an action is drawn only
///   while the host handles it.
enum FlareUpdatePromptForm { sheet, modal, fullscreen }

/// Where the fallback goes: the website on a direct install, the app store
/// otherwise.
enum FlareUpdateFallbackTarget { website, store }

/// What a progress bar's colour says; the words around it carry the meaning.
enum FlareProgressBarTone { primary, success, warning, danger, neutral }

enum FlareUpdatePromptPhase {
  offer,
  metered,
  downloading,
  verifying,
  ready,
  installing,
  failed,
}

enum FlareUpdatePromptLive { polite, assertive }

enum FlareUpdatePromptTitle {
  available,
  required,
  metered,
  downloading,
  verifying,
  ready,
  installing,
  failed,
}

enum FlareUpdatePromptMessage {
  reason,
  required,
  requiredReadOnly,
  metered,
  meteredUnknown,
  ready,
  manifestUnavailable,
  manifestRejected,
  noArtifact,
  insufficientSpace,
  downloadFailed,
  hashMismatch,
  installFailed,
  signatureMismatch,
  downgradeRejected,
  notSkippable,
  unknown,
}

enum FlareUpdatePromptAction {
  update,
  continueDownload,
  restart,
  retry,
  fallback,
  later,
  background,
  skip,
  continueReadOnly,
}

enum FlareVersionPanelRow { check, update, restart }

enum FlareVersionPanelAction { check, update }

enum FlareVersionPanelDetail {
  checking,
  upToDate,
  available,
  required,
  downloading,
  verifying,
  ready,
  installing,
  failed,
}

enum FlareVersionChannelText { stable, beta, internal }

/// `UpdateStatus.progress`, as it arrives.
@immutable
class FlareUpdateProgress {
  const FlareUpdateProgress({required this.received, this.total});

  final int received;

  /// Null while the size is not known yet.
  final int? total;

  @override
  bool operator ==(Object other) =>
      other is FlareUpdateProgress &&
      other.received == received &&
      other.total == total;

  @override
  int get hashCode => Object.hash(received, total);
}

/// A bar's value. Null reads as indeterminate.
@immutable
class FlareProgressBarValue {
  const FlareProgressBarValue({this.value, this.percent});

  static const none = FlareProgressBarValue();

  /// 0..1.
  final double? value;

  /// Whole percent.
  final int? percent;

  @override
  bool operator ==(Object other) =>
      other is FlareProgressBarValue &&
      other.value == value &&
      other.percent == percent;

  @override
  int get hashCode => Object.hash(value, percent);
}

/// What the prompt shows for one status.
@immutable
class FlareUpdatePromptModel {
  const FlareUpdatePromptModel({
    required this.phase,
    required this.forced,
    required this.dismissible,
    required this.live,
    required this.title,
    required this.message,
    required this.actions,
    required this.notes,
    required this.progress,
  });

  final FlareUpdatePromptPhase phase;
  final bool forced;
  final bool dismissible;
  final FlareUpdatePromptLive live;
  final FlareUpdatePromptTitle title;
  final FlareUpdatePromptMessage? message;
  final List<FlareUpdatePromptAction> actions;

  /// The release notes are drawn.
  final bool notes;

  /// The bar; null draws none.
  final FlareProgressBarValue? progress;
}

/// What the version panel's update row shows for one state.
@immutable
class FlareVersionPanelModel {
  const FlareVersionPanelModel({
    required this.row,
    required this.action,
    required this.detail,
  });

  final FlareVersionPanelRow row;

  /// What tapping the row does; null disables it.
  final FlareVersionPanelAction? action;
  final FlareVersionPanelDetail? detail;
}

const flareUpdateMeteredCode = 'update.meteredConfirmationRequired';

const _failures = <String, FlareUpdatePromptMessage>{
  'update.manifestUnavailable': FlareUpdatePromptMessage.manifestUnavailable,
  'update.manifestRejected': FlareUpdatePromptMessage.manifestRejected,
  'update.noArtifact': FlareUpdatePromptMessage.noArtifact,
  'update.insufficientSpace': FlareUpdatePromptMessage.insufficientSpace,
  'update.downloadFailed': FlareUpdatePromptMessage.downloadFailed,
  'update.hashMismatch': FlareUpdatePromptMessage.hashMismatch,
  'update.installFailed': FlareUpdatePromptMessage.installFailed,
  'update.signatureMismatch': FlareUpdatePromptMessage.signatureMismatch,
  'update.downgradeRejected': FlareUpdatePromptMessage.downgradeRejected,
  'update.notSkippable': FlareUpdatePromptMessage.notSkippable,
};

/// What an error code says on the prompt; a code the kit does not know reads
/// as unknown.
FlareUpdatePromptMessage flareUpdateFailure(String? errorCode) =>
    _failures[errorCode] ?? FlareUpdatePromptMessage.unknown;

/// Whether the version line is drawn: the server can refuse the client before
/// any manifest brings a release to name.
bool flareUpdateVersionShown(String? version) =>
    version != null && version.trim().isNotEmpty;

/// A bar's value: clamped to 0..1, or none when it is missing, not finite or
/// asked to be indeterminate.
FlareProgressBarValue flareProgressBarValue(
  double? value, {
  bool indeterminate = false,
}) {
  if (indeterminate || value == null || !value.isFinite) {
    return FlareProgressBarValue.none;
  }
  final shown = value.clamp(0.0, 1.0).toDouble();
  return FlareProgressBarValue(value: shown, percent: (shown * 100).round());
}

FlareUpdatePromptPhase _phaseOf(String? state, String? errorCode) {
  switch (state) {
    case 'downloading':
      return FlareUpdatePromptPhase.downloading;
    case 'verifying':
      return FlareUpdatePromptPhase.verifying;
    case 'readyToInstall':
      return FlareUpdatePromptPhase.ready;
    case 'installing':
      return FlareUpdatePromptPhase.installing;
  }
  if (errorCode == flareUpdateMeteredCode) {
    return FlareUpdatePromptPhase.metered;
  }
  if (state == 'failed' || (errorCode != null && errorCode.isNotEmpty)) {
    return FlareUpdatePromptPhase.failed;
  }
  return FlareUpdatePromptPhase.offer;
}

FlareProgressBarValue? _progressOf(
  FlareUpdatePromptPhase phase,
  FlareUpdateProgress? progress,
) {
  switch (phase) {
    case FlareUpdatePromptPhase.downloading:
      final total = progress?.total;
      if (progress == null || total == null || total <= 0) {
        return FlareProgressBarValue.none;
      }
      return flareProgressBarValue(progress.received / total);
    case FlareUpdatePromptPhase.verifying:
    case FlareUpdatePromptPhase.installing:
      return FlareProgressBarValue.none;
    default:
      return null;
  }
}

/// What the prompt shows for one status (`spec/update-prompt-vectors.json`).
FlareUpdatePromptModel flareUpdatePrompt({
  required FlareUpdatePromptForm form,
  bool mandatory = false,
  String? state,
  FlareUpdateProgress? progress,
  String? errorCode,
  bool retryable = true,
  int? sizeBytes,
  bool canContinueReadOnly = false,
  String? reason,
}) {
  final forced =
      mandatory ||
      state == 'required' ||
      form == FlareUpdatePromptForm.fullscreen;
  final phase = _phaseOf(state, errorCode);
  final readOnly = [
    if (canContinueReadOnly) FlareUpdatePromptAction.continueReadOnly,
  ];
  final tail = forced ? readOnly : const [FlareUpdatePromptAction.later];
  final actions = switch (phase) {
    FlareUpdatePromptPhase.offer => [
      FlareUpdatePromptAction.update,
      ...tail,
      if (!forced && form == FlareUpdatePromptForm.sheet)
        FlareUpdatePromptAction.skip,
    ],
    FlareUpdatePromptPhase.metered => [
      FlareUpdatePromptAction.continueDownload,
      ...tail,
    ],
    FlareUpdatePromptPhase.downloading ||
    FlareUpdatePromptPhase.verifying =>
      forced ? readOnly : const [FlareUpdatePromptAction.background],
    FlareUpdatePromptPhase.ready => [FlareUpdatePromptAction.restart, ...tail],
    FlareUpdatePromptPhase.installing => const <FlareUpdatePromptAction>[],
    FlareUpdatePromptPhase.failed => [
      if (retryable) FlareUpdatePromptAction.retry,
      FlareUpdatePromptAction.fallback,
      ...tail,
    ],
  };
  final title = switch (phase) {
    FlareUpdatePromptPhase.offer =>
      forced
          ? FlareUpdatePromptTitle.required
          : FlareUpdatePromptTitle.available,
    FlareUpdatePromptPhase.metered => FlareUpdatePromptTitle.metered,
    FlareUpdatePromptPhase.downloading => FlareUpdatePromptTitle.downloading,
    FlareUpdatePromptPhase.verifying => FlareUpdatePromptTitle.verifying,
    FlareUpdatePromptPhase.ready => FlareUpdatePromptTitle.ready,
    FlareUpdatePromptPhase.installing => FlareUpdatePromptTitle.installing,
    FlareUpdatePromptPhase.failed => FlareUpdatePromptTitle.failed,
  };
  final message = switch (phase) {
    FlareUpdatePromptPhase.offer =>
      !forced
          ? null
          : reason != null && reason.trim().isNotEmpty
          ? FlareUpdatePromptMessage.reason
          : canContinueReadOnly
          ? FlareUpdatePromptMessage.requiredReadOnly
          : FlareUpdatePromptMessage.required,
    FlareUpdatePromptPhase.metered =>
      sizeBytes != null && sizeBytes >= 0
          ? FlareUpdatePromptMessage.metered
          : FlareUpdatePromptMessage.meteredUnknown,
    FlareUpdatePromptPhase.ready => FlareUpdatePromptMessage.ready,
    FlareUpdatePromptPhase.failed => flareUpdateFailure(errorCode),
    _ => null,
  };
  return FlareUpdatePromptModel(
    phase: phase,
    forced: forced,
    dismissible: !forced && phase != FlareUpdatePromptPhase.installing,
    live: forced
        ? FlareUpdatePromptLive.assertive
        : FlareUpdatePromptLive.polite,
    title: title,
    message: message,
    actions: actions,
    notes: switch (phase) {
      FlareUpdatePromptPhase.offer ||
      FlareUpdatePromptPhase.metered ||
      FlareUpdatePromptPhase.downloading ||
      FlareUpdatePromptPhase.verifying => true,
      _ => false,
    },
    progress: _progressOf(phase, progress),
  );
}

/// What the version panel's update row shows for one state
/// (`spec/update-prompt-vectors.json`).
FlareVersionPanelModel flareVersionPanel(String? updateState) =>
    switch (updateState) {
      'checking' => const FlareVersionPanelModel(
        row: FlareVersionPanelRow.check,
        action: null,
        detail: FlareVersionPanelDetail.checking,
      ),
      'upToDate' => const FlareVersionPanelModel(
        row: FlareVersionPanelRow.check,
        action: FlareVersionPanelAction.check,
        detail: FlareVersionPanelDetail.upToDate,
      ),
      'available' => const FlareVersionPanelModel(
        row: FlareVersionPanelRow.update,
        action: FlareVersionPanelAction.update,
        detail: FlareVersionPanelDetail.available,
      ),
      'required' => const FlareVersionPanelModel(
        row: FlareVersionPanelRow.update,
        action: FlareVersionPanelAction.update,
        detail: FlareVersionPanelDetail.required,
      ),
      'downloading' => const FlareVersionPanelModel(
        row: FlareVersionPanelRow.update,
        action: null,
        detail: FlareVersionPanelDetail.downloading,
      ),
      'verifying' => const FlareVersionPanelModel(
        row: FlareVersionPanelRow.update,
        action: null,
        detail: FlareVersionPanelDetail.verifying,
      ),
      'readyToInstall' => const FlareVersionPanelModel(
        row: FlareVersionPanelRow.restart,
        action: FlareVersionPanelAction.update,
        detail: FlareVersionPanelDetail.ready,
      ),
      'installing' => const FlareVersionPanelModel(
        row: FlareVersionPanelRow.update,
        action: null,
        detail: FlareVersionPanelDetail.installing,
      ),
      'failed' => const FlareVersionPanelModel(
        row: FlareVersionPanelRow.check,
        action: FlareVersionPanelAction.check,
        detail: FlareVersionPanelDetail.failed,
      ),
      _ => const FlareVersionPanelModel(
        row: FlareVersionPanelRow.check,
        action: FlareVersionPanelAction.check,
        detail: null,
      ),
    };

/// The channel's words of its own; null writes the channel as it arrived.
FlareVersionChannelText? flareVersionChannelText(String? channel) =>
    switch (channel) {
      'stable' => FlareVersionChannelText.stable,
      'beta' => FlareVersionChannelText.beta,
      'internal' => FlareVersionChannelText.internal,
      _ => null,
    };

/// The words of an update title.
String flareUpdateTitleLabel(
  FlareUpdatePromptTitle title,
  FlareStrings strings,
) => switch (title) {
  FlareUpdatePromptTitle.available => strings.updatePromptTitleAvailable,
  FlareUpdatePromptTitle.required => strings.updatePromptTitleRequired,
  FlareUpdatePromptTitle.metered => strings.updatePromptTitleMetered,
  FlareUpdatePromptTitle.downloading => strings.updatePromptTitleDownloading,
  FlareUpdatePromptTitle.verifying => strings.updatePromptTitleVerifying,
  FlareUpdatePromptTitle.ready => strings.updatePromptTitleReady,
  FlareUpdatePromptTitle.installing => strings.updatePromptTitleInstalling,
  FlareUpdatePromptTitle.failed => strings.updatePromptTitleFailed,
};

/// The words of an update message; [size] finishes the metered sentence and
/// [reason] is what the host's reason says.
String flareUpdateMessageLabel(
  FlareUpdatePromptMessage message,
  FlareStrings strings, {
  String? size,
  String? reason,
}) => switch (message) {
  FlareUpdatePromptMessage.reason => reason ?? '',
  FlareUpdatePromptMessage.required => strings.updatePromptMessageRequired,
  FlareUpdatePromptMessage.requiredReadOnly =>
    strings.updatePromptMessageRequiredReadOnly,
  FlareUpdatePromptMessage.metered =>
    '${strings.updatePromptMessageMetered} ${size ?? ''}'.trimRight(),
  FlareUpdatePromptMessage.meteredUnknown =>
    strings.updatePromptMessageMeteredUnknown,
  FlareUpdatePromptMessage.ready => strings.updatePromptMessageReady,
  FlareUpdatePromptMessage.manifestUnavailable =>
    strings.updatePromptFailManifestUnavailable,
  FlareUpdatePromptMessage.manifestRejected =>
    strings.updatePromptFailManifestRejected,
  FlareUpdatePromptMessage.noArtifact => strings.updatePromptFailNoArtifact,
  FlareUpdatePromptMessage.insufficientSpace =>
    strings.updatePromptFailInsufficientSpace,
  FlareUpdatePromptMessage.downloadFailed => strings.updatePromptFailDownload,
  FlareUpdatePromptMessage.hashMismatch => strings.updatePromptFailHashMismatch,
  FlareUpdatePromptMessage.installFailed => strings.updatePromptFailInstall,
  FlareUpdatePromptMessage.signatureMismatch =>
    strings.updatePromptFailSignatureMismatch,
  FlareUpdatePromptMessage.downgradeRejected =>
    strings.updatePromptFailDowngrade,
  FlareUpdatePromptMessage.notSkippable => strings.updatePromptFailNotSkippable,
  FlareUpdatePromptMessage.unknown => strings.updatePromptFailUnknown,
};

/// The words of an action.
String flareUpdateActionLabel(
  FlareUpdatePromptAction action,
  FlareStrings strings, {
  FlareUpdateFallbackTarget fallbackTarget = FlareUpdateFallbackTarget.website,
}) => switch (action) {
  FlareUpdatePromptAction.update => strings.connectionUpdate,
  FlareUpdatePromptAction.continueDownload =>
    strings.updatePromptContinueDownload,
  FlareUpdatePromptAction.restart => strings.updatePromptRestart,
  FlareUpdatePromptAction.retry => strings.updatePromptRetry,
  FlareUpdatePromptAction.fallback =>
    fallbackTarget == FlareUpdateFallbackTarget.store
        ? strings.updatePromptFallbackStore
        : strings.updatePromptFallbackWebsite,
  FlareUpdatePromptAction.later => strings.updatePromptLater,
  FlareUpdatePromptAction.background => strings.updatePromptBackground,
  FlareUpdatePromptAction.skip => strings.updatePromptSkip,
  FlareUpdatePromptAction.continueReadOnly =>
    strings.updatePromptContinueReadOnly,
};

/// The words of the version panel's update row.
String flareVersionPanelRowLabel(
  FlareVersionPanelRow row,
  FlareStrings strings,
) => switch (row) {
  FlareVersionPanelRow.check => strings.versionPanelCheck,
  FlareVersionPanelRow.update => strings.connectionUpdate,
  FlareVersionPanelRow.restart => strings.updatePromptRestart,
};

/// What the version panel's update row writes at its end.
String flareVersionPanelDetailLabel(
  FlareVersionPanelDetail detail,
  FlareStrings strings,
) => switch (detail) {
  FlareVersionPanelDetail.checking => strings.versionPanelChecking,
  FlareVersionPanelDetail.upToDate => strings.versionPanelUpToDate,
  FlareVersionPanelDetail.available => strings.updatePromptTitleAvailable,
  FlareVersionPanelDetail.required => strings.updatePromptTitleRequired,
  FlareVersionPanelDetail.downloading => strings.updatePromptTitleDownloading,
  FlareVersionPanelDetail.verifying => strings.updatePromptTitleVerifying,
  FlareVersionPanelDetail.ready => strings.updatePromptTitleReady,
  FlareVersionPanelDetail.installing => strings.updatePromptTitleInstalling,
  FlareVersionPanelDetail.failed => strings.updatePromptTitleFailed,
};

/// The channel in the reader's words, or as it arrived.
String flareVersionChannelLabel(String channel, FlareStrings strings) =>
    switch (flareVersionChannelText(channel)) {
      FlareVersionChannelText.stable => strings.versionPanelChannelStable,
      FlareVersionChannelText.beta => strings.versionPanelChannelBeta,
      FlareVersionChannelText.internal => strings.versionPanelChannelInternal,
      null => channel,
    };
