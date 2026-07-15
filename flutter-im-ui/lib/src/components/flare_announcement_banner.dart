import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Pinned group-announcement banner — a highlighted, optionally collapsible /
/// dismissible notice. Spec: Chat/AnnouncementBanner (`FlareAnnouncementBanner`).
class FlareAnnouncementBanner extends StatefulWidget {
  const FlareAnnouncementBanner({
    super.key,
    required this.text,
    this.author,
    this.collapsible = true,
    this.dismissible = false,
    this.onClose,
  });

  final String text;
  final String? author;
  final bool collapsible;
  final bool dismissible;
  final VoidCallback? onClose;

  @override
  State<FlareAnnouncementBanner> createState() => _FlareAnnouncementBannerState();
}

class _FlareAnnouncementBannerState extends State<FlareAnnouncementBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final isLong = widget.text.length > 40;
    final showToggle = widget.collapsible && isLong;
    final clamp = widget.collapsible && isLong && !_expanded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: colors.bgSelected,
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        border: Border.all(color: colors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primary.withValues(alpha: 0.82)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.campaign, size: 16, color: Colors.white),
          ),
          const SizedBox(width: FlareSizes.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('Announcement',
                        style: TextStyle(
                            color: colors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    if (widget.author != null && widget.author!.isNotEmpty)
                      Flexible(
                        child: Text(' · ${widget.author!}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: colors.textTertiary, fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(widget.text,
                    maxLines: clamp ? 1 : null,
                    overflow: clamp ? TextOverflow.ellipsis : TextOverflow.clip,
                    style: TextStyle(color: colors.textPrimary, fontSize: 13)),
                if (showToggle) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_expanded ? 'Collapse' : 'Expand',
                            style: TextStyle(
                                color: colors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(width: 2),
                        Transform.rotate(
                          angle: _expanded ? 3.14159 : 0,
                          child: Icon(Icons.expand_more, size: 15, color: colors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.dismissible) ...[
            const SizedBox(width: FlareSizes.spacingSm),
            GestureDetector(
              onTap: widget.onClose,
              child: Icon(Icons.close, size: 16, color: colors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
