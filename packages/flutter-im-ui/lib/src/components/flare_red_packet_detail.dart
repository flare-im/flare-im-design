import 'package:flutter/material.dart';

import '../models/red_packet.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';
import 'flare_avatar.dart';
import 'flare_icon_button.dart';

/// Red packet details — the body of an ordinary page, not an overlay: the host
/// pushes it onto its navigation stack inside a `FlareScreen`, which owns the
/// scrolling. A red arched header, the sender with the kind badge, the
/// blessing, the viewer's own amount drawn large with its note, the summary
/// line and the claim list, with "best luck" on the row the plugin marked.
/// Spec: Message/RedPacketDetail (`FlareRedPacketDetail`).
class FlareRedPacketDetail extends StatelessWidget {
  const FlareRedPacketDetail({
    super.key,
    required this.senderName,
    this.senderAvatar,
    required this.blessing,
    this.kindLabel,
    this.amount,
    this.amountNote,
    required this.summary,
    this.claims = const [],
    this.note,
    this.title,
    this.onBack,
  });

  final String senderName;
  final String? senderAvatar;
  final String blessing;

  /// Short kind badge beside the sender, e.g. "拼".
  final String? kindLabel;

  /// What the viewer received, drawn large (host formats it).
  final String? amount;

  /// Line under the amount, e.g. "已存入钱包".
  final String? amountNote;

  /// Progress line above the list, e.g. "已领取 3/5 个，共 2.10/5.00 元".
  final String summary;
  final List<FlareRedPacketClaim> claims;

  /// Closing explanation, e.g. a refund notice after expiry.
  final String? note;

  /// Title of the red bar drawn when [onBack] is set; defaults to the strings
  /// table's `packetDetailTitle`.
  final String? title;

  /// With it the page draws its own red title bar — back key and [title],
  /// light on the deep red, reaching up under the status bar and running into
  /// the arched header — and the host hides its own navigation bar.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final title = strings.packetFromSender(senderName);
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
                          title,
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
                    if (kindLabel != null) ...[
                      const SizedBox(width: FlareSizes.spacingSm),
                      _kindBadge(colors, kindLabel!),
                    ],
                  ],
                ),
                const SizedBox(height: FlareSizes.spacingSm),
                Text(
                  blessing,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: FlareSizes.fontSizeLg,
                  ),
                ),
                if (amount != null) ...[
                  const SizedBox(height: FlareSizes.spacingMd),
                  Text(
                    amount!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.componentRedPacketAmountFontSize,
                      height: FlareSizes.lineHeightTight,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                if (amountNote != null) ...[
                  const SizedBox(height: FlareSizes.spacingSm),
                  Text(
                    amountNote!,
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
          Container(height: 1, color: colors.borderPrimary),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingLg,
              vertical: FlareSizes.spacingMd,
            ),
            child: Text(
              summary,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: FlareSizes.fontSizeMd,
              ),
            ),
          ),
          Container(height: 1, color: colors.borderPrimary),
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
              label: strings.packetClaims,
              explicitChildNodes: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final claim in claims) _row(colors, strings, claim),
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
                note!,
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

  Widget _row(FlareColors colors, FlareStrings strings, FlareRedPacketClaim c) {
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
                    c.time,
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
                  c.amount,
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
