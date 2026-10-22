import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// The quote of a reply that sits on a card (spec message-surface-vectors
/// rules.cardShell): the bubble puts it here and the card shell draws it
/// inside itself, at its top, instead of wrapping the card in a bubble.
///
/// Every kit card shell reads it — [FlareMessageCardShell], `FlarePluginView`
/// and `FlareRedPacketCard` — and a host's own card builder can place
/// [FlareCardQuote.maybeOf] at the top of its shell the same way.
class FlareCardQuote extends InheritedWidget {
  const FlareCardQuote({super.key, required this.quote, required super.child});

  final Widget quote;

  static Widget? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlareCardQuote>()?.quote;

  @override
  bool updateShouldNotify(FlareCardQuote oldWidget) =>
      quote != oldWidget.quote;
}

/// The kit's message card shell — the card surface of a contact card, link
/// card, poll, task, schedule, mini program, announcement or any built-in
/// card body that has no shell of its own (spec message-surface-vectors
/// rules.cardShell). Primary background, `radius.lg`, a hairline border and
/// `spacing.md` padding, at most `richCardWidth` wide (constrained by the
/// parent). The timeline draws nothing around it: this is the one container.
///
/// A [quote] (by default the nearest [FlareCardQuote]) is drawn inside the
/// shell above the content.
class FlareMessageCardShell extends StatelessWidget {
  const FlareMessageCardShell({
    super.key,
    required this.child,
    this.quote,
    this.padding = const EdgeInsets.all(FlareSizes.spacingMd),
  });

  final Widget child;

  /// The quote slot; null reads [FlareCardQuote].
  final Widget? quote;
  final EdgeInsetsGeometry padding;

  /// Key of the shell's surface (tests).
  static const Key surfaceKey = ValueKey('flare-message-card-shell');

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final quote = this.quote ?? FlareCardQuote.maybeOf(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: FlareSizes.componentRichCardWidth,
      ),
      child: DecoratedBox(
        key: surfaceKey,
        decoration: BoxDecoration(
          color: colors.bgPrimary,
          borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
          border: Border.all(color: colors.borderSecondary),
        ),
        child: Padding(
          padding: padding,
          child: quote == null
              ? child
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    quote,
                    const SizedBox(height: FlareSizes.spacingSm),
                    child,
                  ],
                ),
        ),
      ),
    );
  }
}
