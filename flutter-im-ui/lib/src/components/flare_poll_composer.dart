import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Poll composer — a card for authoring a poll: a question, 2–[maxOptions]
/// answer choices, and a "multiple answers" toggle. Submit is disabled until a
/// question and at least two non-empty options are present.
/// Spec: Composer/PollComposer (`FlarePollComposer`).
class FlarePollComposer extends StatefulWidget {
  const FlarePollComposer({
    super.key,
    this.maxOptions = 10,
    this.onSubmit,
    this.onCancel,
    this.title = '发起投票',
    this.questionPlaceholder = '请输入问题',
    this.addOptionLabel = '添加选项',
    this.multipleLabel = '允许多选',
    this.submitLabel = '创建投票',
    this.optionPlaceholder,
  });

  final int maxOptions;
  final void Function(String question, List<String> options, bool multiple)? onSubmit;
  final VoidCallback? onCancel;
  final String title;
  final String questionPlaceholder;
  final String addOptionLabel;
  final String multipleLabel;
  final String submitLabel;

  /// Formats each option's placeholder (defaults to "选项 N").
  final String Function(int index)? optionPlaceholder;

  @override
  State<FlarePollComposer> createState() => _FlarePollComposerState();
}

class _FlarePollComposerState extends State<FlarePollComposer> {
  final TextEditingController _question = TextEditingController();
  final List<TextEditingController> _options = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _multiple = false;

  @override
  void initState() {
    super.initState();
    _question.addListener(_onChanged);
    for (final c in _options) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _question.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _addOption() {
    if (_options.length >= widget.maxOptions) return;
    setState(() {
      final c = TextEditingController()..addListener(_onChanged);
      _options.add(c);
    });
  }

  void _removeOption(int index) {
    if (_options.length <= 2) return;
    setState(() {
      final c = _options.removeAt(index);
      c.dispose();
    });
  }

  List<String> get _filledOptions =>
      _options.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

  bool get _canSubmit =>
      _question.text.trim().isNotEmpty && _filledOptions.length >= 2;

  void _submit() {
    if (!_canSubmit) return;
    widget.onSubmit?.call(_question.text.trim(), _filledOptions, _multiple);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [
          BoxShadow(color: Color(0x2915131C), blurRadius: 28, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.title,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: FlareSizes.fontSize2xl,
                        fontWeight: FontWeight.w600)),
              ),
              GestureDetector(
                onTap: widget.onCancel,
                child: Icon(Icons.close, size: 18, color: colors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Question field.
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.borderPrimary)),
            ),
            child: TextField(
              controller: _question,
              cursorColor: colors.primary,
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
                hintText: widget.questionPlaceholder,
                hintStyle: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Option rows.
          for (var i = 0; i < _options.length; i++) ...[
            _optionRow(colors, i),
            const SizedBox(height: 10),
          ],
          if (_options.length < widget.maxOptions)
            GestureDetector(
              onTap: _addOption,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 17, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(widget.addOptionLabel,
                      style: TextStyle(
                          color: colors.primary,
                          fontSize: FlareSizes.fontSizeLg,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          const SizedBox(height: 10),
          // Multiple toggle.
          GestureDetector(
            onTap: () => setState(() => _multiple = !_multiple),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  _multiple ? Icons.check_box : Icons.check_box_outlined,
                  size: 20,
                  color: _multiple ? colors.primary : colors.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(widget.multipleLabel,
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: FlareSizes.fontSizeLg)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Submit.
          GestureDetector(
            onTap: _canSubmit ? _submit : null,
            child: Opacity(
              opacity: _canSubmit ? 1 : 0.4,
              child: Container(
                height: 40,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.primary.withValues(alpha: 0.82)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
                ),
                child: Text(widget.submitLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: FlareSizes.fontSizeLg,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionRow(FlareColors colors, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _options[index],
              cursorColor: colors.primary,
              style: TextStyle(
                  color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                border: InputBorder.none,
                hintText: widget.optionPlaceholder?.call(index + 1) ?? '选项 ${index + 1}',
                hintStyle: TextStyle(
                    color: colors.textTertiary, fontSize: FlareSizes.fontSizeLg),
              ),
            ),
          ),
          if (_options.length > 2)
            GestureDetector(
              onTap: () => _removeOption(index),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.close, size: 16, color: colors.textTertiary),
              ),
            ),
        ],
      ),
    );
  }
}
