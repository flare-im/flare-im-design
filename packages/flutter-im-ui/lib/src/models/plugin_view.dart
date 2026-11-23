import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../tokens/flare_strings.dart';
import 'capability_ui.dart' show flarePaymentAmountText;
import 'display_name.dart';
import 'plugin_layout.dart' show flarePluginShowsCounter;
import '../components/flare_icon.dart' show flareIconNames;
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

  /// This build cannot draw it; [FlarePluginViewModel.minBuild] names the
  /// first build that can, when known (`FlarePluginUpgradeNotice`).
  upgradeRequired,
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
  file,
  text,
  password,
  textarea,
  number,
  toggle,
  select,
  datetime,
  options,
  members,

  /// An amount: `{amount: "<decimal>", currency}` (vocabulary 2).
  money,

  /// One picture, uploaded like [file] (vocabulary 2).
  image,

  /// A photo of a document side, uploaded like [file] (vocabulary 2).
  document,

  /// A one-time location the engine writes when the page's locationOnce
  /// action completes: [FlarePluginLocationValue].
  location,
}

/// Inputs whose value is an uploaded file's `{fileId}`: file, image and
/// document.
bool flarePluginIsUpload(FlarePluginInputKind kind) =>
    kind == FlarePluginInputKind.file ||
    kind == FlarePluginInputKind.image ||
    kind == FlarePluginInputKind.document;

/// Which side of a document a document input takes.
enum FlarePluginDocumentSide { front, back, holding }

/// How precise a fix a location input takes.
enum FlarePluginLocationPrecision { coarse, fine }

/// A location input's value (flare-plugin-protocol UiLocationValue): what the
/// engine writes into the input when the viewer's one-time location
/// (locationOnce) completes, already truncated to the input's precision.
@immutable
class FlarePluginLocationValue {
  const FlarePluginLocationValue({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.precision,
  });

  final double latitude;
  final double longitude;
  final int accuracyM;
  final FlarePluginLocationPrecision precision;

  /// [value] as a location of [precision] (UiLocationValue::fits): the same
  /// precision, a point on the globe, at most 2 (coarse) or 5 (fine) decimal
  /// places and a whole accuracy of at least 1000 m or 1 m. Else null.
  static FlarePluginLocationValue? of(
    Object? value,
    FlarePluginLocationPrecision? precision,
  ) {
    if (value is FlarePluginLocationValue) value = value.toJson();
    if (value is! Map || precision == null) return null;
    if (value['precision'] != precision.name) return null;
    final lat = value['latitude'], lng = value['longitude'];
    final accuracy = value['accuracyM'];
    if (lat is! num || lng is! num || accuracy is! num) return null;
    if (!lat.isFinite || !lng.isFinite || !accuracy.isFinite) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    final places = precision == FlarePluginLocationPrecision.coarse ? 2 : 5;
    final floor = precision == FlarePluginLocationPrecision.coarse ? 1000 : 1;
    if (_places(lat) > places || _places(lng) > places) return null;
    if (accuracy != accuracy.roundToDouble() || accuracy < floor) return null;
    return FlarePluginLocationValue(
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      accuracyM: accuracy.toInt(),
      precision: precision,
    );
  }

  static int _places(num n) {
    if (n is int || n == n.roundToDouble()) return 0;
    final text = n.abs().toString();
    if (text.contains('e')) return 99;
    final dot = text.indexOf('.');
    return dot < 0 ? 0 : text.length - dot - 1;
  }

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracyM': accuracyM,
    'precision': precision.name,
  };

  /// The fix as the input shows it: "31.23°N, 121.47°E".
  String get text {
    String deg(double v) {
      final abs = v.abs();
      return abs == abs.roundToDouble() ? '${abs.toInt()}' : '$abs';
    }

    return '${deg(latitude)}°${latitude < 0 ? 'S' : 'N'}, '
        '${deg(longitude)}°${longitude < 0 ? 'W' : 'E'}';
  }

  @override
  bool operator ==(Object other) =>
      other is FlarePluginLocationValue &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.accuracyM == accuracyM &&
      other.precision == precision;

  @override
  int get hashCode => Object.hash(latitude, longitude, accuracyM, precision);
}

/// What a location input shows while the host locates: the host's state by
/// input id.
@immutable
class FlarePluginLocationState {
  const FlarePluginLocationState({
    this.value,
    this.locating = false,
    this.error,
  });

  /// The fix the engine wrote (`{kind: "input", input, value}`).
  final FlarePluginLocationValue? value;
  final bool locating;
  final String? error;
}

/// A location input's key: `locate` asks the host to run the page's
/// locationOnce action into this input; `clear` empties it.
enum FlarePluginLocationActionKind { locate, clear }

@immutable
class FlarePluginLocationAction {
  const FlarePluginLocationAction({
    required this.action,
    required this.inputId,
    required this.input,
    required this.formValues,
  });
  final FlarePluginLocationActionKind action;
  final String inputId;
  final FlarePluginInput input;
  final Map<String, Object?> formValues;
}

/// The amount rules of a money input, read by the core SDK: no paths left.
@immutable
class FlarePluginMoneyRules {
  const FlarePluginMoneyRules({this.currency, this.scale, this.min, this.max});
  factory FlarePluginMoneyRules.fromJson(Map<String, Object?> json) =>
      FlarePluginMoneyRules(
        currency: _optString(json['currency']),
        scale: _optInt(json['scale']),
        min: _optString(json['min']),
        max: _optString(json['max']),
      );
  final String? currency;

  /// Fraction digits the amount may have; 2 when null.
  final int? scale;

  /// Bounds as decimal strings.
  final String? min;
  final String? max;
}

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
double? _optDouble(Object? value) =>
    value is num && value.isFinite ? value.toDouble() : null;
Map<String, Object?>? _optMap(Object? value) =>
    value is Map ? value.cast<String, Object?>() : null;
String? _optString(Object? value) => value is String ? value : null;
int _int(Object? value) => value is num ? value.toInt() : 0;
int? _optInt(Object? value) => value is num ? value.toInt() : null;

/// The widest instant a kit draws, in ms either side of the epoch (the
/// ECMAScript `Date` range, spec blocks2.instants).
const flarePluginMaxInstantMs = 8640000000000000;

/// An instant in plugin data, or null when it is absent or outside
/// ±[flarePluginMaxInstantMs]: a view never asks `DateTime` for one it cannot
/// hold.
int? flarePluginInstant(Object? value) =>
    value is num && value.isFinite && value.abs() <= flarePluginMaxInstantMs
    ? value.toInt()
    : null;
bool _bool(Object? value) => value == true;
List<Map<String, Object?>> _maps(Object? value) => value is List
    ? [
        for (final item in value)
          if (item is Map) item.cast<String, Object?>(),
      ]
    : const [];

@immutable
class FlarePluginField {
  const FlarePluginField({
    required this.label,
    required this.value,
    this.format,
    this.tone,
    this.unmapped = false,
  });
  factory FlarePluginField.fromJson(Map<String, Object?> json) =>
      FlarePluginField(
        label: _string(json['label']),
        value: _string(json['value']),
        format: _optMap(json['format']),
        tone: json['tone'] == null ? null : flarePluginBadgeTone(json['tone']),
        unmapped: _bool(json['unmapped']),
      );
  final String label;
  final String value;

  /// What the resolved format adds to [value] (ResolvedUiFormat, as JSON);
  /// read through [flarePluginFormatText]. The text alone is always right.
  final Map<String, Object?>? format;

  /// The tone its value label declares: drawn as the kit tag
  /// (rules.statusValues); null draws the text.
  final FlarePluginTone? tone;

  /// The plugin declared values and this one is not among them: drawn as
  /// pluginView.unknownStatus, never the raw value.
  final bool unmapped;

  /// A `format: reference` field (an order or proof id): folded under
  /// pluginView.references (rules.references).
  bool get isReference => format?['kind'] == 'reference';
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
    this.target,
    this.group,
    this.icon,
    this.disabledReason,
  });
  factory FlarePluginAction.fromJson(Map<String, Object?> json) =>
      FlarePluginAction(
        id: _string(json['id']),
        label: _string(json['label']),
        style: _enum(FlarePluginActionStyle.values, json['style']),
        group: _optString(json['group']),
        icon: _optString(json['icon']),
        disabledReason: _optString(json['disabledReason']),
        confirm: _optString(json['confirm']),
        form: [
          for (final id
              in (json['form'] is List ? json['form'] as List : const []))
            if (id is String) id,
        ],
        target: switch (_optMap(json['target'])) {
          final target? => FlarePluginActionTarget.fromJson(target),
          null => null,
        },
      );
  final String id;
  final String label;
  final FlarePluginActionStyle? style;

  /// The list group a destination joins on an overview page: `common` or
  /// `records` (rules.actionRoles); null joins common.
  final String? group;

  /// A kit icon name drawn in the action's list row (none leaves no gap).
  final String? icon;

  /// Why the action cannot run now (R2.5; the core resolves disabledWhen and
  /// sends the translated reason): its key is disabled, not hidden, and the
  /// reason is written under it.
  final String? disabledReason;

  /// Asked first in the kit DangerConfirm.
  final String? confirm;

  /// Input ids collected first in [FlarePluginForm].
  final List<String> form;

  /// Where the action goes, as the view gives it. The kit reads a native
  /// target's `into`: a page action writing into one of the form's own
  /// inputs runs through that input's key ([flarePluginNativeIntoKey]), so
  /// the host's answer lands in the form's current scope.
  final FlarePluginActionTarget? target;
}

/// An action's target (flare-plugin-protocol UiActionTarget): `native`
/// ([capability], [params], [into]), `operation` or `page`. The kit only
/// reads a native one.
class FlarePluginActionTarget {
  const FlarePluginActionTarget({
    required this.kind,
    this.capability,
    this.params,
    this.into,
  });
  factory FlarePluginActionTarget.fromJson(Map<String, Object?> json) =>
      FlarePluginActionTarget(
        kind: _string(json['kind']),
        capability: _optString(json['capability']),
        params: _optMap(json['params']),
        into: _optString(json['into']),
      );
  final String kind;
  final String? capability;
  final Map<String, Object?>? params;

  /// The page input the native capability writes into.
  final String? into;
}

/// Host capabilities that write a file into an upload input.
const flarePluginUploadCapabilities = [
  'documentCapture',
  'selectImage',
  'camera',
  'selectFile',
];

/// Which key of [input] a native action [target] runs through when it names
/// that input as `into` (spec/plugin-native-into-vectors.json): `file` (the
/// input's own choose, or replace when it holds a file) for an upload
/// capability into an upload input, `location` (its locate key) for
/// `locationOnce` into a location input, null otherwise (the action goes out
/// as itself).
String? flarePluginNativeIntoKey(
  FlarePluginActionTarget? target,
  FlarePluginInput input,
) {
  if (target == null ||
      target.kind != 'native' ||
      target.into == null ||
      target.into != input.id) {
    return null;
  }
  if (target.capability == 'locationOnce') {
    return input.kind == FlarePluginInputKind.location ? 'location' : null;
  }
  return flarePluginUploadCapabilities.contains(target.capability) &&
          flarePluginIsUpload(input.kind)
      ? 'file'
      : null;
}

/// An entry's or a row's enumerated value as words and a tone (the plugin's
/// valueLabels), such as a ledger line's kind; drawn as the kit tag
/// (spec/plugin-view-vectors.json rules.badge).
@immutable
class FlarePluginBadge {
  const FlarePluginBadge({
    required this.text,
    this.tone = FlarePluginTone.neutral,
    this.unmapped = false,
  });
  static FlarePluginBadge? fromJson(Object? json) => json is Map
      ? FlarePluginBadge(
          text: _string(json['text']),
          tone: flarePluginBadgeTone(json['tone']),
          unmapped: _bool(json['unmapped']),
        )
      : null;

  /// The words, translated; an unmapped value as the plugin sent it.
  final String text;
  final FlarePluginTone tone;

  /// Not among the plugin's declared values: drawn as
  /// pluginView.unknownStatus (rules.statusValues).
  final bool unmapped;
}

/// A badge's tone as drawn: one of [FlarePluginTone], brand as info,
/// anything else neutral (a tone from a newer protocol).
FlarePluginTone flarePluginBadgeTone(Object? tone) => tone == 'brand'
    ? FlarePluginTone.info
    : _enum(FlarePluginTone.values, tone) ?? FlarePluginTone.neutral;

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
                timeMs: flarePluginInstant(e['timeMs']),
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
          tone: flarePluginBadgeTone(json['tone']),
          unmapped: _bool(json['unmapped']),
        );
      case 'result':
        return FlarePluginResultBlock(
          state: _string(json['state']),
          title: _string(json['title']),
          tone: flarePluginBadgeTone(json['tone']),
          unmapped: _bool(json['unmapped']),
          amount: _optString(json['amount']),
          format: _optMap(json['format']),
          description: _optString(json['description']),
        );
      case 'progress':
        return FlarePluginProgressBlock(
          label: _optString(json['label']),
          value: _int(json['value']),
          total: _int(json['total']),
          percent: _int(json['percent']),
        );
      case 'time':
        // No instant a kit can draw: the block is left out, as in every kit.
        final at = flarePluginInstant(json['atMs']);
        if (at == null) return null;
        return FlarePluginTimeBlock(
          label: _optString(json['label']),
          atMs: at,
          endMs: flarePluginInstant(json['endMs']),
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
                      timeMs: flarePluginInstant(cell['timeMs']),
                      format: _optMap(cell['format']),
                      tone: cell['tone'] == null
                          ? null
                          : flarePluginBadgeTone(cell['tone']),
                      unmapped: _bool(cell['unmapped']),
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
          groupByDay: _bool(json['groupByDay']),
          // A name the kit draws; any other draws the plain list.
          icon: flareIconNames.contains(json['icon'])
              ? json['icon']! as String
              : null,
          filters: filters is List
              ? [
                  for (final id in filters)
                    if (id is String) id,
                ]
              : null,
        );
      case 'section':
        return FlarePluginSectionBlock(
          label: _optString(json['label']),
          collapsed: _bool(json['collapsed']),
          blocks: [
            for (final b in _maps(json['blocks']))
              if (b['kind'] != 'section')
                if (FlarePluginBlock.fromJson(b) case final block?) block,
          ],
        );
      case 'stats':
        return FlarePluginStatsBlock(
          items: [
            for (final i in _maps(json['items']))
              FlarePluginStat(
                label: _string(i['label']),
                value: _string(i['value']),
                format: _optMap(i['format']),
                trend: i['trend'] is Map
                    ? FlarePluginTrend(
                        text: _string((i['trend'] as Map)['text']),
                        direction: flarePluginTrendDirection(
                          (i['trend'] as Map)['direction'],
                        ),
                      )
                    : null,
                tone: i['tone'] == null
                    ? null
                    : flarePluginBadgeTone(i['tone']),
              ),
          ],
        );
      case 'chart':
        final chartKind = _enum(FlarePluginChartKind.values, json['chartKind']);
        if (chartKind == null) return null;
        return FlarePluginChartBlock(
          chartKind: chartKind,
          series: [
            for (final s in _maps(json['series']))
              FlarePluginChartSeries(
                label: _optString(s['label']),
                points: [
                  for (final p in _maps(s['points']))
                    if (_optDouble(p['value']) case final value?)
                      FlarePluginChartPoint(
                        label: _string(p['label']),
                        value: value,
                        text: _string(p['text']),
                      ),
                ],
              ),
          ],
          emptyText: _optString(json['emptyText']),
        );
      case 'image':
        return FlarePluginImageBlock(
          asset: _optString(json['asset']),
          fileId: _optString(json['fileId']),
          aspect: _string(json['aspect']),
          alt: _string(json['alt']),
        );
      case 'qr':
        return FlarePluginQrBlock(
          value: _string(json['value']),
          label: _optString(json['label']),
          caption: _optString(json['caption']),
          refreshOperation: _optString(json['refreshOperation']),
          valuePath: _string(json['valuePath']),
          expiresAtPath: _optString(json['expiresAtPath']),
          expiresAtMs: flarePluginInstant(json['expiresAtMs']),
        );
      case 'hero':
        return FlarePluginHeroBlock(
          label: _optString(json['label']),
          value: _string(json['value']),
          amount: _bool(json['amount']),
          format: _optMap(json['format']),
          subtitle: _optString(json['subtitle']),
          tone: flarePluginHeroTone(json['tone']),
          maskable: _bool(json['maskable']),
          actions: [
            for (final a in _maps(json['actions']))
              FlarePluginAction.fromJson(a),
          ],
        );
      case 'steps':
        return FlarePluginStepsBlock(
          items: [
            for (final i in _maps(json['items']))
              (
                label: _string(i['label']),
                state: flarePluginStepState(i['state']),
              ),
          ],
        );
      case 'banner':
        final action = json['action'];
        return FlarePluginBannerBlock(
          tone: flarePluginBannerTone(json['tone']),
          text: _string(json['text']),
          action: action is Map
              ? FlarePluginAction.fromJson(action.cast<String, Object?>())
              : null,
        );
      case 'protected-media':
        final action = json['action'];
        final urlPath = _string(json['urlPath']);
        final inputName = _string(json['inputName']);
        if (urlPath.isEmpty || inputName.isEmpty) return null;
        return FlarePluginProtectedMediaBlock(
          label: _optString(json['label']),
          items: [
            for (final i in _maps(json['items']))
              if (_string(i['id']).isNotEmpty)
                FlarePluginProtectedItem(
                  id: _string(i['id']),
                  label: _string(i['label']),
                  mediaType: _optString(i['mediaType']),
                  input: i['input'],
                ),
          ],
          action: action is Map
              ? FlarePluginAction.fromJson(action.cast<String, Object?>())
              : null,
          inputName: inputName,
          reasonInput: _optString(json['reasonInput']),
          urlPath: urlPath,
          emptyText: _optString(json['emptyText']),
        );
      case 'timeline':
        return FlarePluginTimelineBlock(
          items: [
            for (final i in _maps(json['items']))
              // An item without an instant a kit can draw is left out.
              if (flarePluginInstant(i['atMs']) case final at?)
                FlarePluginTimelineItem(
                  atMs: at,
                  title: _string(i['title']),
                  detail: _optString(i['detail']),
                  status: FlarePluginBadge.fromJson(i['status']),
                ),
          ],
          emptyText: _optString(json['emptyText']),
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
    this.timeMs,
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

  /// When it happened, drawn after [text] in the device zone.
  final int? timeMs;
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
    this.unmapped = false,
  });
  final String? label;
  final String text;
  final FlarePluginTone tone;

  /// Not among the plugin's declared values (rules.statusValues).
  final bool unmapped;
}

/// The outcome of a money action, a verification submit or a failed send
/// (rules.result): drawn as `FlareResultView` at the top of the page.
final class FlarePluginResultBlock extends FlarePluginBlock {
  const FlarePluginResultBlock({
    required this.state,
    required this.title,
    this.tone = FlarePluginTone.neutral,
    this.unmapped = false,
    this.amount,
    this.format,
    this.description,
  });

  /// The raw state (`pending` polls).
  final String state;

  /// The state's label.
  final String title;
  final FlarePluginTone tone;
  final bool unmapped;
  final String? amount;
  final Map<String, Object?>? format;
  final String? description;
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
  const FlarePluginRowCell({
    required this.text,
    this.timeMs,
    this.tone,
    this.unmapped = false,
    this.format,
  });
  final String text;

  /// What the resolved format adds to [text] (`{kind: person, userId}` for a
  /// person, money, …).
  final Map<String, Object?>? format;

  /// A person cell's user: drawn as the person's name, never the id
  /// (rules.rowsIcon).
  String? get userId =>
      format?['kind'] == 'person' && format?['userId'] is String
      ? format!['userId']! as String
      : null;

  /// Set in a time column: the instant, drawn in the device zone.
  final int? timeMs;

  /// A status column's tone: the cell draws as the kit tag
  /// (rules.statusValues).
  final FlarePluginTone? tone;

  /// Not among the column's declared values.
  final bool unmapped;
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
    this.groupByDay = false,
    this.icon,
  });

  /// A kit icon name: each row draws as a record, the 5.8 ledger line
  /// ([flarePluginRecordLine]).
  final String? icon;

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

  /// Day headings over the rows by the first time column
  /// ([flarePluginRowDayHeadings]).
  final bool groupByDay;
}

// ── vocabulary 2 blocks (docs/plugin-components.md) ────────────────────────

/// Blocks under a heading, collapsible. Never holds a section, rows or
/// protected media; children of kinds the kit does not know are skipped.
final class FlarePluginSectionBlock extends FlarePluginBlock {
  const FlarePluginSectionBlock({
    this.label,
    this.collapsed = false,
    this.blocks = const [],
  });
  final String? label;
  final bool collapsed;
  final List<FlarePluginBlock> blocks;
}

enum FlarePluginTrendDirection { up, down, flat }

/// How a figure moved: the text as sent and its direction.
@immutable
class FlarePluginTrend {
  const FlarePluginTrend({
    required this.text,
    this.direction = FlarePluginTrendDirection.flat,
  });
  final String text;
  final FlarePluginTrendDirection direction;
}

@immutable
class FlarePluginStat {
  const FlarePluginStat({
    required this.label,
    required this.value,
    this.format,
    this.trend,
    this.tone,
  });
  final String label;

  /// The plain text, whatever [format] says.
  final String value;
  final Map<String, Object?>? format;
  final FlarePluginTrend? trend;
  final FlarePluginTone? tone;
}

/// 2 to 6 figures side by side.
final class FlarePluginStatsBlock extends FlarePluginBlock {
  const FlarePluginStatsBlock({required this.items});
  final List<FlarePluginStat> items;
}

enum FlarePluginChartKind { bar, line, donut }

@immutable
class FlarePluginChartPoint {
  const FlarePluginChartPoint({
    required this.label,
    required this.value,
    required this.text,
  });
  final String label;
  final double value;

  /// The value as text, through the block's format.
  final String text;
}

@immutable
class FlarePluginChartSeries {
  const FlarePluginChartSeries({this.label, this.points = const []});
  final String? label;
  final List<FlarePluginChartPoint> points;
}

/// Up to 3 series (one for a donut) of up to 60 points, drawn with Canvas
/// from kit colours; no chart library.
final class FlarePluginChartBlock extends FlarePluginBlock {
  const FlarePluginChartBlock({
    required this.chartKind,
    this.series = const [],
    this.emptyText,
  });
  final FlarePluginChartKind chartKind;
  final List<FlarePluginChartSeries> series;
  final String? emptyText;
}

/// A picture at its declared aspect: a package [asset] or a private
/// [fileId]; the host's `resolveImage` turns either into an image.
final class FlarePluginImageBlock extends FlarePluginBlock {
  const FlarePluginImageBlock({
    this.asset,
    this.fileId,
    required this.aspect,
    required this.alt,
  });
  final String? asset;
  final String? fileId;

  /// `1:1`, `4:3`, `16:9` or `3:4` ([flarePluginImageRatio]).
  final String aspect;
  final String alt;
}

/// What `onQrRefresh` carries: the host runs [operation] and passes back a
/// view with the fresh code.
typedef FlarePluginQrRefresh = ({
  String operation,
  String valuePath,
  String? expiresAtPath,
});

/// A QR code of [value]; [refreshOperation] (a query) returns a fresh one.
final class FlarePluginQrBlock extends FlarePluginBlock {
  const FlarePluginQrBlock({
    required this.value,
    this.label,
    this.caption,
    this.refreshOperation,
    this.valuePath = '',
    this.expiresAtPath,
    this.expiresAtMs,
  });
  final String value;
  final String? label;
  final String? caption;
  final String? refreshOperation;
  final String valuePath;
  final String? expiresAtPath;
  final int? expiresAtMs;
}

enum FlarePluginHeroTone { neutral, positive, warning, brand }

/// The page's lead figure (one per document) with up to 3 owned actions.
final class FlarePluginHeroBlock extends FlarePluginBlock {
  const FlarePluginHeroBlock({
    this.label,
    required this.value,
    this.amount = false,
    this.format,
    this.subtitle,
    this.tone = FlarePluginHeroTone.neutral,
    this.actions = const [],
    this.maskable = false,
  });
  final String? label;
  final String value;
  final bool amount;
  final Map<String, Object?>? format;
  final String? subtitle;
  final FlarePluginHeroTone tone;
  final List<FlarePluginAction> actions;

  /// The viewer may hide [value] behind an eye toggle.
  final bool maskable;
}

enum FlarePluginStepState { pending, current, done, failed }

/// 2 to 6 steps of a process.
final class FlarePluginStepsBlock extends FlarePluginBlock {
  const FlarePluginStepsBlock({required this.items});
  final List<({String label, FlarePluginStepState state})> items;
}

enum FlarePluginBannerTone { info, success, warning, danger }

/// A prominent notice (at most 2 per document) with an optional owned action.
final class FlarePluginBannerBlock extends FlarePluginBlock {
  const FlarePluginBannerBlock({
    this.tone = FlarePluginBannerTone.info,
    required this.text,
    this.action,
  });
  final FlarePluginBannerTone tone;
  final String text;
  final FlarePluginAction? action;
}

@immutable
class FlarePluginTimelineItem {
  const FlarePluginTimelineItem({
    required this.atMs,
    required this.title,
    this.detail,
    this.status,
  });
  final int atMs;
  final String title;
  final String? detail;
  final FlarePluginBadge? status;
}

/// One item of a protected media block; nothing about its content is in the
/// view.
@immutable
class FlarePluginProtectedItem {
  const FlarePluginProtectedItem({
    required this.id,
    required this.label,
    this.mediaType,
    this.input,
  });
  final String id;
  final String label;
  final String? mediaType;

  /// The action's declared input, bound from the resolved data.
  final Object? input;

  bool get isImage => mediaType == null || mediaType!.startsWith('image/');
}

/// Private material read one item at a time through [action]: with a stated
/// reason when [reasonInput] is declared (a console), with one tap on the
/// owner's own page (no [reasonInput]; the operation is owner-scoped).
final class FlarePluginProtectedMediaBlock extends FlarePluginBlock {
  const FlarePluginProtectedMediaBlock({
    this.label,
    this.items = const [],
    this.action,
    required this.inputName,
    this.reasonInput,
    required this.urlPath,
    this.emptyText,
  });
  final String? label;
  final List<FlarePluginProtectedItem> items;

  /// Absent on a read-only copy.
  final FlarePluginAction? action;
  final String inputName;
  final String? reasonInput;

  /// Reads the action's result (a JSON pointer): the address to draw.
  final String urlPath;
  final String? emptyText;

  /// Whether a read first asks the viewer why
  /// (spec/capability-ui-vectors.json protectedMediaReason).
  bool get asksReason => reasonInput != null && reasonInput!.isNotEmpty;
}

/// What the host has for a protected media item.
@immutable
class FlarePluginProtectedMediaState {
  const FlarePluginProtectedMediaState({
    this.url,
    this.loading = false,
    this.error,
  });

  /// The read's address: the server's short-lived https address
  /// (`?grant=`), or a data:image the host fetched.
  final String? url;
  final bool loading;
  final String? error;
}

/// A protected media read for the host to run and audit.
@immutable
class FlarePluginProtectedMediaRead {
  const FlarePluginProtectedMediaRead({
    required this.action,
    required this.item,
    required this.reason,
    required this.urlPath,
    required this.formValues,
  });
  final FlarePluginAction action;
  final FlarePluginProtectedItem item;

  /// Empty when the block asks for none.
  final String reason;
  final String urlPath;

  /// The item under `inputName` and, when declared, the reason.
  final Map<String, Object?> formValues;
}

/// The address of [url] a protected media block may draw: https (the
/// server's grant address) or data:image; never anything else.
Uri? flarePluginProtectedMediaSource(String? url) {
  if (url == null || url.isEmpty) return null;
  final lower = url.toLowerCase();
  if (lower.startsWith('data:image/')) return Uri.tryParse(url);
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri;
}

/// The address at [urlPath] (a JSON pointer) of a protected media action's
/// result.
String? flarePluginProtectedMediaUrl(Object? result, String urlPath) {
  var value = result;
  for (final key in urlPath.split('/').skip(1)) {
    if (value is! Map) return null;
    value = value[key];
  }
  return value is String && value.isNotEmpty ? value : null;
}

/// Up to 50 dated items, in the plugin's order.
final class FlarePluginTimelineBlock extends FlarePluginBlock {
  const FlarePluginTimelineBlock({this.items = const [], this.emptyText});
  final List<FlarePluginTimelineItem> items;
  final String? emptyText;
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
    this.file,
    this.showWhen,
    this.money,
    this.side,
    this.precision,
    this.help,
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
      file: json['file'] is Map
          ? FlarePluginFilePolicy.fromJson(
              (json['file'] as Map).cast<String, Object?>(),
            )
          : null,
      showWhen: json['showWhen'] is Map
          ? FlarePluginInputCondition.fromJson(
              (json['showWhen'] as Map).cast<String, Object?>(),
            )
          : null,
      money: json['money'] is Map
          ? FlarePluginMoneyRules.fromJson(
              (json['money'] as Map).cast<String, Object?>(),
            )
          : null,
      side: _enum(FlarePluginDocumentSide.values, json['side']),
      precision: _enum(FlarePluginLocationPrecision.values, json['precision']),
      help: _optString(json['help'])?.trim().isNotEmpty == true
          ? json['help'] as String
          : null,
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

  /// file, image and document: what may be uploaded and how.
  final FlarePluginFilePolicy? file;
  final FlarePluginInputCondition? showWhen;

  /// money only.
  final FlarePluginMoneyRules? money;

  /// document only.
  final FlarePluginDocumentSide? side;

  /// location only: how precise a fix it takes.
  final FlarePluginLocationPrecision? precision;

  /// Help under the input (R6: caption, text.secondary), already translated.
  final String? help;
}

@immutable
class FlarePluginInputCondition {
  const FlarePluginInputCondition({required this.field, required this.anyOf});
  factory FlarePluginInputCondition.fromJson(Map<String, Object?> json) =>
      FlarePluginInputCondition(
        field: _string(json['field']),
        anyOf: (json['anyOf'] as List? ?? const [])
            .whereType<String>()
            .toList(),
      );
  final String field;
  final List<String> anyOf;
}

@immutable
class FlarePluginFileUploadPolicy {
  const FlarePluginFileUploadPolicy({
    required this.prepareOperation,
    required this.completeOperation,
    required this.purpose,
  });
  final String prepareOperation, completeOperation, purpose;
}

@immutable
class FlarePluginFilePolicy {
  const FlarePluginFilePolicy({
    required this.accept,
    required this.maxBytes,
    required this.upload,
  });
  factory FlarePluginFilePolicy.fromJson(Map<String, Object?> json) {
    final upload = json['upload'] is Map ? (json['upload'] as Map) : const {};
    return FlarePluginFilePolicy(
      accept: (json['accept'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      maxBytes: _optInt(json['maxBytes']) ?? 0,
      upload: FlarePluginFileUploadPolicy(
        prepareOperation: _string(upload['prepareOperation']),
        completeOperation: _string(upload['completeOperation']),
        purpose: _string(upload['purpose']),
      ),
    );
  }
  final List<String> accept;
  final int maxBytes;
  final FlarePluginFileUploadPolicy upload;
}

/// Opaque protected material identity. No bytes, URL, or read grant is a form value.
@immutable
class FlarePluginFileValue {
  const FlarePluginFileValue({required this.fileId});
  final String fileId;
  Map<String, Object?> toJson() => {'fileId': fileId};
  static FlarePluginFileValue? fromValue(Object? value) {
    if (value is FlarePluginFileValue) value = value.toJson();
    if (value is! Map || value.length != 1 || value['fileId'] is! String)
      return null;
    final id = value['fileId'] as String;
    return RegExp(r'^[A-Za-z0-9_:-]{1,128}$').hasMatch(id) && id == id.trim()
        ? FlarePluginFileValue(fileId: id)
        : null;
  }
}

enum FlarePluginFilePhase { empty, selected, uploading, uploaded, failed }

enum FlarePluginFileActionKind {
  choose,
  retry,
  cancel,
  replace,
  remove,
  preview,
  invalidate,
}

/// Host-only transfer state. Both tickets must match the mounted form field.
@immutable
class FlarePluginFileState {
  const FlarePluginFileState({
    required this.scope,
    required this.generation,
    required this.phase,
    this.value,
    this.fileName,
    this.progress,
    this.error,
    this.preview = false,
    this.previewLoading = false,
    this.image,
  });
  final String scope;
  final int generation;
  final FlarePluginFilePhase phase;
  final FlarePluginFileValue? value;
  final String? fileName, error;
  final double? progress;
  final bool preview, previewLoading;

  /// The picture the viewer picked or captured, held in memory by the host
  /// so a document slot can show it (§6.3); never uploaded from here.
  final Uint8List? image;
}

@immutable
class FlarePluginFileAction {
  const FlarePluginFileAction({
    required this.action,
    required this.inputId,
    required this.input,
    required this.scope,
    required this.generation,
    required this.formValues,
  });
  final FlarePluginFileActionKind action;
  final String inputId, scope;
  final FlarePluginInput input;
  final int generation;
  final Map<String, Object?> formValues;
}

int _pluginFileScope = 0;
String flarePluginNewFileScope() =>
    'plugin-form-${DateTime.now().microsecondsSinceEpoch}-${++_pluginFileScope}';
bool flarePluginInputVisible(
  FlarePluginInput input,
  List<FlarePluginInput> inputs,
  Map<String, Object?> draft,
) {
  final condition = input.showWhen;
  if (condition == null) return true;
  final index = inputs.indexOf(input);
  final controller = inputs.indexWhere((item) => item.id == condition.field);
  return controller >= 0 &&
      controller < index &&
      inputs[controller].kind == FlarePluginInputKind.select &&
      inputs[controller].showWhen == null &&
      draft[condition.field] is String &&
      condition.anyOf.contains(draft[condition.field]);
}

List<FlarePluginInput> flarePluginVisibleInputs(
  List<FlarePluginInput> inputs,
  Map<String, Object?> draft,
) => inputs
    .where((input) => flarePluginInputVisible(input, inputs, draft))
    .toList();

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
    this.minBuild,
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
    required this.minBuild,
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
        presentation: json['presentation'] is Map
            ? Map<String, Object?>.from(json['presentation'] as Map)
            : null,
        minBuild: _optInt(json['minBuild']),
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

  /// [FlarePluginUnavailableReason.upgradeRequired]: the first build that
  /// draws it, when the plugin declared one.
  final int? minBuild;
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
    super.minBuild,
    this.data,
    this.refreshMs,
    this.tabs = const [],
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
    required super.minBuild,
    required this.data,
    required this.refreshMs,
    required this.tabs,
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
      minBuild: view.minBuild,
      data: data is Map ? data.cast<String, Object?>() : null,
      refreshMs: (json['refreshMs'] as num?)?.toInt(),
      tabs: [
        for (final t in _maps(json['tabs']))
          if (_string(t['page']).isNotEmpty)
            FlarePluginPageTab(
              page: _string(t['page']),
              label: _string(t['label']),
              selected: _bool(t['selected']),
            ),
      ],
      source: jsonEncode(json),
    );
  }

  /// What the page was resolved against (the first page's source result, or
  /// the arguments of a page without a source); only while available. Page
  /// actions carry it back unchanged.
  final Map<String, Object?>? data;
  final int? refreshMs;

  /// Sibling pages of the plugin shown as tabs at the top (§4.7,
  /// rules.pageTabs); part of the view's source, so of its equality.
  final List<FlarePluginPageTab> tabs;
}

/// One tab of a page view (rules.pageTabs): a sibling page of the plugin.
@immutable
class FlarePluginPageTab {
  const FlarePluginPageTab({
    required this.page,
    required this.label,
    this.selected = false,
  });
  final String page;
  final String label;
  final bool selected;

  FlarePluginPageTab copyWith({bool? selected}) => FlarePluginPageTab(
    page: page,
    label: label,
    selected: selected ?? this.selected,
  );

  @override
  bool operator ==(Object other) =>
      other is FlarePluginPageTab &&
      other.page == page &&
      other.label == label &&
      other.selected == selected;

  @override
  int get hashCode => Object.hash(page, label, selected);
}

/// The tabs a page draws (rules.pageTabs): the view's own when it is
/// available with ≥ 2; before [page] has a view, the [last] ones drawn with
/// [page] selected; otherwise none.
List<FlarePluginPageTab> flarePluginPageTabs(
  FlarePluginPageViewModel? view,
  String page,
  List<FlarePluginPageTab> last,
) {
  if (view != null) {
    return view.available && view.tabs.length >= 2 ? view.tabs : const [];
  }
  if (!last.any((tab) => tab.page == page)) return const [];
  return [for (final tab in last) tab.copyWith(selected: tab.page == page)];
}

/// The page segment [index] opens: an unselected tab's; the selected one
/// opens nothing.
String? flarePluginPageTabChoice(List<FlarePluginPageTab> tabs, int index) {
  final tab = index >= 0 && index < tabs.length ? tabs[index] : null;
  return tab == null || tab.selected ? null : tab.page;
}

/// A record row's words (5.8, rules.rowsIcon): the second cell titles it,
/// the other cells but the first and the toned or unmapped ones make the
/// line under it, the first cell is the value and the toned cells its Tags
/// (a completed — success — one stays quiet). A person cell reads as
/// [nameOf] its user (the fallback name by default).
({String title, String? line, String value, List<FlarePluginRowCell> tags})
flarePluginRecordLine(
  FlarePluginRowsBlock block,
  FlarePluginRow row,
  int nowMs,
  FlareStrings strings, {
  String Function(String userId)? nameOf,
}) {
  String words(FlarePluginRowCell cell) => switch (cell.userId) {
    final id? => (nameOf ?? flarePluginFallbackName)(id),
    null => cell.text,
  };
  final tagged = {
    for (final (i, cell) in row.cells.indexed)
      if (i > 0 && (cell.tone != null || cell.unmapped)) i,
  };
  final kept = [
    for (var i = 1; i < block.columns.length; i += 1)
      if (!tagged.contains(i)) i,
  ];
  final lines = flarePluginRowLines(
    FlarePluginRowsBlock(columns: [for (final i in kept) block.columns[i]]),
    FlarePluginRow(
      key: row.key,
      cells: [
        for (final i in kept)
          if (row.cells.elementAtOrNull(i) case final cell?)
            FlarePluginRowCell(
              text: words(cell),
              timeMs: cell.timeMs,
              format: cell.format,
            )
          else
            const FlarePluginRowCell(text: ''),
      ],
    ),
    nowMs,
    strings,
  );
  final first = row.cells.firstOrNull;
  return (
    title: lines.primary,
    line: lines.secondary,
    value: first == null
        ? ''
        : flarePluginFormatText(words(first), first.format, strings),
    tags: [
      for (final i in tagged.toList()..sort())
        if (row.cells[i].unmapped ||
            row.cells[i].tone != FlarePluginTone.success)
          row.cells[i],
    ],
  );
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
/// An instant outside what `DateTime` holds is drawn at the nearest one it
/// does, never thrown on.
DateTime _wall(int ms, int? utcOffsetMinutes) {
  const limit = flarePluginMaxInstantMs - 86400000;
  final at = ms.clamp(-limit, limit);
  return utcOffsetMinutes == null
      ? DateTime.fromMillisecondsSinceEpoch(at)
      : DateTime.fromMillisecondsSinceEpoch(
          at + utcOffsetMinutes * 60000,
          isUtc: true,
        );
}

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

/// What a hidden value reads as (a maskable hero).
const flarePluginMaskedValue = '••••';

/// The date part of a date-time pattern (`M月d日 HH:mm` → `M月d日`).
String _datePattern(String pattern) => pattern
    .replaceFirst(RegExp(r'[\s,]*HH:mm[\s,]*'), ' ')
    .replaceFirst(RegExp(r'[\s,]+$'), '')
    .trim();

/// The day headings of a page list grouped by day
/// (`spec/plugin-view-vectors.json` rules.rowsGroupByDay): one per row,
/// present on the first row of each day — today, yesterday, else the date —
/// by the row's first time column; a row without a time starts no group.
List<String?> flarePluginRowDayHeadings(
  FlarePluginRowsBlock block,
  int nowMs,
  FlareStrings strings, {
  int? utcOffsetMinutes,
}) {
  final column = block.columns.indexWhere(
    (c) => c.format == FlarePluginColumnFormat.time,
  );
  if (!block.groupByDay || column < 0) {
    return List<String?>.filled(block.rows.length, null);
  }
  String key(DateTime at) => '${at.year}-${at.month}-${at.day}';
  final now = _wall(nowMs, utcOffsetMinutes);
  final today = key(now);
  final yesterday = key(_wall(nowMs - 86400000, utcOffsetMinutes));
  String? previous;
  return [
    for (final row in block.rows)
      () {
        final ms = column < row.cells.length ? row.cells[column].timeMs : null;
        if (ms == null) return null;
        final at = _wall(ms, utcOffsetMinutes);
        final day = key(at);
        if (day == previous) return null;
        previous = day;
        if (day == today) return strings.accountToday;
        if (day == yesterday) return strings.accountYesterday;
        return flarePluginRenderPattern(
          _datePattern(
            at.year == now.year
                ? strings.pluginViewDateTimeFormat
                : strings.pluginViewDateTimeYearFormat,
          ),
          at,
        );
      }(),
  ];
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
        (_, final cell?) => flarePluginFormatText(
          cell.text,
          cell.format,
          strings,
        ),
        (_, null) => '',
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
  FlarePluginUnavailableReason.upgradeRequired =>
    strings.pluginViewUnavailableUpgradeRequired,
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

/// An explicitly selected top-level form may be composed into a page.
/// Confirmation and password forms retain the existing guarded sheet path.
FlarePluginAction? flarePluginInlineFormAction(
  FlarePluginViewModel view,
  String? id, {
  required bool interactive,
}) {
  if (!interactive ||
      !view.available ||
      flarePluginReadOnly(view) ||
      id == null)
    return null;
  final action = view.actions.where((a) => a.id == id).firstOrNull;
  if (action == null ||
      action.form.isEmpty ||
      (action.confirm?.isNotEmpty ?? false))
    return null;
  for (final inputId in action.form) {
    final input = view.inputs.where((input) => input.id == inputId).firstOrNull;
    if (input == null || input.kind == FlarePluginInputKind.password)
      return null;
  }
  return action;
}

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
      FlarePluginInputKind.text || FlarePluginInputKind.password => 256,
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
    case FlarePluginInputKind.file:
    case FlarePluginInputKind.image:
    case FlarePluginInputKind.document:
      return FlarePluginFileValue.fromValue(raw)?.toJson();
    case FlarePluginInputKind.location:
      return FlarePluginLocationValue.of(raw, input.precision)?.toJson();
    case FlarePluginInputKind.money:
      // The draft is the amount as typed; the currency comes from the input.
      if (raw is String) return raw;
      return raw is Map && raw['amount'] is String ? raw['amount'] : '';
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
    case FlarePluginInputKind.password:
      return '';
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
) {
  final draft = {
    for (final input in inputs) input.id: flarePluginDraftValue(input, values),
  };
  for (final input in inputs) {
    if (!flarePluginInputVisible(input, inputs, draft)) draft.remove(input.id);
  }
  return draft;
}

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
    case FlarePluginInputKind.money:
      return flarePluginCheckMoney(input, draft);
    case FlarePluginInputKind.file:
    case FlarePluginInputKind.image:
    case FlarePluginInputKind.document:
      return draft == null
          ? (input.required ? FlarePluginFormIssue.required : null)
          : FlarePluginFileValue.fromValue(draft) != null
          ? null
          : FlarePluginFormIssue.invalidType;
    case FlarePluginInputKind.location:
      return draft == null
          ? (input.required ? FlarePluginFormIssue.required : null)
          : FlarePluginLocationValue.of(draft, input.precision) != null
          ? null
          : FlarePluginFormIssue.invalidType;
    case FlarePluginInputKind.password:
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
  for (final input in flarePluginVisibleInputs(inputs, draft))
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
  for (final input in flarePluginVisibleInputs(inputs, draft)) {
    final value = draft[input.id];
    switch (input.kind) {
      case FlarePluginInputKind.file:
      case FlarePluginInputKind.image:
      case FlarePluginInputKind.document:
        final file = FlarePluginFileValue.fromValue(value);
        if (file != null) out[input.id] = file.toJson();
      case FlarePluginInputKind.location:
        final fix = FlarePluginLocationValue.of(value, input.precision);
        if (fix != null) out[input.id] = fix.toJson();
      case FlarePluginInputKind.money:
        final amount = flarePluginMoneyAmount(value is String ? value : '');
        final currency = input.money?.currency;
        if (amount.isNotEmpty && currency != null)
          out[input.id] = {'amount': amount, 'currency': currency};
      case FlarePluginInputKind.password:
        final secret = value is String ? value : "";
        if (secret.isNotEmpty) out[input.id] = secret;
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
  // R6: only a declared limit ≤ 200, and only once something is typed.
  final limit = input.maxLength;
  final length = _codePoints('${draft ?? ''}');
  return flarePluginShowsCounter(limit, length) ? '$length/$limit' : null;
}

// ── vocabulary 2: formats, blocks and the upgrade notice ───────────────────
// spec/plugin-view-vectors.json → formats2, blocks2, moneyInput, upgradeNotice.

/// A count written compact (formats2): the largest unit of [units]
/// (`4:万|8:亿`, `3:K|6:M|9:B`: exponent and suffix pairs) the count reaches,
/// one decimal cut (never rounded up) and a trailing `.0` dropped; below
/// every unit, the count itself.
String flarePluginCompactCount(num count, String units) {
  final whole = count.truncate();
  final sign = whole < 0 ? '-' : '';
  final n = whole.abs();
  final parsed = <({int exponent, String suffix})>[];
  for (final pair in units.split('|')) {
    final at = pair.indexOf(':');
    if (at <= 0) continue;
    final exponent = int.tryParse(pair.substring(0, at));
    final suffix = pair.substring(at + 1);
    if (exponent != null && exponent > 0 && suffix.isNotEmpty) {
      parsed.add((exponent: exponent, suffix: suffix));
    }
  }
  parsed.sort((a, b) => b.exponent.compareTo(a.exponent));
  for (final unit in parsed) {
    final base = BigInt.from(10).pow(unit.exponent);
    if (BigInt.from(n) < base) continue;
    final tenths = (BigInt.from(n) * BigInt.from(10)) ~/ base;
    final text = tenths % BigInt.from(10) == BigInt.zero
        ? '${tenths ~/ BigInt.from(10)}'
        : '${tenths ~/ BigInt.from(10)}.${tenths % BigInt.from(10)}';
    return '$sign$text${unit.suffix}';
  }
  return '$sign$n';
}

/// A duration in the viewer's words (formats2): whole seconds; under a minute
/// the seconds alone, else the largest non-zero unit and, when it is not
/// zero, the next one ("2 小时 5 分钟", "1 天").
String flarePluginDurationText(
  int ms, {
  required String days,
  required String hours,
  required String minutes,
  required String seconds,
}) {
  final total = (ms < 0 ? 0 : ms) ~/ 1000;
  String unit(String template, int n) => template.replaceAll('{n}', '$n');
  if (total < 60) return unit(seconds, total);
  final parts = <(int, String)>[
    (total ~/ 86400, days),
    ((total % 86400) ~/ 3600, hours),
    ((total % 3600) ~/ 60, minutes),
    (total % 60, seconds),
  ];
  final first = parts.indexWhere((part) => part.$1 > 0);
  final next = first + 1 < parts.length ? parts[first + 1] : null;
  return unit(parts[first].$2, parts[first].$1) +
      (next != null && next.$1 > 0 ? ' ${unit(next.$2, next.$1)}' : '');
}

/// The text of a value with its resolved format: count and duration in the
/// viewer's language, money with its currency as the payment confirmation
/// writes it (R10), everything else (percent, bytes, money without a currency
/// or scale, an unknown format) the plain text the core SDK wrote.
String flarePluginFormatText(
  String text,
  Map<String, Object?>? format,
  FlareStrings strings,
) {
  switch (format?['kind']) {
    case 'money':
      // With a scale the core SDK already wrote the decimal ("-5.00").
      final currency = format!['currency'];
      if (currency is! String || currency.isEmpty || format['scale'] is! num) {
        return text;
      }
      // A leading minus, or the explicit plus of money in, stays in front.
      final sign = text.startsWith('-') || text.startsWith('+') ? text[0] : '';
      final amount = flarePaymentAmountText(
        text.substring(sign.length),
        currency,
      );
      return amount == null ? text : '$sign$amount';
    case 'count':
      final count = format!['count'];
      return count is num && count.isFinite
          ? flarePluginCompactCount(count, strings.pluginFormatCountUnits)
          : text;
    case 'duration':
      final ms = format!['ms'];
      return ms is num && ms.isFinite
          ? flarePluginDurationText(
              ms.toInt(),
              days: strings.myInviteUnitDays,
              hours: strings.myInviteUnitHours,
              minutes: strings.myInviteUnitMinutes,
              seconds: strings.pluginFormatSeconds,
            )
          : text;
    default:
      return text;
  }
}

/// A step's state as drawn: one of the four, anything else pending.
FlarePluginStepState flarePluginStepState(Object? state) =>
    _enum(FlarePluginStepState.values, state) ?? FlarePluginStepState.pending;

/// A trend's direction as drawn: up, down, anything else flat.
FlarePluginTrendDirection flarePluginTrendDirection(Object? direction) =>
    _enum(FlarePluginTrendDirection.values, direction) ??
    FlarePluginTrendDirection.flat;

/// A banner's tone as drawn: one of the four, anything else info.
FlarePluginBannerTone flarePluginBannerTone(Object? tone) =>
    _enum(FlarePluginBannerTone.values, tone) ?? FlarePluginBannerTone.info;

/// A hero's tone as drawn: one of the four, anything else neutral.
FlarePluginHeroTone flarePluginHeroTone(Object? tone) =>
    _enum(FlarePluginHeroTone.values, tone) ?? FlarePluginHeroTone.neutral;

/// Width over height of an image block's aspect; an unknown one is square.
double flarePluginImageRatio(String aspect) => switch (aspect) {
  '4:3' => 4 / 3,
  '16:9' => 16 / 9,
  '3:4' => 3 / 4,
  _ => 1,
};

/// Whether a QR code has expired: it names an expiry and that instant came.
bool flarePluginQrExpired(int? expiresAtMs, int nowMs) =>
    expiresAtMs != null && expiresAtMs <= nowMs;

/// How long until the code expires; null without an expiry or once expired.
int? flarePluginQrRefreshMs(int? expiresAtMs, int nowMs) =>
    expiresAtMs != null && expiresAtMs > nowMs ? expiresAtMs - nowMs : null;

/// A donut's slices: every point with a positive value, its start and sweep
/// as fractions of the sum of those values, in point order.
List<({int index, double start, double sweep})> flarePluginDonutSlices(
  List<double> values,
) {
  final shown = [
    for (var i = 0; i < values.length; i += 1)
      if (values[i].isFinite && values[i] > 0) (index: i, value: values[i]),
  ];
  final total = shown.fold<double>(0, (sum, point) => sum + point.value);
  if (!(total > 0)) return const [];
  var start = 0.0;
  return [
    for (final point in shown)
      () {
        final slice = (
          index: point.index,
          start: start,
          sweep: point.value / total,
        );
        start += slice.sweep;
        return slice;
      }(),
  ];
}

/// Whether a chart has anything to draw: some series has a point.
bool flarePluginChartHasPoints(List<FlarePluginChartSeries> series) =>
    series.any((s) => s.points.isNotEmpty);

/// The value range a bar or line chart shows (the same rule as the Vue kit's
/// chart geometry): it always holds 0, and its ends are 1, 2, 2.5 or 5 × 10ⁿ.
({double min, double max, bool flat}) flarePluginChartDomain(
  Iterable<double> values,
) {
  double nice(double value) {
    if (!(value > 0) || !value.isFinite) return 0;
    final magnitude = math.pow(10, (math.log(value) / math.ln10).floor());
    final fraction = ((value / magnitude) * 1e9).round() / 1e9;
    final step = fraction <= 1
        ? 1
        : fraction <= 2
        ? 2
        : fraction <= 2.5
        ? 2.5
        : fraction <= 5
        ? 5
        : 10;
    return (step * magnitude).toDouble();
  }

  var high = 0.0, low = 0.0;
  for (final value in values) {
    if (!value.isFinite) continue;
    if (value > high) high = value;
    if (value < low) low = value;
  }
  final max = nice(high);
  final min = low < 0 ? -nice(-low) : 0.0;
  if (max == min) return (min: 0.0, max: 1.0, flat: true);
  return (min: min, max: max, flat: false);
}

/// The blocks in reading order with every section's children after it
/// (blocks2.flatten); [section] is the index of the heading a child belongs
/// to.
List<({FlarePluginBlock block, int? section})> flarePluginFlatBlocks(
  List<FlarePluginBlock> blocks,
) {
  final out = <({FlarePluginBlock block, int? section})>[];
  for (final block in blocks) {
    out.add((block: block, section: null));
    if (block is FlarePluginSectionBlock) {
      final at = out.length - 1;
      for (final child in block.blocks) {
        if (child is! FlarePluginSectionBlock) {
          out.add((block: child, section: at));
        }
      }
    }
  }
  return out;
}

/// What the engine's update.plugin_upgrade_status answers for a
/// placeholder's minBuild.
@immutable
class FlarePluginUpgradeStatus {
  const FlarePluginUpgradeStatus({required this.available, this.build});
  factory FlarePluginUpgradeStatus.fromJson(Map<String, Object?> json) =>
      FlarePluginUpgradeStatus(
        available: _bool(json['available']),
        build: _optInt(json['build']),
      );

  /// A build at least minBuild is offered to this device.
  final bool available;
  final int? build;
}

/// Where an upgrade notice sits.
enum FlarePluginUpgradeVariant { card, entry, page }

/// What an upgrade notice offers (upgradeNotice).
enum FlarePluginUpgradeMode { update, notAvailable, description }

/// [FlarePluginUpgradeMode.update] when a newer build is offered and the host
/// has an update handler; [FlarePluginUpgradeMode.notAvailable] when the
/// status says no build for this device; otherwise
/// [FlarePluginUpgradeMode.description].
FlarePluginUpgradeMode flarePluginUpgradeMode(
  FlarePluginUpgradeStatus? status, {
  required bool canUpdate,
}) {
  if (status?.available == true) {
    return canUpdate
        ? FlarePluginUpgradeMode.update
        : FlarePluginUpgradeMode.description;
  }
  return status == null
      ? FlarePluginUpgradeMode.description
      : FlarePluginUpgradeMode.notAvailable;
}

// ── money input (moneyInput) ───────────────────────────────────────────────

/// Fraction digits of a money input: its scale, 2 when absent.
int flarePluginMoneyScale(FlarePluginInput input) {
  final scale = input.money?.scale;
  return scale != null && scale >= 0 && scale <= 18 ? scale : 2;
}

/// What a money field holds once typed (spec moneyInput.typed): the locale's
/// decimal separator, when it is not ".", becomes "." so a comma-decimal
/// keypad (de_DE, fr_FR) enters fractions; the protocol only reads ".".
String flarePluginMoneyTyped(String text, String decimalSeparator) =>
    decimalSeparator.isEmpty || decimalSeparator == '.'
    ? text
    : text.replaceAll(decimalSeparator, '.');

/// Languages that write a decimal comma (CLDR), Switzerland aside.
const _decimalCommaLanguages = {
  'af', 'az', 'be', 'bg', 'bs', 'ca', 'cs', 'da', 'de', 'el', 'es', 'et', //
  'eu', 'fi', 'fo', 'fr', 'gl', 'hr', 'hu', 'hy', 'id', 'is', 'it', 'ka', //
  'kk', 'ky', 'lt', 'lv', 'mk', 'mn', 'nb', 'nl', 'nn', 'no', 'pl', 'pt', //
  'ro', 'ru', 'sk', 'sl', 'sq', 'sr', 'sv', 'tr', 'uk', 'uz', 'vi',
};

/// The decimal separator of a locale ("." when unknown): what a money field
/// maps to "." ([flarePluginMoneyTyped]).
String flarePluginDecimalSeparator(
  String? languageCode, [
  String? countryCode,
]) {
  if (languageCode == null || countryCode == 'CH') return '.';
  return _decimalCommaLanguages.contains(languageCode) ? ',' : '.';
}

/// The amount typed, as the protocol writes decimals: spaces gone, leading
/// zeros of the whole part dropped (one kept), a leading `.` gets a `0`, a
/// trailing `.` goes. Anything else is left for the check to refuse.
String flarePluginMoneyAmount(String typed) {
  var text = typed.replaceAll(RegExp(r'\s+'), '');
  if (text.startsWith('.')) text = '0$text';
  if (text.endsWith('.')) text = text.substring(0, text.length - 1);
  final at = text.indexOf('.');
  final whole = at < 0 ? text : text.substring(0, at);
  final rest = at < 0 ? '' : text.substring(at);
  final trimmed = RegExp(r'^\d+$').hasMatch(whole)
      ? whole.replaceFirst(RegExp(r'^0+(?=\d)'), '')
      : whole;
  return '$trimmed$rest';
}

/// A decimal the protocol accepts: no sign or exponent, no leading zero, at
/// most 30 whole and [scale] fraction digits.
bool flarePluginIsDecimal(String amount, int scale) {
  final match = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(amount);
  if (match == null) return false;
  final whole = match.group(1)!;
  final fraction = match.group(2);
  return whole.length <= 30 &&
      (whole == '0' || !whole.startsWith('0')) &&
      (fraction == null || fraction.length <= scale);
}

/// The order of two decimals [flarePluginIsDecimal] accepts: -1, 0 or 1.
int flarePluginCompareDecimal(String a, String b) {
  (String, String) split(String s) {
    final at = s.indexOf('.');
    return at < 0
        ? (s, '')
        : (
            s.substring(0, at),
            s.substring(at + 1).replaceFirst(RegExp(r'0+$'), ''),
          );
  }

  final (aw, af) = split(a);
  final (bw, bf) = split(b);
  if (aw.length != bw.length) return aw.length < bw.length ? -1 : 1;
  final whole = aw.compareTo(bw);
  if (whole != 0) return whole.sign;
  final width = af.length > bf.length ? af.length : bf.length;
  return af.padRight(width, '0').compareTo(bf.padRight(width, '0')).sign;
}

/// The light check of a money draft: what the core SDK will say.
FlarePluginFormIssue? flarePluginCheckMoney(
  FlarePluginInput input,
  Object? draft,
) {
  final amount = flarePluginMoneyAmount(draft is String ? draft : '');
  if (amount.isEmpty) {
    return input.required ? FlarePluginFormIssue.required : null;
  }
  final rules = input.money;
  if (!flarePluginIsDecimal(amount, flarePluginMoneyScale(input)) ||
      rules?.currency == null) {
    return FlarePluginFormIssue.invalidType;
  }
  if (rules!.min != null && flarePluginCompareDecimal(amount, rules.min!) < 0) {
    return FlarePluginFormIssue.outOfRange;
  }
  if (rules.max != null && flarePluginCompareDecimal(amount, rules.max!) > 0) {
    return FlarePluginFormIssue.outOfRange;
  }
  return null;
}
