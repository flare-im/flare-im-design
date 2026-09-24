import 'dart:async';

import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../models/invite_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_button.dart';

/// "My invite" — the person's invite code with copy / share / regenerate, how
/// many people each referral depth holds, and who they invited directly.
/// Spec: Profile/MyInvitePanel (`FlareMyInvitePanel`).
///
/// The host fetched all of it and performs every action; this card only shows
/// the snapshot and dispatches intent. It never touches the clipboard or a
/// share sheet.
class FlareMyInvitePanel extends StatefulWidget {
  const FlareMyInvitePanel({
    super.key,
    required this.code,
    this.shareUrl,
    this.stats,
    this.maxDepthShown = 3,
    required this.invitees,
    this.showProfiles = true,
    this.hasMore = false,
    this.loadingMore = false,
    this.loading = false,
    this.canRegenerate = false,
    this.regenerateAvailableAt,
    this.regenerating = false,
    this.title,
    this.onCopy,
    this.onShare,
    this.onRegenerate,
    this.onLoadMore,
    this.onSelect,
  });

  /// The person's invite code; empty while the host has none yet.
  final String code;

  /// Host-built share link; shown under the code and carried by [onShare].
  final String? shareUrl;

  /// Referral counts per depth; null while unknown.
  final FlareReferralStats? stats;

  /// Depth rows to show (1–3).
  final int maxDepthShown;

  /// Direct invitees loaded so far.
  final List<FlareInvitee> invitees;

  /// `false` replaces the invitee list with its count.
  final bool showProfiles;
  final bool hasMore;
  final bool loadingMore;

  /// First load in flight — skeleton, never a fake empty list.
  final bool loading;
  final bool canRegenerate;

  /// Epoch ms from which regenerating is allowed again.
  final int? regenerateAvailableAt;
  final bool regenerating;
  final String? title;

  /// Carries the code.
  final ValueChanged<String>? onCopy;

  /// Carries the share URL, or the code when the host built none.
  final ValueChanged<String>? onShare;
  final VoidCallback? onRegenerate;
  final VoidCallback? onLoadMore;

  /// Carries the invitee's userId.
  final ValueChanged<String>? onSelect;

  @override
  State<FlareMyInvitePanel> createState() => _FlareMyInvitePanelState();
}

class _FlareMyInvitePanelState extends State<FlareMyInvitePanel> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // The cooldown is a clock reading; re-read it every half minute so the
    // control re-enables on its own once the server's deadline passes.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _depthLabel(FlareStrings s, FlareReferralDepth depth) => switch (depth) {
    FlareReferralDepth.direct => s.myInviteDirect,
    FlareReferralDepth.l2 => s.myInviteLevel2,
    FlareReferralDepth.l3 => s.myInviteLevel3,
    FlareReferralDepth.total => s.myInviteTotal,
  };

  String _cooldownText(FlareStrings s, FlareInviteCooldown remaining) {
    final unit = switch (remaining.unit) {
      FlareInviteCooldownUnit.minute => s.myInviteUnitMinutes,
      FlareInviteCooldownUnit.hour => s.myInviteUnitHours,
      FlareInviteCooldownUnit.day => s.myInviteUnitDays,
    };
    return s.myInviteCooldown.replaceAll('{time}', unit.replaceAll('{n}', '${remaining.count}'));
  }

  @override
  Widget build(BuildContext context) {
    final s = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final title = widget.title ?? s.myInviteTitle;
    final hasCode = widget.code.trim().isNotEmpty;
    final showSkeleton = widget.loading && !hasCode;
    final regenerate = regenerateAvailability(
      widget.canRegenerate,
      widget.regenerateAvailableAt,
      DateTime.now().millisecondsSinceEpoch,
    );
    final rows = referralDepthRows(widget.stats, widget.maxDepthShown);
    final inviteeCount = widget.stats?.direct ?? widget.invitees.length;
    final showEmpty = !widget.loading && widget.showProfiles && widget.invitees.isEmpty;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: title,
      child: Container(
        padding: const EdgeInsets.all(FlareSizes.spacingMd),
        decoration: BoxDecoration(
          color: colors.bgPrimary,
          borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
          border: Border.all(color: colors.borderPrimary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: FlareSizes.fontSizeLg,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: FlareSizes.spacingMd),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(FlareSizes.spacingMd),
              decoration: BoxDecoration(
                color: colors.bgSecondary,
                borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.myInviteCodeLabel,
                    style: TextStyle(fontSize: FlareSizes.fontSizeSm, color: colors.textTertiary),
                  ),
                  const SizedBox(height: FlareSizes.spacingSm),
                  if (showSkeleton)
                    Semantics(
                      label: s.myInviteLoading,
                      liveRegion: true,
                      child: _Ghost(width: 160, height: 28, color: colors.bgPrimary),
                    )
                  else if (hasCode)
                    SelectableText(
                      widget.code,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontFamilyFallback: const ['Menlo', 'Roboto Mono', 'Courier New'],
                        fontSize: FlareSizes.fontSize4xl,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                        color: colors.primaryText,
                      ),
                    )
                  else
                    Text(
                      s.myInviteCodeUnavailable,
                      style: TextStyle(fontSize: FlareSizes.fontSizeSm, color: colors.textSecondary),
                    ),
                  if (hasCode && widget.shareUrl != null && widget.shareUrl!.isNotEmpty) ...[
                    const SizedBox(height: FlareSizes.spacingXs),
                    Text(
                      widget.shareUrl!,
                      style: TextStyle(fontSize: FlareSizes.fontSizeSm, color: colors.textTertiary),
                    ),
                  ],
                  const SizedBox(height: FlareSizes.spacingSm),
                  Wrap(
                    spacing: FlareSizes.spacingSm,
                    runSpacing: FlareSizes.spacingSm,
                    children: [
                      FlareButton(
                        label: s.myInviteCopy,
                        icon: 'copy',
                        variant: FlareButtonVariant.secondary,
                        size: FlareControlSize.sm,
                        disabled: !hasCode,
                        onPressed: () => widget.onCopy?.call(widget.code),
                      ),
                      FlareButton(
                        label: s.myInviteShare,
                        icon: 'share',
                        variant: FlareButtonVariant.primary,
                        size: FlareControlSize.sm,
                        disabled: !hasCode,
                        onPressed: () => widget.onShare?.call(
                          (widget.shareUrl?.isNotEmpty ?? false) ? widget.shareUrl! : widget.code,
                        ),
                      ),
                      if (regenerate.shown)
                        FlareButton(
                          label: widget.regenerating ? s.myInviteRegenerating : s.myInviteRegenerate,
                          icon: 'refresh',
                          variant: FlareButtonVariant.ghost,
                          size: FlareControlSize.sm,
                          loading: widget.regenerating,
                          disabled: !regenerate.enabled || widget.regenerating || widget.loading,
                          onPressed: widget.onRegenerate,
                        ),
                    ],
                  ),
                  if (regenerate.remaining != null) ...[
                    const SizedBox(height: FlareSizes.spacingXs),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _cooldownText(s, regenerate.remaining!),
                        style: TextStyle(fontSize: FlareSizes.fontSizeSm, color: colors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (rows.isNotEmpty) ...[
              const SizedBox(height: FlareSizes.spacingMd),
              Semantics(
                label: s.myInviteStatsTitle,
                child: Wrap(
                  spacing: FlareSizes.spacingSm,
                  runSpacing: FlareSizes.spacingSm,
                  children: [
                    for (final depth in rows)
                      _StatTile(
                        label: _depthLabel(s, depth),
                        value: '${widget.stats!.of(depth)}',
                        emphasized: depth == FlareReferralDepth.total,
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: FlareSizes.spacingMd),
            Text(
              s.myInviteInviteesTitle,
              style: TextStyle(
                fontSize: FlareSizes.fontSizeMd,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: FlareSizes.spacingSm),
            if (!widget.showProfiles)
              Text(
                s.myInviteCountOnly.replaceAll('{count}', '$inviteeCount'),
                style: TextStyle(fontSize: FlareSizes.fontSizeLg, color: colors.textPrimary),
              )
            else if (showSkeleton)
              ExcludeSemantics(
                child: Column(
                  children: [
                    for (var i = 0; i < 3; i++)
                      SizedBox(
                        height: FlareSizes.touchTarget,
                        child: Row(
                          children: [
                            _Ghost(width: FlareSizes.avatarSize, height: FlareSizes.avatarSize, color: colors.bgSecondary, round: true),
                            const SizedBox(width: FlareSizes.spacingMd),
                            _Ghost(width: 120, height: FlareSizes.iconSizeSm, color: colors.bgSecondary),
                          ],
                        ),
                      ),
                  ],
                ),
              )
            else if (showEmpty)
              Semantics(
                liveRegion: true,
                child: Text(
                  s.myInviteEmpty,
                  style: TextStyle(fontSize: FlareSizes.fontSizeSm, color: colors.textSecondary),
                ),
              )
            else ...[
              for (var i = 0; i < widget.invitees.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.borderSecondary),
                _InviteeRow(
                  invitee: widget.invitees[i],
                  joined: s.myInviteJoined.replaceAll(
                    '{date}',
                    inviteJoinedDateLabel(widget.invitees[i].joinedAt),
                  ),
                  onSelect: widget.onSelect,
                ),
              ],
              if (widget.hasMore) ...[
                const SizedBox(height: FlareSizes.spacingSm),
                FlareButton(
                  label: s.myInviteLoadMore,
                  variant: FlareButtonVariant.ghost,
                  size: FlareControlSize.sm,
                  block: true,
                  loading: widget.loadingMore,
                  disabled: widget.loadingMore,
                  onPressed: widget.onLoadMore,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.emphasized});
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(
        horizontal: FlareSizes.spacingMd,
        vertical: FlareSizes.spacingSm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
        border: Border.all(color: colors.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: FlareSizes.fontSizeSm, color: colors.textTertiary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: FlareSizes.fontSize3xl,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: emphasized ? colors.primaryText : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteeRow extends StatelessWidget {
  const _InviteeRow({required this.invitee, required this.joined, required this.onSelect});
  final FlareInvitee invitee;
  final String joined;
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Semantics(
      button: onSelect != null,
      label: invitee.displayName,
      child: InkWell(
        onTap: onSelect == null ? null : () => onSelect!(invitee.userId),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
            child: Row(
              children: [
                FlareAvatar(
                  userId: invitee.userId,
                  displayName: invitee.displayName,
                  avatarUrl: invitee.avatarUrl,
                  size: FlareSizes.avatarSize,
                ),
                const SizedBox(width: FlareSizes.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        invitee.displayName,
                        style: TextStyle(
                          fontSize: FlareSizes.fontSizeLg,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        joined,
                        style: TextStyle(fontSize: FlareSizes.fontSizeSm, color: colors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Ghost extends StatelessWidget {
  const _Ghost({required this.width, required this.height, required this.color, this.round = false});
  final double width;
  final double height;
  final Color color;
  final bool round;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(round ? height / 2 : FlareSizes.radiusSm),
    ),
  );
}
