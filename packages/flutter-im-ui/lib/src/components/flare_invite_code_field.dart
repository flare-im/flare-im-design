import 'dart:async';

import 'package:flutter/material.dart';

import '../models/invite_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_form_field.dart';
import 'flare_icon.dart';
import 'flare_input.dart';

/// The registration form's invite-code field. Spec: Form/InviteCodeField.
///
/// The tenant decides whether it exists ([mode]), the person types or pastes a
/// code, the field normalizes it the way the server reads it and — once the
/// code is complete — asks the host to pre-check it through [onCheck]. The host
/// owns the request: it sets [checking], then hands back [checkResult] (or an
/// [error] it has already localized). The field never touches the network.
class FlareInviteCodeField extends StatefulWidget {
  const FlareInviteCodeField({
    super.key,
    this.controller,
    this.mode = FlareInviteCodeMode.optional,
    this.prefill,
    this.checking = false,
    this.checkResult,
    this.error,
    this.disabled = false,
    this.length = flareInviteCodeDefaultLength,
    this.label,
    this.placeholder,
    this.onChanged,
    this.onCheck,
  });

  /// Holds the code; its text is kept normalized. Owned by the field when null.
  final TextEditingController? controller;

  /// Tenant invite mode: `off` renders nothing.
  final FlareInviteCodeMode mode;

  /// Deep-link value applied once while the field is empty.
  final String? prefill;

  /// The host's pre-check is in flight.
  final bool checking;

  /// The host's pre-check result for the current code.
  final FlareInviteCodeCheckResult? checkResult;

  /// Host-localized error shown instead of the hint; wins over [checkResult].
  final String? error;
  final bool disabled;

  /// Code length the tenant configured; a check is only requested for a complete code.
  final int length;
  final String? label;
  final String? placeholder;

  /// The normalized code after every change.
  final ValueChanged<String>? onChanged;

  /// A complete, normalized code the host should pre-check; debounced after typing stops.
  final ValueChanged<String>? onCheck;

  @override
  State<FlareInviteCodeField> createState() => _FlareInviteCodeFieldState();
}

class _FlareInviteCodeFieldState extends State<FlareInviteCodeField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  bool _own = false;
  Timer? _timer;
  String? _lastRequested;
  bool _prefillApplied = false;

  @override
  void initState() {
    super.initState();
    _own = widget.controller == null;
    _controller.addListener(_onText);
    _applyPrefill();
  }

  @override
  void didUpdateWidget(covariant FlareInviteCodeField old) {
    super.didUpdateWidget(old);
    if (old.prefill != widget.prefill || old.mode != widget.mode) _applyPrefill();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_onText);
    if (_own) _controller.dispose();
    super.dispose();
  }

  // Deep-link prefill: applied once, while the field is empty, and checked like
  // a paste. A person who clears the field afterwards is not re-filled.
  void _applyPrefill() {
    final prefill = widget.prefill;
    if (_prefillApplied || widget.mode == FlareInviteCodeMode.off) return;
    if (prefill == null || prefill.isEmpty || _controller.text.isNotEmpty) return;
    final next = normalizeInviteCode(prefill, widget.length);
    if (next.isEmpty) return;
    _prefillApplied = true;
    _controller.text = next;
  }

  void _onText() {
    final next = normalizeInviteCode(_controller.text, widget.length);
    if (next != _controller.text) {
      // Normalize in place, cursor at the end: the person sees what the server reads.
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
      return; // the listener runs again with the normalized text
    }
    widget.onChanged?.call(next);
    _scheduleCheck(next);
    if (mounted) setState(() {});
  }

  // Debounced pre-check: one request about 400 ms after the last keystroke, and
  // only for a complete code.
  void _scheduleCheck(String value) {
    _timer?.cancel();
    _timer = null;
    final code = inviteCodeToCheck(
      value: value,
      length: widget.length,
      mode: widget.mode,
      disabled: widget.disabled,
    );
    if (code == null) {
      _lastRequested = null;
      return;
    }
    if (code == _lastRequested) return;
    _timer = Timer(flareInviteCheckDebounce, () {
      _timer = null;
      _lastRequested = code;
      widget.onCheck?.call(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = inviteCodeFieldState(
      mode: widget.mode,
      value: _controller.text,
      checking: widget.checking,
      checkResult: widget.checkResult,
      error: widget.error,
      disabled: widget.disabled,
    );
    if (state == FlareInviteCodeFieldState.off) return const SizedBox.shrink();
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    // A stale result for another code must not be shown as this code's verdict.
    final resultMatches = widget.checkResult == null ||
        inviteCodeToCheck(value: _controller.text, length: widget.length) != null;
    final inviter = widget.checkResult?.inviterDisplayName?.trim();
    final String? errorLine = widget.error != null && widget.error!.isNotEmpty
        ? widget.error
        : (state == FlareInviteCodeFieldState.invalid && resultMatches
            ? strings.inviteCodeInvalid
            : null);
    final String? hint = widget.mode == FlareInviteCodeMode.optional &&
            state == FlareInviteCodeFieldState.idle
        ? strings.inviteCodeOptional
        : null;
    Widget? status;
    if (state == FlareInviteCodeFieldState.checking) {
      status = _StatusLine(
        leading: SizedBox(
          width: FlareSizes.iconSizeSm,
          height: FlareSizes.iconSizeSm,
          child: CircularProgressIndicator(strokeWidth: 2, color: colors.textSecondary),
        ),
        text: strings.inviteCodeChecking,
        color: colors.textSecondary,
      );
    } else if (state == FlareInviteCodeFieldState.valid && resultMatches) {
      status = _StatusLine(
        leading: FlareIcon('success', size: FlareSizes.iconSizeSm, color: colors.successText),
        text: inviter != null && inviter.isNotEmpty
            ? strings.inviteCodeInviter.replaceAll('{name}', inviter)
            : strings.inviteCodeValid,
        color: colors.successText,
      );
    }
    return FlareFormField(
      label: widget.label ?? strings.inviteCodeLabel,
      required: widget.mode == FlareInviteCodeMode.required,
      hint: hint,
      error: errorLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FlareInput(
            controller: _controller,
            placeholder: widget.placeholder ?? strings.inviteCodePlaceholder,
            disabled: widget.disabled,
            monospace: true,
          ),
          if (status != null) ...[
            const SizedBox(height: FlareSizes.spacing2xs),
            Semantics(liveRegion: true, child: status),
          ],
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.leading, required this.text, required this.color});
  final Widget leading;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      leading,
      const SizedBox(width: FlareSizes.spacing2xs),
      Flexible(
        child: Text(text, style: TextStyle(fontSize: FlareSizes.fontSizeSm, color: color)),
      ),
    ],
  );
}
