import 'package:flutter/material.dart';
import '../models/red_packet.dart';
import '../tokens/flare_tokens.dart';
import '../tokens/flare_strings.dart';
import 'flare_message_card_shell.dart';
import 'red_packet_tint.dart';

/// Red-packet (lucky-money) message card — a tappable envelope with a gold
/// wax seal, the greeting, one status line and a brand line.
/// Spec: Message/RedPacketCard (`FlareRedPacketCard`); red packet v5
/// (docs/design/red-packet-v5-roles-and-wallet.md §1).
///
/// The card never shows an amount, not even the viewer's own. The brand line
/// carries the [kind] badge (拼手气, 专属; a normal packet has none) and, on an
/// exclusive packet, "给 [recipientName]". [state] comes from the plugin's
/// public layer and the viewer's personal layer ([flareRedPacketCardState]):
/// [FlareRedPacketCardState.unopened] and [FlareRedPacketCardState.viewable]
/// are the saturated envelope; claimed, finished, expired and refunded are the
/// same envelope, quieter — every colour mixed with `redPacketFadedMixTarget`
/// (white in light mode, a deep red in dark mode) by the shared ratio
/// (`FlareSizes.componentRedPacketFadedMix`), the words in `redPacketFadedInk`
/// because white on the light face is under 3:1. Busy and disabled cards keep
/// the unopened face; only the status line changes. Every state but busy and
/// disabled stays tappable: the host routes the tap by the personal layer's
/// tapAction (the open sheet, the details, or the not-eligible notice).
/// Status precedence (`spec/red-packet-vectors.json` → card): busy,
/// [statusLabel], then the state's copy ([flareRedPacketCardStatus]).
///
/// The card is the message's card surface: the timeline draws no bubble
/// around it, and a quoted reply ([FlareCardQuote]) sits inside the envelope.
class FlareRedPacketCard extends StatelessWidget {
  const FlareRedPacketCard({
    super.key,
    required this.blessing,
    this.kind = FlareRedPacketKind.normal,
    this.recipientName,
    this.state = FlareRedPacketCardState.unopened,
    this.disabled = false,
    this.busy = false,
    this.statusLabel,
    this.onOpen,
  });

  /// The greeting.
  final String blessing;
  final FlareRedPacketKind kind;

  /// Exclusive packets: the designated member's name (from the IM directory).
  final String? recipientName;
  final FlareRedPacketCardState state;
  final bool disabled;
  final bool busy;
  final String? statusLabel;
  final VoidCallback? onOpen;

  /// Key of the small envelope glyph, for tests.
  static const Key glyphKey = Key('flare-red-packet-card-glyph');

  /// The status line this card shows for [strings].
  String statusFor(FlareStrings strings) => flareRedPacketCardStatus(
    strings,
    state: state,
    busy: busy,
    disabled: disabled,
    statusLabel: statusLabel,
  );

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final status = statusFor(strings);
    final dimmed = flareRedPacketCardDimmed(state);
    final badge = flareRedPacketCardBadge(
      strings,
      kind: kind,
      recipientName: recipientName,
    );
    final canOpen = !disabled && !busy && onOpen != null;
    final palette = _Palette(colors, faded: dimmed);
    final quote = FlareCardQuote.maybeOf(context);
    final kindLine = [
      ?badge.badge,
      ?badge.recipient,
    ].join(' · ');
    final card = Container(
      width: FlareSizes.componentRedPacketCardWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.start, palette.middle, palette.end],
          stops: const [0, 0.52, 1],
        ),
        borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
        boxShadow: dimmed
            ? null
            : [
                BoxShadow(
                  color: colors.redPacketEnd.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(FlareSizes.spacing2md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (quote != null) ...[
              quote,
              const SizedBox(height: FlareSizes.spacingSm),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _glyph(palette),
                const SizedBox(width: FlareSizes.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        blessing,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.text,
                          fontSize: FlareSizes.fontSizeLg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        status,
                        softWrap: true,
                        style: TextStyle(
                          color: palette.status,
                          fontSize: FlareSizes.fontSizeSm,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: FlareSizes.spacingMd),
            Container(height: 1, color: palette.rule),
            const SizedBox(height: FlareSizes.spacingSm),
            if (kindLine.isEmpty)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(strings.packetBrand, style: _brandStyle(palette)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      kindLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _brandStyle(palette),
                    ),
                  ),
                  const SizedBox(width: FlareSizes.spacingSm),
                  Text(
                    strings.packetBrand,
                    maxLines: 1,
                    textAlign: TextAlign.end,
                    style: _brandStyle(palette),
                  ),
                ],
              ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: canOpen,
      label: blessing,
      value: status,
      hint: kindLine.isEmpty ? null : kindLine,
      liveRegion: busy,
      onTap: canOpen ? onOpen : null,
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: canOpen ? onOpen : null,
            borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
            child: card,
          ),
        ),
      ),
    );
  }

  TextStyle _brandStyle(_Palette palette) => TextStyle(
    color: palette.soft,
    fontSize: FlareSizes.fontSize2xs,
    fontWeight: FontWeight.w500,
  );

  Widget _glyph(_Palette palette) => ExcludeSemantics(
    child: CustomPaint(
      key: glyphKey,
      size: const Size(
        _GlyphPainter.width,
        _GlyphPainter.width * _GlyphPainter.aspect,
      ),
      painter: _GlyphPainter(
        body: palette.gold,
        bodyDeep: palette.goldDeep,
        seal: palette.end,
        shadow: palette.flapShadow,
      ),
    ),
  );
}

/// The colours one card paints: the token colours while unopened (and while
/// busy or disabled), each mixed toward the fade target once the packet is
/// spent.
class _Palette {
  _Palette(FlareColors colors, {required bool faded})
    : start = _tone(colors.redPacketStart, colors, faded),
      middle = _tone(colors.redPacketMiddle, colors, faded),
      end = _tone(colors.redPacketEnd, colors, faded),
      gold = _tone(colors.redPacketGold, colors, faded),
      goldDeep = _tone(colors.redPacketGoldDeep, colors, faded),
      text = faded ? colors.redPacketFadedInk : Colors.white,
      status = faded ? colors.redPacketFadedInk : colors.redPacketOnSurface,
      soft = faded
          ? colors.redPacketFadedInk.withValues(alpha: 0.72)
          : colors.redPacketOnSurface.withValues(alpha: 0.6),
      rule = faded
          ? colors.redPacketFadedInk.withValues(alpha: 0.18)
          : colors.redPacketOnSurface.withValues(alpha: 0.28),
      flapShadow = colors.redPacketEnd.withValues(alpha: faded ? 0.12 : 0.25);

  final Color start;
  final Color middle;
  final Color end;
  final Color gold;
  final Color goldDeep;
  final Color text;
  final Color status;
  final Color soft;
  final Color rule;
  final Color flapShadow;

  static Color _tone(Color color, FlareColors colors, bool faded) =>
      faded ? flareRedPacketFaded(color, colors) : color;
}

/// The small gold envelope on a card — body, flap and a red seal — drawn to
/// the same geometry as iOS `RedPacketGlyph` and Compose `RedPacketGlyph`:
/// 30 wide, 1.3 times as tall, corners 0.18 of the width, a flap 0.42 of the
/// height whose curved edge dips 0.3 of the flap below its straight sides, and
/// a seal 0.36 of the width centred on the lowest point of that edge. The body
/// runs gold to goldDeep top to bottom; the flap is goldDeep over a one-pixel
/// shadow of the deep red; the seal is the deep red. A spent card passes the
/// colours already mixed toward the fade target.
class _GlyphPainter extends CustomPainter {
  _GlyphPainter({
    required this.body,
    required this.bodyDeep,
    required this.seal,
    required this.shadow,
  });

  static const double width = 30;
  static const double aspect = 1.3;
  static const double cornerShare = 0.18;
  static const double flapShare = 0.42;
  static const double flapDepthShare = 0.3;
  static const double sealShare = 0.36;

  final Color body;
  final Color bodyDeep;
  final Color seal;
  final Color shadow;

  /// The flap: a rectangle whose bottom edge bows down to [flap] at the middle.
  static Path flapPath(double w, double flap) {
    final side = flap - flap * flapDepthShare;
    // A quadratic curve through (w / 2, flap): its control point sits as far
    // below the curve's lowest point as the sides are above it.
    return Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, side)
      ..quadraticBezierTo(w / 2, flap + (flap - side), 0, side)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final flap = size.height * flapShare;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * cornerShare)),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [body, bodyDeep],
        ).createShader(rect),
    );
    final path = flapPath(size.width, flap);
    canvas.drawPath(
      path.shift(const Offset(0, 1)),
      Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
    );
    canvas.drawPath(path, Paint()..color = bodyDeep);
    canvas.drawCircle(
      Offset(size.width / 2, flap),
      size.width * sealShare / 2,
      Paint()..color = seal,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.body != body ||
      old.bodyDeep != bodyDeep ||
      old.seal != seal ||
      old.shadow != shadow;
}
