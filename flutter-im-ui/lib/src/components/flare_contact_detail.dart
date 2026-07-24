import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_settings_list.dart';

/// Contact profile — hero (avatar / name / star chip), a 3-up action row
/// (message / voice / video), a 资料 settings card (Flare ID / 备注 / 描述 /
/// star toggle) and a danger zone (block / remove). Purely presentational: it
/// renders state from props and raises intents; the host owns the edit dialogs
/// and the SDK writes. Spec: Contacts/ContactDetail (`FlareContactDetail`).
class FlareContactDetail extends StatelessWidget {
  const FlareContactDetail({
    super.key,
    required this.contact,
    this.starred = false,
    this.description,
    this.labels = const FlareContactDetailLabels(),
    this.onMessage,
    this.onCall,
    this.onVideo,
    this.onEditRemark,
    this.onEditDescription,
    this.onToggleStar,
    this.onBlock,
    this.onRemove,
  });

  final FlareContact contact;

  /// Whether the viewer has starred (favorited) this contact.
  final bool starred;

  /// Free-text description the viewer set for this contact.
  final String? description;

  final FlareContactDetailLabels labels;

  final VoidCallback? onMessage;
  final VoidCallback? onCall;
  final VoidCallback? onVideo;

  /// Edit the remark (备注).
  final VoidCallback? onEditRemark;

  /// Edit the description (描述).
  final VoidCallback? onEditDescription;
  final ValueChanged<bool>? onToggleStar;
  final VoidCallback? onBlock;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final sections = <FlareSettingsSection>[
      FlareSettingsSection(title: labels.info, items: [
        FlareSettingsItem(
            key: 'flareId',
            label: labels.flareId,
            icon: Icons.badge_outlined,
            kind: FlareSettingKind.value,
            detail: contact.id),
        FlareSettingsItem(
            key: 'remark',
            label: labels.remark,
            icon: Icons.edit_outlined,
            kind: FlareSettingKind.value,
            detail: (contact.remark?.isNotEmpty ?? false) ? contact.remark! : labels.notSet),
        FlareSettingsItem(
            key: 'description',
            label: labels.description,
            icon: Icons.notes_outlined,
            kind: FlareSettingKind.value,
            detail: (description?.isNotEmpty ?? false) ? description! : labels.notSet),
        FlareSettingsItem(
            key: 'star',
            label: labels.star,
            icon: Icons.star_outline_rounded,
            kind: FlareSettingKind.toggle,
            value: starred),
      ]),
    ];

    return ListView(
      children: [
        // Hero.
        Padding(
          padding: const EdgeInsets.fromLTRB(FlareSizes.spacingLg,
              FlareSizes.spacing2xl, FlareSizes.spacingLg, FlareSizes.spacingMd),
          child: Column(
            children: [
              FlareAvatar(
                  userId: contact.id,
                  displayName: contact.name,
                  avatarUrl: contact.avatarUrl,
                  size: 84,
                  presence: contact.presence),
              const SizedBox(height: FlareSizes.spacingMd),
              Text(contact.name,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.fontSize4xl,
                      fontWeight: FontWeight.w700)),
              if (contact.signature != null && contact.signature!.isNotEmpty) ...[
                const SizedBox(height: FlareSizes.spacingXs),
                Text(contact.signature!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: FlareSizes.fontSizeLg)),
              ],
              if (starred) ...[
                const SizedBox(height: FlareSizes.spacingSm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.bgSelected,
                    borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
                  ),
                  child: Text('★ ${labels.star}',
                      style: TextStyle(
                          color: colors.primary,
                          fontSize: FlareSizes.fontSizeSm,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ),

        // 3-up actions.
        Padding(
          padding: const EdgeInsets.fromLTRB(FlareSizes.spacingLg, FlareSizes.spacingSm,
              FlareSizes.spacingLg, FlareSizes.spacingXs),
          child: Row(
            children: [
              _action(labels.message, Icons.chat_bubble_outline_rounded, onMessage, colors, primary: true),
              const SizedBox(width: FlareSizes.spacingMd),
              _action(labels.voice, Icons.call_outlined, onCall, colors),
              const SizedBox(width: FlareSizes.spacingMd),
              _action(labels.video, Icons.videocam_outlined, onVideo, colors),
            ],
          ),
        ),

        // 资料 settings card.
        FlareSettingsList(
          sections: sections,
          onSelect: (item) {
            if (item.key == 'remark') onEditRemark?.call();
            else if (item.key == 'description') onEditDescription?.call();
          },
          onToggle: (item, value) {
            if (item.key == 'star') onToggleStar?.call(value);
          },
          shrinkWrap: true,
        ),

        // Danger zone.
        Padding(
          padding: const EdgeInsets.fromLTRB(FlareSizes.spacingLg, FlareSizes.spacingSm,
              FlareSizes.spacingLg, FlareSizes.spacingLg),
          child: Column(
            children: [
              _footButton(labels.block, onBlock, colors, danger: false),
              const SizedBox(height: FlareSizes.spacingMd),
              _footButton(labels.remove, onRemove, colors, danger: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _action(String label, IconData icon, VoidCallback? onTap, FlareColors colors,
      {bool primary = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingMd, horizontal: 4),
          decoration: BoxDecoration(
            color: primary ? colors.primary : colors.bgElevated,
            borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
            boxShadow: [
              BoxShadow(
                color: primary
                    ? colors.primary.withValues(alpha: 0.35)
                    : const Color(0x14151320),
                blurRadius: primary ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: primary ? Colors.white : colors.textSecondary, size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: primary ? Colors.white : colors.textPrimary,
                      fontSize: FlareSizes.fontSizeSm,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footButton(String label, VoidCallback? onTap, FlareColors colors,
      {required bool danger}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: danger ? colors.error : colors.bgElevated,
          borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
          border: danger ? null : Border.all(color: colors.borderPrimary),
        ),
        child: Text(label,
            style: TextStyle(
                color: danger ? Colors.white : colors.textPrimary,
                fontSize: FlareSizes.fontSizeXl,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}

/// Localizable copy for [FlareContactDetail] (Chinese defaults).
class FlareContactDetailLabels {
  const FlareContactDetailLabels({
    this.info = '资料',
    this.flareId = 'Flare ID',
    this.remark = '备注',
    this.description = '描述',
    this.star = '星标好友',
    this.notSet = '未设置',
    this.message = '发消息',
    this.voice = '语音通话',
    this.video = '视频通话',
    this.block = '加入黑名单',
    this.remove = '删除好友',
  });

  final String info;
  final String flareId;
  final String remark;
  final String description;
  final String star;
  final String notSet;
  final String message;
  final String voice;
  final String video;
  final String block;
  final String remove;
}
