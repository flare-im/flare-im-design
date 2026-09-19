import 'flare_button.dart';
import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_icon.dart';
import 'flare_settings_list.dart';

/// Contact profile — hero (avatar / name / star chip), an action row
/// (message / voice / video), a 资料 settings card (Flare ID / 备注 / 描述 /
/// star toggle) and a danger zone (block / remove). Purely presentational: it
/// renders state from props and raises intents; the host owns the edit dialogs
/// and persistence. Spec: Contacts/ContactDetail (`FlareContactDetail`).
///
/// The Flare ID row shows the public [FlareContact.flareId] and is left out
/// without one; the account id is never shown.
///
/// An intent appears only when the host handles it: an action shows only with
/// its callback (no action row without any), 备注 and 描述 are editable rows
/// with a chevron only with their edit callbacks and otherwise read-only values
/// shown only when set, the star toggle needs [onToggleStar], and the danger
/// zone holds only the handled [onBlock] / [onRemove] (none without either). A
/// stranger's profile therefore gets no friend-only controls.
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
    this.extraActions = const [],
    this.onExtraAction,
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
  /// Host actions the kit cannot know about (report, share, an admin tool), drawn with the
  /// kit's own footer buttons; the kit reports the id back and nothing else (FR-046).
  final List<FlareDetailExtraAction> extraActions;
  final ValueChanged<String>? onExtraAction;
  final VoidCallback? onBlock;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final flareId = contact.flareId ?? '';
    final remark = contact.remark ?? '';
    final note = description ?? '';
    final items = [
      // The public handle only: the account id is internal and never shown.
      if (flareId.isNotEmpty)
        FlareSettingsItem(
          key: 'flareId',
          label: labels.flareId,
          icon: 'id',
          kind: FlareSettingKind.value,
          detail: flareId,
        ),
      if (onEditRemark != null || remark.isNotEmpty)
        FlareSettingsItem(
          key: 'remark',
          label: labels.remark,
          icon: 'edit',
          kind: onEditRemark != null
              ? FlareSettingKind.navigation
              : FlareSettingKind.value,
          detail: remark.isNotEmpty ? remark : labels.notSet,
        ),
      if (onEditDescription != null || note.isNotEmpty)
        FlareSettingsItem(
          key: 'description',
          label: labels.description,
          icon: 'comment',
          kind: onEditDescription != null
              ? FlareSettingKind.navigation
              : FlareSettingKind.value,
          detail: note.isNotEmpty ? note : labels.notSet,
        ),
      if (onToggleStar != null)
        FlareSettingsItem(
          key: 'star',
          label: labels.star,
          icon: 'star',
          kind: FlareSettingKind.toggle,
          value: starred,
        ),
    ];
    final actions = [
      if (onMessage != null)
        _action(
          labels.message,
          Icons.chat_bubble_outline_rounded,
          onMessage!,
          primary: true,
        ),
      if (onCall != null) _action(labels.voice, Icons.call_outlined, onCall!),
      if (onVideo != null)
        _action(labels.video, Icons.videocam_outlined, onVideo!),
    ];
    // Rows are tappable only when one of them edits something, so a read-only
    // profile exposes no tap actions at all.
    final editable = onEditRemark != null || onEditDescription != null;
    final dangers = [
      for (final action in extraActions)
        _footButton(
          action.label,
          () => onExtraAction?.call(action.id),
          danger: action.danger,
        ),
      if (onBlock != null) _footButton(labels.block, onBlock!, danger: false),
      if (onRemove != null) _footButton(labels.remove, onRemove!, danger: true),
    ];

    return ListView(
      children: [
        // Hero.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FlareSizes.spacingLg,
            FlareSizes.spacing2xl,
            FlareSizes.spacingLg,
            FlareSizes.spacingMd,
          ),
          child: Column(
            children: [
              FlareAvatar(
                userId: contact.id,
                displayName: contact.name,
                avatarUrl: contact.avatarUrl,
                size: 76,
                presence: contact.presence,
              ),
              const SizedBox(height: FlareSizes.spacingMd),
              Text(
                contact.name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSize4xl,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (contact.signature != null &&
                  contact.signature!.isNotEmpty) ...[
                const SizedBox(height: FlareSizes.spacingXs),
                Text(
                  contact.signature!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: FlareSizes.fontSizeMd,
                  ),
                ),
              ],
              if (starred) ...[
                const SizedBox(height: FlareSizes.spacingSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bgSelected,
                    borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlareIcon(
                        'star',
                        size: FlareSizes.fontSizeSm,
                        color: colors.primaryText,
                      ),
                      const SizedBox(width: FlareSizes.spacingXs),
                      Text(
                        labels.star,
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: FlareSizes.fontSizeSm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Actions the host handles, sharing the row.
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FlareSizes.spacingLg,
              FlareSizes.spacingSm,
              FlareSizes.spacingLg,
              FlareSizes.spacingXs,
            ),
            child: Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: FlareSizes.spacingMd),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ),

        // 资料 settings card, left out when it has no rows.
        if (items.isNotEmpty)
          FlareSettingsList(
            sections: [FlareSettingsSection(title: labels.info, items: items)],
            onSelect: editable
                ? (item) {
                    if (item.key == 'remark') {
                      onEditRemark?.call();
                    } else if (item.key == 'description') {
                      onEditDescription?.call();
                    }
                  }
                : null,
            onToggle: onToggleStar == null
                ? null
                : (item, value) {
                    if (item.key == 'star') onToggleStar!(value);
                  },
            shrinkWrap: true,
          ),

        // Danger zone.
        if (dangers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FlareSizes.spacingLg,
              FlareSizes.spacingSm,
              FlareSizes.spacingLg,
              FlareSizes.spacingLg,
            ),
            child: Column(
              children: [
                for (var i = 0; i < dangers.length; i++) ...[
                  if (i > 0) const SizedBox(height: FlareSizes.spacingMd),
                  dangers[i],
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _action(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool primary = false,
  }) {
    return FlareButton(
      variant: primary
          ? FlareButtonVariant.primary
          : FlareButtonVariant.secondary,
      size: FlareControlSize.lg,
      onPressed: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: FlareSizes.spacingSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: FlareSizes.fontSizeSm)),
        ],
      ),
    );
  }

  Widget _footButton(String label, VoidCallback onTap, {required bool danger}) {
    return FlareButton(
      label: label,
      onPressed: onTap,
      block: true,
      size: FlareControlSize.lg,
      variant: danger
          ? FlareButtonVariant.danger
          : FlareButtonVariant.secondary,
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
