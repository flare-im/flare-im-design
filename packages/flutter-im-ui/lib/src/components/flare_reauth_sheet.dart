import 'package:flutter/material.dart';
import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import '../tokens/flare_strings.dart';
import 'flare_button.dart';
import 'flare_input.dart';
import 'flare_select.dart';
import 'flare_form_field.dart';
import 'flare_status_banner.dart';

/// Masked display copy and an opaque SDK id. Never a login credential or proof.
class FlareReauthDestination {
  const FlareReauthDestination({
    required this.id,
    required this.label,
    this.detail,
  });
  final String id, label;
  final String? detail;
}

/// Host-driven OTP form body; the host owns presentation, timing and all effects.
class FlareReauthSheet extends StatefulWidget {
  const FlareReauthSheet({
    super.key,
    this.title,
    this.subtitle,
    required this.destinations,
    required this.selectedId,
    required this.code,
    this.codeLength = 6,
    this.sending = false,
    this.submitting = false,
    required this.canSend,
    required this.canSubmit,
    this.resendInSeconds = 0,
    this.error,
    this.notice,
    required this.onSelectDestination,
    required this.onCodeChange,
    required this.onSend,
    required this.onSubmit,
    required this.onCancel,
  });
  final String? title, subtitle, error, notice;
  final List<FlareReauthDestination> destinations;
  final String selectedId, code;
  final int codeLength, resendInSeconds;
  final bool sending, submitting, canSend, canSubmit;
  final ValueChanged<String> onSelectDestination, onCodeChange;
  final VoidCallback onSend, onSubmit, onCancel;
  @override
  State<FlareReauthSheet> createState() => _FlareReauthSheetState();
}

class _FlareReauthSheetState extends State<FlareReauthSheet> {
  late final _code = TextEditingController(text: widget.code);
  bool _syncing = false;
  @override
  void didUpdateWidget(FlareReauthSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_code.text != widget.code) {
      _syncing = true;
      _code.text = widget.code;
      _syncing = false;
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = FlareStrings.of(context), colors = FlareColors.of(context);
    final selected = widget.destinations
        .where((item) => item.id == widget.selectedId)
        .firstOrNull;
    final busy = widget.sending || widget.submitting;
    final canSend =
        widget.canSend &&
        selected != null &&
        !busy &&
        widget.resendInSeconds <= 0;
    final canSubmit = widget.canSubmit && selected != null && !busy;
    return Padding(
      padding: const EdgeInsets.all(FlareSizes.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title ?? s.reauthTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: FlareSizes.fontSizeLg,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.subtitle != null)
            Text(
              widget.subtitle!,
              style: TextStyle(color: colors.textSecondary),
            ),
          if (widget.notice != null)
            FlareStatusBanner(text: widget.notice!, tone: FlareStatusTone.info),
          if (widget.error != null)
            FlareStatusBanner(
              text: widget.error!,
              tone: FlareStatusTone.danger,
            ),
          if (widget.destinations.isEmpty)
            FlareStatusBanner(
              text: s.reauthUnavailable,
              tone: FlareStatusTone.warning,
            ),
          const SizedBox(height: FlareSizes.spacingMd),
          FlareFormField(
            label: s.reauthDestination,
            hint: selected?.detail,
            child: FlareSelect(
              options: [
                for (final item in widget.destinations)
                  FlareSelectOption(value: item.id, label: item.label),
              ],
              value: widget.selectedId,
              disabled: busy || widget.destinations.isEmpty,
              onChanged: widget.onSelectDestination,
            ),
          ),
          const SizedBox(height: FlareSizes.spacingMd),
          FlareFormField(
            label: s.reauthCode,
            child: FlareInput(
              controller: _code,
              maxLength: widget.codeLength,
              disabled: busy,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              monospace: true,
              onChanged: (value) {
                if (!_syncing) widget.onCodeChange(value);
              },
              onSubmitted: (_) {
                if (canSubmit) widget.onSubmit();
              },
            ),
          ),
          const SizedBox(height: FlareSizes.spacingMd),
          FlareButton(
            label: widget.resendInSeconds > 0
                ? s.reauthResendIn.replaceAll(
                    '{seconds}',
                    '${widget.resendInSeconds}',
                  )
                : s.reauthSendCode,
            variant: FlareButtonVariant.secondary,
            disabled: !canSend,
            loading: widget.sending,
            onPressed: canSend ? widget.onSend : null,
          ),
          const SizedBox(height: FlareSizes.spacingSm),
          FlareButton(
            label: s.confirm,
            disabled: !canSubmit,
            loading: widget.submitting,
            onPressed: canSubmit ? widget.onSubmit : null,
          ),
          FlareButton(
            label: s.cancel,
            variant: FlareButtonVariant.quiet,
            onPressed: widget.onCancel,
          ),
        ],
      ),
    );
  }
}
