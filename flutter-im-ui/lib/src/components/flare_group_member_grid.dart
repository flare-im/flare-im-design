import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// Group member grid — avatars + owner / admin badges + an add-member tile.
/// Spec: Contacts/GroupMemberGrid (`FlareGroupMemberGrid`).
class FlareGroupMemberGrid extends StatelessWidget {
  const FlareGroupMemberGrid({
    super.key,
    required this.members,
    this.ownerId,
    this.adminIds = const [],
    this.showAdd = true,
    this.columns = 5,
    this.onSelect,
    this.onAddMember,
    this.title = '群成员',
    this.ownerLabel = '群主',
    this.adminLabel = '管理员',
    this.addLabel = '加成员',
    this.memberCountText,
  });

  final List<FlareContact> members;
  final String? ownerId;
  final List<String> adminIds;
  final bool showAdd;
  final int columns;
  final void Function(String id)? onSelect;
  final VoidCallback? onAddMember;
  final String title;
  final String ownerLabel;
  final String adminLabel;
  final String addLabel;
  /// Formats the right-side member count (defaults to "N 名成员").
  final String Function(int count)? memberCountText;

  String? _role(FlareContact m) {
    if (m.id == ownerId) return ownerLabel;
    if (adminIds.contains(m.id)) return adminLabel;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.all(FlareSizes.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.fontSizeLg,
                      fontWeight: FontWeight.w600)),
              Text(memberCountText?.call(members.length) ?? '${members.length} 名成员',
                  style: TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
            children: [
              ...members.map((m) => _cell(colors, m)),
              if (showAdd) _addCell(colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(FlareColors colors, FlareContact m) {
    final role = _role(m);
    return GestureDetector(
      onTap: () => onSelect?.call(m.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              FlareAvatar(userId: m.id, displayName: m.name, avatarUrl: m.avatarUrl, size: 48),
              if (role != null)
                Positioned(
                  bottom: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        color: m.id == ownerId ? colors.warning : colors.textTertiary,
                        borderRadius: BorderRadius.circular(999)),
                    child: Text(role, style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(m.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, fontSize: FlareSizes.fontSizeSm)),
        ],
      ),
    );
  }

  Widget _addCell(FlareColors colors) {
    return GestureDetector(
      onTap: onAddMember,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.borderHover, style: BorderStyle.solid),
            ),
            child: Icon(Icons.add, color: colors.textTertiary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(addLabel, style: TextStyle(color: colors.textSecondary, fontSize: FlareSizes.fontSizeSm)),
        ],
      ),
    );
  }
}
