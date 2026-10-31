import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../tokens/flare_strings.dart';
import 'display_name.dart';
import 'plural.dart';
import 'server_clock.dart';

/// Plugin view contracts (spec PluginView / PluginForm / PluginDetailSheet):
/// the core SDK's resolved view (ResolvedPluginView of flare-plugin-protocol)
/// as the kit draws it. Presentation only — the kit reads no paths and
/// evaluates nothing; the pure rules below are tested against
/// spec/plugin-view-vectors.json on every kit.

/// Semantic colour of a status, note or people group.
enum FlarePluginTone { neutral, info, success, warning, danger }

/// How an action key is drawn; secondary when absent.
enum FlarePluginActionStyle { primary, danger }

/// Why a resolved view is unavailable or read-only
/// (ResolvedPluginView.unavailableReason; the wire writes it snake_case).
/// [unboundCopy] is a forged or forwarded copy of a card: the core SDK keeps
/// it available but strips every action, so it draws read-only.
enum FlarePluginUnavailableReason {
  disabled,
  notInstalled,
  noPermission,
  unsupportedPlatform,
  incompatibleVersion,
  catalogUnreachable,
  unboundCopy,
}

/// The wire name of [reason] (`not_installed` …).
String flarePluginUnavailableReasonName(FlarePluginUnavailableReason reason) =>
    reason.name.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => '_${m[0]!.toLowerCase()}',
    );

FlarePluginUnavailableReason? _reasonOf(Object? wire) {
  for (final reason in FlarePluginUnavailableReason.values) {
    if (flarePluginUnavailableReasonName(reason) == wire) return reason;
  }
  return null;
}

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

/// An entry's or a row's enumerated value as words and a tone (the plugin's
/// valueLabels), such as a ledger line's kind; drawn as the kit tag
/// (spec/plugin-view-vectors.json rules.badge).
@immutable
class FlarePluginBadge {
  const FlarePluginBadge({
    required this.text,
    this.tone = FlarePluginTone.neutral,
  });
  static FlarePluginBadge? fromJson(Object? json) => json is Map
      ? FlarePluginBadge(
          text: _string(json['text']),
          tone: flarePluginBadgeTone(json['tone']),
        )
      : null;

  /// The words, translated; an unmapped value as the plugin sent it.
  final String text;
  final FlarePluginTone tone;
}

/// A badge's tone as drawn: one of [FlarePluginTone], anything else neutral
/// (a tone from a newer protocol).
FlarePluginTone flarePluginBadgeTone(Object? tone) =>
    _enum(FlarePluginTone.values, tone) ?? FlarePluginTone.neutral;

/// One display block of a resolved view; kinds the kit does not know are
/// skipped.
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
          maxSelections: _optInt(json['maxSelections']),
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
                group: e['group'] is Map
                    ? FlarePluginEntryGroup.fromJson(
                        (e['group'] as Map).cast<String, Object?>(),
                      )
                    : null,
                badge: FlarePluginBadge.fromJson(e['badge']),
              ),
          ],
          numbered: json['numbered'] != false,
          grouped: _bool(json['grouped']),
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
      case 'rows':
        final filters = json['filters'];
        return FlarePluginRowsBlock(
          source: _string(json['source']),
          columns: [
            for (final c in _maps(json['columns']))
              FlarePluginColumn(
                label: _string(c['label']),
                format:
                    _enum(FlarePluginColumnFormat.values, c['format']) ??
                    FlarePluginColumnFormat.text,
              ),
          ],
          rows: [
            for (final r in _maps(json['rows']))
              FlarePluginRow(
                key: _string(r['key']),
                cells: [
                  for (final cell in _maps(r['cells']))
                    FlarePluginRowCell(
                      text: _string(cell['text']),
                      timeMs: _optInt(cell['timeMs']),
                    ),
                ],
                actions: [
                  for (final a in _maps(r['actions']))
                    (id: _string(a['id']), input: a['input']),
                ],
                badge: FlarePluginBadge.fromJson(r['badge']),
              ),
          ],
          actions: [
            for (final a in _maps(json['actions']))
              FlarePluginAction.fromJson(a),
          ],
          emptyText: _optString(json['emptyText']),
          filters: filters is List
              ? [
                  for (final id in filters)
                    if (id is String) id,
                ]
              : null,
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
    this.maxSelections,
    this.action,
  });
  final List<FlarePluginChoice> options;
  final bool multiple;
  final bool voted;
  final bool closed;
  final bool showResults;
  final int? total;
  final String inputName;

  /// A multiple choice's cap (1..=options): once the draft holds this many,
  /// the other options are disabled. Read it through [flarePluginChoiceCap].
  final int? maxSelections;
  final FlarePluginAction? action;
}

/// The group an entry opens in a grouped list (a poll option with its votes):
/// the kit draws a header row "label · N 票 · P%" before that entry.
@immutable
class FlarePluginEntryGroup {
  const FlarePluginEntryGroup({
    required this.key,
    required this.label,
    this.count,
    this.total,
    this.percent,
  });
  factory FlarePluginEntryGroup.fromJson(Map<String, Object?> json) =>
      FlarePluginEntryGroup(
        key: _string(json['key']),
        label: _string(json['label']),
        count: _optInt(json['count']),
        total: _optInt(json['total']),
        percent: _optInt(json['percent']),
      );
  final String key;

  /// Data, not translated.
  final String label;
  final int? count;
  final int? total;
  final int? percent;
}

@immutable
class FlarePluginEntry {
  const FlarePluginEntry({
    required this.index,
    required this.text,
    this.name,
    this.userId,
    this.group,
    this.badge,
  });

  /// 1-based position in the data (within its group in a grouped list).
  final int index;
  final String text;
  final String? name;
  final String? userId;

  /// Set on the first entry of each group of a grouped list.
  final FlarePluginEntryGroup? group;

  /// Drawn after the name and the "我" tag, before [text].
  final FlarePluginBadge? badge;
}

/// Entries — sign-ups, voters; [more] offers "see all". A [grouped] list is
/// one flat list whose entries that carry a group open it with a header row.
final class FlarePluginEntriesBlock extends FlarePluginBlock {
  const FlarePluginEntriesBlock({
    required this.items,
    this.numbered = true,
    this.grouped = false,
    this.total = 0,
    this.more = false,
    this.emptyText,
  });
  final List<FlarePluginEntry> items;
  final bool numbered;
  final bool grouped;
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

/// How a rows column formats its cells: [time] cells carry an instant.
enum FlarePluginColumnFormat { text, time }

@immutable
class FlarePluginColumn {
  const FlarePluginColumn({
    required this.label,
    this.format = FlarePluginColumnFormat.text,
  });
  final String label;
  final FlarePluginColumnFormat format;
}

@immutable
class FlarePluginRowCell {
  const FlarePluginRowCell({required this.text, this.timeMs});
  final String text;

  /// Set in a time column: the instant, drawn in the device zone.
  final int? timeMs;
}

/// What a row action carries: the row's key and the input the view bound for
/// that action (`rows[].actions[].input`), handed back unchanged.
typedef FlarePluginRowInput = ({String key, Object? input});

/// One row of a rows block.
@immutable
class FlarePluginRow {
  const FlarePluginRow({
    required this.key,
    this.cells = const [],
    this.actions = const [],
    this.badge,
  });
  final String key;

  /// One per column, in column order.
  final List<FlarePluginRowCell> cells;

  /// The block actions this row offers, each with its bound input.
  final List<({String id, Object? input})> actions;

  /// Leads the row's first line.
  final FlarePluginBadge? badge;
}

/// Rows of a plugin page (`spec/plugin-view-vectors.json` rules.pageRows):
/// drawn as a list, one item per key — the badge and the first cell, then the
/// other cells, then the row's action keys. They page with the page (the
/// view's nextCursor), so the block has no load more of its own.
final class FlarePluginRowsBlock extends FlarePluginBlock {
  const FlarePluginRowsBlock({
    this.source = '',
    this.columns = const [],
    this.rows = const [],
    this.actions = const [],
    this.emptyText,
    this.filters,
  });

  /// The query operation the rows come from.
  final String source;
  final List<FlarePluginColumn> columns;
  final List<FlarePluginRow> rows;

  /// The actions rows may offer (style, confirm and form apply).
  final List<FlarePluginAction> actions;
  final String? emptyText;

  /// Ids of the view's inputs the page shows as its filters; null: every
  /// input ([flarePluginFilterInputs]).
  final List<String>? filters;
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
  const FlarePluginActionPayload({this.selection, this.formValues, this.row});

  /// Chosen option indices of a choices block, ascending.
  final List<int>? selection;

  /// Submitted form values by input id.
  final Map<String, Object?>? formValues;

  /// The row of a rows action.
  final FlarePluginRowInput? row;

  Map<String, Object?> toJson() => {
    if (row != null) 'row': {'key': row!.key, 'input': row!.input},
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
    this.menuActions = const [],
    this.unavailableReason,
    this.presentation,
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
    required this.menuActions,
    required this.unavailableReason,
    required this.presentation,
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
        menuActions: [
          for (final a in _maps(json['menuActions']))
            FlarePluginAction.fromJson(a),
        ],
        unavailableReason: _reasonOf(json['unavailableReason']),
        presentation: json['presentation'] is Map ? Map<String, Object?>.from(json['presentation'] as Map) : null,
        source: jsonEncode(json),
      );

  final bool available;
  final Map<String, Object?>? presentation;
  final String title;
  final List<FlarePluginField> fields;

  /// Footer actions; actions a block owns are not here.
  final List<FlarePluginAction> actions;

  /// Actions the plugin placed in the card's ⋯ menu (placement menu), in
  /// order; they run like [actions].
  final List<FlarePluginAction> menuActions;

  /// Why the view is unavailable, or read-only ([FlarePluginUnavailableReason.unboundCopy]).
  final FlarePluginUnavailableReason? unavailableReason;
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
          other.runtimeType == runtimeType &&
          _source != null &&
          other._source == _source);

  @override
  int get hashCode => _source?.hashCode ?? identityHashCode(this);
}

/// The page a `FlarePluginPage` shows, as invokePageAction names it.
@immutable
class FlarePluginPageRef {
  const FlarePluginPageRef({required this.pluginId, required this.page});

  /// The plugin's id.
  final String pluginId;

  /// The page contribution's id.
  final String page;

  Map<String, Object?> toJson() => {'pluginId': pluginId, 'page': page};

  @override
  bool operator ==(Object other) =>
      other is FlarePluginPageRef &&
      other.pluginId == pluginId &&
      other.page == page;

  @override
  int get hashCode => Object.hash(pluginId, page);

  @override
  String toString() => 'FlarePluginPageRef($pluginId, $page)';
}

/// A resolved plugin page (the core SDK's pluginPage result): every
/// [FlarePluginViewModel] field — its nextCursor is the page's next page, and
/// rows and entries page with it — plus [data]. An unavailable page is
/// `{available: false, title: "", unavailableReason}`.
///
/// Equality works as on [FlarePluginViewModel].
@immutable
class FlarePluginPageViewModel extends FlarePluginViewModel {
  const FlarePluginPageViewModel({
    required super.available,
    required super.title,
    super.fields,
    super.actions,
    super.blocks,
    super.inputs,
    super.nextCursor,
    super.menuActions,
    super.unavailableReason,
    super.presentation,
    this.data,
  });

  FlarePluginPageViewModel._json({
    required super.available,
    required super.title,
    required super.fields,
    required super.actions,
    required super.blocks,
    required super.inputs,
    required super.nextCursor,
    required super.menuActions,
    required super.unavailableReason,
    required super.presentation,
    required this.data,
    required super.source,
  }) : super._json(detail: false);

  factory FlarePluginPageViewModel.fromJson(Map<String, Object?> json) {
    final view = FlarePluginViewModel.fromJson(json);
    final data = json['data'];
    return FlarePluginPageViewModel._json(
      available: view.available,
      title: view.title,
      fields: view.fields,
      actions: view.actions,
      blocks: view.blocks,
      inputs: view.inputs,
      nextCursor: view.nextCursor,
      menuActions: view.menuActions,
      unavailableReason: view.unavailableReason,
      presentation: view.presentation,
      data: data is Map ? data.cast<String, Object?>() : null,
      source: jsonEncode(json),
    );
  }

  /// What the page was resolved against (the first page's source result, or
  /// the arguments of a page without a source); only while available. Page
  /// actions carry it back unchanged.
  final Map<String, Object?>? data;
}

/// What `FlarePluginPage`'s onAction carries: the request invokePageAction
/// takes, without the platform and the gesture.
@immutable
class FlarePluginPageActionPayload extends FlarePluginActionPayload {
  const FlarePluginPageActionPayload({
    required this.page,
    this.data,
    super.row,
    super.selection,
    super.formValues,
  });

  /// The page, from the page's reference.
  final FlarePluginPageRef page;

  /// The view's data, when it has one.
  final Map<String, Object?>? data;

  @override
  Map<String, Object?> toJson() => {
    'page': page.toJson(),
    if (data != null) 'data': data,
    ...super.toJson(),
  };

  @override
  String toString() => 'FlarePluginPageActionPayload(${jsonEncode(toJson())})';
}

/// An action run on a plugin page, as the page action request.
typedef FlarePluginPageActionCallback =
    void Function(String actionId, FlarePluginPageActionPayload payload);

// ── pure rules (spec/plugin-view-vectors.json → rules) ──────────────────────

/// The clock plugin time blocks read (epoch milliseconds). Plugin times are the
/// server's clock, so this is the server's now ([FlareServerClock]); tests pin
/// it.
int Function() flarePluginNowMs = FlareServerClock.nowMs;

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
/// view has a detail, is available and is not [embedded], no entries block
/// shows its see all and it has no rows block. The card also needs an
/// `onOpenDetail`.
bool flarePluginShowsDetailKey(
  FlarePluginViewModel view, {
  required bool embedded,
}) =>
    view.detail &&
    view.available &&
    !embedded &&
    !view.blocks.any(
      (b) =>
          b is FlarePluginRowsBlock || (b is FlarePluginEntriesBlock && b.more),
    );

// ── the choices cap (rules.maxSelections) ──────────────────────────────────

/// A multiple choice's cap, or null (a single choice, absent or not a
/// positive count).
int? flarePluginChoiceCap(FlarePluginChoicesBlock block) {
  final max = block.maxSelections;
  return block.multiple && max != null && max > 0 ? max : null;
}

/// Whether option [index] is held back by the cap: the [draft] is full and
/// does not hold it. Ticked options always stay tappable, so unticking one
/// frees the rest.
bool flarePluginChoiceCapped(
  FlarePluginChoicesBlock block,
  List<int> draft,
  int index,
) {
  final cap = flarePluginChoiceCap(block);
  return cap != null && draft.length >= cap && !draft.contains(index);
}

/// Whether [draft] fits the cap (always without one). A selection above a
/// lowered cap does not, so its submit waits until the draft shrinks.
bool flarePluginWithinCap(FlarePluginChoicesBlock block, List<int> draft) {
  final cap = flarePluginChoiceCap(block);
  return cap == null || draft.length <= cap;
}

/// The hint that leads a capped block's footer while it can be chosen
/// ("最多选 2 项"), or null.
String? flarePluginChoiceCapHint(
  FlarePluginChoicesBlock block,
  FlareStrings strings,
) {
  final cap = flarePluginChoiceCap(block);
  return cap != null && block.action != null && !block.closed
      ? strings.pluginViewMaxSelections.replaceAll('{n}', '$cap')
      : null;
}

// ── rows and plugin pages (rules.pageRows, page, pageFilters) ──────────────

/// A page's filter inputs, in the view's input order: the ones its rows block
/// lists in `filters`, or every input when the block lists none; the other
/// inputs belong to row action forms (`spec/plugin-view-vectors.json`
/// filterInputs).
List<FlarePluginInput> flarePluginFilterInputs(FlarePluginViewModel view) {
  final rows = view.blocks.whereType<FlarePluginRowsBlock>().firstOrNull;
  final listed = rows?.filters;
  if (listed == null) return List.of(view.inputs);
  return [
    for (final input in view.inputs)
      if (listed.contains(input.id)) input,
  ];
}

/// The rows to draw: in order, each key once, the first kept.
List<FlarePluginRow> flarePluginRowsOnce(List<FlarePluginRow> rows) {
  final seen = <String>{};
  return [
    for (final row in rows)
      if (seen.add(row.key)) row,
  ];
}

/// A list item's two lines: the first cell, and the other cells in column
/// order (time columns formatted as plugin time blocks are, blank cells
/// skipped) joined with " · ", or null when none is left.
({String primary, String? secondary}) flarePluginRowLines(
  FlarePluginRowsBlock block,
  FlarePluginRow row,
  int nowMs,
  FlareStrings strings, {
  int? utcOffsetMinutes,
}) {
  final texts = [
    for (var i = 0; i < block.columns.length; i += 1)
      switch ((
        block.columns[i].format,
        i < row.cells.length ? row.cells[i] : null,
      )) {
        (FlarePluginColumnFormat.time, FlarePluginRowCell(:final timeMs?)) =>
          flarePluginDateTime(
            timeMs,
            nowMs,
            strings,
            utcOffsetMinutes: utcOffsetMinutes,
          ),
        (_, final cell) => cell?.text ?? '',
      },
  ];
  final rest = texts.skip(1).where((text) => text.trim().isNotEmpty).toList();
  return (
    primary: texts.isEmpty ? '' : texts.first,
    secondary: rest.isEmpty ? null : rest.join(' · '),
  );
}

/// What a plugin page shows (spec PluginPage states).
enum FlarePluginPageState { loading, error, unavailable, loaded }

/// A page's state from what the host passes (rules.page): a view is loaded or
/// unavailable; without one, a failure that is not being retried is the
/// error, anything else is loading.
FlarePluginPageState flarePluginPageState(
  FlarePluginViewModel? view, {
  required bool loading,
  required String? error,
}) {
  if (view != null) {
    return view.available
        ? FlarePluginPageState.loaded
        : FlarePluginPageState.unavailable;
  }
  return (error ?? '').isNotEmpty && !loading
      ? FlarePluginPageState.error
      : FlarePluginPageState.loading;
}

/// The empty state of an unavailable page: the reason's copy, or
/// pluginViewEmpty when the view names none.
String flarePluginPageUnavailableText(
  FlarePluginViewModel view,
  FlareStrings strings,
) => switch (view.unavailableReason) {
  final reason? => flarePluginUnavailableReasonText(reason, strings),
  null => strings.pluginViewEmpty,
};

/// One select filter of a page: its tabs, all (value null) first, and the
/// selected choice's value (null: all).
@immutable
class FlarePluginPageFilter {
  const FlarePluginPageFilter({
    required this.input,
    required this.tabs,
    this.selected,
  });
  final FlarePluginInput input;
  final List<({String? value, String label})> tabs;
  final String? selected;
}

/// A page's select filters: with a rows block, the [flarePluginFilterInputs]
/// of kind select, each with [all] and then its choices; selected is the
/// host's value in [filters] when it is one of the choices, else all.
List<FlarePluginPageFilter> flarePluginPageFilters(
  FlarePluginViewModel view,
  Map<String, Object?> filters,
  String all,
) {
  if (!view.blocks.any((b) => b is FlarePluginRowsBlock)) return const [];
  return [
    for (final input in flarePluginFilterInputs(view))
      if (input.kind == FlarePluginInputKind.select && input.choices.isNotEmpty)
        FlarePluginPageFilter(
          input: input,
          tabs: [
            (value: null, label: all),
            for (final choice in input.choices)
              (value: choice.value, label: choice.label),
          ],
          selected: switch (filters[input.id]) {
            final String value
                when input.choices.any((c) => c.value == value) =>
              value,
            _ => null,
          },
        ),
  ];
}

/// The host's [filters] with [inputId] set to [value], or without it for all
/// (null).
Map<String, Object?> flarePluginPageFilterValues(
  Map<String, Object?> filters,
  String inputId,
  String? value,
) {
  final next = Map<String, Object?>.of(filters);
  if (value == null) {
    next.remove(inputId);
  } else {
    next[inputId] = value;
  }
  return next;
}

/// The payload of an action run on a page: the page, the view's data when it
/// has one, and what the action carries.
FlarePluginPageActionPayload flarePluginPagePayload(
  FlarePluginPageRef page,
  FlarePluginViewModel? view,
  FlarePluginActionPayload payload,
) => FlarePluginPageActionPayload(
  page: page,
  data: view is FlarePluginPageViewModel ? view.data : null,
  row: payload.row,
  selection: payload.selection,
  formValues: payload.formValues,
);

/// The words for [reason] (`spec/plugin-view-vectors.json` → unavailableReasons).
String flarePluginUnavailableReasonText(
  FlarePluginUnavailableReason reason,
  FlareStrings strings,
) => switch (reason) {
  FlarePluginUnavailableReason.disabled =>
    strings.pluginViewUnavailableDisabled,
  FlarePluginUnavailableReason.notInstalled =>
    strings.pluginViewUnavailableNotInstalled,
  FlarePluginUnavailableReason.noPermission =>
    strings.pluginViewUnavailableNoPermission,
  FlarePluginUnavailableReason.unsupportedPlatform =>
    strings.pluginViewUnavailableUnsupportedPlatform,
  FlarePluginUnavailableReason.incompatibleVersion =>
    strings.pluginViewUnavailableIncompatibleVersion,
  FlarePluginUnavailableReason.catalogUnreachable =>
    strings.pluginViewUnavailableCatalogUnreachable,
  FlarePluginUnavailableReason.unboundCopy =>
    strings.pluginViewUnavailableUnboundCopy,
};

/// The reason line of a view (rules.unavailableReason): an unavailable view
/// says why, led by the envelope's [displayName] and " · " when there is one
/// ("投票 · 插件已停用"); a read-only copy closes with "副本，仅供查看"; a view
/// without a reason has no line.
String? flarePluginReasonLine(
  FlarePluginViewModel view,
  FlareStrings strings, {
  String? displayName,
}) {
  final reason = view.unavailableReason;
  if (reason == null) return null;
  final text = flarePluginUnavailableReasonText(reason, strings);
  if (reason == FlarePluginUnavailableReason.unboundCopy) return text;
  if (view.available) return null;
  final name = displayName?.trim() ?? '';
  return name.isEmpty ? text : '$name · $text';
}

/// Whether the view is a read-only copy (unbound_copy).
bool flarePluginReadOnly(FlarePluginViewModel view) =>
    view.unavailableReason == FlarePluginUnavailableReason.unboundCopy;

/// The header row of a group in a grouped entries list (rules.entriesGrouped):
/// the label, then "N 票" when the count is known (plural by [locale]) and
/// "P%" when the percent is, joined with " · ".
String flarePluginEntryGroupHeader(
  FlarePluginEntryGroup group,
  FlareStrings strings, {
  String? locale,
}) => [
  group.label,
  if (group.count != null) strings.pluginViewVotesCount(group.count!, locale),
  if (group.percent != null) '${group.percent}%',
].join(' · ');

/// The name drawn for a user id the host could not resolve: the id's tail,
/// [flareIdTail] (its last 4 scalars).
String flarePluginFallbackName(String userId) => flareIdTail(userId);

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
