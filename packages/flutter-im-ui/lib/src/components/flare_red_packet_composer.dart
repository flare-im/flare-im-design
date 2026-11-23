import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/directory_data.dart';
import '../models/red_packet.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_segmented_control.dart';
import 'flare_status_banner.dart';
import 'flare_tag.dart';
import 'red_packet_tint.dart';
import 'red_packet_arch.dart';

/// The send-a-red-packet form: a kind switch (lucky / normal / exclusive), the
/// amount, the share count (lucky and normal), the [recipient] slot (exclusive),
/// the greeting, the total drawn large and the "塞钱进红包" button.
/// Spec: Message/RedPacketComposer (`FlareRedPacketComposer`).
///
/// Every value is the host's: [kind], [amount], [count] and [greeting] come in
/// and each edit goes out through its `on…Change` callback. The form only
/// restricts the format — digits with at most [currencyExponent] decimals for
/// the amount (none at 0, with a digits-only keyboard), digits for the count
/// (`spec/red-packet-vectors.json`); ranges, the balance and [total] are
/// computed by the host, which turns the amount into minor units with
/// [flareRedPacketAmountMinor]. The amount label follows the kind:
/// total for lucky, amount each for normal, amount for exclusive. While [busy]
/// every field and the button are locked.
///
/// The compact [FlareRedPacketArch] spans the top edge (the host's page header
/// sits right above it); [errorField] puts the host [error] on its row and
/// [focusField] moves focus there (docs/plugin-experience.md §4.2).
class FlareRedPacketComposer extends StatefulWidget {
  const FlareRedPacketComposer({
    super.key,
    required this.kinds,
    this.kind = FlareRedPacketKind.lucky,
    this.amount = '',
    this.currencyExponent = 2,
    this.count = 0,
    this.greeting = '',
    this.recipient,
    required this.total,
    this.error,
    this.busy = false,
    this.locked = false,
    this.submitLabel,
    this.errorField,
    this.focusField,
    this.currencySymbol,
    this.memberCount,
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

  /// The currency's ISO 4217 exponent from the plugin's limits (0 JPY, 2 CNY,
  /// 3 KWD), rounded and held to 0..12: the amount field keeps at most that
  /// many decimals and its placeholder shows that many.
  final int currencyExponent;

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

  /// Where [error] belongs: that row turns `color.message.failed.background`
  /// with the reason under it; [FlareRedPacketField.form] draws a danger
  /// banner above the card, as does null or a row not on screen. A field
  /// error keeps the send key off until the host clears it.
  final FlareRedPacketField? errorField;

  /// Moves focus to this field when it changes (not while busy or locked).
  final FlareRedPacketField? focusField;

  /// The sign before the amount field ("¥"); none when null or empty.
  final String? currencySymbol;

  /// Group chats: how many members, read as "本群共 N 人" under the fields.
  final int? memberCount;
  final ValueChanged<FlareRedPacketKind>? onKindChange;
  final ValueChanged<String>? onAmountChange;
  final ValueChanged<int>? onCountChange;
  final ValueChanged<String>? onGreetingChange;
  final VoidCallback? onSubmit;

  /// The reason under the row [errorField] names (tests).
  static const Key errorCaptionKey = ValueKey(
    'flare-red-packet-composer-error',
  );

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

  final _amountFocus = FocusNode();
  final _countFocus = FocusNode();
  final _greetingFocus = FocusNode();
  // Wraps the host's recipient slot: never a stop itself, focus goes to the
  // slot's first control.
  final _recipientFocus = FocusNode(
    canRequestFocus: false,
    skipTraversal: true,
  );

  static String _countText(int count) => count > 0 ? '$count' : '';

  // shortcut: §4.2's 24-character greeting has no token or contract field;
  // move it there once one exists.
  static const int _greetingMaxLength = 24;

  FlareRedPacketKind get _kind => widget.kinds.contains(widget.kind)
      ? widget.kind
      : (widget.kinds.isEmpty ? widget.kind : widget.kinds.first);

  @override
  void initState() {
    super.initState();
    _focus(widget.focusField);
  }

  @override
  void didUpdateWidget(FlareRedPacketComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The host owns the values: a reset or a restored draft replaces the text.
    _sync(_amount, widget.amount);
    _sync(_count, _countText(widget.count));
    _sync(_greeting, widget.greeting);
    // A new field, or the same one reported with a fresh error (a retry that
    // failed the same way), takes focus again.
    if (widget.focusField != oldWidget.focusField ||
        (widget.error != null && widget.error != oldWidget.error)) {
      _focus(widget.focusField);
    }
  }

  void _focus(FlareRedPacketField? field) {
    if (field == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.busy || widget.locked || widget.kinds.isEmpty) {
        return;
      }
      final node = switch (field) {
        FlareRedPacketField.amount => _amountFocus,
        FlareRedPacketField.count => _countFocus,
        FlareRedPacketField.greeting => _greetingFocus,
        FlareRedPacketField.recipient =>
          _recipientFocus.traversalDescendants.firstOrNull,
        FlareRedPacketField.form => null,
      };
      node?.requestFocus();
    });
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
    _amountFocus.dispose();
    _countFocus.dispose();
    _greetingFocus.dispose();
    _recipientFocus.dispose();
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

  /// §4.2: no sending a zero total or past a field error. The total is the
  /// host's formatted text, so zero is read from the raw [amount] it is built
  /// from: empty or a number equal to 0 makes every kind's total 0; anything
  /// else stays sendable while the host validates.
  bool get _blocked =>
      widget.locked ||
      widget.kinds.isEmpty ||
      (num.tryParse(widget.amount.trim().isEmpty ? '0' : widget.amount) == 0) ||
      (widget.error != null &&
          widget.errorField != null &&
          widget.errorField != FlareRedPacketField.form);

  void _submit() {
    if (!widget.busy && !_blocked) widget.onSubmit?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final kind = _kind;
    final error = widget.error;
    final exponent = flareRedPacketExponent(widget.currencyExponent);
    final off = widget.busy || widget.locked || widget.kinds.isEmpty;
    final showsCount = kind != FlareRedPacketKind.exclusive && !_direct;
    final showsRecipient = kind == FlareRedPacketKind.exclusive;
    // Where the host error goes: its own row, else (form, no field, a row not
    // on screen) a danger banner above the card.
    final errorField = error == null ? null : widget.errorField;
    final onRow = switch (errorField) {
      FlareRedPacketField.amount || FlareRedPacketField.greeting => true,
      FlareRedPacketField.count => showsCount,
      FlareRedPacketField.recipient => showsRecipient,
      _ => false,
    };
    final banner = onRow ? null : error;
    Widget mark(FlareRedPacketField field, Widget row) =>
        onRow && errorField == field ? _invalid(colors, error!, row) : row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Spans the page right under its header, never clipped in a card.
        const FlareRedPacketArch(compact: true),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: FlareSizes.detailPaneMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.all(FlareSizes.spacingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.kinds.length > 1) ...[
                    Semantics(
                      label: strings.packetKindPicker,
                      container: true,
                      // Locked for pointer and keyboard alike.
                      child: ExcludeFocus(
                        excluding: off,
                        child: IgnorePointer(
                          ignoring: off,
                          child: FlareSegmentedControl(
                            accent: colors.redPacketAccent,
                            options: [
                              for (final k in widget.kinds)
                                _kindLabel(strings, k),
                            ],
                            selectedIndex: widget.kinds.indexOf(kind),
                            onSelect: off
                                ? null
                                : (index) {
                                    final next = widget.kinds[index];
                                    if (next != kind) {
                                      widget.onKindChange?.call(next);
                                    }
                                  },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: FlareSizes.spacingMd),
                  ],
                  if (banner != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: FlareStatusBanner(
                        text: banner,
                        tone: FlareStatusTone.danger,
                      ),
                    ),
                    const SizedBox(height: FlareSizes.spacingMd),
                  ],
                  _group(colors, [
                    mark(
                      FlareRedPacketField.amount,
                      _field(
                        colors,
                        label: _amountLabel(strings),
                        controller: _amount,
                        focusNode: _amountFocus,
                        placeholder: flareRedPacketAmountPlaceholder(exponent),
                        keyboardType: exponent == 0
                            ? TextInputType.number
                            : const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                        formatter: FlareRedPacketAmountFormatter(
                          exponent: exponent,
                        ),
                        money: true,
                        // §4.2: a lucky packet marks its total 「拼」.
                        badge: kind == FlareRedPacketKind.lucky
                            ? strings.packetBadgeLuckyShort
                            : null,
                        onChanged: (value) =>
                            widget.onAmountChange?.call(value),
                      ),
                    ),
                    if (showsCount)
                      mark(
                        FlareRedPacketField.count,
                        _field(
                          colors,
                          label: strings.packetFieldCount,
                          controller: _count,
                          focusNode: _countFocus,
                          placeholder: strings.packetCountPlaceholder,
                          keyboardType: TextInputType.number,
                          formatter: const FlareRedPacketCountFormatter(),
                          unit: strings.packetCountUnit.isEmpty
                              ? null
                              : strings.packetCountUnit,
                          onChanged: (value) => widget.onCountChange?.call(
                            flareRedPacketCount(value),
                          ),
                        ),
                      ),
                    if (showsRecipient)
                      mark(
                        FlareRedPacketField.recipient,
                        _row(
                          colors,
                          label: strings.packetFieldRecipient,
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: IgnorePointer(
                              ignoring: off,
                              child: Focus(
                                focusNode: _recipientFocus,
                                child:
                                    widget.recipient ?? const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ]),
                  if (widget.memberCount case final members?)
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        FlareSizes.spacingLg,
                        FlareSizes.spacingXs,
                        FlareSizes.spacingLg,
                        0,
                      ),
                      child: Text(
                        strings.packetGroupMembers.replaceAll(
                          '{count}',
                          '$members',
                        ),
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: FlareSizes.fontSizeSm,
                        ),
                      ),
                    ),
                  const SizedBox(height: FlareSizes.spacingMd),
                  _group(colors, [
                    mark(
                      FlareRedPacketField.greeting,
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FlareSizes.spacingLg,
                        ),
                        child: ConstrainedBox(
                          // §4.2: every form row is the same 56 high.
                          constraints: const BoxConstraints(
                            minHeight:
                                FlareSizes.componentRedPacketFormRowHeight,
                          ),
                          child: Center(
                            // The placeholder is the default greeting, so the
                            // field is named separately for a screen reader.
                            child: MergeSemantics(
                              child: Semantics(
                                label: strings.packetGreetingLabel,
                                child: TextField(
                                  controller: _greeting,
                                  focusNode: _greetingFocus,
                                  enabled:
                                      !widget.busy && widget.kinds.isNotEmpty,
                                  readOnly: widget.locked,
                                  // §4.2: a greeting holds 24 characters.
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(
                                      _greetingMaxLength,
                                    ),
                                  ],
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
                    ),
                  ]),
                  const SizedBox(height: FlareSizes.spacing2xl),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      widget.total,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: flareRedPacketAmountFontSize(context),
                        height: FlareSizes.lineHeightTight,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: FlareSizes.spacingXl),
                  FlareRedPacketTint(
                    child: FlareButton(
                      block: true,
                      size: FlareControlSize.lg,
                      variant: FlareButtonVariant.primary,
                      label: widget.submitLabel ?? strings.packetSubmit,
                      loading: widget.busy,
                      disabled: _blocked,
                      onPressed: _submit,
                    ),
                  ),
                  const SizedBox(height: FlareSizes.spacingSm),
                  Text(
                    strings.packetRefundNotice,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: FlareSizes.fontSizeSm,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The row the host error belongs to: the failed tint and the reason under
  /// it, read out when it appears.
  Widget _invalid(FlareColors colors, String error, Widget row) => ColoredBox(
    color: colors.messageFailedBackground,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FlareSizes.spacingLg,
            0,
            FlareSizes.spacingLg,
            FlareSizes.spacingSm,
          ),
          child: Semantics(
            liveRegion: true,
            child: Text(
              error,
              key: FlareRedPacketComposer.errorCaptionKey,
              style: TextStyle(
                color: colors.messageFailedForeground,
                fontSize: FlareSizes.fontSizeSm,
              ),
            ),
          ),
        ),
      ],
    ),
  );

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
    String? badge,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: FlareSizes.componentRedPacketFormRowHeight,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingLg),
        child: Row(
          children: [
            if (badge != null) ...[
              FlareTag(label: badge),
              const SizedBox(width: FlareSizes.spacingXs),
            ],
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
    required FocusNode focusNode,
    required String placeholder,
    required TextInputType keyboardType,
    required TextInputFormatter formatter,
    required ValueChanged<String> onChanged,
    bool money = false,
    String? badge,
    String? unit,
  }) {
    // The amount is the row's figure: 18/600 after the currency sign.
    TextStyle big(TextStyle style) => money
        ? style.copyWith(
            fontSize: FlareSizes.fontSize3xl,
            fontWeight: FontWeight.w600,
          )
        : style;
    final input = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: !widget.busy && widget.kinds.isNotEmpty,
      readOnly: widget.locked,
      keyboardType: keyboardType,
      inputFormatters: [formatter],
      textAlign: TextAlign.end,
      style: big(_inputStyle(colors)),
      decoration: InputDecoration.collapsed(
        hintText: placeholder,
        hintStyle: big(_hintStyle(colors)),
      ),
      onChanged: onChanged,
    );
    final sign = money ? _currencySign : null;
    // One node: the visible label names the field for a screen reader.
    return MergeSemantics(
      child: _row(
        colors,
        label: label,
        badge: badge,
        child: unit != null
            ? Row(
                children: [
                  Expanded(child: input),
                  const SizedBox(width: FlareSizes.spacingXs),
                  Text(unit, style: _inputStyle(colors)),
                ],
              )
            : sign == null
            ? input
            // The sign sits right before the figure, so the input is only as
            // wide as its text; a tap anywhere on the row still reaches it.
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: focusNode.requestFocus,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(sign, style: big(_inputStyle(colors))),
                    const SizedBox(width: FlareSizes.spacingXs),
                    Flexible(child: IntrinsicWidth(child: input)),
                  ],
                ),
              ),
      ),
    );
  }

  String? get _currencySign {
    final sign = widget.currencySymbol?.trim() ?? '';
    return sign.isEmpty ? null : sign;
  }
}
