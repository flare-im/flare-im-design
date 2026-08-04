import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// Moments visibility list — the members under one rule, with add / remove.
///
/// Two rule kinds exist and they point in **opposite** directions: hide-from
/// controls who cannot see me, mute controls whose posts I do not see. Getting
/// them backwards is not a cosmetic bug — it leaks moments to someone the user
/// meant to hide from — so title, hint, empty copy and accent colour are all
/// keyed off [kind] rather than shared.
/// Spec: Moments/MomentsVisibilityRuleList (`FlareMomentsVisibilityRuleList`).
class FlareMomentsVisibilityRuleList extends StatelessWidget {
  const FlareMomentsVisibilityRuleList({
    super.key,
    required this.kind,
    required this.members,
    this.loading = false,
    this.labels = const FlareMomentsVisibilityLabels(),
    this.onAdd,
    this.onRemove,
    this.onSelectMember,
  });

  final FlareMomentsVisibilityRuleKind kind;
  final List<FlareContactBrief> members;
  final bool loading;
  final FlareMomentsVisibilityLabels labels;
  final VoidCallback? onAdd;
  final ValueChanged<FlareContactBrief>? onRemove;
  final ValueChanged<FlareContactBrief>? onSelectMember;

  bool get _isHideFrom => kind == FlareMomentsVisibilityRuleKind.hideFrom;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(FlareSizes.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  _isHideFrom ? Icons.visibility_off_outlined : Icons.volume_off_outlined,
                  size: 16,
                  // Distinct accents so both rules on one screen stay tellable apart.
                  color: _isHideFrom ? colors.warning : colors.textTertiary,
                ),
              ),
              const SizedBox(width: FlareSizes.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_isHideFrom ? labels.hideFromTitle : labels.muteTitle,
                        style: TextStyle(
                            color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg)),
                    const SizedBox(height: 2),
                    Text(_isHideFrom ? labels.hideFromHint : labels.muteHint,
                        style: TextStyle(
                            color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onAdd,
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.person_add_alt, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: FlareSizes.spacingLg),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (members.isEmpty)
          Padding(
            padding: const EdgeInsets.only(
                left: FlareSizes.spacingMd,
                right: FlareSizes.spacingMd,
                bottom: FlareSizes.spacingLg),
            child: Text(labels.empty,
                style: TextStyle(
                    color: colors.textTertiary, fontSize: FlareSizes.fontSizeMd)),
          )
        else
          ...members.map((m) => InkWell(
                onTap: onSelectMember == null ? null : () => onSelectMember!(m),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingXs),
                  child: Row(
                    children: [
                      FlareAvatar(
                          userId: m.userId,
                          displayName: m.displayName,
                          avatarUrl: m.avatarUrl,
                          size: 32),
                      const SizedBox(width: FlareSizes.spacingSm),
                      Expanded(
                        child: Text(m.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: FlareSizes.fontSizeLg)),
                      ),
                      TextButton(
                        onPressed: onRemove == null ? null : () => onRemove!(m),
                        child: Text(labels.remove,
                            style: const TextStyle(fontSize: FlareSizes.fontSizeMd)),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}

/// Copy for [FlareMomentsVisibilityRuleList]. Kept per-kind on purpose.
class FlareMomentsVisibilityLabels {
  const FlareMomentsVisibilityLabels({
    this.hideFromTitle = '不让他看我的朋友圈',
    this.hideFromHint = '名单中的人看不到你发的内容',
    this.muteTitle = '不看他的朋友圈',
    this.muteHint = '你不会看到名单中的人发的内容',
    this.empty = '名单为空',
    this.remove = '移出',
  });

  final String hideFromTitle;
  final String hideFromHint;
  final String muteTitle;
  final String muteHint;
  final String empty;
  final String remove;
}
