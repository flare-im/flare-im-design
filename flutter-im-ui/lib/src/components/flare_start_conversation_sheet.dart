import 'package:flutter/material.dart';

import '../models/contact_option.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// New-conversation entry — pick a contact (single) or several (group). Spec:
/// Conversation/StartConversationDialog (`FlareStartConversationSheet`).
///
/// Contacts come from the product; [onConfirm] returns the selected ids and the
/// host creates/opens the conversation via the client.
class FlareStartConversationSheet extends StatefulWidget {
  const FlareStartConversationSheet({
    super.key,
    required this.contacts,
    this.allowGroup = true,
    this.busy = false,
    this.onConfirm,
    this.onSearchChanged,
  });

  final List<FlareContactOption> contacts;
  final bool allowGroup;
  final bool busy;

  final void Function(List<String> selectedIds)? onConfirm;
  final ValueChanged<String>? onSearchChanged;

  @override
  State<FlareStartConversationSheet> createState() =>
      _FlareStartConversationSheetState();
}

class _FlareStartConversationSheetState
    extends State<FlareStartConversationSheet> {
  final Set<String> _selected = {};
  String _query = '';

  List<FlareContactOption> get _filtered {
    if (_query.trim().isEmpty) return widget.contacts;
    final q = _query.toLowerCase();
    return widget.contacts
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            (c.subtitle?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final canConfirm = _selected.isNotEmpty && !widget.busy;

    return Material(
      color: colors.bgPrimary,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: FlareSizes.spacingSm),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: colors.borderPrimary,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(FlareSizes.spacingMd),
            child: TextField(
              onChanged: (v) {
                setState(() => _query = v);
                widget.onSearchChanged?.call(v);
              },
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search contacts',
                filled: true,
                fillColor: colors.bgSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Flexible(
            child: _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(FlareSizes.spacing2xl),
                    child: Text('No contacts found',
                        style: TextStyle(color: colors.textTertiary)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final c = _filtered[index];
                      final checked = _selected.contains(c.id);
                      return ListTile(
                        leading: FlareAvatar(
                            userId: c.id,
                            displayName: c.name,
                            avatarUrl: c.avatarUrl,
                            size: 40),
                        title: Text(c.name,
                            style: TextStyle(color: colors.textPrimary)),
                        subtitle: c.subtitle == null
                            ? null
                            : Text(c.subtitle!,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: widget.allowGroup
                            ? Icon(
                                checked
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked,
                                color: checked
                                    ? colors.primary
                                    : colors.textTertiary,
                              )
                            : null,
                        onTap: () {
                          if (!widget.allowGroup) {
                            widget.onConfirm?.call([c.id]);
                            return;
                          }
                          setState(() {
                            if (checked) {
                              _selected.remove(c.id);
                            } else {
                              _selected.add(c.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          if (widget.allowGroup)
            Padding(
              padding: const EdgeInsets.all(FlareSizes.spacingMd),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canConfirm
                      ? () => widget.onConfirm?.call(_selected.toList())
                      : null,
                  style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(
                          vertical: FlareSizes.spacingMd)),
                  child: widget.busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_selected.isEmpty
                          ? 'OK'
                          : 'OK (${_selected.length})'),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}
