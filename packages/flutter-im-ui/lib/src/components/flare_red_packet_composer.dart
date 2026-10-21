import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/directory_data.dart';
import '../models/red_packet.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_segmented_control.dart';
import 'red_packet_tint.dart';

/// The send-a-red-packet form: a kind switch (lucky / normal / exclusive), the
/// amount, the share count (lucky and normal), the [recipient] slot (exclusive),
/// the greeting, the total drawn large and the "塞钱进红包" button.
/// Spec: Message/RedPacketComposer (`FlareRedPacketComposer`).
///
/// Every value is the host's: [kind], [amount], [count] and [greeting] come in
/// and each edit goes out through its `on…Change` callback. The form only
/// restricts the format — digits with at most two decimals for the amount,
/// digits for the count (`spec/red-packet-vectors.json`); ranges, the balance
/// and [total] are computed by the host. The amount label follows the kind:
/// total for lucky, amount each for normal, amount for exclusive. While [busy]
/// every field and the button are locked.
class FlareRedPacketComposer extends StatefulWidget {
  const FlareRedPacketComposer({
    super.key,
    required this.kinds,
    this.kind = FlareRedPacketKind.lucky,
    this.amount = '',
    this.count = 0,
    this.greeting = '',
    this.recipient,
    required this.total,
    this.error,
    this.busy = false,
    this.locked = false,
    this.submitLabel,
    this.onKindChange,
    this.onAmountChange,
    this.onCountChange,
    this.onGreetingChange,
    this.onSubmit,
  });

  /// Kinds the host offers, in segment order; a 1:1 conversation passes only
  /// [FlareRedPacketKind.normal] — no kind switch, no count, and the amount is
  /// labelled plainly. A [kind] outside it shows as the first one.
  final List<FlareRedPacketKind> kinds;
  final FlareRedPacketKind kind;
  final String amount;

  /// Share count for lucky / normal packets in a group; 0 while the field is
  /// empty.
  final int count;
  final String greeting;

  /// The host's member picker for an exclusive packet.
  final Widget? recipient;

  /// The total the host computed, already formatted ("¥0.00").
  final String total;
  final String? error;
  final bool busy;

  /// The original command's outcome is unknown and awaits reconciliation: the
  /// fields and the kind switch are read-only and the button cannot be pressed,
  /// without progress (unlike [busy]). The host usually explains why in a
  /// status banner above the form.
  final bool locked;
  final String? submitLabel;
  final ValueChanged<FlareRedPacketKind>? onKindChange;
  final ValueChanged<String>? onAmountChange;
  final ValueChanged<int>? onCountChange;
  final ValueChanged<String>? onGreetingChange;
  final VoidCallback? onSubmit;

  @override
  State<FlareRedPacketComposer> createState() => _FlareRedPacketComposerState();
}

class _FlareRedPacketComposerState extends State<FlareRedPacketComposer> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.amount,
  );
  late final TextEditingController _count = TextEditingController(
    text: _countText(widget.count),
  );
  late final TextEditingController _greeting = TextEditingController(
    text: widget.greeting,
  );

  static String _countText(int count) => count > 0 ? '$count' : '';

  FlareRedPacketKind get _kind => widget.kinds.contains(widget.kind)
      ? widget.kind
      : (widget.kinds.isEmpty ? widget.kind : widget.kinds.first);

  @override
  void didUpdateWidget(FlareRedPacketComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The host owns the values: a reset or a restored draft replaces the text.
    _sync(_amount, widget.amount);
    _sync(_count, _countText(widget.count));
    _sync(_greeting, widget.greeting);
  }

  void _sync(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _count.dispose();
    _greeting.dispose();
    super.dispose();
  }

  /// Only `normal` on offer is a 1:1 conversation: one packet for the one
  /// peer, so there is no count to ask for and the amount is just the amount
  /// (`spec/red-packet-vectors.json` → composer).
  bool get _direct =>
      widget.kinds.length == 1 &&
      widget.kinds.first == FlareRedPacketKind.normal;

  String _amountLabel(FlareStrings strings) => switch (_kind) {
    FlareRedPacketKind.lucky => strings.packetFieldTotal,
    FlareRedPacketKind.normal =>
      _direct ? strings.packetFieldAmount : strings.packetFieldEach,
    FlareRedPacketKind.exclusive => strings.packetFieldAmount,
  };

  String _kindLabel(FlareStrings strings, FlareRedPacketKind kind) =>
      switch (kind) {
        FlareRedPacketKind.lucky => strings.packetKindLucky,
        FlareRedPacketKind.normal => strings.packetKindNormal,
        FlareRedPacketKind.exclusive => strings.packetKindExclusive,
      };

  void _submit() {
    if (!widget.busy && !widget.locked) widget.onSubmit?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final kind = _kind;
    final error = widget.error;
    return Padding(
      padding: const EdgeInsets.all(FlareSizes.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.kinds.length > 1) ...[
            Semantics(
              label: strings.packetKindPicker,
              container: true,
              child: IgnorePointer(
                ignoring: widget.busy || widget.locked,
                child: FlareSegmentedControl(
                  accent: colors.redPacketAccent,
                  options: [
                    for (final k in widget.kinds) _kindLabel(strings, k),
                  ],
                  selectedIndex: widget.kinds.indexOf(kind),
                  onSelect: (index) {
                    final next = widget.kinds[index];
                    if (next != kind) widget.onKindChange?.call(next);
                  },
                ),
              ),
            ),
            const SizedBox(height: FlareSizes.spacingMd),
          ],
          _group(colors, [
            _field(
              colors,
              label: _amountLabel(strings),
              controller: _amount,
              placeholder: '0.00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              formatter: const FlareRedPacketAmountFormatter(),
              onChanged: (value) => widget.onAmountChange?.call(value),
            ),
            if (kind != FlareRedPacketKind.exclusive && !_direct)
              _field(
                colors,
                label: strings.packetFieldCount,
                controller: _count,
                placeholder: strings.packetCountPlaceholder,
                keyboardType: TextInputType.number,
                formatter: const FlareRedPacketCountFormatter(),
                onChanged: (value) =>
                    widget.onCountChange?.call(flareRedPacketCount(value)),
              ),
            if (kind == FlareRedPacketKind.exclusive)
              _row(
                colors,
                label: strings.packetFieldRecipient,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IgnorePointer(
                    ignoring: widget.busy || widget.locked,
                    child: widget.recipient ?? const SizedBox.shrink(),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: FlareSizes.spacingMd),
          _group(colors, [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingLg,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: FlareSizes.touchTarget,
                ),
                child: Center(
                  // The placeholder is the default greeting, so the field is
                  // named separately for a screen reader.
                  child: MergeSemantics(
                    child: Semantics(
                      label: strings.packetGreetingLabel,
                      child: TextField(
                        controller: _greeting,
                        enabled: !widget.busy,
                        readOnly: widget.locked,
                        style: _inputStyle(colors),
                        decoration: InputDecoration.collapsed(
                          hintText: strings.packetDefaultGreeting,
                          hintStyle: _hintStyle(colors),
                        ),
                        onChanged: (value) =>
                            widget.onGreetingChange?.call(value),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
          if (error != null) ...[
            const SizedBox(height: FlareSizes.spacingMd),
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: TextStyle(
                  color: colors.errorText,
                  fontSize: FlareSizes.fontSizeMd,
                ),
              ),
            ),
          ],
          const SizedBox(height: FlareSizes.spacing2xl),
          Semantics(
            liveRegion: true,
            child: Text(
              widget.total,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: FlareSizes.componentRedPacketAmountFontSize,
                height: FlareSizes.lineHeightTight,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: FlareSizes.spacingXl),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingXl,
            ),
            child: FlareRedPacketTint(
              child: FlareButton(
                block: true,
                size: FlareControlSize.lg,
                label: widget.submitLabel ?? strings.packetSubmit,
                loading: widget.busy,
                disabled: widget.locked,
                onPressed: _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _inputStyle(FlareColors colors) => TextStyle(
    color: widget.busy
        ? colors.textDisabled
        : widget.locked
        ? colors.textSecondary
        : colors.textPrimary,
    fontSize: FlareSizes.fontSizeXl,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  TextStyle _hintStyle(FlareColors colors) =>
      TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeXl);

  Widget _group(FlareColors colors, List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0)
        children.add(Container(height: 1, color: colors.borderSecondary));
      children.add(rows[i]);
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
        border: Border.all(color: colors.borderSecondary),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _row(
    FlareColors colors, {
    required String label,
    required Widget child,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingLg),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: FlareSizes.fontSizeXl,
              ),
            ),
            const SizedBox(width: FlareSizes.spacingMd),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _field(
    FlareColors colors, {
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required TextInputType keyboardType,
    required TextInputFormatter formatter,
    required ValueChanged<String> onChanged,
  }) {
    // One node: the visible label names the field for a screen reader.
    return MergeSemantics(
      child: _row(
        colors,
        label: label,
        child: TextField(
          controller: controller,
          enabled: !widget.busy,
          readOnly: widget.locked,
          keyboardType: keyboardType,
          inputFormatters: [formatter],
          textAlign: TextAlign.end,
          style: _inputStyle(colors),
          decoration: InputDecoration.collapsed(
            hintText: placeholder,
            hintStyle: _hintStyle(colors),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
