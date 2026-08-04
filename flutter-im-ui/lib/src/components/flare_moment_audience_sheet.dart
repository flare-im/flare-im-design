import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// 发动态时的「谁可以看」。
///
/// 两层正交：[visibility] 圈定人群（0=朋友 1=公开 2=私密），[audienceMode] 在其上
/// 做加减（1=部分可见 2=不给谁看）。
///
/// **两个方向的出错后果不对称**：把「部分可见」设成「不给谁看」，动态会发给你本想
/// 避开的所有人；反过来只是少给几个人看。所以两项不共用措辞，也不共用强调色。
/// Spec: Moments/MomentAudienceSheet (`FlareMomentAudienceSheet`).
class FlareMomentAudienceSheet extends StatelessWidget {
  const FlareMomentAudienceSheet({
    super.key,
    required this.visibility,
    required this.audienceMode,
    required this.audienceUserIds,
    required this.contacts,
    this.labels = const FlareMomentAudienceLabels(),
    this.onVisibilityChanged,
    this.onAudienceChanged,
    this.onClose,
  });

  final int visibility;
  final int audienceMode;
  final List<String> audienceUserIds;
  final List<FlareContactBrief> contacts;
  final FlareMomentAudienceLabels labels;
  final ValueChanged<int>? onVisibilityChanged;
  final void Function(int mode, List<String> userIds)? onAudienceChanged;
  final VoidCallback? onClose;

  /// 私密时名单没有意义：没人看得到，加减谁都不改变结果。
  bool get _audienceApplies => visibility != 2;

  void _pickMode(int mode) {
    // 再点一次当前模式即取消，并清空名单 —— 留着名单而把 mode 归零，
    // 下次切回来会突然冒出一份用户以为已经删掉的名单。
    final next = audienceMode == mode ? 0 : mode;
    onAudienceChanged?.call(next, next == 0 ? const [] : audienceUserIds);
  }

  void _toggle(FlareContactBrief c) {
    final ids = List<String>.from(audienceUserIds);
    ids.contains(c.userId) ? ids.remove(c.userId) : ids.add(c.userId);
    onAudienceChanged?.call(audienceMode, ids);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final picked = audienceUserIds.toSet();

    Widget row({
      required IconData icon,
      required String title,
      required String hint,
      required bool active,
      required VoidCallback onTap,
      Color? activeColor,
      String? trailing,
    }) {
      final tone = active ? (activeColor ?? colors.textPrimary) : colors.textSecondary;
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingSm),
          child: Row(
            children: [
              Icon(icon, size: 16, color: tone),
              const SizedBox(width: FlareSizes.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: TextStyle(color: tone, fontSize: FlareSizes.fontSizeLg)),
                    Text(hint,
                        style: TextStyle(
                            color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
                  ],
                ),
              ),
              if (trailing != null)
                Text(trailing,
                    style:
                        TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm))
              else if (active)
                Icon(Icons.check, size: 16, color: colors.primary),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(FlareSizes.spacingMd),
          child: Text(labels.title,
              style: TextStyle(color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg)),
        ),
        row(
          icon: Icons.people_outline,
          title: labels.friends,
          hint: labels.friendsHint,
          active: visibility == 0,
          onTap: () => onVisibilityChanged?.call(0),
        ),
        row(
          icon: Icons.public,
          title: labels.public,
          hint: labels.publicHint,
          active: visibility == 1,
          onTap: () => onVisibilityChanged?.call(1),
        ),
        row(
          icon: Icons.lock_outline,
          title: labels.private,
          hint: labels.privateHint,
          active: visibility == 2,
          onTap: () => onVisibilityChanged?.call(2),
        ),
        if (_audienceApplies) ...[
          const Divider(height: 1),
          row(
            icon: Icons.person_add_alt,
            title: labels.include,
            hint: labels.includeHint,
            active: audienceMode == 1,
            activeColor: colors.primary,
            onTap: () => _pickMode(1),
            trailing: audienceMode == 1 ? labels.selected(audienceUserIds.length) : null,
          ),
          row(
            icon: Icons.visibility_off_outlined,
            title: labels.exclude,
            hint: labels.excludeHint,
            active: audienceMode == 2,
            activeColor: colors.warning,
            onTap: () => _pickMode(2),
            trailing: audienceMode == 2 ? labels.selected(audienceUserIds.length) : null,
          ),
          if (audienceMode != 0) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingSm),
              child: Text(labels.pick,
                  style:
                      TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView(
                shrinkWrap: true,
                children: contacts
                    .map((c) => InkWell(
                          onTap: () => _toggle(c),
                          child: Container(
                            color: picked.contains(c.userId) ? colors.bgHover : null,
                            padding: const EdgeInsets.symmetric(
                                horizontal: FlareSizes.spacingMd,
                                vertical: FlareSizes.spacingXs),
                            child: Row(
                              children: [
                                FlareAvatar(
                                    userId: c.userId,
                                    displayName: c.displayName,
                                    avatarUrl: c.avatarUrl,
                                    size: 32),
                                const SizedBox(width: FlareSizes.spacingSm),
                                Expanded(
                                  child: Text(c.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: colors.textPrimary,
                                          fontSize: FlareSizes.fontSizeLg)),
                                ),
                                if (picked.contains(c.userId))
                                  Icon(Icons.check, size: 16, color: colors.primary),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(FlareSizes.spacingMd),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: onClose, child: Text(labels.done)),
          ),
        ),
      ],
    );
  }
}

/// Copy for [FlareMomentAudienceSheet]. 两个方向的措辞刻意分开。
class FlareMomentAudienceLabels {
  const FlareMomentAudienceLabels({
    this.title = '谁可以看',
    this.public = '公开',
    this.publicHint = '所有人可见',
    this.friends = '朋友可见',
    this.friendsHint = '你的好友可见',
    this.private = '私密',
    this.privateHint = '仅自己可见',
    this.include = '部分可见',
    this.includeHint = '仅选中的朋友可见',
    this.exclude = '不给谁看',
    this.excludeHint = '选中的朋友看不到',
    this.pick = '选择朋友',
    this.done = '完成',
    this.selected = _defaultSelected,
  });

  final String title;
  final String public;
  final String publicHint;
  final String friends;
  final String friendsHint;
  final String private;
  final String privateHint;
  final String include;
  final String includeHint;
  final String exclude;
  final String excludeHint;
  final String pick;
  final String done;

  /// 「已选 N 人」。回调而非模板串，让复数形式不同的语言也能表达。
  final String Function(int count) selected;

  static String _defaultSelected(int count) => '已选 $count 人';
}
