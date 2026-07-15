import 'package:flutter/material.dart';

/// Red-packet (lucky-money) message card — a tappable envelope with a gold
/// wax seal, blessing text and a claim status line.
/// Spec: Message/RedPacketCard (`FlareRedPacketCard`).
class FlareRedPacketCard extends StatelessWidget {
  const FlareRedPacketCard({
    super.key,
    required this.blessing,
    this.amount,
    this.opened = false,
    this.finished = false,
    this.onOpen,
  });

  final String blessing;
  final String? amount;
  final bool opened;
  final bool finished;
  final VoidCallback? onOpen;

  static const Color _foreground = Color(0xFFFFF5E6);
  static const Color _gold = Color(0xFFFFE9B8);
  static const Color _sealInk = Color(0xFFC8291F);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 248,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0503C), Color(0xFFE23B2E), Color(0xFFC8291F)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x33C8291F), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _seal(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(blessing,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      _status(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.28)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Flare Packet',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );

    final content = finished
        ? ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.45, 0.45, 0.1, 0, 0, //
              0.45, 0.45, 0.1, 0, 0, //
              0.45, 0.45, 0.1, 0, 0, //
              0, 0, 0, 1, 0, //
            ]),
            child: card,
          )
        : card;

    return GestureDetector(
      onTap: finished ? null : onOpen,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }

  Widget _seal() {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [_gold, Color(0xFFF6C453)],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.card_giftcard, size: 22, color: _sealInk),
    );
  }

  Widget _status() {
    late final String text;
    Color color = _foreground.withValues(alpha: 0.9);
    if (opened && amount != null) {
      return Text.rich(
        TextSpan(
          style: TextStyle(color: color, fontSize: 12),
          children: [
            const TextSpan(text: 'Received · '),
            TextSpan(
                text: amount,
                style: const TextStyle(color: _gold, fontWeight: FontWeight.w600)),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else if (finished) {
      text = 'All claimed';
    } else {
      text = 'Tap to open';
    }
    return Text(text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: 12));
  }
}
