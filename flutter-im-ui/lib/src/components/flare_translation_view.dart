import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Inline translation block — shows a translated message with a provider
/// footer and a toggle to reveal the original text.
/// Spec: Message/TranslationView (`FlareTranslationView`).
class FlareTranslationView extends StatefulWidget {
  const FlareTranslationView({
    super.key,
    required this.translated,
    this.original,
    this.provider,
    this.pending = false,
    this.translatingLabel = '翻译中…',
    this.translatedLabel = '已翻译',
    this.showOriginalLabel = '显示原文',
    this.hideOriginalLabel = '隐藏原文',
    this.translatedByText,
  });

  final String translated;
  final String? original;
  final String? provider;
  final bool pending;
  final String translatingLabel;
  final String translatedLabel;
  final String showOriginalLabel;
  final String hideOriginalLabel;

  /// Formats the provider footer (defaults to "由 X 翻译").
  final String Function(String provider)? translatedByText;

  @override
  State<FlareTranslationView> createState() => _FlareTranslationViewState();
}

class _FlareTranslationViewState extends State<FlareTranslationView>
    with SingleTickerProviderStateMixin {
  bool _showOriginal = false;
  AnimationController? _spin;

  @override
  void initState() {
    super.initState();
    _maybeStartSpin();
  }

  @override
  void didUpdateWidget(covariant FlareTranslationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pending != oldWidget.pending) _maybeStartSpin();
  }

  void _maybeStartSpin() {
    final spinning =
        widget.pending && !(WidgetsBinding.instance.disableAnimations);
    if (spinning) {
      _spin ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );
      _spin!.repeat();
    } else {
      _spin?.stop();
    }
  }

  @override
  void dispose() {
    _spin?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colors.primary.withValues(alpha: 0.4), width: 2),
        ),
      ),
      child: widget.pending ? _pending(colors) : _content(colors),
    );
  }

  Widget _pending(FlareColors colors) {
    Widget icon = Icon(Icons.translate, size: 14, color: colors.textTertiary);
    if (_spin != null) icon = RotationTransition(turns: _spin!, child: icon);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 8),
        Text(widget.translatingLabel,
            style: TextStyle(
                color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
      ],
    );
  }

  Widget _content(FlareColors colors) {
    final label = widget.provider != null && widget.provider!.isNotEmpty
        ? (widget.translatedByText?.call(widget.provider!) ?? '由 ${widget.provider} 翻译')
        : widget.translatedLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.translated,
            style: TextStyle(
                color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg)),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.translate, size: 11, color: colors.textTertiary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: colors.textTertiary, fontSize: FlareSizes.fontSizeXs)),
            ),
            const SizedBox(width: 10),
            if (widget.original != null && widget.original!.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _showOriginal = !_showOriginal),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_showOriginal ? widget.hideOriginalLabel : widget.showOriginalLabel,
                        style: TextStyle(
                            color: colors.primary,
                            fontSize: FlareSizes.fontSizeXs,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 2),
                    AnimatedRotation(
                      turns: _showOriginal ? 0.5 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(Icons.expand_more,
                          size: 14, color: colors.primary),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (widget.original != null && widget.original!.isNotEmpty && _showOriginal) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.borderPrimary)),
            ),
            padding: const EdgeInsets.only(top: 8),
            child: Text(widget.original!,
                style: TextStyle(
                    color: colors.textSecondary, fontSize: FlareSizes.fontSizeMd)),
          ),
        ],
      ],
    );
  }
}
