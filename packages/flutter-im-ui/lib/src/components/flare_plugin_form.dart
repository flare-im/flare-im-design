import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/contact_picker.dart';
import '../models/directory_data.dart';
import '../models/plugin_layout.dart';
import '../models/plugin_view.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_contact_picker.dart';
import 'flare_date_picker.dart';
import 'flare_form_field.dart';
import 'flare_icon.dart';
import 'flare_icon_button.dart';
import 'flare_input.dart';
import 'flare_radio_group.dart';
import 'flare_switch.dart';
import 'flare_textarea.dart';
import 'flare_time_picker.dart';
import 'flare_file_upload.dart';
import 'flare_image_upload_slot.dart';
import 'flare_document_slot.dart';
import 'flare_pin_input.dart';
import 'flare_plugin_view.dart' show FlarePluginPinnedBar;
import 'flare_select.dart';
import 'flare_status_banner.dart';

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
    this.embedded = false,
    this.busy = false,
    this.error,
    this.members = const [],
    this.membersLoading = false,
    this.membersRevision = 0,
    this.membersError,
    this.onMemberSearch,
    this.onMembersRetry,
    this.onSubmit,
    this.onCancel,
    this.fileStates = const {},
    this.onFileAction,
    this.locationStates = const {},
    this.onLocationAction,
    this.pinSubmit = false,
  });

  /// An embedded (page) form on a phone: the submit sits in a bar pinned to
  /// the bottom of the screen (R6), drawn through the overlay.
  final bool pinSubmit;

  final List<FlarePluginInput> inputs;

  /// Initial values by input id; an input without one starts from its default.
  final Map<String, Object?>? values;

  /// The host's errors (UiFormError).
  final List<FlarePluginFormError> errors;

  /// The submit key; `pluginViewSubmit` when null.
  final String? submitLabel;

  /// Page composition: no sheet inset or cancel key; the submit fills the row.
  final bool embedded;
  final bool busy;

  /// A failure line above the keys.
  final String? error;

  /// Candidates for members inputs.
  final List<FlarePluginMember> members;

  /// Server member-search state; without onMemberSearch the picker filters locally.
  final bool membersLoading;

  /// An authoritative roster/permission invalidation, never an ordinary search result.
  final int membersRevision;
  final String? membersError;
  final ValueChanged<String>? onMemberSearch;
  final VoidCallback? onMembersRetry;
  final ValueChanged<Map<String, Object?>>? onSubmit;
  final VoidCallback? onCancel;
  final Map<String, FlarePluginFileState> fileStates;
  final ValueChanged<FlarePluginFileAction>? onFileAction;

  /// Location inputs: the host's fix, a running locate or a failure, by input
  /// id. The host drops an input's state on [FlarePluginLocationActionKind.clear].
  final Map<String, FlarePluginLocationState> locationStates;

  /// A location input's key: `locate` runs the page's locationOnce action into
  /// the input; `clear` empties it. Without it the locate key is disabled.
  final ValueChanged<FlarePluginLocationAction>? onLocationAction;

  @override
  State<FlarePluginForm> createState() => FlarePluginFormState();
}

/// The form's state. [nativeInto] lets the view run a page action's native
/// target through the input it writes into.
class FlarePluginFormState extends State<FlarePluginForm> {
  final _pinned = OverlayPortalController()..show();
  final Map<String, Object?> _draft = {};
  final Set<String> _edited = {};
  final Set<String> _editedSinceErrors = {};
  bool _attempted = false;
  final Map<String, TextEditingController> _text = {};
  final Map<String, List<TextEditingController>> _rows = {};
  final Map<String, ({String date, String time})> _dateParts = {};
  final _memberRevision = ValueNotifier(0);
  ModalRoute<Object?>? _memberRoute;
  NavigatorState? _memberNavigator;
  final _selectedMembers = <String, FlarePluginMember>{};
  String _signature = '';
  String _fileScope = '';
  final _fileGenerations = <String, int>{};
  final _localFiles = <String, FlarePluginFileState>{};
  List<FlarePluginInput> get _visible =>
      flarePluginVisibleInputs(widget.inputs, _draft);

  FlarePluginFileState _fileState(FlarePluginInput input) {
    final generation = _fileGenerations[input.id] ?? 0;
    final controlled = widget.fileStates[input.id];
    if (controlled?.scope == _fileScope && controlled?.generation == generation)
      return controlled!;
    final local = _localFiles[input.id];
    if (local?.scope == _fileScope && local?.generation == generation)
      return local!;
    final value = FlarePluginFileValue.fromValue(_draft[input.id]);
    return FlarePluginFileState(
      scope: _fileScope,
      generation: generation,
      phase: value == null
          ? FlarePluginFilePhase.empty
          : FlarePluginFilePhase.uploaded,
      value: value,
    );
  }

  bool get _filesPending =>
      _visible.where((i) => flarePluginIsUpload(i.kind)).any((input) {
        final state = _fileState(input);
        return state.phase != FlarePluginFilePhase.empty &&
            (state.phase != FlarePluginFilePhase.uploaded ||
                FlarePluginFileValue.fromValue(
                      state.value ?? _draft[input.id],
                    ) ==
                    null);
      });

  FlarePluginFileAction _advanceFile(
    FlarePluginInput input,
    FlarePluginFileActionKind action,
  ) {
    if (action != FlarePluginFileActionKind.preview) {
      _fileGenerations[input.id] = (_fileGenerations[input.id] ?? 0) + 1;
      _draft[input.id] = null;
      _editedSinceErrors.add(input.id);
      _localFiles[input.id] = FlarePluginFileState(
        scope: _fileScope,
        generation: _fileGenerations[input.id]!,
        phase:
            const [
              FlarePluginFileActionKind.choose,
              FlarePluginFileActionKind.retry,
              FlarePluginFileActionKind.replace,
            ].contains(action)
            ? FlarePluginFilePhase.selected
            : FlarePluginFilePhase.empty,
      );
    }
    return FlarePluginFileAction(
      action: action,
      inputId: input.id,
      input: input,
      scope: _fileScope,
      generation: _fileGenerations[input.id] ?? 0,
      formValues: flarePluginFormValues(widget.inputs, _draft),
    );
  }

  void _fileAction(FlarePluginInput input, FlarePluginFileActionKind action) {
    if (widget.busy || !_visible.contains(input)) return;
    late FlarePluginFileAction event;
    setState(() => event = _advanceFile(input, action));
    widget.onFileAction?.call(event);
  }

  /// A page action's native [target] writing `into` one of this form's
  /// inputs: run it through that input's own key, so the host gets the
  /// form's scope with it and its answer lands in this form, even before the
  /// viewer touched the input. False when no visible input here takes it (or
  /// the host has no handler for that key): the action then goes out as
  /// itself.
  bool nativeInto(FlarePluginActionTarget? target) {
    if (widget.busy) return false;
    final input = _visible
        .where(
          (candidate) => flarePluginNativeIntoKey(target, candidate) != null,
        )
        .firstOrNull;
    if (input == null) return false;
    if (flarePluginNativeIntoKey(target, input) == 'location') {
      if (widget.onLocationAction == null) return false;
      _locationAction(input, FlarePluginLocationActionKind.locate);
      return true;
    }
    if (widget.onFileAction == null) return false;
    _fileAction(
      input,
      _fileState(input).phase == FlarePluginFilePhase.empty
          ? FlarePluginFileActionKind.choose
          : FlarePluginFileActionKind.replace,
    );
    return true;
  }

  /// The host's fix is the input's value; one of another precision is never
  /// taken.
  void _applyLocations() {
    for (final input in _visible.where(
      (i) => i.kind == FlarePluginInputKind.location,
    )) {
      final fix = FlarePluginLocationValue.of(
        widget.locationStates[input.id]?.value,
        input.precision,
      );
      if (fix == null) continue;
      if (FlarePluginLocationValue.of(_draft[input.id], input.precision) == fix)
        continue;
      _draft[input.id] = fix.toJson();
      _editedSinceErrors.add(input.id);
    }
  }

  void _locationAction(
    FlarePluginInput input,
    FlarePluginLocationActionKind action,
  ) {
    if (widget.busy || !_visible.contains(input)) return;
    if (action == FlarePluginLocationActionKind.clear) {
      setState(() {
        _draft[input.id] = null;
        _editedSinceErrors.add(input.id);
      });
    } else if (widget.locationStates[input.id]?.locating == true) {
      return;
    }
    widget.onLocationAction?.call(
      FlarePluginLocationAction(
        action: action,
        inputId: input.id,
        input: input,
        formValues: flarePluginFormValues(widget.inputs, _draft),
      ),
    );
  }

  void _applyFiles() {
    for (final input in _visible.where((i) => flarePluginIsUpload(i.kind))) {
      final state = widget.fileStates[input.id];
      if (state?.scope != _fileScope ||
          state?.generation != (_fileGenerations[input.id] ?? 0))
        continue;
      final value = state!.phase == FlarePluginFilePhase.uploaded
          ? FlarePluginFileValue.fromValue(state.value)
          : null;
      _draft[input.id] = value?.toJson();
      // Ordinary refresh can release the host's transfer owner and preview.
      // Preserve only a validated receipt for the exact same field ticket.
      _localFiles[input.id] = FlarePluginFileState(
        scope: state.scope,
        generation: state.generation,
        phase: state.phase == FlarePluginFilePhase.uploaded && value == null
            ? FlarePluginFilePhase.failed
            : state.phase,
        value: value,
        fileName: state.fileName,
        error: state.error,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(FlarePluginForm old) {
    super.didUpdateWidget(old);
    // R6: the host's field errors take the reader to the first one.
    if (!identical(old.errors, widget.errors) && widget.errors.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusFirstError());
    }
    if (_signatureOf(widget) != _signature) _reset();
    _applyFiles();
    _applyLocations();
    if (old.membersRevision != widget.membersRevision) {
      _selectedMembers.clear();
      for (final input in widget.inputs.where(
        (input) => input.kind == FlarePluginInputKind.members,
      )) {
        _draft[input.id] = <String>[];
        _edited.add(input.id);
        _editedSinceErrors.add(input.id);
      }
      final route = _memberRoute, navigator = _memberNavigator;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator?.mounted == true && route?.isActive == true)
          navigator!.removeRoute(route!);
      });
    }
    if (!identical(old.members, widget.members) &&
        widget.onMemberSearch == null) {
      final current = widget.members.map((member) => member.userId).toSet();
      final removed = old.members
          .map((member) => member.userId)
          .where((id) => !current.contains(id))
          .toSet();
      for (final input in widget.inputs) {
        if (_draft[input.id] case final List ids
            when input.kind == FlarePluginInputKind.members) {
          _draft[input.id] = ids
              .whereType<String>()
              .where((id) => !removed.contains(id))
              .toList();
        }
      }
    }
    if (!identical(old.members, widget.members) ||
        old.membersLoading != widget.membersLoading ||
        old.membersRevision != widget.membersRevision ||
        old.membersError != widget.membersError) {
      // The sheet reads current props, including a phase change without new rows.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _memberRevision.value++;
      });
    }
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
    final emit = widget.onFileAction;
    final events = [
      for (final input in widget.inputs.where(
        (i) => flarePluginIsUpload(i.kind),
      ))
        _advanceFile(input, FlarePluginFileActionKind.invalidate),
    ];
    if (emit != null)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final event in events) emit(event);
      });
    _memberRevision.dispose();
    _disposeControllers();
    super.dispose();
  }

  /// What identifies a form: its inputs and initial values, by content.
  String _signatureOf(FlarePluginForm form) {
    try {
      return jsonEncode([
        for (final input in form.inputs)
          [
            input.id,
            input.kind.name,
            input.defaultValue,
            input.showWhen == null
                ? null
                : [input.showWhen!.field, input.showWhen!.anyOf],
            input.file == null
                ? null
                : [
                    input.file!.accept,
                    input.file!.maxBytes,
                    input.file!.upload.prepareOperation,
                    input.file!.upload.completeOperation,
                    input.file!.upload.purpose,
                  ],
            [
              for (final choice in input.choices) [choice.value, choice.label],
            ],
          ],
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
    if (_fileScope.isNotEmpty) {
      final emit = widget.onFileAction;
      final events = [
        for (final input in widget.inputs.where(
          (i) => flarePluginIsUpload(i.kind),
        ))
          _advanceFile(input, FlarePluginFileActionKind.invalidate),
      ];
      if (emit != null)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final event in events) emit(event);
        });
    }
    _fileScope = flarePluginNewFileScope();
    _fileGenerations.clear();
    _localFiles.clear();
    _selectedMembers.clear();
    _signature = _signatureOf(widget);
    _disposeControllers();
    _draft
      ..clear()
      ..addAll(flarePluginDraft(widget.inputs, widget.values));
    for (final input in widget.inputs) {
      final value = _draft[input.id];
      switch (input.kind) {
        case FlarePluginInputKind.password:
        case FlarePluginInputKind.text:
        case FlarePluginInputKind.money:
          _text[input.id] = TextEditingController(text: '${value ?? ''}');
        case FlarePluginInputKind.number:
          _text[input.id] = TextEditingController(
            text: value is num ? '$value' : '',
          );
        case FlarePluginInputKind.options:
          _rows[input.id] = [
            for (final row in value is List<String> ? value : const <String>[])
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
    _applyLocations();
  }

  void _set(String id, Object? value) {
    final events = <FlarePluginFileAction>[];
    setState(() {
      final changed = _draft[id] != value;
      _draft[id] = value;
      _edited.add(id);
      _editedSinceErrors.add(id);
      final dependents = changed
          ? widget.inputs.where((i) => i.showWhen?.field == id).toList()
          : <FlarePluginInput>[];
      for (final input in dependents) {
        _draft[input.id] = null;
        _text[input.id]?.clear();
        for (final row in _rows[input.id] ?? <TextEditingController>[]) {
          row.clear();
        }
        _dateParts[input.id] = (date: '', time: '');
        _edited.remove(input.id);
        _editedSinceErrors.add(input.id);
      }
      for (final input in dependents) {
        if (flarePluginIsUpload(input.kind))
          events.add(_advanceFile(input, FlarePluginFileActionKind.invalidate));
      }
    });
    for (final event in events) widget.onFileAction?.call(event);
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

  /// Submits like the form's own key (a page's pinned bar runs it).
  void submit() => _submit();

  final Map<String, GlobalKey> _anchors = {};
  GlobalKey _anchor(String id) => _anchors[id] ??= GlobalKey();

  /// R6: scroll the first wrong field into view and focus its control.
  void _focusFirstError() {
    if (!mounted) return;
    final strings = FlareStrings.of(context);
    final input = _visible
        .where((input) => _errorText(input, strings) != null)
        .firstOrNull;
    final anchor = input == null ? null : _anchors[input.id]?.currentContext;
    if (anchor == null) return;
    Scrollable.ensureVisible(
      anchor,
      alignment: 0.1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
    );
    FocusNode? node;
    void visit(Element element) {
      if (node != null) return;
      final widget = element.widget;
      if (widget is EditableText) {
        node = widget.focusNode;
      } else if (widget is Focus &&
          widget.focusNode != null &&
          widget.focusNode!.canRequestFocus &&
          !widget.focusNode!.skipTraversal) {
        node = widget.focusNode;
      } else {
        element.visitChildren(visit);
      }
    }

    (anchor as Element).visitChildren(visit);
    node?.requestFocus();
  }

  /// A select without choices holds the submit back (R6).
  bool get _noOptions => _visible.any(
    (input) =>
        input.kind == FlarePluginInputKind.select && input.choices.isEmpty,
  );

  /// Upload inputs holding a file, and how many of them are uploaded.
  ({int done, int total}) get _uploads {
    var done = 0, total = 0;
    for (final input in _visible.where((i) => flarePluginIsUpload(i.kind))) {
      final phase = _fileState(input).phase;
      if (phase == FlarePluginFilePhase.empty) continue;
      total++;
      if (phase == FlarePluginFilePhase.uploaded) done++;
    }
    return (done: done, total: total);
  }

  /// Required document photos still missing (§6.3).
  int get _photosMissing => _visible
      .where(
        (input) =>
            input.kind == FlarePluginInputKind.document &&
            input.required &&
            _fileState(input).phase != FlarePluginFilePhase.uploaded,
      )
      .length;

  void _submit() {
    // Enter runs this too: hold back whatever holds the key back.
    if (widget.busy || _filesPending || _noOptions || _photosMissing > 0)
      return;
    setState(() => _attempted = true);
    if (_visible.any(
      (input) => flarePluginCheckInput(input, _draft[input.id]) != null,
    )) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusFirstError());
      return;
    }
    final values = flarePluginFormValues(widget.inputs, _draft);
    for (final input in widget.inputs.where(
      (i) => i.kind == FlarePluginInputKind.password,
    )) {
      _draft[input.id] = '';
      _text[input.id]?.clear();
    }
    widget.onSubmit?.call(values);
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
    // fill: the picker takes the sheet's height and brings its own header, so
    // the sheet's title is its accessible name only.
    if (widget.busy) return;
    final revision = widget.membersRevision;
    widget.onMemberSearch?.call('');
    final picked = await FlareBottomSheet.show<List<FlareContactPickerEntry>>(
      context,
      title: input.label,
      fill: true,
      listenable: _memberRevision,
      builder: (sheetContext) {
        _memberRoute = ModalRoute.of(sheetContext);
        _memberNavigator = Navigator.of(sheetContext);
        return FlareContactPicker(
          groups: [
            FlareContactPickerGroup(
              id: 'members',
              label: input.label,
              entries: [
                for (final m in widget.members)
                  FlareContactPickerEntry(
                    userId: m.userId,
                    name: m.name,
                    avatarUrl: m.avatarUrl,
                  ),
              ],
            ),
          ],
          multiple: flarePluginMaxItems(input) != 1,
          title: input.label,
          loading: widget.membersLoading,
          error: widget.membersError,
          onSearch: widget.onMemberSearch,
          onRetry: widget.onMembersRetry,
          onSelect: (chosen) {
            if (!mounted ||
                revision != widget.membersRevision ||
                widget.busy ||
                widget.membersLoading ||
                (widget.membersError?.isNotEmpty ?? false))
              return;
            Navigator.of(sheetContext).pop(chosen);
          },
          onCancel: () => Navigator.of(sheetContext).pop(),
        );
      },
    );
    _memberRoute = null;
    _memberNavigator = null;
    if (picked == null ||
        !mounted ||
        revision != widget.membersRevision ||
        widget.membersLoading ||
        (widget.membersError?.isNotEmpty ?? false))
      return;
    final current = widget.members.map((member) => member.userId).toSet();
    if (widget.onMemberSearch != null) {
      for (final entry in picked) {
        _selectedMembers[entry.userId] = FlarePluginMember(
          userId: entry.userId,
          name: entry.name,
          avatarUrl: entry.avatarUrl,
        );
      }
    }
    for (final member in widget.members.where(
      (member) => picked.any((entry) => entry.userId == member.userId),
    )) {
      _selectedMembers[member.userId] = member;
    }
    _set(input.id, [
      for (final e
          in picked
              .where(
                (entry) =>
                    current.contains(entry.userId) ||
                    (widget.onMemberSearch != null &&
                        _selectedMembers.containsKey(entry.userId)),
              )
              .take(flarePluginMaxItems(input)))
        e.userId,
    ]);
  }

  Widget _field(
    FlarePluginInput input,
    FlareStrings strings,
    FlareColors colors,
  ) {
    final error = _errorText(input, strings);
    final disabled = widget.busy;
    // R6 / §12.9: kit Input large (48) on a phone, 40 from the PC breakpoint.
    final size =
        (MediaQuery.maybeSizeOf(context)?.width ?? 0) >=
            FlareSizes.appShellCompactMinWidth
        ? FlareControlSize.md
        : FlareControlSize.lg;
    // R11: Enter in a single-line input submits the form, as its key does.
    void enter(String _) => _submit();
    Widget wrap(Widget child, {bool labelled = true}) => KeyedSubtree(
      key: ValueKey('flare-plugin-input-${input.id}'),
      child: FlareFormField(
        label: labelled ? input.label : null,
        labelColor: colors.textPrimary,
        required: input.required,
        counter: flarePluginCounter(input, _draft[input.id]),
        hint: input.help,
        error: error,
        child: child,
      ),
    );
    switch (input.kind) {
      case FlarePluginInputKind.file:
      case FlarePluginInputKind.image:
      case FlarePluginInputKind.document:
        final file = _fileState(input);
        final policy = input.file;
        final max = policy?.maxBytes ?? 0;
        final size = max >= 1048576
            ? '${(max / 1048576).toStringAsFixed(max % 1048576 == 0 ? 0 : 1)} MiB'
            : '${(max / 1024).ceil()} KiB';
        // A document input names the side it takes after its label.
        final side = switch (input.side) {
          FlarePluginDocumentSide.front =>
            ' · ${strings.pluginFormDocumentFront}',
          FlarePluginDocumentSide.back =>
            ' · ${strings.pluginFormDocumentBack}',
          FlarePluginDocumentSide.holding =>
            ' · ${strings.pluginFormDocumentHolding}',
          null => '',
        };
        final hint = policy == null
            ? strings.pluginFileChoose
            : '${policy.accept.map((mime) => mime.split('/').last.toUpperCase()).join(', ')} · ≤ $size';
        return wrap(
          FlareFileUpload(
            title: '${input.label}$side${input.required ? ' *' : ''}',
            pickLabel: switch (input.kind) {
              FlarePluginInputKind.image => strings.pluginFormChooseImage,
              FlarePluginInputKind.document =>
                strings.pluginFormCaptureDocument,
              _ => null,
            },
            icon: input.kind == FlarePluginInputKind.file ? 'file' : 'image',
            state: FlareImageUploadState.values.byName(file.phase.name),
            fileName: file.fileName,
            progress: file.progress,
            statusText:
                file.error ??
                switch (file.phase) {
                  FlarePluginFilePhase.empty => hint,
                  FlarePluginFilePhase.selected => strings.pluginFileSelected,
                  FlarePluginFilePhase.uploading => strings.pluginFileUploading,
                  FlarePluginFilePhase.uploaded => strings.pluginFileUploaded,
                  FlarePluginFilePhase.failed => strings.pluginFileFailed,
                },
            image: input.kind != FlarePluginInputKind.file,
            replaceLabel: strings.pluginFileReplace,
            retryLabel: strings.retry,
            cancelLabel: strings.cancel,
            removeLabel: strings.pluginFileRemove,
            previewLabel: file.preview ? strings.pluginFilePreview : null,
            previewLoading: file.previewLoading,
            disabled: disabled || widget.onFileAction == null || policy == null,
            onChoose: () =>
                _fileAction(input, FlarePluginFileActionKind.choose),
            onReplace: () =>
                _fileAction(input, FlarePluginFileActionKind.replace),
            onRetry: () => _fileAction(input, FlarePluginFileActionKind.retry),
            onCancel: () =>
                _fileAction(input, FlarePluginFileActionKind.cancel),
            onRemove: () =>
                _fileAction(input, FlarePluginFileActionKind.remove),
            onPreview: () =>
                _fileAction(input, FlarePluginFileActionKind.preview),
          ),
          labelled: false,
        );
      case FlarePluginInputKind.location:
        final state = widget.locationStates[input.id];
        final fix = FlarePluginLocationValue.of(
          _draft[input.id],
          input.precision,
        );
        final locating = state?.locating == true;
        return KeyedSubtree(
          key: ValueKey('flare-plugin-input-${input.id}'),
          child: FlareFormField(
            label: input.label,
            labelColor: colors.textPrimary,
            required: input.required,
            hint: input.help,
            error: state?.error ?? error,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: FlareSizes.touchTarget,
              ),
              child: Row(
                children: [
                  const FlareIcon('location'),
                  const SizedBox(width: FlareSizes.spacingSm),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: locating
                          ? Text(
                              strings.pluginLocationLocating,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: FlareSizes.fontSizeMd,
                              ),
                            )
                          : fix == null
                          ? Text(
                              strings.pluginLocationEmpty,
                              key: const ValueKey(
                                'flare-plugin-location-empty',
                              ),
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: FlareSizes.fontSizeMd,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fix.text,
                                  key: const ValueKey(
                                    'flare-plugin-location-place',
                                  ),
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: FlareSizes.fontSizeLg,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${fix.precision == FlarePluginLocationPrecision.fine ? strings.pluginLocationFine : strings.pluginLocationCoarse}'
                                  ' · ${strings.pluginLocationAccuracy.replaceAll('{m}', '${fix.accuracyM}')}',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: FlareSizes.fontSizeSm,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (fix != null && !locating)
                    FlareButton(
                      key: const ValueKey('flare-plugin-location-clear'),
                      size: FlareControlSize.sm,
                      variant: FlareButtonVariant.quiet,
                      label: strings.pluginLocationClear,
                      disabled: disabled,
                      onPressed: () => _locationAction(
                        input,
                        FlarePluginLocationActionKind.clear,
                      ),
                    ),
                  const SizedBox(width: FlareSizes.spacingXs),
                  FlareButton(
                    key: const ValueKey('flare-plugin-location-locate'),
                    size: FlareControlSize.sm,
                    variant: FlareButtonVariant.secondary,
                    label: fix == null
                        ? strings.pluginLocationLocate
                        : strings.pluginLocationRelocate,
                    loading: locating,
                    disabled: disabled || widget.onLocationAction == null,
                    onPressed: () => _locationAction(
                      input,
                      FlarePluginLocationActionKind.locate,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case FlarePluginInputKind.password
          when input.maxLength == FlarePinInput.length:
        // §5.10: a 6-digit payment password is six PIN cells; the last digit
        // submits a form that has nothing else to fill.
        // The field's error reads under the cells, which only turn red.
        return wrap(
          FlarePinInput(
            value: '${_draft[input.id] ?? ''}',
            label: input.label,
            error: error != null,
            disabled: disabled,
            onChange: (v) => _set(input.id, v),
            onComplete: (v) {
              _set(input.id, v);
              // §5.10: the sixth digit submits unless a required field after
              // it still waits.
              final after = _visible
                  .skipWhile((other) => other.id != input.id)
                  .skip(1);
              if (!after.any(
                (other) =>
                    other.required &&
                    flarePluginCheckInput(other, _draft[other.id]) != null,
              )) {
                _submit();
              }
            },
          ),
          labelled: false,
        );
      case FlarePluginInputKind.password:
      case FlarePluginInputKind.text:
        return wrap(
          FlareInput(
            controller: _text[input.id],
            secure: input.kind == FlarePluginInputKind.password,
            semanticLabel: input.label,
            placeholder: input.placeholder,
            size: size,
            error: error,
            disabled: disabled,
            onChanged: (v) => _set(input.id, v),
            onSubmitted: enter,
          ),
        );
      case FlarePluginInputKind.money:
        final currency = input.money?.currency;
        final scale = flarePluginMoneyScale(input);
        return wrap(
          Row(
            children: [
              Expanded(
                child: FlareInput(
                  key: ValueKey('flare-plugin-money-${input.id}'),
                  controller: _text[input.id],
                  semanticLabel: input.label,
                  placeholder:
                      input.placeholder ??
                      (scale == 0 ? '0' : '0.${'0' * scale}'),
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: scale > 0,
                  ),
                  size: size,
                  error: error,
                  onSubmitted: enter,
                  disabled: disabled || currency == null,
                  // The locale's decimal separator is kept as "." (spec
                  // moneyInput.typed).
                  onChanged: (v) => _set(
                    input.id,
                    flarePluginMoneyTyped(
                      v,
                      flarePluginDecimalSeparator(
                        Localizations.maybeLocaleOf(context)?.languageCode,
                        Localizations.maybeLocaleOf(context)?.countryCode,
                      ),
                    ),
                  ),
                ),
              ),
              if (currency != null) ...[
                const SizedBox(width: FlareSizes.spacingSm),
                Text(
                  currency,
                  style: TextStyle(
                    fontSize: FlareSizes.fontSizeLg,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      case FlarePluginInputKind.textarea:
        return wrap(
          FlareTextarea(
            value: '${_draft[input.id] ?? ''}',
            placeholder: input.placeholder,
            semanticLabel: input.label,
            error: error,
            maxRows: 6,
            disabled: disabled,
            onChanged: (v) => _set(input.id, v),
          ),
        );
      case FlarePluginInputKind.number:
        return wrap(
          FlareInput(
            controller: _text[input.id],
            semanticLabel: input.label,
            placeholder: input.placeholder,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            size: size,
            error: error,
            onSubmitted: enter,
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
        // R6: ≤ 4 choices as cards, more as a select, none as a disabled
        // select that says why.
        final pick = flarePluginSelectControl(input.choices.length);
        final options = [
          for (final c in input.choices)
            FlareSelectOption(value: c.value, label: c.label),
        ];
        if (pick.disabled) {
          return KeyedSubtree(
            key: ValueKey('flare-plugin-input-${input.id}'),
            child: FlareFormField(
              label: input.label,
              labelColor: colors.textPrimary,
              required: input.required,
              hint: strings.pluginViewNoOptionsHelp,
              error: error,
              child: FlareSelect(
                key: ValueKey('flare-plugin-select-empty-${input.id}'),
                options: const [],
                value: '',
                placeholder: strings.pluginViewNoOptions,
                title: input.label,
                size: size,
                disabled: true,
              ),
            ),
          );
        }
        return wrap(
          pick.control == FlarePluginSelectControl.cards
              ? FlareRadioGroup(
                  options: options,
                  value: '${_draft[input.id] ?? ''}',
                  optionLayout: FlareRadioOptionLayout.cards,
                  onSelect: disabled ? null : (v) => _set(input.id, v),
                )
              : FlareSelect(
                  options: options,
                  value: '${_draft[input.id] ?? ''}',
                  placeholder: input.placeholder ?? strings.select,
                  title: input.label,
                  size: size,
                  disabled: disabled,
                  onChanged: (v) => _set(input.id, v),
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
                  size: size,
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
                  size: size,
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
                          semanticLabel: '${input.label} ${i + 1}',
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
                _selectedMembers[id]?.name ??
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

  /// §6.3: document inputs as capture slots, 2 per row on a phone and 3 on
  /// PC; a slot runs the input's own file keys (the host captures).
  // A captured slot draws the photo the host holds in the file state.
  Widget _documentGrid(
    List<FlarePluginInput> inputs,
    FlareStrings strings,
    FlareColors colors,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          (MediaQuery.maybeSizeOf(context)?.width ?? 0) >=
              FlareSizes.appShellCompactMinWidth
          ? 3
          : 2;
      final width =
          (constraints.maxWidth - FlareSizes.spacingMd * (columns - 1)) /
          columns;
      return Wrap(
        spacing: FlareSizes.spacingMd,
        runSpacing: FlareSizes.spacingMd,
        children: [
          for (final input in inputs)
            SizedBox(
              key: _anchor(input.id),
              width: width,
              child: KeyedSubtree(
                key: ValueKey('flare-plugin-input-${input.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    () {
                      final file = _fileState(input);
                      final ready =
                          !widget.busy &&
                          widget.onFileAction != null &&
                          input.file != null;
                      return FlareDocumentSlot(
                        label: input.label,
                        side: input.side ?? FlarePluginDocumentSide.front,
                        state: switch (file.phase) {
                          FlarePluginFilePhase.empty =>
                            FlareDocumentSlotState.empty,
                          FlarePluginFilePhase.selected ||
                          FlarePluginFilePhase.uploading =>
                            FlareDocumentSlotState.uploading,
                          FlarePluginFilePhase.uploaded =>
                            FlareDocumentSlotState.captured,
                          FlarePluginFilePhase.failed =>
                            FlareDocumentSlotState.failed,
                        },
                        progress: file.progress,
                        image: file.image == null
                            ? null
                            : MemoryImage(file.image!),
                        disabled: !ready,
                        onCapture: () => _fileAction(
                          input,
                          file.phase == FlarePluginFilePhase.empty
                              ? FlarePluginFileActionKind.choose
                              : FlarePluginFileActionKind.replace,
                        ),
                        onRetry: () =>
                            _fileAction(input, FlarePluginFileActionKind.retry),
                      );
                    }(),
                    if (_errorText(input, strings) case final message?)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: FlareSizes.spacingXs,
                        ),
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: FlareTextRoles.caption.fontSize,
                            color: colors.errorText,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final error = widget.error;
    return Padding(
      padding: widget.embedded
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(
              FlareSizes.spacingLg,
              FlareSizes.spacingMd,
              FlareSizes.spacingLg,
              FlareSizes.spacingXl,
            ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final drawn = <Widget>[];
          final visible = _visible;
          for (var i = 0; i < visible.length; i += 1) {
            final input = visible[i];
            if (input.kind == FlarePluginInputKind.document) {
              // §6.3: consecutive document inputs are one grid of slots.
              final run = [input];
              while (i + 1 < visible.length &&
                  visible[i + 1].kind == FlarePluginInputKind.document) {
                run.add(visible[++i]);
              }
              drawn.add(_documentGrid(run, strings, colors));
            } else {
              drawn.add(
                KeyedSubtree(
                  key: _anchor(input.id),
                  child: _field(input, strings, colors),
                ),
              );
            }
          }
          final fields = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < drawn.length; i += 1) ...[
                if (i > 0) const SizedBox(height: FlareSizes.spacingLg),
                drawn[i],
              ],
            ],
          );
          final uploads = _uploads;
          final missing = _photosMissing;
          final submitNote = _filesPending && uploads.total > 0
              ? strings.pluginViewUploading
                    .replaceAll('{done}', '${uploads.done}')
                    .replaceAll('{total}', '${uploads.total}')
              : missing > 0
              ? (missing == 1
                        ? strings.realnamePhotosNeededOne
                        : strings.realnamePhotosNeeded)
                    .replaceAll('{count}', '$missing')
              : null;
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
                // R6: a failure that is no field's is a danger banner.
                Semantics(
                  liveRegion: true,
                  child: FlareStatusBanner(
                    key: const ValueKey('flare-plugin-form-error'),
                    text: error,
                    tone: FlareStatusTone.danger,
                  ),
                ),
              ],
              const SizedBox(height: FlareSizes.spacingLg),
              if (widget.embedded && widget.pinSubmit)
                // R6: a phone page's form submits from a bar pinned to the
                // bottom; the body keeps room for it.
                OverlayPortal(
                  controller: _pinned,
                  overlayChildBuilder: (context) => Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: FlarePluginPinnedBar(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FlareButton(
                            key: const ValueKey('flare-plugin-form-submit'),
                            label:
                                widget.submitLabel ?? strings.pluginViewSubmit,
                            size: FlareControlSize.lg,
                            block: true,
                            loading: widget.busy,
                            disabled:
                                widget.busy ||
                                _filesPending ||
                                _noOptions ||
                                missing > 0,
                            onPressed: _submit,
                          ),
                          if (submitNote != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: FlareSizes.spacingXs,
                              ),
                              child: Text(
                                submitNote,
                                key: const ValueKey(
                                  'flare-plugin-form-submit-note',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: FlareTextRoles.caption.fontSize,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  child: SizedBox(
                    height:
                        FlareSizes.controlHeightLg +
                        FlareSizes.spacingMd * 2 +
                        FlareSizes.spacingXl +
                        MediaQuery.paddingOf(context).bottom,
                  ),
                )
              else ...[
                Row(
                  children: [
                    if (!widget.embedded) ...[
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
                    ],
                    Expanded(
                      child: FlareButton(
                        key: const ValueKey('flare-plugin-form-submit'),
                        label: widget.submitLabel ?? strings.pluginViewSubmit,
                        loading: widget.busy,
                        disabled:
                            widget.busy ||
                            _filesPending ||
                            _noOptions ||
                            missing > 0,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
                if (submitNote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: FlareSizes.spacingXs),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        submitNote,
                        key: const ValueKey('flare-plugin-form-submit-note'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: FlareTextRoles.caption.fontSize,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
