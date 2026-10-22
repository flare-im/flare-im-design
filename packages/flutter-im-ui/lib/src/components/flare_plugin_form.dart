import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/contact_picker.dart';
import '../models/directory_data.dart';
import '../models/plugin_view.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_contact_picker.dart';
import 'flare_date_picker.dart';
import 'flare_form_field.dart';
import 'flare_icon_button.dart';
import 'flare_input.dart';
import 'flare_radio_group.dart';
import 'flare_switch.dart';
import 'flare_textarea.dart';
import 'flare_time_picker.dart';

/// The inputs of a plugin action (spec Form/PluginForm), put on the kit sheet
/// by the host (or by [FlarePluginView] for a card action).
///
/// The kit checks only required and length — at once for an input that was
/// edited, for every input after a submit attempt; the core SDK's
/// validate_form decides, and its [errors] show under their inputs until the
/// input is edited. [onSubmit] receives the cleaned values
/// (spec/plugin-view-vectors.json → form).
class FlarePluginForm extends StatefulWidget {
  const FlarePluginForm({
    super.key,
    required this.inputs,
    this.values,
    this.errors = const [],
    this.submitLabel,
    this.busy = false,
    this.error,
    this.members = const [],
    this.onSubmit,
    this.onCancel,
  });

  final List<FlarePluginInput> inputs;

  /// Initial values by input id; an input without one starts from its default.
  final Map<String, Object?>? values;

  /// The host's errors (UiFormError).
  final List<FlarePluginFormError> errors;

  /// The submit key; `pluginViewSubmit` when null.
  final String? submitLabel;
  final bool busy;

  /// A failure line above the keys.
  final String? error;

  /// Candidates for members inputs.
  final List<FlarePluginMember> members;
  final ValueChanged<Map<String, Object?>>? onSubmit;
  final VoidCallback? onCancel;

  @override
  State<FlarePluginForm> createState() => _FlarePluginFormState();
}

class _FlarePluginFormState extends State<FlarePluginForm> {
  final Map<String, Object?> _draft = {};
  final Set<String> _edited = {};
  final Set<String> _editedSinceErrors = {};
  bool _attempted = false;
  final Map<String, TextEditingController> _text = {};
  final Map<String, List<TextEditingController>> _rows = {};
  final Map<String, ({String date, String time})> _dateParts = {};
  String _signature = '';

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(FlarePluginForm old) {
    super.didUpdateWidget(old);
    if (_signatureOf(widget) != _signature) _reset();
    if (jsonEncode([
          for (final e in old.errors) '${e.input}:${e.issue.name}',
        ]) !=
        jsonEncode([
          for (final e in widget.errors) '${e.input}:${e.issue.name}',
        ])) {
      _editedSinceErrors.clear();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  /// What identifies a form: its inputs and initial values, by content.
  String _signatureOf(FlarePluginForm form) {
    try {
      return jsonEncode([
        for (final input in form.inputs)
          [input.id, input.kind.name, input.defaultValue],
        form.values,
      ]);
    } on JsonUnsupportedObjectError {
      return '${identityHashCode(form.inputs)}:${identityHashCode(form.values)}';
    }
  }

  void _disposeControllers() {
    for (final c in _text.values) {
      c.dispose();
    }
    for (final rows in _rows.values) {
      for (final c in rows) {
        c.dispose();
      }
    }
    _text.clear();
    _rows.clear();
  }

  String _pad2(int n) => n.toString().padLeft(2, '0');

  /// A new form (other inputs or initial values): start over from them.
  void _reset() {
    _signature = _signatureOf(widget);
    _disposeControllers();
    _draft
      ..clear()
      ..addAll(flarePluginDraft(widget.inputs, widget.values));
    for (final input in widget.inputs) {
      final value = _draft[input.id];
      switch (input.kind) {
        case FlarePluginInputKind.text:
          _text[input.id] = TextEditingController(text: '${value ?? ''}');
        case FlarePluginInputKind.number:
          _text[input.id] = TextEditingController(
            text: value is num ? '$value' : '',
          );
        case FlarePluginInputKind.options:
          _rows[input.id] = [
            for (final row in value as List<String>)
              TextEditingController(text: row),
          ];
        case FlarePluginInputKind.datetime:
          final at = value is num
              ? DateTime.fromMillisecondsSinceEpoch(value.toInt())
              : null;
          _dateParts[input.id] = at == null
              ? (date: '', time: '')
              : (
                  date: '${at.year}-${_pad2(at.month)}-${_pad2(at.day)}',
                  time: '${_pad2(at.hour)}:${_pad2(at.minute)}',
                );
        default:
          break;
      }
    }
    _edited.clear();
    _editedSinceErrors.clear();
    _attempted = false;
  }

  void _set(String id, Object? value) {
    setState(() {
      _draft[id] = value;
      _edited.add(id);
      _editedSinceErrors.add(id);
    });
  }

  /// The host's first error for an input, else the client's issue once it may show.
  String? _errorText(FlarePluginInput input, FlareStrings strings) {
    if (!_editedSinceErrors.contains(input.id)) {
      for (final e in widget.errors) {
        if (e.input == input.id)
          return flarePluginIssueText(e.issue, input, strings);
      }
    }
    if (!_attempted && !_edited.contains(input.id)) return null;
    final issue = flarePluginCheckInput(input, _draft[input.id]);
    return issue == null ? null : flarePluginIssueText(issue, input, strings);
  }

  void _submit() {
    if (widget.busy) return;
    setState(() => _attempted = true);
    if (widget.inputs.any(
      (input) => flarePluginCheckInput(input, _draft[input.id]) != null,
    ))
      return;
    widget.onSubmit?.call(flarePluginFormValues(widget.inputs, _draft));
  }

  void _setDatePart(String id, {String? date, String? time}) {
    final parts = _dateParts[id] ?? (date: '', time: '');
    final next = (date: date ?? parts.date, time: time ?? parts.time);
    _dateParts[id] = next;
    int? ms;
    if (next.date.isNotEmpty && next.time.isNotEmpty) {
      final d = next.date.split('-').map(int.tryParse).toList();
      final t = next.time.split(':').map(int.tryParse).toList();
      if (d.length == 3 &&
          t.length == 2 &&
          !d.contains(null) &&
          !t.contains(null)) {
        ms = DateTime(d[0]!, d[1]!, d[2]!, t[0]!, t[1]!).millisecondsSinceEpoch;
      }
    }
    _set(id, ms);
  }

  List<String> _rowTexts(String id) => [
    for (final c in _rows[id] ?? const <TextEditingController>[]) c.text,
  ];

  void _addRow(FlarePluginInput input) {
    final rows = _rows[input.id]!;
    if (rows.length >= flarePluginMaxItems(input)) return;
    rows.add(TextEditingController());
    _set(input.id, _rowTexts(input.id));
  }

  void _removeRow(FlarePluginInput input, int index) {
    final rows = _rows[input.id]!;
    if (rows.length <= flarePluginMinRows(input)) return;
    rows.removeAt(index).dispose();
    _set(input.id, _rowTexts(input.id));
  }

  Future<void> _pickMembers(FlarePluginInput input) async {
    final entries = [
      for (final m in widget.members)
        FlareContactPickerEntry(
          userId: m.userId,
          name: m.name,
          avatarUrl: m.avatarUrl,
        ),
    ];
    // fill: the picker takes the sheet's height and brings its own header, so
    // the sheet's title is its accessible name only.
    final picked = await FlareBottomSheet.show<List<FlareContactPickerEntry>>(
      context,
      title: input.label,
      fill: true,
      builder: (sheetContext) => FlareContactPicker(
        groups: [
          FlareContactPickerGroup(
            id: 'members',
            label: input.label,
            entries: entries,
          ),
        ],
        multiple: flarePluginMaxItems(input) != 1,
        title: input.label,
        onSelect: (chosen) => Navigator.of(sheetContext).pop(chosen),
        onCancel: () => Navigator.of(sheetContext).pop(),
      ),
    );
    if (picked == null || !mounted) return;
    _set(input.id, [
      for (final e in picked.take(flarePluginMaxItems(input))) e.userId,
    ]);
  }

  Widget _field(
    FlarePluginInput input,
    FlareStrings strings,
    FlareColors colors,
  ) {
    final error = _errorText(input, strings);
    final disabled = widget.busy;
    Widget wrap(Widget child, {bool labelled = true}) => KeyedSubtree(
      key: ValueKey('flare-plugin-input-${input.id}'),
      child: FlareFormField(
        label: labelled ? input.label : null,
        required: input.required,
        hint: flarePluginCounter(input, _draft[input.id]),
        error: error,
        child: child,
      ),
    );
    switch (input.kind) {
      case FlarePluginInputKind.text:
        return wrap(
          FlareInput(
            controller: _text[input.id],
            placeholder: input.placeholder,
            disabled: disabled,
            onChanged: (v) => _set(input.id, v),
          ),
        );
      case FlarePluginInputKind.textarea:
        return wrap(
          FlareTextarea(
            value: '${_draft[input.id] ?? ''}',
            placeholder: input.placeholder,
            maxRows: 6,
            disabled: disabled,
            onChanged: (v) => _set(input.id, v),
          ),
        );
      case FlarePluginInputKind.number:
        return wrap(
          FlareInput(
            controller: _text[input.id],
            placeholder: input.placeholder,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            disabled: disabled,
            onChanged: (v) => _set(
              input.id,
              v.trim().isEmpty ? null : num.tryParse(v.trim()),
            ),
          ),
        );
      case FlarePluginInputKind.toggle:
        return wrap(
          Row(
            children: [
              Expanded(
                child: Text(
                  input.label,
                  style: TextStyle(
                    fontSize: FlareSizes.fontSizeLg,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              FlareSwitch(
                value: _draft[input.id] == true,
                disabled: disabled,
                onChanged: (v) => _set(input.id, v),
              ),
            ],
          ),
          labelled: false,
        );
      case FlarePluginInputKind.select:
        return wrap(
          FlareRadioGroup(
            options: [
              for (final c in input.choices)
                FlareSelectOption(value: c.value, label: c.label),
            ],
            value: '${_draft[input.id] ?? ''}',
            vertical: true,
            onSelect: disabled ? null : (v) => _set(input.id, v),
          ),
        );
      case FlarePluginInputKind.datetime:
        final parts = _dateParts[input.id] ?? (date: '', time: '');
        return wrap(
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FlareDatePicker(
                  value: parts.date,
                  placeholder: strings.selectDate,
                  title: input.label,
                  disabled: disabled,
                  onChanged: (v) => _setDatePart(input.id, date: v),
                ),
              ),
              const SizedBox(width: FlareSizes.spacingSm),
              Expanded(
                flex: 2,
                child: FlareTimePicker(
                  value: parts.time,
                  placeholder: strings.selectTime,
                  title: input.label,
                  disabled: disabled,
                  onChanged: (v) => _setDatePart(input.id, time: v),
                ),
              ),
            ],
          ),
        );
      case FlarePluginInputKind.options:
        final rows = _rows[input.id]!;
        return wrap(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows.length; i += 1)
                Padding(
                  key: ObjectKey(rows[i]),
                  padding: const EdgeInsets.only(bottom: FlareSizes.spacingXs),
                  child: Row(
                    children: [
                      Expanded(
                        child: FlareInput(
                          controller: rows[i],
                          placeholder: input.placeholder,
                          disabled: disabled,
                          onChanged: (_) => _set(input.id, _rowTexts(input.id)),
                        ),
                      ),
                      FlareIconButton(
                        key: ValueKey('flare-plugin-option-remove-$i'),
                        icon: 'close',
                        semanticLabel: strings.removeOption,
                        disabled:
                            disabled ||
                            rows.length <= flarePluginMinRows(input),
                        onPressed: () => _removeRow(input, i),
                      ),
                    ],
                  ),
                ),
              FlareButton(
                key: const ValueKey('flare-plugin-option-add'),
                variant: FlareButtonVariant.text,
                icon: 'add',
                label: strings.addOption,
                disabled: disabled || rows.length >= flarePluginMaxItems(input),
                onPressed: () => _addRow(input),
              ),
            ],
          ),
        );
      case FlarePluginInputKind.members:
        final ids = _draft[input.id] is List
            ? (_draft[input.id] as List).whereType<String>().toList()
            : <String>[];
        final names = [
          for (final id in ids)
            widget.members
                    .where((m) => m.userId == id)
                    .map((m) => m.name)
                    .firstOrNull ??
                id,
        ].join('、');
        return wrap(
          Wrap(
            spacing: FlareSizes.spacingSm,
            runSpacing: FlareSizes.spacingXs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (names.isNotEmpty)
                Text(
                  names,
                  key: ValueKey('flare-plugin-members-${input.id}'),
                  style: TextStyle(
                    fontSize: FlareSizes.fontSizeLg,
                    color: colors.textPrimary,
                  ),
                ),
              FlareButton(
                key: ValueKey('flare-plugin-members-choose-${input.id}'),
                variant: FlareButtonVariant.secondary,
                size: FlareControlSize.sm,
                label: input.placeholder ?? strings.select,
                disabled: disabled,
                onPressed: () => _pickMembers(input),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final error = widget.error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FlareSizes.spacingLg,
        FlareSizes.spacingMd,
        FlareSizes.spacingLg,
        FlareSizes.spacingXl,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fields = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.inputs.length; i += 1) ...[
                if (i > 0) const SizedBox(height: FlareSizes.spacingMd),
                _field(widget.inputs[i], strings, colors),
              ],
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // In a bounded sheet the fields scroll and the keys stay; unbounded, it all lays out.
              if (constraints.hasBoundedHeight)
                Flexible(child: SingleChildScrollView(child: fields))
              else
                fields,
              if (error != null && error.isNotEmpty) ...[
                const SizedBox(height: FlareSizes.spacingMd),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeSm,
                      color: colors.errorText,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: FlareSizes.spacingLg),
              Row(
                children: [
                  Expanded(
                    child: FlareButton(
                      key: const ValueKey('flare-plugin-form-cancel'),
                      label: strings.cancel,
                      variant: FlareButtonVariant.secondary,
                      disabled: widget.busy,
                      onPressed: widget.onCancel,
                    ),
                  ),
                  const SizedBox(width: FlareSizes.spacingMd),
                  Expanded(
                    child: FlareButton(
                      key: const ValueKey('flare-plugin-form-submit'),
                      label: widget.submitLabel ?? strings.pluginViewSubmit,
                      loading: widget.busy,
                      disabled: widget.busy,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
