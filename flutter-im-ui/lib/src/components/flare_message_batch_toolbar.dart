import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Multi-select batch toolbar — select-all / forward / delete / exit over a set
/// of chosen messages. Spec: Message/MessageBatchToolbar
/// (`FlareMessageBatchToolbar`).
class FlareMessageBatchToolbar extends StatelessWidget {
  const FlareMessageBatchToolbar({
    super.key,
    required this.count,
    required this.total,
    this.busy = false,
    this.onSelectAll,
    this.onForwardEach,
    this.onForwardMerged,
    this.onDelete,
    this.onExit,
    this.selectAllLabel = '全选',
    this.forwardEachLabel = '逐条转发',
    this.forwardMergedLabel = '合并转发',
    this.deleteLabel = '删除',
    this.selectedLabel = '已选',
  });

  final int count;
  final int total;
  final bool busy;
  final VoidCallback? onSelectAll;
  final VoidCallback? onForwardEach;
  final VoidCallback? onForwardMerged;
  final VoidCallback? onDelete;
  final VoidCallback? onExit;
  final String selectAllLabel;
  final String forwardEachLabel;
  final String forwardMergedLabel;
  final String deleteLabel;
  final String selectedLabel;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [
          BoxShadow(color: Color(0x1415131C), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: '$count',
                style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700),
              ),
              TextSpan(text: ' / $total · $selectedLabel', style: TextStyle(color: colors.textSecondary)),
            ]),
            style: const TextStyle(fontSize: FlareSizes.fontSizeMd),
          ),
          const SizedBox(width: FlareSizes.spacingMd),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: FlareSizes.spacingSm,
              runSpacing: FlareSizes.spacingSm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _button(colors,
                    icon: Icons.done_all,
                    label: selectAllLabel,
                    disabled: total == 0 || busy,
                    onTap: onSelectAll),
                _button(colors,
                    icon: Icons.forward,
                    label: forwardEachLabel,
                    disabled: count == 0 || busy,
                    onTap: onForwardEach),
                _button(colors,
                    icon: Icons.library_books_outlined,
                    label: forwardMergedLabel,
                    disabled: count < 2 || busy,
                    onTap: onForwardMerged),
                _button(colors,
                    icon: Icons.delete_outline,
                    label: deleteLabel,
                    color: colors.error,
                    disabled: count == 0 || busy,
                    onTap: onDelete),
                _iconButton(colors, icon: Icons.close, onTap: onExit),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(
    FlareColors colors, {
    required IconData icon,
    required String label,
    required bool disabled,
    Color? color,
    VoidCallback? onTap,
  }) {
    final fg = disabled ? colors.textTertiary : (color ?? colors.textPrimary);
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: FlareSizes.spacingXs),
              Text(label, style: TextStyle(color: fg, fontSize: FlareSizes.fontSizeSm)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton(FlareColors colors, {required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        width: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.bgSecondary,
          borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
        ),
        child: Icon(icon, size: 16, color: colors.textSecondary),
      ),
    );
  }
}
