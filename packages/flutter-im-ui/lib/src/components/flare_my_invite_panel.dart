import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../models/invite_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_button.dart';
import 'flare_icon_button.dart';
import 'qr/flare_qr_code_frame.dart';

/// "My invite" — scan or copy an invite, then view permitted referral details.
/// Spec: Profile/MyInvitePanel (`FlareMyInvitePanel`).
///
/// The host fetched all of it and performs every action; this card only shows
/// the snapshot and dispatches intent. It never touches the clipboard.
class FlareMyInvitePanel extends StatelessWidget {
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
    this.title,
    this.showTitle = true,
    this.onCopy,
    this.onLoadMore,
    this.onLoadChildren,
    this.onSelect,
  });

  /// The person's invite code; empty while the host has none yet.
  final String code;

  /// Registration URL encoded in the QR, when available.
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
  final String? title;
  final bool showTitle;

  /// Carries the code.
  final ValueChanged<String>? onCopy;

  final VoidCallback? onLoadMore;

  /// Loads one page below the selected user. The panel manages expansion state.
  final Future<FlareInviteeBranchPage> Function(
    String parentUserId,
    String? cursor,
  )?
  onLoadChildren;

  /// Carries the invitee's userId.
  final ValueChanged<String>? onSelect;

  String _depthLabel(FlareStrings s, FlareReferralDepth depth) =>
      switch (depth) {
        FlareReferralDepth.direct => s.myInviteDirect,
        FlareReferralDepth.l2 => s.myInviteLevel2,
        FlareReferralDepth.l3 => s.myInviteLevel3,
        FlareReferralDepth.total => s.myInviteTotal,
      };

  @override
  Widget build(BuildContext context) {
    final s = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final heading = title ?? s.myInviteTitle;
    final hasCode = code.trim().isNotEmpty;
    final showSkeleton = loading;
    final qrPayload = shareUrl?.trim() ?? '';
    final rows = referralDepthRows(stats, maxDepthShown);
    final showEmpty = !loading && showProfiles && invitees.isEmpty;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: heading,
      child: Container(
        padding: showTitle
            ? const EdgeInsets.all(FlareSizes.spacingMd)
            : EdgeInsets.zero,
        decoration: showTitle
            ? BoxDecoration(
                color: colors.bgPrimary,
                borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
                border: Border.all(color: colors.borderPrimary),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTitle) ...[
              Text(
                heading,
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeLg,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: FlareSizes.spacingMd),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(FlareSizes.spacingLg),
              decoration: BoxDecoration(
                color: colors.bgSelected,
                border: Border.all(color: colors.borderPrimary),
                borderRadius: BorderRadius.circular(FlareSizes.radiusBubble),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSkeleton)
                    Semantics(
                      label: s.myInviteLoading,
                      liveRegion: true,
                      child: _Ghost(
                        width: 160,
                        height: 28,
                        color: colors.bgPrimary,
                      ),
                    )
                  else if (!hasCode)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.all(FlareSizes.spacingSm),
                        child: Text(
                          s.myInviteCodeUnavailable,
                          style: TextStyle(
                            fontSize: FlareSizes.fontSizeMd,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    if (qrPayload.isNotEmpty) ...[
                      Center(
                        child: SizedBox(
                          width: 196,
                          child: FlareQrCodeFrame(
                            payload: qrPayload,
                            name: heading,
                            hint: s.myInviteQrHint,
                          ),
                        ),
                      ),
                      const SizedBox(height: FlareSizes.spacingLg),
                    ],
                    _InviteCodeRow(
                      code: code,
                      onCopy: onCopy == null ? null : () => onCopy!(code),
                    ),
                  ],
                ],
              ),
            ),
            if (rows.isNotEmpty) ...[
              const SizedBox(height: FlareSizes.spacingMd),
              Semantics(
                header: true,
                child: Text(
                  s.myInviteStatsTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: FlareSizes.spacingSm),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = FlareSizes.spacingSm;
                  final columns = constraints.maxWidth >= 400 ? rows.length : 2;
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final depth in rows)
                        SizedBox(
                          width: width,
                          child: _StatTile(
                            label: _depthLabel(s, depth),
                            value: '${stats!.of(depth)}',
                            emphasized: depth == FlareReferralDepth.total,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
            if (showProfiles && maxDepthShown > 0) ...[
              const SizedBox(height: FlareSizes.spacingMd),
              Semantics(
                header: true,
                child: Text(
                  s.myInviteRelationships,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: FlareSizes.spacingSm),
              if (showSkeleton)
                ExcludeSemantics(
                  child: Column(
                    children: [
                      for (var i = 0; i < 3; i++)
                        SizedBox(
                          height: FlareSizes.touchTarget,
                          child: Row(
                            children: [
                              _Ghost(
                                width: FlareSizes.avatarSize,
                                height: FlareSizes.avatarSize,
                                color: colors.bgSecondary,
                                round: true,
                              ),
                              const SizedBox(width: FlareSizes.spacingMd),
                              _Ghost(
                                width: 120,
                                height: FlareSizes.iconSizeSm,
                                color: colors.bgSecondary,
                              ),
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
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeSm,
                      color: colors.textSecondary,
                    ),
                  ),
                )
              else ...[
                for (var i = 0; i < invitees.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: colors.borderSecondary),
                  _InviteTreeNode(
                    key: ValueKey((invitees[i].userId, maxDepthShown)),
                    invitee: invitees[i],
                    levelsRemaining: maxDepthShown.clamp(1, 3),
                    onLoadChildren: onLoadChildren,
                    onSelect: onSelect,
                  ),
                ],
                if (hasMore) ...[
                  const SizedBox(height: FlareSizes.spacingSm),
                  FlareButton(
                    label: s.myInviteLoadMore,
                    variant: FlareButtonVariant.ghost,
                    size: FlareControlSize.sm,
                    block: true,
                    loading: loadingMore,
                    disabled: loadingMore,
                    onPressed: onLoadMore,
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InviteCodeRow extends StatelessWidget {
  const _InviteCodeRow({required this.code, required this.onCopy});

  final String code;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          strings.myInviteCodeLabel,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: FlareSizes.fontSizeSm,
          ),
        ),
        const SizedBox(height: FlareSizes.spacingXs),
        SelectableText(
          code,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: FlareSizes.fontSize4xl,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: colors.primaryText,
          ),
        ),
      ],
    );
    final action = onCopy == null
        ? null
        : FlareButton(
            label: strings.myInviteCopy,
            icon: 'copy',
            size: FlareControlSize.sm,
            maintainTouchTarget: true,
            onPressed: onCopy,
          );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlareSizes.spacingMd,
        vertical: FlareSizes.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (action == null) return content;
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          if (constraints.maxWidth < 240 * textScale) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: FlareSizes.spacingXs),
                Align(alignment: AlignmentDirectional.centerEnd, child: action),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: FlareSizes.spacingSm),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.emphasized,
  });
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Container(
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
          Text(
            label,
            style: TextStyle(
              fontSize: FlareSizes.fontSizeSm,
              color: colors.textTertiary,
            ),
          ),
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

class _InviteTreeNode extends StatefulWidget {
  const _InviteTreeNode({
    super.key,
    required this.invitee,
    required this.levelsRemaining,
    required this.onLoadChildren,
    required this.onSelect,
  });

  final FlareInvitee invitee;
  final int levelsRemaining;
  final Future<FlareInviteeBranchPage> Function(String, String?)?
  onLoadChildren;
  final ValueChanged<String>? onSelect;

  @override
  State<_InviteTreeNode> createState() => _InviteTreeNodeState();
}

class _InviteTreeNodeState extends State<_InviteTreeNode> {
  final _children = <FlareInvitee>[];
  bool _expanded = false;
  bool _loading = false;
  bool _loaded = false;
  bool _failed = false;
  String? _cursor;

  bool get _canExpand =>
      widget.invitee.hasChildren &&
      widget.levelsRemaining > 1 &&
      widget.onLoadChildren != null;

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded && !_loaded && !_failed) _load();
  }

  Future<void> _load() async {
    final load = widget.onLoadChildren;
    if (!_canExpand || _loading || load == null) return;
    final cursor = _cursor;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await load(widget.invitee.userId, cursor);
      if (!mounted) return;
      setState(() {
        final seen = _children.map((child) => child.userId).toSet();
        _children.addAll(
          page.invitees.where((child) => seen.add(child.userId)),
        );
        final next = page.nextCursor;
        _cursor = next == null || next.isEmpty || next == cursor ? null : next;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final invitee = widget.invitee;
    final expanded = _canExpand && _expanded;
    final label =
        (_expanded ? strings.myInviteCollapse : strings.myInviteExpand)
            .replaceAll('{name}', invitee.displayName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _InviteeRow(
                invitee: invitee,
                joined: strings.myInviteJoined.replaceAll(
                  '{date}',
                  inviteJoinedDateLabel(invitee.joinedAt),
                ),
                onTap: widget.onSelect != null
                    ? () => widget.onSelect!(invitee.userId)
                    : _canExpand
                    ? _toggle
                    : null,
              ),
            ),
            if (_canExpand)
              FlareIconButton(
                icon: expanded ? 'chevron-up' : 'chevron-down',
                semanticLabel: label,
                size: FlareControlSize.lg,
                onPressed: _toggle,
              ),
          ],
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: FlareSizes.spacingLg,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(color: colors.borderSecondary),
                ),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: FlareSizes.spacingMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final child in _children)
                      _InviteTreeNode(
                        key: ValueKey(child.userId),
                        invitee: child,
                        levelsRemaining: widget.levelsRemaining - 1,
                        onLoadChildren: widget.onLoadChildren,
                        onSelect: widget.onSelect,
                      ),
                    if (_loading)
                      Semantics(liveRegion: true, child: Text(strings.loading))
                    else if (_failed || _cursor != null)
                      FlareButton(
                        label: _failed
                            ? strings.retry
                            : strings.myInviteLoadMore,
                        size: FlareControlSize.sm,
                        variant: FlareButtonVariant.ghost,
                        maintainTouchTarget: true,
                        onPressed: _load,
                      )
                    else if (_loaded && _children.isEmpty)
                      Text(strings.myInviteNoChildren),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InviteeRow extends StatelessWidget {
  const _InviteeRow({
    required this.invitee,
    required this.joined,
    required this.onTap,
  });
  final FlareInvitee invitee;
  final String joined;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Semantics(
      button: onTap != null,
      label: invitee.displayName,
      child: InkWell(
        onTap: onTap,
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
                        style: TextStyle(
                          fontSize: FlareSizes.fontSizeSm,
                          color: colors.textTertiary,
                        ),
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
  const _Ghost({
    required this.width,
    required this.height,
    required this.color,
    this.round = false,
  });
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
      borderRadius: BorderRadius.circular(
        round ? height / 2 : FlareSizes.radiusSm,
      ),
    ),
  );
}
