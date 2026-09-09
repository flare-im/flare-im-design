import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Why the host cannot show a real profile. Names match the cross-platform
/// contract (Vue `kind` prop / SwiftUI / Compose enums).
enum FlareUnknownUserKind { unknown, deactivated, blocked, unreachable }

/// `row` inside lists, `card` on a detail surface.
enum FlareUnknownUserDensity { row, card }

/// Tone accompanies — never replaces — the icon and the title text.
enum FlareUnknownUserTone { neutral, warning, danger }

/// Icon + tone for one [FlareUnknownUserKind].
@immutable
class FlareUnknownUserPresentation {
  const FlareUnknownUserPresentation(this.kind, this.tone);
  final FlareUnknownUserKind kind;
  final FlareUnknownUserTone tone;
}

/// Icon + tone for [kind]; a null kind degrades to `unknown` rather than
/// rendering blank, so a stale host value can never blank the row.
FlareUnknownUserPresentation unknownUserPresentation(FlareUnknownUserKind? kind) =>
    switch (kind) {
      FlareUnknownUserKind.deactivated => const FlareUnknownUserPresentation(
          FlareUnknownUserKind.deactivated, FlareUnknownUserTone.neutral),
      FlareUnknownUserKind.blocked => const FlareUnknownUserPresentation(
          FlareUnknownUserKind.blocked, FlareUnknownUserTone.danger),
      FlareUnknownUserKind.unreachable => const FlareUnknownUserPresentation(
          FlareUnknownUserKind.unreachable, FlareUnknownUserTone.warning),
      _ => const FlareUnknownUserPresentation(
          FlareUnknownUserKind.unknown, FlareUnknownUserTone.neutral),
    };

/// Default budget for the diagnostic id line; long ids are middle-elided.
const int kFlareUnknownUserIdMaxLength = 24;

/// The user id as it appears in the diagnostic slot: trimmed, and middle-elided
/// to [maxLength] characters (ellipsis included) so a 64-character id never
/// becomes the widest thing on screen. Never used as the title.
String shortenUserId(String? userId, [int maxLength = kFlareUnknownUserIdMaxLength]) {
  final id = (userId ?? '').trim();
  final limit = maxLength < 8 ? 8 : maxLength;
  if (id.length <= limit) return id;
  final head = (limit - 1 + 1) ~/ 2; // ceil((limit - 1) / 2)
  final tail = limit - 1 - head;
  return '${id.substring(0, head)}…${id.substring(id.length - tail)}';
}

/// Placeholder for an account the host cannot describe: an id that resolved to
/// nothing, a deactivated account, a blocked one, or one that is simply not
/// contactable right now. Without it these rows render blank or, worse, show a
/// bare user id as the title. Pure display: no actions, no callbacks, no I/O.
/// Spec: Contacts/UnknownUserPlaceholder.
class FlareUnknownUserPlaceholder extends StatelessWidget {
  const FlareUnknownUserPlaceholder({
    super.key,
    required this.userId,
    required this.kind,
    this.density = FlareUnknownUserDensity.row,
    this.detail,
    this.unknownText = '未知用户',
    this.deactivatedText = '该账号已注销',
    this.blockedText = '该账号已被屏蔽',
    this.unreachableText = '暂时无法联系该账号',
    this.idLabel = 'ID',
    this.idMaxLength = kFlareUnknownUserIdMaxLength,
  });

  /// The id the host failed to resolve. Diagnostic only — never the title.
  final String userId;
  final FlareUnknownUserKind kind;
  final FlareUnknownUserDensity density;

  /// Host-supplied supplement, e.g. where the id came from.
  final String? detail;
  final String unknownText, deactivatedText, blockedText, unreachableText, idLabel;
  final int idMaxLength;

  String get title => switch (unknownUserPresentation(kind).kind) {
        FlareUnknownUserKind.deactivated => deactivatedText,
        FlareUnknownUserKind.blocked => blockedText,
        FlareUnknownUserKind.unreachable => unreachableText,
        FlareUnknownUserKind.unknown => unknownText,
      };

  static IconData iconFor(FlareUnknownUserKind kind) => switch (kind) {
        FlareUnknownUserKind.unknown => Icons.person_outline,
        FlareUnknownUserKind.deactivated => Icons.person_off_outlined,
        FlareUnknownUserKind.blocked => Icons.block,
        FlareUnknownUserKind.unreachable => Icons.lock_outline,
      };

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final presentation = unknownUserPresentation(kind);
    final card = density == FlareUnknownUserDensity.card;
    final fullId = userId.trim();
    final shortId = shortenUserId(userId, idMaxLength);
    final supplement = (detail ?? '').trim();
    final badgeColor = switch (presentation.tone) {
      FlareUnknownUserTone.danger => colors.error,
      FlareUnknownUserTone.warning => colors.warning,
      FlareUnknownUserTone.neutral => colors.textSecondary,
    };
    // The id is diagnostic, so it is read out after the reason, never before it.
    final semanticLabel = [
      title,
      if (supplement.isNotEmpty) supplement,
      if (fullId.isNotEmpty) '$idLabel $fullId',
    ].join(' · ');

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: card ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: colors.bgDisabled, shape: BoxShape.circle),
              child: Icon(iconFor(presentation.kind), size: 14, color: badgeColor),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                textAlign: card ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: card ? FlareSizes.fontSize3xl : FlareSizes.fontSizeLg,
                  fontWeight: FontWeight.w600,
                  height: FlareSizes.lineHeightTight,
                ),
              ),
            ),
          ],
        ),
        if (supplement.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            supplement,
            textAlign: card ? TextAlign.center : TextAlign.start,
            style: TextStyle(color: colors.textSecondary, fontSize: FlareSizes.fontSizeMd),
          ),
        ],
        if (shortId.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(idLabel,
                  style: TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
              const SizedBox(width: 5),
              Flexible(
                // Ids stay LTR even in an RTL layout — they are opaque tokens.
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    shortId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    final avatar = Container(
      width: card ? 64 : FlareSizes.avatarSize,
      height: card ? 64 : FlareSizes.avatarSize,
      decoration: BoxDecoration(color: colors.bgDisabled, shape: BoxShape.circle),
      // Neutral silhouette, never an emoji.
      child: Icon(Icons.person_outline, size: card ? 28 : 20, color: colors.textTertiary),
    );

    return Semantics(
      container: true,
      label: semanticLabel,
      child: card
          ? Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: FlareSizes.spacingLg, vertical: FlareSizes.spacingXl),
              decoration: BoxDecoration(
                color: colors.bgSecondary,
                borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [avatar, const SizedBox(height: FlareSizes.spacingSm), body],
              ),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  avatar,
                  const SizedBox(width: FlareSizes.spacingMd),
                  Expanded(child: body),
                ],
              ),
            ),
    );
  }
}
