import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// Slash-command menu — the popover the composer shows when a message begins
/// with `/`, listing matching commands.
/// Spec: Message/SlashCommandMenu (`FlareSlashCommandMenu`).
class FlareSlashCommandMenu extends StatelessWidget {
  const FlareSlashCommandMenu({
    super.key,
    required this.commands,
    this.query = '',
    this.onSelect,
    this.onClose,
  });

  final List<FlareSlashCommand> commands;
  final String query;
  final void Function(FlareSlashCommand)? onSelect;
  final VoidCallback? onClose;

  List<FlareSlashCommand> get _filtered {
    var q = query.trim().toLowerCase();
    if (q.startsWith('/')) q = q.substring(1);
    if (q.isEmpty) return commands;
    return commands.where((c) {
      final cmd = c.command.toLowerCase();
      final desc = (c.description ?? '').toLowerCase();
      return cmd.contains(q) || desc.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final rows = _filtered;
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [
          BoxShadow(color: Color(0x2915131C), blurRadius: 28, offset: Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              children: [
                Icon(Icons.terminal, size: 13, color: colors.textTertiary),
                const SizedBox(width: 6),
                Text('COMMANDS',
                    style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8)),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text('No matching commands',
                  style: TextStyle(
                      color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: rows.length,
                itemBuilder: (context, i) => _row(colors, rows[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(FlareColors colors, FlareSlashCommand c) {
    return GestureDetector(
      onTap: () => onSelect?.call(c),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('/${c.command}',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        color: colors.primary,
                        fontSize: FlareSizes.fontSizeMd,
                        fontWeight: FontWeight.w600)),
                if (c.hint != null && c.hint!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(c.hint!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: 'monospace',
                            color: colors.textTertiary,
                            fontSize: FlareSizes.fontSizeSm)),
                  ),
                ],
              ],
            ),
            if (c.description != null && c.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(c.description!,
                  style: TextStyle(
                      color: colors.textSecondary, fontSize: FlareSizes.fontSizeSm)),
            ],
          ],
        ),
      ),
    );
  }
}
