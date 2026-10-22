import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../tokens/flare_strings.dart';

/// Plugin view contracts (spec PluginView / PluginForm / PluginDetailSheet):
/// the core SDK's resolved view (ResolvedPluginView of flare-plugin-protocol)
/// as the kit draws it. Presentation only — the kit reads no paths and
/// evaluates nothing; the pure rules below are tested against
/// spec/plugin-view-vectors.json on every kit.

/// Semantic colour of a status, note or people group.
enum FlarePluginTone { neutral, info, success, warning, danger }

/// How an action key is drawn; secondary when absent.
enum FlarePluginActionStyle { primary, danger }

/// Where a `FlarePluginView` sits (spec PluginViewInset, rules.inset): none
/// (the host's surface pads it); [sheet] — straight in a kit sheet, spacing md
/// on top, lg at the sides and xl at the bottom, the same as
/// `FlarePluginForm`; [sheetTop] — at the top of a sheet with more under it
/// (a preface above `FlarePluginForm`), md on top, lg at the sides and nothing
/// at the bottom, so the next part's own top inset is the gap. It pads every
/// state: the embedded body, available or not, and a card shell kept in a
/// sheet.
enum FlarePluginViewInset { none, sheet, sheetTop }

/// How a text block is set.
enum FlarePluginTextStyle { body, title, secondary }

/// Form input kinds.
enum FlarePluginInputKind {
  text,
  textarea,
  number,
  toggle,
  select,
  datetime,
  options,
  members,
}

/// Form error kinds (UiFormIssue).
enum FlarePluginFormIssue {
  required,
  unknown,
  invalidType,
  tooLong,
  outOfRange,
  notAChoice,
  tooFewItems,
  tooManyItems,
  invalidItem,
  duplicateItem,
}

T? _enum<T extends Enum>(List<T> values, Object? name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

String _string(Object? value) => value is String ? value : '';
String? _optString(Object? value) => value is String ? value : null;
int _int(Object? value) => value is num ? value.toInt() : 0;
int? _optInt(Object? value) => value is num ? value.toInt() : null;
bool _bool(Object? value) => value == true;
List<Map<String, Object?>> _maps(Object? value) => value is List
    ? [
        for (final item in value)
          if (item is Map) item.cast<String, Object?>(),
      ]
    : const [];

@immutable
class FlarePluginField {
  const FlarePluginField({required this.label, required this.value});
  factory FlarePluginField.fromJson(Map<String, Object?> json) =>
      FlarePluginField(
        label: _string(json['label']),
        value: _string(json['value']),
      );
  final String label;
  final String value;
}

/// A resolved action. Its target and input stay with the core SDK; the kit
/// hands [id] back in `onAction`.
@immutable
class FlarePluginAction {
  const FlarePluginAction({
    required this.id,
    required this.label,
    this.style,
    this.confirm,
    this.form = const [],
  });
  factory FlarePluginAction.fromJson(Map<String, Object?> json) =>
      FlarePluginAction(
        id: _string(json['id']),
        label: _string(json['label']),
        style: _enum(FlarePluginActionStyle.values, json['style']),
        confirm: _optString(json['confirm']),
        form: [
          for (final id
              in (json['form'] is List ? json['form'] as List : const []))
            if (id is String) id,
        ],
      );
  final String id;
  final String label;
  final FlarePluginActionStyle? style;

  /// Asked first in the kit DangerConfirm.
  final String? confirm;

  /// Input ids collected first in [FlarePluginForm].
  final List<String> form;
}

/// One display block of a resolved view; kinds the kit does not know (and
/// `rows`, which only admin pages on the web draw) are skipped.
sealed class FlarePluginBlock {
  const FlarePluginBlock();

  static FlarePluginBlock? fromJson(Map<String, Object?> json) {
    switch (json['kind']) {
      case 'text':
        return FlarePluginTextBlock(
          text: _string(json['text']),
          maxLines: _optInt(json['maxLines']),
          style:
              _enum(FlarePluginTextStyle.values, json['style']) ??
              FlarePluginTextStyle.body,
        );
      case 'fields':
        return FlarePluginFieldsBlock(
          fields: [
            for (final f in _maps(json['fields'])) FlarePluginField.fromJson(f),
          ],
        );
      case 'choices':
        final action = json['action'];
        return FlarePluginChoicesBlock(
          options: [
            for (final o in _maps(json['options']))
              FlarePluginChoice(
                index: _int(o['index']),
                label: _string(o['label']),
                selected: _bool(o['selected']),
                count: _optInt(o['count']),
                percent: _optInt(o['percent']),
              ),
          ],
          multiple: _bool(json['multiple']),
          voted: _bool(json['voted']),
          closed: _bool(json['closed']),
          showResults: _bool(json['showResults']),
          total: _optInt(json['total']),
          inputName: _string(json['inputName']),
          action: action is Map
              ? FlarePluginAction.fromJson(action.cast<String, Object?>())
              : null,
        );
      case 'entries':
        return FlarePluginEntriesBlock(
          items: [
            for (final e in _maps(json['items']))
              FlarePluginEntry(
                index: _int(e['index']),
                text: _string(e['text']),
                name: _optString(e['name']),
                userId: _optString(e['userId']),
              ),
          ],
          numbered: json['numbered'] != false,
          total: _int(json['total']),
          more: _bool(json['more']),
          emptyText: _optString(json['emptyText']),
        );
      case 'people':
        return FlarePluginPeopleBlock(
          groups: [
            for (final g in _maps(json['groups']))
              FlarePluginPeopleGroup(
                label: _string(g['label']),
                userIds: [
                  for (final id
                      in (g['userIds'] is List
                          ? g['userIds'] as List
                          : const []))
                    if (id is String) id,
                ],
                count: _int(g['count']),
                tone: _enum(FlarePluginTone.values, g['tone']),
              ),
          ],
        );
      case 'status':
        return FlarePluginStatusBlock(
          label: _optString(json['label']),
          text: _string(json['text']),
          tone:
              _enum(FlarePluginTone.values, json['tone']) ??
              FlarePluginTone.neutral,
        );
      case 'progress':
        return FlarePluginProgressBlock(
          label: _optString(json['label']),
          value: _int(json['value']),
          total: _int(json['total']),
          percent: _int(json['percent']),
        );
      case 'time':
        return FlarePluginTimeBlock(
          label: _optString(json['label']),
          atMs: _int(json['atMs']),
          endMs: _optInt(json['endMs']),
          countdown: _bool(json['countdown']),
        );
      case 'divider':
        return const FlarePluginDividerBlock();
      case 'note':
        return FlarePluginNoteBlock(
          text: _string(json['text']),
          tone: _enum(FlarePluginTone.values, json['tone']),
        );
    }
    return null;
  }
}

/// Text cut at [maxLines], with "expand" when it overflows.
final class FlarePluginTextBlock extends FlarePluginBlock {
  const FlarePluginTextBlock({
    required this.text,
    this.maxLines,
    this.style = FlarePluginTextStyle.body,
  });
  final String text;
  final int? maxLines;
  final FlarePluginTextStyle style;
}

/// Label/value rows.
final class FlarePluginFieldsBlock extends FlarePluginBlock {
  const FlarePluginFieldsBlock({required this.fields});
  final List<FlarePluginField> fields;
}

/// One option of a choices block.
@immutable
class FlarePluginChoice {
  const FlarePluginChoice({
    required this.index,
    required this.label,
    this.selected = false,
    this.count,
    this.percent,
  });
  final int index;
  final String label;
  final bool selected;

  /// Votes and 0..100, present when results show.
  final int? count;
  final int? percent;
}

/// Options; [action] is the block's submit action, present while the viewer
/// can choose.
final class FlarePluginChoicesBlock extends FlarePluginBlock {
  const FlarePluginChoicesBlock({
    required this.options,
    this.multiple = false,
    this.voted = false,
    this.closed = false,
    this.showResults = false,
    this.total,
    this.inputName = 'selection',
    this.action,
  });
  final List<FlarePluginChoice> options;
  final bool multiple;
  final bool voted;
  final bool closed;
  final bool showResults;
  final int? total;
  final String inputName;
  final FlarePluginAction? action;
}

@immutable
class FlarePluginEntry {
  const FlarePluginEntry({
    required this.index,
    required this.text,
    this.name,
    this.userId,
  });

  /// 1-based position in the data.
  final int index;
  final String text;
  final String? name;
  final String? userId;
}

/// Numbered entries; [more] offers "see all".
final class FlarePluginEntriesBlock extends FlarePluginBlock {
  const FlarePluginEntriesBlock({
    required this.items,
    this.numbered = true,
    this.total = 0,
    this.more = false,
    this.emptyText,
  });
  final List<FlarePluginEntry> items;
  final bool numbered;
  final int total;
  final bool more;
  final String? emptyText;
}

@immutable
class FlarePluginPeopleGroup {
  const FlarePluginPeopleGroup({
    required this.label,
    this.userIds = const [],
    this.count = 0,
    this.tone,
  });
  final String label;

  /// At most the block's max, in data order.
  final List<String> userIds;
  final int count;
  final FlarePluginTone? tone;
}

/// One row of avatars and a count per group.
final class FlarePluginPeopleBlock extends FlarePluginBlock {
  const FlarePluginPeopleBlock({required this.groups});
  final List<FlarePluginPeopleGroup> groups;
}

/// A badge.
final class FlarePluginStatusBlock extends FlarePluginBlock {
  const FlarePluginStatusBlock({
    this.label,
    required this.text,
    this.tone = FlarePluginTone.neutral,
  });
  final String? label;
  final String text;
  final FlarePluginTone tone;
}

/// A bar with value/total.
final class FlarePluginProgressBlock extends FlarePluginBlock {
  const FlarePluginProgressBlock({
    this.label,
    required this.value,
    required this.total,
    required this.percent,
  });
  final String? label;
  final int value;
  final int total;
  final int percent;
}

/// An instant or a range, optionally counting down to [atMs].
final class FlarePluginTimeBlock extends FlarePluginBlock {
  const FlarePluginTimeBlock({
    this.label,
    required this.atMs,
    this.endMs,
    this.countdown = false,
  });
  final String? label;
  final int atMs;
  final int? endMs;
  final bool countdown;
}

final class FlarePluginDividerBlock extends FlarePluginBlock {
  const FlarePluginDividerBlock();
}

/// A tinted note.
final class FlarePluginNoteBlock extends FlarePluginBlock {
  const FlarePluginNoteBlock({required this.text, this.tone});
  final String text;
  final FlarePluginTone? tone;
}

/// A resolved form input (UiInput).
@immutable
class FlarePluginInput {
  const FlarePluginInput({
    required this.id,
    required this.kind,
    required this.label,
    this.required = false,
    this.placeholder,
    this.maxLength,
    this.min,
    this.max,
    this.defaultValue,
    this.choices = const [],
  });
  static FlarePluginInput? fromJson(Map<String, Object?> json) {
    final kind = _enum(FlarePluginInputKind.values, json['kind']);
    if (kind == null) return null;
    return FlarePluginInput(
      id: _string(json['id']),
      kind: kind,
      label: _string(json['label']),
      required: _bool(json['required']),
      placeholder: _optString(json['placeholder']),
      maxLength: _optInt(json['maxLength']),
      min: json['min'] is num ? json['min'] as num : null,
      max: json['max'] is num ? json['max'] as num : null,
      defaultValue: json['default'],
      choices: [
        for (final c in _maps(json['choices']))
          (value: _string(c['value']), label: _string(c['label'])),
      ],
    );
  }

  final String id;
  final FlarePluginInputKind kind;
  final String label;
  final bool required;
  final String? placeholder;
  final int? maxLength;

  /// number: the range; options, members: item counts.
  final num? min;
  final num? max;

  /// The initial value (`default` in the JSON).
  final Object? defaultValue;

  /// select only.
  final List<({String value, String label})> choices;
}

/// One problem with a submitted value (UiFormError).
@immutable
class FlarePluginFormError {
  const FlarePluginFormError({required this.input, required this.issue});
  static FlarePluginFormError? fromJson(Map<String, Object?> json) {
    final issue = _enum(FlarePluginFormIssue.values, json['issue']);
    return issue == null
        ? null
        : FlarePluginFormError(input: _string(json['input']), issue: issue);
  }

  final String input;
  final FlarePluginFormIssue issue;

  @override
  bool operator ==(Object other) =>
      other is FlarePluginFormError &&
      other.input == input &&
      other.issue == issue;

  @override
  int get hashCode => Object.hash(input, issue);

  @override
  String toString() => 'FlarePluginFormError($input, ${issue.name})';
}

/// What the host's resolveUser answers for a user id.
@immutable
class FlarePluginUser {
  const FlarePluginUser({required this.name, this.avatarUrl});
  final String name;
  final String? avatarUrl;
}

/// A candidate for a members input.
@immutable
class FlarePluginMember {
  const FlarePluginMember({
    required this.userId,
    required this.name,
    this.avatarUrl,
  });
  final String userId;
  final String name;
  final String? avatarUrl;
}

/// What `onAction` carries.
@immutable
class FlarePluginActionPayload {
  const FlarePluginActionPayload({this.selection, this.formValues});

  /// Chosen option indices of a choices block, ascending.
  final List<int>? selection;

  /// Submitted form values by input id.
  final Map<String, Object?>? formValues;

  Map<String, Object?> toJson() => {
    if (selection != null) 'selection': selection,
    if (formValues != null) 'formValues': formValues,
  };

  @override
  bool operator ==(Object other) =>
      other is FlarePluginActionPayload &&
      jsonEncode(other.toJson()) == jsonEncode(toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;

  @override
  String toString() => 'FlarePluginActionPayload(${jsonEncode(toJson())})';
}

/// Name and avatar of a user id; may answer from a cache or later.
typedef FlarePluginResolveUser =
    FutureOr<FlarePluginUser?> Function(String userId);

/// An action of the card, with the viewer's selection or form values.
typedef FlarePluginActionCallback =
    void Function(String actionId, FlarePluginActionPayload payload);

/// A resolved plugin view (core SDK ResolvedPluginView).
///
/// Two views built by [FlarePluginViewModel.fromJson] from the same JSON are
/// equal, so a host may re-parse on every build; views built with the
/// constructor compare by identity — keep the instance while it is current.
@immutable
class FlarePluginViewModel {
  const FlarePluginViewModel({
    required this.available,
    required this.title,
    this.fields = const [],
    this.actions = const [],
    this.blocks = const [],
    this.inputs = const [],
    this.detail = false,
    this.nextCursor,
  }) : _source = null;

  FlarePluginViewModel._json({
    required this.available,
    required this.title,
    required this.fields,
    required this.actions,
    required this.blocks,
    required this.inputs,
    required this.detail,
    required this.nextCursor,
    required String source,
  }) : _source = source;

  factory FlarePluginViewModel.fromJson(Map<String, Object?> json) =>
      FlarePluginViewModel._json(
        available: _bool(json['available']),
        title: _string(json['title']),
        fields: [
          for (final f in _maps(json['fields'])) FlarePluginField.fromJson(f),
        ],
        actions: [
          for (final a in _maps(json['actions'])) FlarePluginAction.fromJson(a),
        ],
        blocks: [
          for (final b in _maps(json['blocks']))
            if (FlarePluginBlock.fromJson(b) case final block?) block,
        ],
        inputs: [
          for (final i in _maps(json['inputs']))
            if (FlarePluginInput.fromJson(i) case final input?) input,
        ],
        detail: _bool(json['detail']),
        nextCursor: _optString(json['nextCursor']),
        source: jsonEncode(json),
      );

  final bool available;
  final String title;
  final List<FlarePluginField> fields;

  /// Footer actions; actions a block owns are not here.
  final List<FlarePluginAction> actions;
  final List<FlarePluginBlock> blocks;

  /// Every input of the document; an action's form names the ones it collects.
  final List<FlarePluginInput> inputs;

  /// The contribution has a detail view ("see all").
  final bool detail;

  /// Detail views only: the cursor of the next page. While it is set
  /// `FlarePluginDetailSheet` offers load more; the host fetches that page and
  /// passes back the merged view (the core SDK appends pages).
  final String? nextCursor;

  /// [nextCursor] when it names a page: null when absent or blank (the last
  /// page).
  String? get nextPageCursor {
    final cursor = nextCursor;
    return cursor != null && cursor.trim().isNotEmpty ? cursor : null;
  }

  final String? _source;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlarePluginViewModel &&
          _source != null &&
          other._source == _source);

  @override
  int get hashCode => _source?.hashCode ?? identityHashCode(this);
}

// ── pure rules (spec/plugin-view-vectors.json → rules) ──────────────────────

/// The clock plugin time blocks read (epoch milliseconds). The device clock;
/// tests pin it.
int Function() flarePluginNowMs = () => DateTime.now().millisecondsSinceEpoch;

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
String _pad2(int n) => n.toString().padLeft(2, '0');

/// The wall clock of an instant: the device zone, or a fixed offset (tests).
DateTime _wall(int ms, int? utcOffsetMinutes) => utcOffsetMinutes == null
    ? DateTime.fromMillisecondsSinceEpoch(ms)
    : DateTime.fromMillisecondsSinceEpoch(
        ms + utcOffsetMinutes * 60000,
        isUtc: true,
      );

/// Renders a date-time pattern: y year, M month, MMM Jan..Dec, d day, HH
/// hour, mm minute; anything else is literal.
String flarePluginRenderPattern(String pattern, DateTime at) {
  final out = StringBuffer();
  var i = 0;
  while (i < pattern.length) {
    final c = pattern[i];
    if ('yMdHm'.contains(c)) {
      var j = i;
      while (j < pattern.length && pattern[j] == c) {
        j += 1;
      }
      final run = pattern.substring(i, j);
      out.write(switch (run) {
        'y' => '${at.year}',
        'M' => '${at.month}',
        'MMM' => _months[at.month - 1],
        'd' => '${at.day}',
        'HH' => _pad2(at.hour),
        'mm' => _pad2(at.minute),
        _ => run,
      });
      i = j;
    } else {
      out.write(c);
      i += 1;
    }
  }
  return out.toString();
}

/// One instant as plugin time blocks write it (the year only outside the
/// current one).
String flarePluginDateTime(
  int ms,
  int nowMs,
  FlareStrings strings, {
  int? utcOffsetMinutes,
}) {
  final at = _wall(ms, utcOffsetMinutes);
  final now = _wall(nowMs, utcOffsetMinutes);
  return flarePluginRenderPattern(
    at.year == now.year
        ? strings.pluginViewDateTimeFormat
        : strings.pluginViewDateTimeYearFormat,
    at,
  );
}

/// A time block's text: an instant, a range on one day (`…14:00–15:00`) or
/// across days (`… – …`).
String flarePluginTimeText(
  int atMs,
  int? endMs,
  int nowMs,
  FlareStrings strings, {
  int? utcOffsetMinutes,
}) {
  final start = flarePluginDateTime(
    atMs,
    nowMs,
    strings,
    utcOffsetMinutes: utcOffsetMinutes,
  );
  if (endMs == null) return start;
  final a = _wall(atMs, utcOffsetMinutes);
  final b = _wall(endMs, utcOffsetMinutes);
  if (a.year == b.year && a.month == b.month && a.day == b.day) {
    return '$start–${_pad2(b.hour)}:${_pad2(b.minute)}';
  }
  return '$start – ${flarePluginDateTime(endMs, nowMs, strings, utcOffsetMinutes: utcOffsetMinutes)}';
}

/// The countdown to [atMs] and when to draw it again (null once passed).
({String text, int? refreshMs}) flarePluginCountdown(
  int atMs,
  int nowMs,
  FlareStrings strings,
) {
  final r = atMs - nowMs;
  if (r <= 0) return (text: strings.pluginViewDeadlinePassed, refreshMs: null);
  String unit(String template, int n) => template.replaceAll('{n}', '$n');
  String remaining(String time) =>
      strings.pluginViewRemaining.replaceAll('{time}', time);
  if (r < 3600000) {
    final s = r ~/ 1000;
    return (
      text: remaining('${_pad2(s ~/ 60)}:${_pad2(s % 60)}'),
      refreshMs: 1000,
    );
  }
  final String time;
  if (r < 86400000) {
    final h = r ~/ 3600000;
    final m = (r % 3600000) ~/ 60000;
    time =
        unit(strings.myInviteUnitHours, h) +
        (m > 0 ? ' ${unit(strings.myInviteUnitMinutes, m)}' : '');
  } else {
    final d = r ~/ 86400000;
    final h = (r % 86400000) ~/ 3600000;
    time =
        unit(strings.myInviteUnitDays, d) +
        (h > 0 ? ' ${unit(strings.myInviteUnitHours, h)}' : '');
  }
  return (text: remaining(time), refreshMs: 60000);
}

/// Whether a card draws its own view details key (spec rules.detailKey): the
/// view has a detail, is available and is not [embedded], and no entries
/// block shows its see all. The card also needs an `onOpenDetail`.
bool flarePluginShowsDetailKey(
  FlarePluginViewModel view, {
  required bool embedded,
}) =>
    view.detail &&
    view.available &&
    !embedded &&
    !view.blocks.any((b) => b is FlarePluginEntriesBlock && b.more);

/// The name drawn for a user id the host could not resolve: its last 4
/// characters.
String flarePluginFallbackName(String userId) =>
    userId.length > 4 ? userId.substring(userId.length - 4) : userId;

// ── forms ──────────────────────────────────────────────────────────────────

int _codePoints(String s) => s.runes.length;

int? flarePluginMaxLength(FlarePluginInput input) =>
    input.maxLength ??
    switch (input.kind) {
      FlarePluginInputKind.text => 256,
      FlarePluginInputKind.textarea => 2000,
      FlarePluginInputKind.options => 100,
      _ => null,
    };

/// Most option rows / members of an input.
int flarePluginMaxItems(FlarePluginInput input) =>
    input.max?.toInt() ??
    switch (input.kind) {
      FlarePluginInputKind.options => 50,
      FlarePluginInputKind.members => 500,
      _ => 1,
    };

/// Fewest option rows the editor keeps.
int flarePluginMinRows(FlarePluginInput input) {
  final min = input.min?.toInt() ?? 1;
  return min < 1 ? 1 : min;
}

/// The editable draft of one input: `values[id]`, else its default.
Object? flarePluginDraftValue(
  FlarePluginInput input,
  Map<String, Object?>? values,
) {
  final raw = values != null && values.containsKey(input.id)
      ? values[input.id]
      : input.defaultValue;
  switch (input.kind) {
    case FlarePluginInputKind.toggle:
      return raw == true;
    case FlarePluginInputKind.options:
      return raw is List
          ? [for (final x in raw) x is String ? x : '${x ?? ''}']
          : List<String>.filled(flarePluginMinRows(input), '', growable: true);
    case FlarePluginInputKind.members:
      return raw is List
          ? [
              for (final x in raw)
                if (x is String) x,
            ]
          : <String>[];
    case FlarePluginInputKind.text:
    case FlarePluginInputKind.textarea:
    case FlarePluginInputKind.select:
      return raw is String ? raw : '';
    case FlarePluginInputKind.number:
    case FlarePluginInputKind.datetime:
      return raw is num && raw.isFinite ? raw : null;
  }
}

Map<String, Object?> flarePluginDraft(
  List<FlarePluginInput> inputs,
  Map<String, Object?>? values,
) => {
  for (final input in inputs) input.id: flarePluginDraftValue(input, values),
};

List<String> _items(Object? value) => [
  for (final x in (value is List ? value : const []))
    if ('${x ?? ''}'.trim().isNotEmpty) '${x ?? ''}'.trim(),
];

/// The client's light check of one input: required and length.
FlarePluginFormIssue? flarePluginCheckInput(
  FlarePluginInput input,
  Object? draft,
) {
  final limit = flarePluginMaxLength(input);
  switch (input.kind) {
    case FlarePluginInputKind.text:
    case FlarePluginInputKind.textarea:
      final text = '${draft ?? ''}'.trim();
      if (input.required && text.isEmpty) return FlarePluginFormIssue.required;
      if (limit != null && _codePoints(text) > limit)
        return FlarePluginFormIssue.tooLong;
      return null;
    case FlarePluginInputKind.number:
    case FlarePluginInputKind.datetime:
      return input.required && draft == null
          ? FlarePluginFormIssue.required
          : null;
    case FlarePluginInputKind.select:
      return input.required && (draft == null || draft == '')
          ? FlarePluginFormIssue.required
          : null;
    case FlarePluginInputKind.options:
      final items = _items(draft);
      if (input.required && items.isEmpty) return FlarePluginFormIssue.required;
      if (limit != null && items.any((item) => _codePoints(item) > limit))
        return FlarePluginFormIssue.tooLong;
      return null;
    case FlarePluginInputKind.members:
      return input.required && !(draft is List && draft.isNotEmpty)
          ? FlarePluginFormIssue.required
          : null;
    case FlarePluginInputKind.toggle:
      return null;
  }
}

List<FlarePluginFormError> flarePluginCheckForm(
  List<FlarePluginInput> inputs,
  Map<String, Object?> draft,
) => [
  for (final input in inputs)
    if (flarePluginCheckInput(input, draft[input.id]) case final issue?)
      FlarePluginFormError(input: input.id, issue: issue),
];

/// What submit hands over: trimmed text, cleaned option rows, only the inputs
/// with a value.
Map<String, Object?> flarePluginFormValues(
  List<FlarePluginInput> inputs,
  Map<String, Object?> draft,
) {
  final out = <String, Object?>{};
  for (final input in inputs) {
    final value = draft[input.id];
    switch (input.kind) {
      case FlarePluginInputKind.text:
      case FlarePluginInputKind.textarea:
        final text = '${value ?? ''}'.trim();
        if (text.isNotEmpty) out[input.id] = text;
      case FlarePluginInputKind.number:
      case FlarePluginInputKind.datetime:
        if (value is num && value.isFinite) out[input.id] = value;
      case FlarePluginInputKind.toggle:
        out[input.id] = value == true;
      case FlarePluginInputKind.select:
        if (value is String && value.isNotEmpty) out[input.id] = value;
      case FlarePluginInputKind.options:
        final items = _items(value);
        if (items.isNotEmpty) out[input.id] = items;
      case FlarePluginInputKind.members:
        if (value is List && value.isNotEmpty)
          out[input.id] = List<String>.of(value.whereType<String>());
    }
  }
  return out;
}

/// The words for one form error under its input.
String flarePluginIssueText(
  FlarePluginFormIssue issue,
  FlarePluginInput? input,
  FlareStrings strings,
) => switch (issue) {
  FlarePluginFormIssue.required => strings.pluginFormRequired,
  FlarePluginFormIssue.tooLong => strings.pluginFormTooLong,
  FlarePluginFormIssue.outOfRange => strings.pluginFormOutOfRange,
  FlarePluginFormIssue.duplicateItem => strings.pluginFormDuplicateItem,
  FlarePluginFormIssue.tooFewItems => strings.pluginFormTooFewItems.replaceAll(
    '{n}',
    '${input?.min?.toInt() ?? 1}',
  ),
  FlarePluginFormIssue.tooManyItems =>
    strings.pluginFormTooManyItems.replaceAll(
      '{n}',
      '${input == null ? 1 : flarePluginMaxItems(input)}',
    ),
  _ => strings.pluginFormInvalid,
};

/// `{length}/{max}` under a text or textarea.
String? flarePluginCounter(FlarePluginInput input, Object? draft) {
  if (input.kind != FlarePluginInputKind.text &&
      input.kind != FlarePluginInputKind.textarea)
    return null;
  final limit = flarePluginMaxLength(input);
  return limit == null ? null : '${_codePoints('${draft ?? ''}')}/$limit';
}
