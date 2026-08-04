import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// Contact-book match results — who from the user's address book is already here.
///
/// Every row echoes [FlareMatchedContact.matchedBy]: the display name is
/// whatever nickname the other person chose, which often does not match the name
/// in the address book. Without the matched number the user cannot tell who this
/// actually is.
/// Spec: Contacts/ContactMatchList (`FlareContactMatchList`).
class FlareContactMatchList extends StatelessWidget {
  const FlareContactMatchList({
    super.key,
    required this.matches,
    this.loading = false,
    this.labels = const FlareContactMatchLabels(),
    this.onAddFriend,
    this.onOpenConversation,
    this.onSelectContact,
  });

  final List<FlareMatchedContact> matches;
  final bool loading;
  final FlareContactMatchLabels labels;
  final ValueChanged<FlareMatchedContact>? onAddFriend;
  final ValueChanged<FlareMatchedContact>? onOpenConversation;
  final ValueChanged<FlareMatchedContact>? onSelectContact;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);

    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: FlareSizes.spacing2xl),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacing2xl),
        child: Center(
          child: Text(labels.empty,
              style: TextStyle(
                  color: colors.textTertiary, fontSize: FlareSizes.fontSizeMd)),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: matches
          .map((c) => InkWell(
                onTap: onSelectContact == null ? null : () => onSelectContact!(c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingSm),
                  child: Row(
                    children: [
                      FlareAvatar(
                          userId: c.userId,
                          displayName: c.displayName,
                          avatarUrl: c.avatarUrl,
                          size: 40),
                      const SizedBox(width: FlareSizes.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(c.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: FlareSizes.fontSizeLg)),
                            // Weaker than the name: it identifies, it does not label.
                            Text(c.matchedBy,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: colors.textTertiary,
                                    fontSize: FlareSizes.fontSizeSm)),
                          ],
                        ),
                      ),
                      if (c.alreadyFriend)
                        TextButton(
                          onPressed: onOpenConversation == null
                              ? null
                              : () => onOpenConversation!(c),
                          child: Text(labels.message),
                        )
                      else
                        FilledButton.tonal(
                          onPressed: onAddFriend == null ? null : () => onAddFriend!(c),
                          child: Text(labels.add),
                        ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

/// Copy for [FlareContactMatchList].
class FlareContactMatchLabels {
  const FlareContactMatchLabels({
    this.add = '添加',
    this.message = '发消息',
    this.empty = '通讯录里还没有已注册的联系人',
  });

  final String add;
  final String message;
  final String empty;
}
