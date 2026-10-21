import 'package:flutter/material.dart';
import '../tokens/flare_tokens.dart';
import '../tokens/flare_strings.dart';

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
    this.disabled = false,
    this.busy = false,
    this.statusLabel,
    this.onOpen,
    this.brandLabel,
    this.receivedLabel,
    this.finishedLabel,
    this.openLabel,
  });

  final String blessing;
  final String? amount;
  final bool opened;
  final bool finished;
  final bool disabled;
  final bool busy;
  final String? statusLabel;
  final VoidCallback? onOpen;
  final String? brandLabel;
  final String? receivedLabel;
  final String? finishedLabel;
  final String? openLabel;

  static const Color _foreground = Color(0xFFFFF5E6);
  static const Color _gold = Color(0xFFFFE9B8);
  static const Color _sealInk = Color(0xFFC8291F);

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final status = busy
        ? strings.packetBusy
        : statusLabel ??
              (opened && amount != null
                  ? (receivedLabel != null
                        ? '$receivedLabel$amount'
                        : strings.packetClaimed(amount!))
                  : finished
                  ? finishedLabel ?? strings.packetFinished
                  : disabled
                  ? strings.packetUnavailable
                  : openLabel ?? strings.packetTapToClaim);
    final canOpen = !finished && !disabled && !busy && onOpen != null;
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
          BoxShadow(
            color: Color(0x33C8291F),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacing2md,
          vertical: FlareSizes.spacing2md,
        ),
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
                      Text(
                        blessing,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text.rich(
                        TextSpan(
                          text: status,
                          style: TextStyle(
                            color:
                                !busy &&
                                    statusLabel == null &&
                                    opened &&
                                    amount != null
                                ? _gold
                                : _foreground,
                            fontSize: 12,
                          ),
                        ),
                        softWrap: true,
                      ),
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
              child: Text(
                brandLabel ?? strings.packetBrand,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: FlareSizes.fontSize2xs,
                  fontWeight: FontWeight.w500,
                ),
              ),
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

    return Semantics(
      button: true,
      enabled: canOpen,
      label: blessing,
      value: status,
      liveRegion: busy,
      onTap: canOpen ? onOpen : null,
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: canOpen ? onOpen : null,
            borderRadius: BorderRadius.circular(14),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _seal() {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [_gold, Color(0xFFF6C453)]),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.card_giftcard, size: 22, color: _sealInk),
    );
  }
}
