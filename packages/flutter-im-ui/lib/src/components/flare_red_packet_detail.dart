import 'package:flutter/material.dart';

import '../models/plugin_view.dart' show flarePluginNowMs;
import '../models/red_packet.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';
import 'flare_avatar.dart';
import 'flare_icon_button.dart';

/// Red packet details — the body of an ordinary page, not an overlay: the host
/// pushes it onto its navigation stack inside a `FlareScreen`, which owns the
/// scrolling. Spec: Message/RedPacketDetail (`FlareRedPacketDetail`); red
/// packet v5 §2.
///
/// It draws the plugin's [details] for this viewer and nothing else
/// ([flareRedPacketDetailPresentation], `spec/red-packet-vectors.json` →
/// detail): the viewer's own amount large with "已存入钱包" when the server
/// returned it; a headline for the eligible who came too late ("手慢了，红包派完
/// 了" / "红包已过期") and for a viewer the packet is not meant for ("仅
/// [designatedName] 可领取"); the summary line, with totals only when the
/// server sent them (to the sender); the claim list only when
/// [FlareRedPacketDetailsView.claimsListed], with "best luck" on the row the
/// server marked; the sender's refund note. An amount the server did not send
/// is never drawn. Amounts are formatted from minor units with the
/// currency's exponent ([flareRedPacketMoney]); times read [nowMs] (the plugin
/// view clock, `flarePluginNowMs`, by default).
class FlareRedPacketDetail extends StatelessWidget {
  const FlareRedPacketDetail({
    super.key,
    required this.senderName,
    this.senderAvatar,
    required this.details,
    this.designatedName,
    this.claims = const [],
    this.title,
    this.nowMs,
    this.onBack,
  });

  final String senderName;
  final String? senderAvatar;

  /// The plugin's details result for this viewer.
  final FlareRedPacketDetailsView details;

  /// Exclusive packets: the designated member's name, for "仅 某某 可领取".
  final String? designatedName;

  /// Claim rows, names and avatars from the host's directory; drawn only when
  /// the server lists them.
  final List<FlareRedPacketClaim> claims;

  /// Title of the red bar drawn when [onBack] is set; defaults to the strings
  /// table's `packetDetailTitle`.
  final String? title;

  /// The clock times are read against; null reads `flarePluginNowMs`.
  final int? nowMs;

  /// With it the page draws its own red title bar — back key and [title],
  /// light on the deep red, reaching up under the status bar and running into
  /// the arched header — and the host hides its own navigation bar.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final now = nowMs ?? flarePluginNowMs();
    final view = flareRedPacketDetailPresentation(
      details,
      strings: strings,
      nowMs: now,
      designatedName: designatedName,
    );
    final heading = strings.packetFromSender(senderName);
    final badge = flareRedPacketCardBadge(strings, kind: details.kind).badge;
    final amount = view.amount;
    final headline = view.headline;
    final summary = view.summary;
    final note = view.note;
    return ColoredBox(
      color: colors.bgPrimary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onBack != null) _bar(colors, strings),
          _hero(colors),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FlareSizes.spacingXl,
              FlareSizes.spacing2xl,
              FlareSizes.spacingXl,
              FlareSizes.spacingXl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: FlareAvatar(
                        userId: senderName,
                        displayName: senderName,
                        avatarUrl: senderAvatar,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: FlareSizes.spacingSm),
                    Flexible(
                      child: Semantics(
                        header: true,
                        child: Text(
                          heading,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: FlareSizes.fontSize3xl,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: FlareSizes.spacingSm),
                      _kindBadge(colors, badge),
                    ],
                  ],
                ),
                const SizedBox(height: FlareSizes.spacingSm),
                Text(
                  details.greeting,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: FlareSizes.fontSizeLg,
                  ),
                ),
                if (headline != null) ...[
                  const SizedBox(height: FlareSizes.spacingMd),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      headline,
                      key: headlineKey,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: FlareSizes.fontSizeXl,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (amount != null) ...[
                  const SizedBox(height: FlareSizes.spacingMd),
                  Text(
                    amount,
                    key: amountKey,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.componentRedPacketAmountFontSize,
                      height: FlareSizes.lineHeightTight,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: FlareSizes.spacingSm),
                  Text(
                    strings.packetDeposited,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.warningText,
                      fontSize: FlareSizes.fontSizeMd,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (summary != null || view.claims)
            Container(height: 1, color: colors.borderPrimary),
          if (summary != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingLg,
                vertical: FlareSizes.spacingMd,
              ),
              child: Text(
                summary,
                key: summaryKey,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: FlareSizes.fontSizeMd,
                ),
              ),
            ),
            Container(height: 1, color: colors.borderPrimary),
          ],
          if (view.claims)
            if (claims.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FlareSizes.spacingLg,
                  vertical: FlareSizes.spacingXl,
                ),
                child: Text(
                  strings.packetNoClaims,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: FlareSizes.fontSizeMd,
                  ),
                ),
              )
            else
              Semantics(
                key: claimsKey,
                label: strings.packetClaims,
                explicitChildNodes: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final claim in claims)
                      _row(colors, strings, claim, now),
                  ],
                ),
              ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FlareSizes.spacingLg,
                FlareSizes.spacingLg,
                FlareSizes.spacingLg,
                FlareSizes.spacingXl,
              ),
              child: Text(
                note,
                key: noteKey,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: FlareSizes.fontSizeMd,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The viewer's own amount (tests).
  static const Key amountKey = ValueKey('flare-red-packet-detail-amount');

  /// The headline (tests).
  static const Key headlineKey = ValueKey('flare-red-packet-detail-headline');

  /// The summary line (tests).
  static const Key summaryKey = ValueKey('flare-red-packet-detail-summary');

  /// The claim list (tests).
  static const Key claimsKey = ValueKey('flare-red-packet-detail-claims');

  /// The refund note (tests).
  static const Key noteKey = ValueKey('flare-red-packet-detail-note');

  /// The page's own title bar: the deep red keeps the light title and back
  /// key above 4.5:1, and it reaches up under the status bar.
  Widget _bar(FlareColors colors, FlareStrings strings) => ColoredBox(
    color: colors.redPacketEnd,
    child: SafeArea(
      bottom: false,
      child: SizedBox(
        height: FlareSizes.headerHeight,
        child: Row(
          children: [
            SizedBox(
              width: FlareSizes.touchTarget,
              child: Center(
                child: FlareIconButton(
                  icon: 'back',
                  semanticLabel: strings.back,
                  tintColor: Colors.white,
                  backgroundColor: Colors.transparent,
                  onPressed: onBack,
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title ?? strings.packetDetailTitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: FlareSizes.fontSize2xl,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: FlareSizes.touchTarget),
          ],
        ),
      ),
    ),
  );

  /// The red band that bows out at the bottom, the way the envelope's flap does.
  Widget _hero(FlareColors colors) => LayoutBuilder(
    builder: (context, constraints) => ExcludeSemantics(
      child: Container(
        height: FlareSizes.componentRedPacketDetailHeaderHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Under the title bar the arch starts from the bar's deep red.
            colors: onBack != null
                ? [colors.redPacketEnd, colors.redPacketMiddle]
                : [colors.redPacketMiddle, colors.redPacketStart],
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.elliptical(
              constraints.maxWidth / 2,
              FlareSizes.spacing2xl,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _kindBadge(FlareColors colors, String label) => Container(
    constraints: const BoxConstraints(
      minWidth: FlareSizes.iconSizeMd,
      minHeight: FlareSizes.iconSizeMd,
    ),
    padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingXs),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: colors.redPacketGold,
      borderRadius: BorderRadius.circular(FlareSizes.radiusXs),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: colors.redPacketEnd,
        fontSize: FlareSizes.fontSizeXs,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _row(
    FlareColors colors,
    FlareStrings strings,
    FlareRedPacketClaim c,
    int now,
  ) {
    final amount =
        flareRedPacketMoney(
          c.amountMinor,
          details.currencyExponent,
          details.currency,
        ) ??
        '';
    final time = flareRedPacketTime(c.claimedAtMs, now, strings);
    return MergeSemantics(
      child: Container(
        constraints: const BoxConstraints(
          minHeight: FlareSizes.sessionItemHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingLg,
          vertical: FlareSizes.spacingSm,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.borderSecondary)),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: FlareAvatar(
                userId: c.id,
                displayName: c.name,
                avatarUrl: c.avatar,
                size: FlareSizes.componentMessageAvatarSize,
              ),
            ),
            const SizedBox(width: FlareSizes.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.fontSizeXl,
                    ),
                  ),
                  const SizedBox(height: FlareSizes.spacing3xs),
                  Text(
                    time,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: FlareSizes.fontSizeSm,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: FlareSizes.spacingMd),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: FlareSizes.fontSizeXl,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (c.best) ...[
                  const SizedBox(height: FlareSizes.spacing3xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          flareIconGlyph('star'),
                          size: FlareSizes.iconSizeSm,
                          color: colors.redPacketGoldDeep,
                        ),
                      ),
                      const SizedBox(width: FlareSizes.spacing3xs),
                      Text(
                        strings.packetBestLuck,
                        style: TextStyle(
                          color: colors.warningText,
                          fontSize: FlareSizes.fontSizeXs,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
