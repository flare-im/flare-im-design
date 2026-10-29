import 'package:flutter/material.dart';

import '../models/call_record.dart';
import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_call_controls.dart';
import 'flare_icon.dart';
import 'flare_message_card_shell.dart';

/// The call record in the chat timeline — the media icon, one
/// viewer-relative status line, the media name and at most one action.
/// Spec: Call/CallRecordCard (`FlareCallRecordCard`); the rules are the shared
/// table `spec/call-record-vectors.json` ([flareCallRecordStatus],
/// [flareCallRecordTone], [flareCallRecordAction]).
///
/// Presentational only: the host maps the call plugin's record and the
/// viewer's own facts onto these fields, and owns what [onJoin] and
/// [onCallBack] do. [canJoin] (a group call in progress the viewer is not in)
/// and [canCallBack] (calls available for this conversation) are the host's
/// decisions; [disabled] (the plugin is unavailable) keeps the record and
/// drops the action, and [busy] shows the action in progress without taking
/// another tap.
///
/// The card is the message's card surface ([FlareMessageCardShell] at the
/// compact card width): the timeline draws no bubble around it, and a quoted
/// reply ([FlareCardQuote]) sits inside the shell.
class FlareCallRecordCard extends StatelessWidget {
  const FlareCallRecordCard({
    super.key,
    required this.media,
    required this.scope,
    required this.state,
    this.endReason,
    this.durationSeconds,
    this.joinedCount,
    required this.viewerIsInitiator,
    required this.canJoin,
    required this.canCallBack,
    this.disabled = false,
    this.busy = false,
    this.onJoin,
    this.onCallBack,
  });

  final FlareCallMode media;
  final FlareCallRecordScope scope;
  final FlareCallRecordState state;

  /// Why an ended call ended; null reads completed.
  final FlareCallEndReason? endReason;

  /// Talk time of a completed call, in seconds.
  final int? durationSeconds;

  /// People in a group call in progress.
  final int? joinedCount;
  final bool viewerIsInitiator;
  final bool canJoin;
  final bool canCallBack;
  final bool disabled;
  final bool busy;
  final VoidCallback? onJoin;
  final VoidCallback? onCallBack;

  /// Key of the media icon disc, for tests.
  static const Key iconKey = Key('flare-call-record-card-icon');

  /// Key of the action button, for tests.
  static const Key actionKey = Key('flare-call-record-card-action');

  /// The status line this card shows.
  FlareCallRecordStatus get status => flareCallRecordStatus(
    scope: scope,
    state: state,
    viewerIsInitiator: viewerIsInitiator,
    endReason: endReason,
    durationSeconds: durationSeconds,
    joinedCount: joinedCount,
  );

  /// The action this card offers, or null.
  FlareCallRecordAction? get action => flareCallRecordAction(
    scope: scope,
    state: state,
    canJoin: canJoin,
    canCallBack: canCallBack,
    disabled: disabled,
  );

  /// The status line's copy in [strings].
  String statusFor(FlareStrings strings) => flareCallRecordStatusText(
    strings,
    status,
    joinedCount: joinedCount,
    durationSeconds: durationSeconds,
  );

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final text = statusFor(strings);
    final danger = flareCallRecordTone(status) == FlareCallRecordTone.danger;
    final action = this.action;
    final mediaText = media == FlareCallMode.video
        ? strings.callRecordVideo
        : strings.callRecordVoice;
    final accent = danger ? colors.error : colors.primary;
    final ink = danger ? colors.errorText : colors.primaryText;

    return Semantics(
      container: true,
      label: mediaText,
      value: text,
      child: SizedBox(
        width: FlareSizes.componentRichCardCompactWidth,
        child: FlareMessageCardShell(
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  key: iconKey,
                  width: FlareSizes.controlHeightMd,
                  height: FlareSizes.controlHeightMd,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: FlareOpacity.tintWeak),
                    shape: BoxShape.circle,
                  ),
                  child: FlareIcon(
                    media == FlareCallMode.video ? 'video' : 'phone',
                    size: FlareSizes.iconSizeMd,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        text,
                        softWrap: true,
                        style: TextStyle(
                          color: danger ? colors.errorText : colors.textPrimary,
                          fontSize: FlareSizes.fontSizeLg,
                          fontWeight: FontWeight.w500,
                          height: FlareSizes.lineHeightSnug,
                        ),
                      ),
                      const SizedBox(height: FlareSizes.spacing3xs),
                      Text(
                        mediaText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: FlareSizes.fontSizeSm,
                          height: FlareSizes.lineHeightSnug,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: FlareSizes.spacingMd),
                FlareButton(
                  key: actionKey,
                  label: action == FlareCallRecordAction.join
                      ? strings.callRecordJoin
                      : strings.callRecordCallBack,
                  variant: FlareButtonVariant.secondary,
                  size: FlareControlSize.sm,
                  loading: busy,
                  onPressed: action == FlareCallRecordAction.join
                      ? onJoin
                      : onCallBack,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
