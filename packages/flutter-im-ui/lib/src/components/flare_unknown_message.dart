import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_icon.dart';

/// What to show for a message this client cannot render. Spec: Message/UnknownMessage.
class FlareUnknownMessagePresentation {
  const FlareUnknownMessagePresentation({
    required this.title,
    required this.body,
    required this.diagnostic,
    required this.hasSummary,
  });

  /// Human title: the host's label, else the generic "unsupported type" wording.
  final String title;

  /// Human body: the sender's fallback text, else the generic hint.
  final String body;

  /// Raw content type for the diagnostic row; empty means render no diagnostic.
  final String diagnostic;

  /// True when [body] is the sender's real fallback rather than the generic hint.
  final bool hasSummary;

  @override
  bool operator ==(Object other) =>
      other is FlareUnknownMessagePresentation &&
      other.title == title &&
      other.body == body &&
      other.diagnostic == diagnostic &&
      other.hasSummary == hasSummary;

  @override
  int get hashCode => Object.hash(title, body, diagnostic, hasSummary);
}

/// Deterministic and side-effect free, so the four platforms cannot drift on
/// which string wins. The raw type token is never promoted to the body: a reader
/// who sees only `[flare.poll.v2]` learns nothing and it reads as a rendering bug.
FlareUnknownMessagePresentation unknownMessagePresentation({
  String? contentType,
  String? label,
  String? summary,
  required String hint,
  required String unsupportedText,
}) {
  String clean(String? value) => (value ?? '').trim();
  final cleanLabel = clean(label);
  final cleanSummary = clean(summary);
  return FlareUnknownMessagePresentation(
    title: cleanLabel.isEmpty ? clean(unsupportedText) : cleanLabel,
    body: cleanSummary.isEmpty ? clean(hint) : cleanSummary,
    diagnostic: clean(contentType),
    hasSummary: cleanSummary.isNotEmpty,
  );
}

/// Body for a message whose content type this client cannot render.
class FlareUnknownMessage extends StatelessWidget {
  const FlareUnknownMessage({
    super.key,
    this.contentType,
    this.label,
    this.summary,
    this.isSelf = false,
    this.actionText = '',
    this.onAction,
    this.hint,
    this.unsupportedText,
    this.diagnosticLabel,
  });

  /// Raw wire content type, e.g. `flare.poll.v2`.
  final String? contentType;

  /// Human name for the type when the host knows it.
  final String? label;

  /// Plain-text fallback the sender's client attached.
  final String? summary;
  final bool isSelf;

  /// Host action label; without [onAction] no button is rendered.
  final String actionText;
  final VoidCallback? onAction;

  /// The generic hint, title and diagnostic label; null reads the kit's words
  /// ([FlareStrings.unknownMessageHint], [FlareStrings.unknownMessageUnsupported],
  /// [FlareStrings.unknownMessageDiagnostic]) in the host's language.
  final String? hint;
  final String? unsupportedText;
  final String? diagnosticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final p = unknownMessagePresentation(
      contentType: contentType,
      label: label,
      summary: summary,
      hint: hint ?? strings.unknownMessageHint,
      unsupportedText: unsupportedText ?? strings.unknownMessageUnsupported,
    );
    // No handler (or no label) means the host cannot act, so no button is offered.
    final showsAction = onAction != null && actionText.trim().isNotEmpty;
    final secondary = isSelf ? null : colors.textSecondary;
    final tertiary = isSelf ? null : colors.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlareIcon('info', size: 16, color: secondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                p.title,
                style: TextStyle(
                  color: secondary,
                  fontSize: FlareSizes.fontSizeMd,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          p.body,
          style: TextStyle(
            fontSize: FlareSizes.fontSizeLg,
            color: isSelf ? null : colors.textPrimary,
          ),
        ),
        if (p.diagnostic.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Text(
                diagnosticLabel ?? strings.unknownMessageDiagnostic,
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeSm,
                  color: tertiary,
                ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  p.diagnostic,
                  style: TextStyle(
                    fontSize: FlareSizes.fontSizeSm,
                    color: tertiary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ],
        if (showsAction) ...[
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              side: BorderSide(color: colors.borderPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
              ),
            ),
            child: Text(
              actionText,
              style: TextStyle(fontSize: FlareSizes.fontSizeMd),
            ),
          ),
        ],
      ],
    );
  }
}
