import 'flare_button.dart';
import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_icon.dart';
import 'flare_settings_list.dart';
import 'flare_screen.dart';
import '../tokens/flare_strings.dart';

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
///
/// Someone who is not a contact yet gets the page's main step from the host:
/// [primaryActionLabel] with [onPrimaryAction] leads the action row as the
/// primary key ("添加到通讯录"), and Message, when handled, follows as a
/// secondary key. It is not one of the footer's [extraActions]. While the
/// host runs it, [primaryActionBusy] puts a spinner in place of its icon and
/// takes that key's taps away; the rest of the page stays usable.
///
/// [after] sits below the 资料 card, inside the page's scroll (the host's
/// relation bar for someone who is not a friend). [busy] disables the
/// editable rows and the star toggle while the host writes.
class FlareContactDetail extends StatelessWidget {
  const FlareContactDetail({
    super.key,
    required this.contact,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.primaryActionBusy = false,
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
    this.after,
    this.busy = false,
  });

  final FlareContact contact;

  /// Label of the page's primary action for someone who is not a contact yet;
  /// drawn with [onPrimaryAction].
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  /// The host is carrying out the primary action (sending the friend
  /// request): that key shows a spinner and takes no taps, keys or focus,
  /// and reads as an unavailable button; the other actions stay usable.
  final bool primaryActionBusy;

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
  final Widget? after;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    // The const default means "the environment's language"; labels a host
    // passes still win.
    final labels = identical(this.labels, const FlareContactDetailLabels())
        ? FlareContactDetailLabels.of(FlareStrings.of(context))
        : this.labels;
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
          disabled: busy,
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
          disabled: busy,
          detail: note.isNotEmpty ? note : labels.notSet,
        ),
      if (onToggleStar != null)
        FlareSettingsItem(
          key: 'star',
          label: labels.star,
          icon: 'star',
          kind: FlareSettingKind.toggle,
          disabled: busy,
          value: starred,
        ),
    ];
    final primaryLabel = primaryActionLabel ?? '';
    // The host's primary action leads the row; Message is then a secondary
    // key, so the row has one primary.
    final lead = primaryLabel.isNotEmpty && onPrimaryAction != null;
    // Vue: the primary key fills the row on a page, keeps its size in a detail pane.
    final block = !FlareScreen.detailOf(context);
    final actions = [
      if (lead)
        _action(
          primaryLabel,
          'person-add',
          onPrimaryAction!,
          primary: true,
          block: block,
          busy: primaryActionBusy,
          key: const ValueKey('flare-contact-primary-action'),
        ),
      // Message is a label-only key, as in the Vue kit.
      if (onMessage != null)
        _action(
          labels.message,
          null,
          onMessage!,
          primary: !lead,
          block: block && !lead,
        ),
      if (onCall != null) _action(labels.voice, 'phone', onCall!),
      if (onVideo != null) _action(labels.video, 'video', onVideo!),
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

    final actionRow = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: block ? FlareSizes.spacingMd : 0,
        vertical: FlareSizes.spacingSm,
      ),
      child: Wrap(spacing: FlareSizes.spacing2sm, children: actions),
    );
    final content = ListView(
      children: [
        // Hero: avatar beside the identity (name with the star mark, then the
        // signature), as the Vue kit's compact identity.
        Padding(
          // In a detail pane the screen owns the gutter (Vue `.is-detail`).
          padding: block
              ? const EdgeInsets.fromLTRB(
                  FlareSizes.spacingMd,
                  FlareSizes.spacingLg,
                  FlareSizes.spacingMd,
                  FlareSizes.spacingMd,
                )
              : const EdgeInsets.only(bottom: FlareSizes.spacingMd),
          child: Row(
            children: [
              FlareAvatar(
                userId: contact.id,
                displayName: contact.name,
                avatarUrl: contact.avatarUrl,
                size: 64,
                presence: contact.presence,
              ),
              const SizedBox(width: FlareSizes.spacing2md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Semantics(
                            header: true,
                            child: Text(
                              contact.name,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: FlareSizes.fontSizeXl,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (starred) ...[
                          const SizedBox(width: FlareSizes.spacingSm),
                          Semantics(
                            label: labels.star,
                            child: FlareIcon(
                              'star',
                              size: 16,
                              color: colors.primaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (contact.signature != null &&
                        contact.signature!.isNotEmpty) ...[
                      const SizedBox(height: FlareSizes.spacingXs),
                      Text(
                        contact.signature!,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: FlareSizes.fontSizeMd,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Actions the host handles, sharing the row.
        if (!block && actions.isNotEmpty) actionRow,

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

        ?after,

        // Danger zone.
        if (dangers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FlareSizes.spacingLg,
              FlareSizes.spacingSm,
              FlareSizes.spacingLg,
              FlareSizes.spacingLg,
            ),
            child: Column(children: dangers),
          ),
      ],
    );
    if (!block || actions.isEmpty) return content;
    return Column(
      children: [
        Expanded(child: content),
        ColoredBox(
          color: colors.bgPrimary,
          child: SafeArea(top: false, child: actionRow),
        ),
      ],
    );
  }

  Widget _action(
    String label,
    String? icon,
    VoidCallback onTap, {
    bool primary = false,
    bool block = false,
    bool busy = false,
    Key? key,
  }) {
    return FlareButton(
      key: key,
      label: label,
      icon: icon,
      block: block,
      variant: primary
          ? FlareButtonVariant.primary
          : FlareButtonVariant.secondary,
      size: FlareControlSize.lg,
      maintainTouchTarget: true,
      loading: busy,
      onPressed: onTap,
    );
  }

  Widget _footButton(String label, VoidCallback onTap, {required bool danger}) {
    return FlareButton(
      label: label,
      onPressed: onTap,
      block: true,
      size: FlareControlSize.lg,
      maintainTouchTarget: true,
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

  /// The labels in the environment's language.
  factory FlareContactDetailLabels.of(FlareStrings strings) =>
      FlareContactDetailLabels(
        info: strings.contactDetailInfo,
        remark: strings.contactDetailRemark,
        description: strings.contactDetailDescription,
        star: strings.contactDetailStar,
        notSet: strings.contactDetailNotSet,
        message: strings.sendMessage,
        voice: strings.contactDetailVoice,
        video: strings.contactDetailVideo,
        block: strings.contactDetailBlock,
        remove: strings.contactDetailRemove,
      );
}
