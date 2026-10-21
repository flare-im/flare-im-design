import 'package:flutter/material.dart';
import '../models/red_packet.dart';
import '../tokens/flare_tokens.dart';
import '../tokens/flare_strings.dart';
import 'red_packet_tint.dart';

/// Red-packet (lucky-money) message card — a tappable envelope with a gold
/// wax seal, blessing text, a claim status line and a brand line.
/// Spec: Message/RedPacketCard (`FlareRedPacketCard`).
///
/// [state] is what the current viewer sees: [FlareRedPacketState.unopened] is
/// the saturated envelope; claimed, finished and expired are the same envelope,
/// quieter — every colour mixed with `redPacketFadedMixTarget` (white in light
/// mode, a deep red in dark mode) by the shared ratio
/// (`FlareSizes.componentRedPacketFadedMix`), the words in `redPacketFadedInk`
/// because white on the light face is under 3:1. Busy and disabled cards keep
/// the unopened face and white words; only the status line changes. Finished and expired cards stay tappable —
/// that is how the viewer reaches the claim details. Only [disabled], [busy]
/// or a missing [onOpen] make the card inert. Status precedence
/// (`spec/red-packet-vectors.json` → card): busy, [statusLabel], received
/// amount, claimed, finished, expired, unavailable, tap to open.
class FlareRedPacketCard extends StatelessWidget {
  const FlareRedPacketCard({
    super.key,
    required this.blessing,
    this.kindLabel,
    this.state = FlareRedPacketState.unopened,
    this.amount,
    this.disabled = false,
    this.busy = false,
    this.statusLabel,
    this.onOpen,
  });

  final String blessing;

  /// Packet kind on the brand line, e.g. "拼手气红包".
  final String? kindLabel;
  final FlareRedPacketState state;

  /// What the viewer received (host formats it); shown on a claimed card.
  final String? amount;
  final bool disabled;
  final bool busy;
  final String? statusLabel;
  final VoidCallback? onOpen;

  /// Key of the small envelope glyph, for tests.
  static const Key glyphKey = Key('flare-red-packet-card-glyph');

  /// The status line this card shows for [strings].
  String statusFor(FlareStrings strings) {
    if (busy) return strings.packetBusy;
    final label = statusLabel;
    if (label != null) return label;
    return switch (state) {
      FlareRedPacketState.claimed =>
        amount != null
            ? strings.packetClaimed(amount!)
            : strings.packetStateClaimed,
      FlareRedPacketState.finished => strings.packetFinished,
      FlareRedPacketState.expired => strings.packetStateExpired,
      FlareRedPacketState.unopened =>
        disabled ? strings.packetUnavailable : strings.packetTapToClaim,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final status = statusFor(strings);
    final dimmed = state != FlareRedPacketState.unopened;
    final receivedAmount =
        !busy &&
        statusLabel == null &&
        state == FlareRedPacketState.claimed &&
        amount != null;
    final canOpen = !disabled && !busy && onOpen != null;
    final palette = _Palette(colors, faded: dimmed);
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
                          color: receivedAmount
                              ? palette.amount
                              : palette.status,
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
            if (kindLabel == null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(strings.packetBrand, style: _brandStyle(palette)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      kindLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _brandStyle(palette),
                    ),
                  ),
                  const SizedBox(width: FlareSizes.spacingSm),
                  Expanded(
                    child: Text(
                      strings.packetBrand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: _brandStyle(palette),
                    ),
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
      hint: kindLabel,
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
      amount = faded ? colors.redPacketFadedInk : colors.redPacketGold,
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
  final Color amount;
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
