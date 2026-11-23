import 'package:flutter/foundation.dart';

import '../tokens/flare_strings.dart';
import 'plugin_view.dart';

/// Plugin page layout rules of docs/plugin-experience.md §2 (R1–R12), pure
/// and shared with the Vue, SwiftUI and Compose kits through
/// spec/plugin-view-vectors.json (rules.actionRoles, blockBoundInputs,
/// refreshKey, accountDerivation, formPlacement, actionDedupe, references,
/// statusValues, result, pageStates, statusCard) and
/// spec/plugin-refresh-vectors.json (afterAction, afterReturn).

/// What a top-level action is on a page (R2).
enum FlarePluginActionRole { primary, danger, destination, command }

/// Which of the page prototypes a view is (R2.1–R2.4).
enum FlarePluginPageArchetype { card, overview, task, records }

/// Why a plugin page asks its host to read it again (R4): a pull, the header
/// key, a timer (refreshMs or a pending result), a settled action, or a
/// return from the next page. [returned] is `return` on the wire.
enum FlarePluginRefreshReason { pull, key, timer, action, returned }

/// The wire name of [reason].
String flarePluginRefreshReasonName(FlarePluginRefreshReason reason) =>
    reason == FlarePluginRefreshReason.returned ? 'return' : reason.name;

/// danger → danger; primary → primary; a page target without a form →
/// destination; anything else → command.
FlarePluginActionRole flarePluginActionRole(FlarePluginAction action) =>
    switch (action.style) {
      FlarePluginActionStyle.danger => FlarePluginActionRole.danger,
      FlarePluginActionStyle.primary => FlarePluginActionRole.primary,
      null =>
        action.target?.kind == 'page' && action.form.isEmpty
            ? FlarePluginActionRole.destination
            : FlarePluginActionRole.command,
    };

/// rules.rowTap: a row whose only action passes this (it opens a page, with
/// no form, and is not danger) is one control that runs it; other rows keep
/// their keys.
bool flarePluginRowTaps(FlarePluginAction action) =>
    action.target?.kind == 'page' &&
    action.form.isEmpty &&
    action.style != FlarePluginActionStyle.danger;

/// The inputs only a block fills (R6.1): every protected-media and choices
/// block's inputName, top level or in a section.
Set<String> flarePluginBoundInputs(FlarePluginViewModel view) => {
  for (final (:block, section: _) in flarePluginFlatBlocks(view.blocks))
    if (block is FlarePluginProtectedMediaBlock)
      block.inputName
    else if (block is FlarePluginChoicesBlock)
      block.inputName,
};

/// An action whose form lists bound inputs only: the block runs it.
bool flarePluginIsBlockAction(FlarePluginAction action, Set<String> bound) =>
    action.form.isNotEmpty && action.form.every(bound.contains);

/// The fields [action]'s form draws: its inputs without the bound ones.
List<FlarePluginInput> flarePluginFormFields(
  FlarePluginViewModel view,
  FlarePluginAction action,
) {
  final bound = flarePluginBoundInputs(view);
  return [
    for (final id in action.form)
      if (!bound.contains(id))
        ...view.inputs.where((input) => input.id == id).take(1),
  ];
}

/// view.actions, then the menu actions on an embedded view, without block
/// actions and without a repeated label (R9).
List<FlarePluginAction> flarePluginTopLevelActions(
  FlarePluginViewModel view, {
  required bool embedded,
}) {
  final bound = flarePluginBoundInputs(view);
  return flarePluginDedupeActions([
    for (final action in [...view.actions, if (embedded) ...view.menuActions])
      if (!flarePluginIsBlockAction(action, bound)) action,
  ]);
}

final Set<String> _warned = {};

void _warnOnce(String key, String message) {
  assert(() {
    if (_warned.add(key)) debugPrint('flare_im_ui: $message');
    return true;
  }());
}

/// Of the actions with one label only the first stays (R9); a development
/// build warns once per label.
List<FlarePluginAction> flarePluginDedupeActions(
  List<FlarePluginAction> actions,
) {
  final labels = <String>{};
  final drawn = <FlarePluginAction>[];
  for (final action in actions) {
    if (labels.add(action.label)) {
      drawn.add(action);
    } else {
      _warnOnce(
        'dedupe:${action.label}',
        'plugin actions share the label "${action.label}"; only the first is drawn',
      );
    }
  }
  return drawn;
}

bool _hasBlock(
  FlarePluginViewModel view,
  bool Function(FlarePluginBlock) test,
) => flarePluginFlatBlocks(view.blocks).any((entry) => test(entry.block));

/// card when not embedded; overview with a hero or stats and ≥ 4
/// destinations; task with an inline form, or without rows, entries or a
/// timeline and ≤ 3 actions of which one is primary; records otherwise.
FlarePluginPageArchetype flarePluginArchetype(
  FlarePluginViewModel view, {
  required bool embedded,
  String? inlineFormActionId,
}) {
  if (!embedded) return FlarePluginPageArchetype.card;
  final top = flarePluginTopLevelActions(view, embedded: true);
  final roles = top.map(flarePluginActionRole).toList();
  final destinations = roles
      .where((r) => r == FlarePluginActionRole.destination)
      .length;
  if (destinations >= 4 &&
      _hasBlock(
        view,
        (b) => b is FlarePluginHeroBlock || b is FlarePluginStatsBlock,
      )) {
    return FlarePluginPageArchetype.overview;
  }
  if (inlineFormActionId != null) return FlarePluginPageArchetype.task;
  final records = _hasBlock(
    view,
    (b) =>
        b is FlarePluginRowsBlock ||
        b is FlarePluginEntriesBlock ||
        b is FlarePluginTimelineBlock,
  );
  if (!records &&
      top.length <= 3 &&
      roles.contains(FlarePluginActionRole.primary)) {
    return FlarePluginPageArchetype.task;
  }
  return FlarePluginPageArchetype.records;
}

/// One titled list card of an overview page: `common`, `records`, or null
/// for the single untitled card.
typedef FlarePluginActionGroup = ({
  String? group,
  List<FlarePluginAction> actions,
});

/// Where each top-level action is drawn (rules.actionRoles). A place the
/// archetype does not use is empty.
@immutable
class FlarePluginActionPlaces {
  const FlarePluginActionPlaces({
    required this.archetype,
    this.quick = const [],
    this.list = const [],
    this.bar = const [],
    this.barSecondary = const [],
    this.header = const [],
    this.commands = const [],
    this.more = const [],
    this.danger = const [],
    this.footer = const [],
    this.menu = const [],
  });
  final FlarePluginPageArchetype archetype;

  /// Overview: keys at the bottom of the overview card.
  final List<FlarePluginAction> quick;

  /// Overview: list cards (destinations end with a chevron).
  final List<FlarePluginActionGroup> list;

  /// Task: the pinned primary (phone) / the leading key (PC).
  final List<FlarePluginAction> bar;

  /// Task: quiet keys above the primary (phone) / secondary keys after it.
  final List<FlarePluginAction> barSecondary;

  /// Records: the header key.
  final List<FlarePluginAction> header;

  /// Records: a secondary key row after the body.
  final List<FlarePluginAction> commands;

  /// Task and records: the "more actions" list card.
  final List<FlarePluginAction> more;

  /// The last list card, every row through DangerConfirm.
  final List<FlarePluginAction> danger;

  /// Card: up to 3 footer keys.
  final List<FlarePluginAction> footer;

  /// Card: the ⋯ menu.
  final List<FlarePluginAction> menu;

  /// Every action drawn on the page body or header, in drawing order.
  Iterable<FlarePluginAction> get all => [
    ...header,
    ...quick,
    ...bar,
    ...barSecondary,
    ...commands,
    for (final group in list) ...group.actions,
    ...more,
    ...danger,
    ...footer,
    ...menu,
  ];
}

/// The list cards of an overview (R2.1): by `group` when any action has
/// one — `common` (an unknown group too) before `records` — else one
/// untitled card, each in declaration order.
List<FlarePluginActionGroup> flarePluginListGroups(
  List<FlarePluginAction> actions,
) => actions.any((a) => a.group != null)
    ? [
        for (final group in const ['common', 'records'])
          if (actions
                  .where(
                    (a) =>
                        (a.group == 'records' ? 'records' : 'common') == group,
                  )
                  .toList()
              case final listed when listed.isNotEmpty)
            (group: group, actions: listed),
      ]
    : [if (actions.isNotEmpty) (group: null, actions: actions)];

/// The places of [view]'s top-level actions (rules.actionRoles); [archetype]
/// overrides the derived prototype (the account layout is an overview, R12).
FlarePluginActionPlaces flarePluginActionPlaces(
  FlarePluginViewModel view, {
  required bool embedded,
  String? inlineFormActionId,
  FlarePluginPageArchetype? archetype,
}) {
  archetype ??= flarePluginArchetype(
    view,
    embedded: embedded,
    inlineFormActionId: inlineFormActionId,
  );
  if (archetype == FlarePluginPageArchetype.card) {
    final bound = flarePluginBoundInputs(view);
    final actions = flarePluginDedupeActions([
      for (final action in view.actions)
        if (!flarePluginIsBlockAction(action, bound)) action,
    ]);
    final ordered = [
      ...actions.where((a) => a.style == FlarePluginActionStyle.primary),
      ...actions.where((a) => a.style != FlarePluginActionStyle.primary),
    ];
    return FlarePluginActionPlaces(
      archetype: archetype,
      footer: ordered.take(3).toList(),
      menu: [...view.menuActions, ...ordered.skip(3)],
    );
  }
  final top = flarePluginTopLevelActions(view, embedded: true);
  List<FlarePluginAction> having(FlarePluginActionRole role) =>
      top.where((a) => flarePluginActionRole(a) == role).toList();
  final primaries = having(FlarePluginActionRole.primary);
  // A command that declares group is always a list item (more on task and
  // records pages), never a quick, barSecondary or commands key.
  final commands = [
    for (final a in having(FlarePluginActionRole.command))
      if (a.group == null) a,
  ];
  final danger = having(FlarePluginActionRole.danger);
  switch (archetype) {
    case FlarePluginPageArchetype.overview:
      final quick = [...primaries.take(2), ...commands.take(2)];
      final rest = [
        for (final action in top)
          if (!quick.contains(action) && !danger.contains(action)) action,
      ];
      return FlarePluginActionPlaces(
        archetype: archetype,
        quick: quick,
        list: flarePluginListGroups(rest),
        danger: danger,
      );
    case FlarePluginPageArchetype.task:
      final bar = primaries.take(1).toList();
      final secondary = [
        for (final action in top)
          if (!bar.contains(action) &&
              (flarePluginActionRole(action) == FlarePluginActionRole.primary ||
                  commands.contains(action)))
            action,
      ].take(2).toList();
      return FlarePluginActionPlaces(
        archetype: archetype,
        bar: bar,
        barSecondary: secondary,
        more: [
          for (final action in top)
            if (!bar.contains(action) &&
                !secondary.contains(action) &&
                !danger.contains(action))
              action,
        ],
        danger: danger,
      );
    case FlarePluginPageArchetype.records:
      final header = primaries.take(1).toList();
      return FlarePluginActionPlaces(
        archetype: archetype,
        header: header,
        commands: [
          for (final action in top)
            if (!header.contains(action) &&
                (flarePluginActionRole(action) ==
                        FlarePluginActionRole.primary ||
                    commands.contains(action)))
              action,
        ],
        more: [
          for (final action in top)
            if (flarePluginActionRole(action) ==
                    FlarePluginActionRole.destination ||
                (flarePluginActionRole(action) ==
                        FlarePluginActionRole.command &&
                    !commands.contains(action)))
              action,
        ],
        danger: danger,
      );
    case FlarePluginPageArchetype.card:
      throw StateError('unreachable');
  }
}

const _inlineFormBlocks = {
  FlarePluginNoteBlock,
  FlarePluginTextBlock,
  FlarePluginStepsBlock,
  FlarePluginBannerBlock,
  FlarePluginFieldsBlock,
  FlarePluginStatusBlock,
  FlarePluginTimeBlock,
  FlarePluginSectionBlock,
  FlarePluginChoicesBlock,
  FlarePluginProtectedMediaBlock,
};

/// The page's own form (R6 "页内表单"): the view's only action with a form
/// (block actions aside) when the view has no presentation and only
/// instruction, progress and block-bound blocks — it is then drawn inline.
String? flarePluginPageInlineFormActionId(
  FlarePluginViewModel view, {
  required bool interactive,
}) {
  if (view.presentation != null) return null;
  final bound = flarePluginBoundInputs(view);
  final forms = [
    for (final action in view.actions)
      if (action.form.isNotEmpty && !flarePluginIsBlockAction(action, bound))
        action,
  ];
  if (forms.length != 1) return null;
  if (flarePluginFlatBlocks(
    view.blocks,
  ).any((entry) => !_inlineFormBlocks.contains(entry.block.runtimeType))) {
    return null;
  }
  return flarePluginInlineFormAction(
    view,
    forms.single.id,
    interactive: interactive,
  )?.id;
}

/// The header refresh key and pull to refresh show only on a data page (R1).
bool flarePluginShowsRefreshKey(
  FlarePluginViewModel view, {
  String? inlineFormActionId,
}) {
  if (!view.available) return false;
  final presentation = view.presentation;
  if (presentation != null && presentation['renderer'] != 'account') {
    return false;
  }
  if (_hasBlock(view, (b) => b is FlarePluginResultBlock)) return false;
  if (flarePluginArchetype(
        view,
        embedded: true,
        inlineFormActionId: inlineFormActionId,
      ) ==
      FlarePluginPageArchetype.task) {
    return false;
  }
  return view.fields.isNotEmpty ||
      _hasBlock(
        view,
        (b) =>
            b is FlarePluginRowsBlock ||
            b is FlarePluginEntriesBlock ||
            b is FlarePluginStatsBlock ||
            b is FlarePluginHeroBlock ||
            b is FlarePluginTimelineBlock ||
            b is FlarePluginPeopleBlock ||
            b is FlarePluginStatusBlock ||
            (b is FlarePluginFieldsBlock && b.fields.isNotEmpty),
      );
}

/// Whether an absent appearance derives the account layout (R12): the
/// account renderer, or no presentation, a section holding a maskable amount
/// hero without actions and exactly one rows block of ≥ 2 columns.
bool flarePluginDerivesAccount(FlarePluginViewModel view) {
  final presentation = view.presentation;
  if (presentation != null) return presentation['renderer'] == 'account';
  final hero = view.blocks.any(
    (block) =>
        block is FlarePluginSectionBlock &&
        block.blocks.any(
          (child) =>
              child is FlarePluginHeroBlock &&
              child.amount &&
              child.maskable &&
              child.actions.isEmpty,
        ),
  );
  final rows = view.blocks.whereType<FlarePluginRowsBlock>().toList();
  return hero && rows.length == 1 && rows.single.columns.length >= 2;
}

/// Where an action form opens (R6).
enum FlarePluginFormPlacement { sheet, page }

/// ≤ 4 drawn fields and none of file, document, image or members → sheet;
/// otherwise, or the page's inline form → page.
FlarePluginFormPlacement flarePluginFormPlacement(
  List<FlarePluginInputKind> kinds, {
  required bool inline,
}) =>
    !inline &&
        kinds.length <= 4 &&
        !kinds.any(
          (kind) =>
              kind == FlarePluginInputKind.file ||
              kind == FlarePluginInputKind.document ||
              kind == FlarePluginInputKind.image ||
              kind == FlarePluginInputKind.members,
        )
    ? FlarePluginFormPlacement.sheet
    : FlarePluginFormPlacement.page;

/// The counter shows with a declared limit ≤ 200 and something typed (R6).
bool flarePluginShowsCounter(int? maxLength, int length) =>
    maxLength != null && maxLength <= 200 && length > 0;

/// How a select input is drawn (R6): ≤ 4 choices as cards, more as a
/// select, none as a disabled select that holds the submit back.
enum FlarePluginSelectControl { cards, select }

({FlarePluginSelectControl control, bool disabled}) flarePluginSelectControl(
  int choices,
) => (
  control: choices > 0 && choices <= 4
      ? FlarePluginSelectControl.cards
      : FlarePluginSelectControl.select,
  disabled: choices == 0,
);

/// Fields without and with `format: reference` (R3), each in order.
({List<FlarePluginField> main, List<FlarePluginField> references})
flarePluginReferenceSplit(List<FlarePluginField> fields) => (
  main: [
    for (final field in fields)
      if (!field.isReference) field,
  ],
  references: [
    for (final field in fields)
      if (field.isReference) field,
  ],
);

/// The words a value label draws (R3): pluginView.unknownStatus when the
/// value is not among the declared ones (a development build warns once per
/// [where] and raw value), else [text].
String flarePluginStatusText(
  String text, {
  required bool unmapped,
  required FlareStrings strings,
  String where = '',
}) {
  if (!unmapped) return text;
  _warnOnce(
    'unmapped:$where:$text',
    'plugin value "$text"${where.isEmpty ? '' : ' at $where'} is not among its declared values',
  );
  return strings.pluginViewUnknownStatus;
}

/// The icon of a result or status card's tone (R7).
String flarePluginToneIcon(FlarePluginTone tone) => switch (tone) {
  FlarePluginTone.success => 'success',
  FlarePluginTone.info => 'clock',
  FlarePluginTone.warning => 'warning',
  FlarePluginTone.danger => 'error',
  FlarePluginTone.neutral => 'info',
};

/// A pending result asks for a quiet refresh every [flarePluginResultPollMs]
/// for at most [flarePluginResultPollForMs] (R7).
const flarePluginResultPollMs = 3000;
const flarePluginResultPollForMs = 60000;
bool flarePluginResultPolls(FlarePluginResultBlock block) =>
    !block.unmapped && block.state == 'pending';

/// The first result block of [view], top level or in a section.
FlarePluginResultBlock? flarePluginResultOf(FlarePluginViewModel view) =>
    flarePluginFlatBlocks(view.blocks)
        .map((entry) => entry.block)
        .whereType<FlarePluginResultBlock>()
        .firstOrNull;

/// Whether [view] draws the status card (§6.1): the status.card renderer, or
/// a first steps block with a toned field.
bool flarePluginShowsStatusCard(FlarePluginViewModel view) {
  if (view.presentation?['renderer'] == 'status.card') return true;
  if (view.presentation != null) return false;
  return view.blocks.firstOrNull is FlarePluginStepsBlock &&
      view.fields.any((field) => field.tone != null);
}

/// The first load draws nothing for this long, then the skeleton (R8).
const flarePluginSkeletonDelayMs = 300;

/// Whether an action's settle asks the host to read the page again (R4):
/// it settled with no error and no form errors while the page is visible.
bool flarePluginRefreshAfterAction({required bool ok, required bool visible}) =>
    ok && visible;

/// What a host does when control comes back to a page (R4, afterReturn):
/// `pop` refreshes this page; `done` pops to the page that started the flow
/// and refreshes it, or closes without one; a sent message card closes.
({bool refresh, String page}) flarePluginAfterReturn(
  String event, {
  bool origin = false,
}) => switch (event) {
  'pop' => (refresh: true, page: 'self'),
  'done' when origin => (refresh: true, page: 'origin'),
  _ => (refresh: false, page: 'close'),
};

/// Where a result's done key lands (R4.2, doneTarget): [stack] lists the
/// plugin pages bottom to top by archetype name (`overview`, `records`,
/// `task`, `result`); the index of the nearest page below the top that is an
/// overview or records page, which then reads itself again (`return`), or
/// null to close the plugin page stack.
int? flarePluginDoneTarget(List<String> stack) {
  for (var i = stack.length - 2; i >= 0; i--) {
    if (stack[i] == 'overview' || stack[i] == 'records') return i;
  }
  return null;
}

/// The name [flarePluginDoneTarget] reads for a page: `result` for a page
/// with a result block, else its archetype.
String flarePluginStackArchetype(
  FlarePluginViewModel view, {
  String? inlineFormActionId,
}) => flarePluginResultOf(view) != null
    ? 'result'
    : flarePluginArchetype(
        view,
        embedded: true,
        inlineFormActionId: inlineFormActionId,
      ).name;
