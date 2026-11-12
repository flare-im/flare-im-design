import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import '../tokens/flare_strings.dart';
import '../models/directory_data.dart';
import 'flare_button.dart';
import 'flare_avatar.dart';
import 'qr/flare_qr_code_frame.dart';

/// QR contact card — an identity header above the user's QR code.
///
/// The kit encodes [qrPayload] itself (byte mode UTF-8, error correction M, the
/// smallest version, 4-module quiet zone) and paints crisp modules, dark on a
/// light panel in both themes, so any scanner reads it. Without a payload — or
/// with one too long for a QR code — the frame says "QR code unavailable"
/// instead; the card never draws a look-alike matrix.
/// Spec: Profile/QRCard (`FlareQRCard`).
class FlareQRCard extends StatelessWidget {
  const FlareQRCard({
    super.key,
    required this.name,
    this.subtitle,
    this.avatarUrl,
    this.qrPayload,
    this.hint,
    this.phase = 'ready',
    this.refreshInMs,
    this.onRefresh,
    this.onSave,
    this.onShare,
  });

  final String phase;
  final int? refreshInMs;
  final VoidCallback? onRefresh, onSave, onShare;
  final String name;
  final String? subtitle;
  final String? avatarUrl;

  /// Text encoded into the code, e.g. the host's add-friend token or link.
  final String? qrPayload;

  /// Scan hint under the code; defaults to [FlareStrings.qrCardHint]. It is
  /// not shown while the code is unavailable.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final s = FlareStrings.of(context);
    final displayPayload = ['ready', 'offline'].contains(phase) && (refreshInMs == null || refreshInMs! > 0) ? qrPayload : null;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2915131C),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FlareAvatar(
                userId: name,
                displayName: name,
                avatarUrl: avatarUrl,
                size: 44,
              ),
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: FlareSizes.fontSize2xl,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: FlareSizes.fontSizeSm,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FlareSizes.spacingLg),
          FlareQrCodeFrame(payload: displayPayload, name: name, hint: hint),
          Wrap(spacing: FlareSizes.spacingSm, children: [
            if (!['loading', 'refreshing'].contains(phase) && onRefresh != null) FlareButton(label: displayPayload == null ? s.retry : s.pluginPageRefresh, variant: FlareButtonVariant.quiet, onPressed: onRefresh),
            if (displayPayload != null && onSave != null) FlareButton(label: s.scanSaveCode, variant: FlareButtonVariant.quiet, onPressed: onSave),
            if (displayPayload != null && onShare != null) FlareButton(label: s.scanShareCode, variant: FlareButtonVariant.quiet, onPressed: onShare),
          ]),
        ],
      ),
    );
  }
}

/// Public matrix surface reused by host-bound plugin QR presentations.
class FlareQrMatrix extends StatelessWidget {
  const FlareQrMatrix({super.key, required this.payload, required this.label, this.size = 240});
  final String? payload;
  final String label;
  final double size;
  @override
  Widget build(BuildContext context) => ConstrainedBox(constraints: BoxConstraints(maxWidth: size), child: FlareQrCodeFrame(payload: payload, name: label, hint: null));
}
