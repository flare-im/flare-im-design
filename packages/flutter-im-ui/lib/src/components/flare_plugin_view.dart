import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/directory_data.dart';
import '../models/plugin_layout.dart';
import '../models/plugin_view.dart';
import '../models/plural.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_action_menu.dart';
import 'flare_resolved_presentation.dart';
import 'flare_avatar.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_icon.dart';
import 'flare_icon_button.dart';
import 'flare_message_card_shell.dart';
import 'flare_plugin_blocks_extra.dart';
import 'flare_plugin_form.dart';
import 'flare_plugin_protected_media.dart';
import 'flare_plugin_upgrade_notice.dart';
import 'flare_empty_state.dart';
import 'flare_result_view.dart';
import 'flare_settings_list.dart';
import 'flare_scene_panels.dart';
import 'flare_screen.dart';
import 'flare_status_banner.dart';
import 'flare_tag.dart';

/// Visual placement only; every layout keeps the same guarded action runner.
/// [roles] is a plugin page's (rules.actionRoles): each top-level action is
/// drawn where its role and the page's archetype put it — the overview's
/// quick keys and grouped list cards, a task's action row, a records page's
/// command keys and "more actions" card, the danger card last. The page
/// itself draws the records header key, and a task's pinned bar when
/// [FlarePluginView.pinBar] is set. [list] draws the account layout's
/// service list as R2.1 list cards (by `group`, the danger rows in a card of
/// their own, last); [quick] draws its keys as the overview's quick row.
enum FlarePluginActionLayout { inline, compact, list, roles, quick }

/// A plugin card: the core SDK's resolved view drawn as a kit business card
/// (spec Message/PluginView; facts in spec/plugin-view-vectors.json). Inert —
/// it reads no paths, evaluates nothing and calls no network; actions go out
/// through [onAction] as opaque ids with the viewer's selection or form
/// values, and the host invokes them.
///
/// Choices are marked at once when submitted and settle when a new [view]
/// arrives; a new non-empty [error] reverts them. An action with a form opens
/// [FlarePluginForm] on the kit sheet. The host's settle signal is
/// [settleToken] (incremented once per finished action, after [error] and
/// [formErrors] are set for it): without either a submitted form closes and
/// the mark stays until the new view; with [error] the mark reverts and the
/// form stays; with [formErrors] the form stays with them. [busyActionId]
/// leaving the action settles the same way as a fallback.
///
/// Protocol v2 (`spec/plugin-view-vectors.json` rules.menuActions,
/// entriesGrouped, unavailableReason, shell): [FlarePluginViewModel.menuActions]
/// open from a ⋯ key at the end of the title row (the kit action menu; an
/// embedded view draws them as keys after its actions) and run like buttons;
/// a grouped entries list draws "选项 · N 票 · P%" before each group and tags
/// the [viewerId]'s rows "我"; an unavailable view says why after its title,
/// led by [displayName]; a read-only copy draws its content and closes with
/// "副本，仅供查看". The card shell is the message's card surface — nothing is
/// drawn around it — and a quoted reply ([FlareCardQuote]) sits inside it,
/// above the title row.
///
/// Entries and rows draw their badge as the kit tag in its tone (rules.badge).
/// A multiple choice with maxSelections disables the options outside a full
/// draft, submits only a draft within the cap and leads its footer with
/// "最多选 n 项" (rules.maxSelections). A rows block (a plugin page) is a list:
/// each key once, the badge and the first cell, the other cells, and the
/// row's action keys, which run like buttons and carry the row
/// (rules.pageRows).
class FlarePluginView extends StatefulWidget {
  const FlarePluginView({
    super.key,
    required this.view,
    this.onInteractionChanged,
    this.icon,
    this.displayName,
    this.viewerId,
    this.busy = false,
    this.busyActionId,
    this.error,
    this.embedded = false,
    this.actionLayout = FlarePluginActionLayout.inline,
    this.archetype,
    this.labelRows = false,
    this.inlineFormActionId,
    this.inlineFormTitle,
    this.inlineFormDescription,
    this.showError = true,
    this.inset = FlarePluginViewInset.none,
    this.resolveUser,
    this.members = const [],
    this.membersLoading = false,
    this.membersRevision = 0,
    this.membersError,
    this.onMemberSearch,
    this.onMembersRetry,
    this.formErrors = const [],
    this.fileStates = const {},
    this.onFileAction,
    this.locationStates = const {},
    this.onLocationAction,
    this.protectedMedia = const {},
    this.onProtectedMediaRead,
    this.settleToken = 0,
    this.onAction,
    this.onOpenDetail,
    this.resolveImage,
    this.onQrRefresh,
    this.upgradeStatus,
    this.onUpdate,
    this.upgradeBusy = false,
    this.offline = false,
    this.pinBar = false,
    this.onDone,
    this.onClearFilters,
  });

  final FlarePluginViewModel view;

  /// The host is offline: every action is disabled, not hidden (R8).
  final bool offline;

  /// [FlarePluginActionLayout.roles]: the page pins a task's bar and
  /// bar-secondary keys itself (a phone), so the view leaves them out.
  final bool pinBar;

  /// A result block's done key (R7); without it the result has none.
  final VoidCallback? onDone;

  /// A page filter other than "all" is chosen (§5.8): an empty list says
  /// so and offers to clear it.
  final VoidCallback? onClearFilters;
  final ValueChanged<bool>? onInteractionChanged;

  /// Kit icon name before the title (the plugin's icon).
  final String? icon;

  /// The card envelope's displayName (the plugin's name): leads the reason
  /// line of an unavailable view ("投票 · 插件已停用").
  final String? displayName;

  /// The viewer's user id: entries rows of that user carry the "我" tag.
  final String? viewerId;

  /// The whole card is busy: every action, choice and submit is disabled.
  final bool busy;

  /// The action in flight: its key spins and every other control waits.
  final String? busyActionId;

  /// Failure text from the host, at the bottom of the card (and in an open
  /// form).
  final String? error;

  /// No card shell or title row (the detail sheet draws the view). An
  /// unavailable embedded view still says what it was: its title as one line
  /// of secondary text.
  final bool embedded;

  final FlarePluginActionLayout actionLayout;

  /// With [FlarePluginActionLayout.roles], the page prototype to place the
  /// actions by instead of the derived one (the account layout's overview).
  final FlarePluginPageArchetype? archetype;

  /// Show page row details as column label/value pairs below each row title.
  final bool labelRows;

  /// A top-level action whose eligible form is composed into this view.
  final String? inlineFormActionId;

  /// Optional heading immediately before an eligible inline form.
  final String? inlineFormTitle;

  /// Supporting copy for that inline form; no effect on action eligibility.
  final String? inlineFormDescription;

  /// Composed pages may draw the host error once, while open forms still receive it.
  final bool showError;

  /// Where the view sits: [FlarePluginViewInset.sheet] gives it the
  /// bottom-sheet insets (md / lg / xl, as [FlarePluginForm]) for a view put
  /// straight into a kit sheet; [FlarePluginViewInset.sheetTop] the same
  /// without the bottom one, for a view with more of the sheet under it (a
  /// preface above [FlarePluginForm]). It pads every state: the embedded
  /// body, available or not, and a card shell kept in a sheet (around the
  /// shell, which keeps its own padding).
  final FlarePluginViewInset inset;
  final FlarePluginResolveUser? resolveUser;

  /// Candidates for members inputs in action forms.
  final List<FlarePluginMember> members;

  /// Server member-search state; without onMemberSearch the picker filters locally.
  final bool membersLoading;

  /// An authoritative roster/permission invalidation, never an ordinary search result.
  final int membersRevision;
  final String? membersError;
  final ValueChanged<String>? onMemberSearch;
  final VoidCallback? onMembersRetry;

  /// The host's validation errors for the open action form.
  final List<FlarePluginFormError> formErrors;
  final Map<String, FlarePluginFileState> fileStates;
  final ValueChanged<FlarePluginFileAction>? onFileAction;

  /// Location inputs: the host's fix, a running locate or a failure, by input
  /// id ([FlarePluginForm.locationStates]).
  final Map<String, FlarePluginLocationState> locationStates;

  /// A location input's locate or clear key: the host runs the page's
  /// locationOnce action into the input ([FlarePluginForm.onLocationAction]).
  final ValueChanged<FlarePluginLocationAction>? onLocationAction;

  /// What the host has for each protected media item, by item id: the read's
  /// address (the server's https grant address), a running read or a failure.
  final Map<String, FlarePluginProtectedMediaState> protectedMedia;

  /// A protected media read (with its reason when the block asks one): the
  /// host runs and audits it, then fills [protectedMedia] with
  /// [flarePluginProtectedMediaUrl] of the result.
  final ValueChanged<FlarePluginProtectedMediaRead>? onProtectedMediaRead;

  /// The host's settle signal: incremented once per finished action, after
  /// that result's [error] / [formErrors] are set. Every change settles the
  /// optimistic choice and a submitted form (spec rules.settle).
  final int settleToken;
  final FlarePluginActionCallback? onAction;

  /// "See all" of an entries block, and the card's view details key: shown
  /// under the action keys when the view has a detail no entries block offers
  /// (spec rules.detailKey). Without it the card offers no view details key.
  final VoidCallback? onOpenDetail;

  /// Image blocks: turns the block's asset path or private file id into what
  /// the host fetched. Without it an image block keeps its frame and says the
  /// image is unavailable.
  final FlarePluginImageResolver? resolveImage;

  /// An expired QR code with a refresh query asks the host for a fresh one:
  /// the host runs the query and passes back a view. Without it no refresh
  /// key is drawn.
  final ValueChanged<FlarePluginQrRefresh>? onQrRefresh;

  /// [FlarePluginUnavailableReason.upgradeRequired]: the engine's
  /// update.plugin_upgrade_status for the view's minBuild.
  final FlarePluginUpgradeStatus? upgradeStatus;

  /// [FlarePluginUnavailableReason.upgradeRequired]: opens the update flow;
  /// without it the notice has no update key.
  final VoidCallback? onUpdate;

  /// The update flow is opening.
  final bool upgradeBusy;

  /// The view details key (a test hook).
  static const Key detailKey = ValueKey('flare-plugin-detail-key');

  /// The ⋯ key of the card's menu actions (a test hook).
  static const Key menuKey = ValueKey('flare-plugin-menu-key');

  /// The reason line of an unavailable view or a read-only copy.
  static const Key reasonKey = ValueKey('flare-plugin-reason');

  /// The list item of the row [key] in a rows block (a test hook).
  static Key rowKey(String key) => ValueKey('flare-plugin-row:$key');

  /// The key of [actionId] on the row [key] (a test hook).
  static Key rowActionKey(String key, String actionId) =>
      ValueKey('flare-plugin-row-action:$key:$actionId');

  /// The empty text of a rows block without rows.
  static const Key rowsEmptyKey = ValueKey('flare-plugin-rows-empty');

  /// The clear-filter key of an empty filtered list (§5.8).
  static const Key clearFiltersKey = ValueKey('flare-plugin-clear-filters');

  @override
  State<FlarePluginView> createState() => FlarePluginViewState();
}

class _Pending {
  const _Pending(this.block, this.actionId, this.selection);
  final int block;
  final String actionId;
  final List<int> selection;
}

class _FormState {
  const _FormState({this.busy = false, this.errors = const [], this.error});
  final bool busy;
  final List<FlarePluginFormError> errors;
  final String? error;
}

/// The view's state: [runAction] runs a top-level action the host page draws
/// itself (a records header key, a phone task's pinned bar) through the same
/// confirm and form flow as the view's own keys.
class FlarePluginViewState extends State<FlarePluginView> {
  final Map<String, FlarePluginUser?> _users = {};

  /// A section's fold the reader chose, by its index in the flat blocks.
  final Map<int, bool> _folded = {};
  final Map<int, List<int>> _drafts = {};
  _Pending? _pending;

  /// The row whose action was run last: its key spins while that action is
  /// in flight.
  String? _rowInFlight;

  FlarePluginAction? _formAction;
  // What the action carried when its form opened (a choices selection and its
  // optimistic mark): the form adds its values to it.
  FlarePluginActionPayload _formCarry = const FlarePluginActionPayload();
  VoidCallback? _formBefore;
  bool _formSubmitted = false;
  BuildContext? _sheetContext;
  final ValueNotifier<_FormState> _form = ValueNotifier(const _FormState());
  final ValueNotifier<bool> _formBusy = ValueNotifier(false);
  String? _inlineSubmitted;
  int _inlineRevision = 0;

  // The forms on this view: a page action whose native target writes into
  // one of their inputs runs through it. The inline form's key changes with
  // its action and revision, like the value key it replaced.
  GlobalKey<FlarePluginFormState>? _inlineFormKey;
  String _inlineFormKeyId = '';
  GlobalKey<FlarePluginFormState>? _sheetFormKey;
  GlobalKey<FlarePluginFormState> _inlineKey(String id) {
    if (_inlineFormKey == null || _inlineFormKeyId != id) {
      _inlineFormKeyId = id;
      _inlineFormKey = GlobalKey<FlarePluginFormState>(
        debugLabel: 'flare-plugin-inline-form:$id',
      );
    }
    return _inlineFormKey!;
  }

  bool get _locked =>
      widget.busy || widget.busyActionId != null || _inlineSubmitted != null;

  /// Every action key waits: locked, offline or no host.
  bool get _keysOff => _locked || widget.offline || widget.onAction == null;

  /// Runs the top-level action [id] (a key the page draws); a danger one
  /// always asks first.
  void runAction(String id) {
    final action = flarePluginTopLevelActions(
      widget.view,
      embedded: true,
    ).where((a) => a.id == id).firstOrNull;
    if (action == null) return;
    // The page's own form submits through its inline form's checks.
    if (action.id == _inlineAction?.id) {
      _inlineFormKey?.currentState?.submit();
      return;
    }
    _run(
      action,
      const FlarePluginActionPayload(),
      confirmDanger: action.style == FlarePluginActionStyle.danger,
    );
  }

  FlarePluginAction? get _inlineAction => flarePluginInlineFormAction(
    widget.view,
    widget.inlineFormActionId,
    interactive: widget.onAction != null,
  );

  @override
  void initState() {
    super.initState();
    _requestUsers();
  }

  @override
  void didUpdateWidget(FlarePluginView old) {
    super.didUpdateWidget(old);
    // Answers are kept per id: hosts pass resolvers as closures built in
    // build, so a new function is not a new directory.
    if (old.view != widget.view) {
      _pending = null;
      _drafts.clear();
    }
    final previousInline = flarePluginInlineFormAction(
      old.view,
      old.inlineFormActionId,
      interactive: old.onAction != null,
    );
    if (previousInline?.id != _inlineAction?.id) {
      _inlineSubmitted = null;
      _inlineRevision++;
    }
    final error = widget.error;
    if (error != null && error.isNotEmpty && error != old.error) _revert();
    // The fallback: busyActionId leaving the action.
    final before = old.busyActionId;
    if (before != null && widget.busyActionId != before) _settle(before);
    // The explicit signal: every change of the token (a busyActionId set and
    // cleared within one frame never shows a change).
    if (widget.settleToken != old.settleToken) _settle(null);
    // The open form's sheet is another route: update it after this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncForm();
    });
    _requestUsers();
  }

  @override
  void dispose() {
    _form.dispose();
    _formBusy.dispose();
    super.dispose();
  }

  // ── users ──────────────────────────────────────────────────────────────
  void _requestUsers() {
    final resolve = widget.resolveUser;
    if (resolve == null) return;
    for (final id in _userIds()) {
      if (_users.containsKey(id)) continue;
      _users[id] = null;
      try {
        final answer = resolve(id);
        if (answer is Future<FlarePluginUser?>) {
          answer.then((user) {
            if (user != null && mounted) setState(() => _users[id] = user);
          }, onError: (_) {});
        } else if (answer != null) {
          _users[id] = answer;
        }
      } catch (_) {
        // The fallback stands.
      }
    }
  }

  Iterable<String> _userIds() sync* {
    for (final (:block, section: _) in flarePluginFlatBlocks(
      widget.view.blocks,
    )) {
      if (block is FlarePluginPeopleBlock) {
        for (final group in block.groups) {
          yield* group.userIds;
        }
      } else if (block is FlarePluginEntriesBlock) {
        for (final entry in block.items) {
          if (entry.userId != null && entry.name == null) yield entry.userId!;
        }
      } else if (block is FlarePluginRowsBlock) {
        // A person cell reads as the person's name (rules.rowsIcon).
        for (final row in block.rows) {
          for (final cell in row.cells) {
            if (cell.userId case final id?) yield id;
          }
        }
      }
    }
  }

  FlarePluginUser _userOf(String userId) =>
      _users[userId] ?? FlarePluginUser(name: flarePluginFallbackName(userId));

  // ── vocabulary 2: sections and QR refresh ──────────────────────────────
  /// Whether the section at [index] of [flat] is folded: the reader's choice,
  /// else what the plugin declared; a section without a label never is.
  bool _sectionCollapsed(
    List<({FlarePluginBlock block, int? section})> flat,
    int index,
  ) {
    final block = flat[index].block;
    if (block is! FlarePluginSectionBlock || (block.label ?? '').isEmpty) {
      return false;
    }
    return _folded[index] ?? block.collapsed;
  }

  void _refreshQr(FlarePluginQrBlock block) {
    final operation = block.refreshOperation;
    if (_locked || operation == null) return;
    widget.onQrRefresh?.call((
      operation: operation,
      valuePath: block.valuePath,
      expiresAtPath: block.expiresAtPath,
    ));
  }

  // ── choices ────────────────────────────────────────────────────────────
  List<int> _viewSelection(FlarePluginChoicesBlock block) => [
    for (final option in block.options)
      if (option.selected) option.index,
  ];

  bool _sameSet(List<int> a, List<int> b) =>
      a.length == b.length &&
      (List.of(a)..sort()).join(',') == (List.of(b)..sort()).join(',');

  bool _interactive(FlarePluginChoicesBlock block, int index) =>
      !flarePluginReadOnly(widget.view) &&
      block.action != null &&
      !block.closed &&
      !_locked &&
      _pending?.block != index &&
      widget.onAction != null;

  List<int> _shown(FlarePluginChoicesBlock block, int index) {
    final pending = _pending;
    if (pending != null && pending.block == index) return pending.selection;
    if (block.multiple && block.action != null && !block.closed)
      return _drafts[index] ?? _viewSelection(block);
    return _viewSelection(block);
  }

  List<int> _draft(FlarePluginChoicesBlock block, int index) =>
      _drafts[index] ?? _viewSelection(block);

  bool _submitEnabled(FlarePluginChoicesBlock block, int index) {
    final draft = _draft(block, index);
    return draft.isNotEmpty &&
        !_sameSet(draft, _viewSelection(block)) &&
        flarePluginWithinCap(block, draft);
  }

  /// The options the cap holds back while the block can be chosen.
  Set<int> _capped(FlarePluginChoicesBlock block, int index) {
    if (!_interactive(block, index)) return const {};
    final draft = _draft(block, index);
    return {
      for (final option in block.options)
        if (flarePluginChoiceCapped(block, draft, option.index)) option.index,
    };
  }

  void _pick(FlarePluginChoicesBlock block, int index, int option) {
    if (!_interactive(block, index)) return;
    if (flarePluginChoiceCapped(block, _draft(block, index), option)) return;
    if (block.multiple) {
      final draft = {...(_drafts[index] ?? _viewSelection(block))};
      if (!draft.remove(option)) draft.add(option);
      setState(() => _drafts[index] = draft.toList()..sort());
      return;
    }
    final current = _viewSelection(block);
    if (current.length == 1 && current.first == option) return;
    _submitChoices(block, index, [option]);
  }

  void _submitChoices(
    FlarePluginChoicesBlock block,
    int index,
    List<int> selection,
  ) {
    final action = block.action;
    if (action == null) return;
    final sorted = List<int>.of(selection)..sort();
    _run(
      action,
      FlarePluginActionPayload(selection: sorted),
      before: () =>
          setState(() => _pending = _Pending(index, action.id, sorted)),
    );
  }

  void _runRow(FlarePluginAction action, FlarePluginRow row, Object? input) =>
      _run(
        action,
        FlarePluginActionPayload(row: (key: row.key, input: input)),
        before: () => setState(() => _rowInFlight = row.key),
      );

  void _revert() {
    final pending = _pending;
    if (pending == null) return;
    _drafts.remove(pending.block);
    _pending = null;
  }

  /// The host finished an action ([actionId] when the fallback knows which):
  /// an optimistic choice reverts when the result carries an error or form
  /// errors and otherwise stays until the new view; a submitted form closes
  /// unless it came back with errors. Settling twice is the same as once.
  void _settle(String? actionId) {
    final failed =
        (widget.error ?? '').isNotEmpty || widget.formErrors.isNotEmpty;
    if (_inlineSubmitted != null &&
        (actionId == null || actionId == _inlineSubmitted)) {
      _inlineSubmitted = null;
      if (!failed) _inlineRevision++;
    }
    final pending = _pending;
    if (failed &&
        pending != null &&
        (actionId == null || pending.actionId == actionId)) {
      _revert();
    }
    final form = _formAction;
    if (form != null &&
        _formSubmitted &&
        !failed &&
        (actionId == null || form.id == actionId)) {
      _closeForm();
    }
  }

  // ── actions, confirmation and forms ───────────────────────────────────
  Future<void> _run(
    FlarePluginAction action,
    FlarePluginActionPayload payload, {
    VoidCallback? before,
    bool confirmDanger = false,
  }) async {
    if (_locked || widget.offline || widget.onAction == null) return;
    // A native target writing `into` an input of a form on this view runs
    // through that input's own key, so the host's answer is written into the
    // form's current scope (no earlier touch of the input needed).
    final target = action.target;
    if (payload.row == null &&
        target?.kind == 'native' &&
        target?.into != null &&
        ((_inlineFormKey?.currentState?.nativeInto(target) ?? false) ||
            (_sheetFormKey?.currentState?.nativeInto(target) ?? false))) {
      return;
    }
    // The input belongs to another action's form that is not open (a page's
    // capture keys beside its submit): open that form and run the target
    // through the input's key there, so the answer lands in the form.
    final holder = payload.row == null && _formAction == null
        ? _nativeIntoHolder(target, action.id)
        : null;
    if (holder != null) {
      _openForm(holder, const FlarePluginActionPayload(), before);
      _runInOpenedForm(target!, holder.id, 30);
      return;
    }
    final confirm = (action.confirm?.isNotEmpty ?? false)
        ? action.confirm
        // R2: a page's danger action always goes through DangerConfirm.
        : confirmDanger
        ? ''
        : null;
    if (confirm != null) {
      widget.onInteractionChanged?.call(true);
      final ok = await FlareDangerConfirm.show(
        context,
        title: action.label,
        description: confirm,
        confirmText: action.label,
      );
      widget.onInteractionChanged?.call(false);
      if (!ok || !mounted) return;
    }
    if (action.form.isNotEmpty) {
      _openForm(action, payload, before);
      return;
    }
    before?.call();
    widget.onAction?.call(action.id, payload);
  }

  /// Another action of this view, asking no confirmation, whose form holds
  /// the input [target] writes into (and the host has that input's key).
  FlarePluginAction? _nativeIntoHolder(
    FlarePluginActionTarget? target,
    String excluding,
  ) {
    if (target?.kind != 'native' || target?.into == null) return null;
    return widget.view.actions
        .where(
          (other) =>
              other.id != excluding &&
              (other.confirm == null || other.confirm!.isEmpty) &&
              _formInputs(other).any((input) {
                switch (flarePluginNativeIntoKey(target, input)) {
                  case 'file':
                    return widget.onFileAction != null;
                  case 'location':
                    return widget.onLocationAction != null;
                  default:
                    return false;
                }
              }),
        )
        .firstOrNull;
  }

  /// Runs [target] through the form opened for it once the form is built; a
  /// form closed (or another opened) meanwhile drops it.
  void _runInOpenedForm(
    FlarePluginActionTarget target,
    String formActionId,
    int frames,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _formAction?.id != formActionId) return;
      final form = _sheetFormKey?.currentState;
      if (form != null) {
        form.nativeInto(target);
      } else if (frames > 0) {
        _runInOpenedForm(target, formActionId, frames - 1);
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// The inputs [action]'s form draws: block-bound ones are the block's
  /// (R6.1).
  List<FlarePluginInput> _formInputs(FlarePluginAction action) =>
      flarePluginFormFields(widget.view, action);

  void _submitFormValues(
    FlarePluginAction action,
    Map<String, Object?> values, {
    FlarePluginActionPayload carry = const FlarePluginActionPayload(),
    VoidCallback? before,
    bool inline = false,
  }) {
    if (!mounted ||
        _locked ||
        widget.onAction == null ||
        !widget.view.available ||
        flarePluginReadOnly(widget.view))
      return;
    if (inline && _inlineAction?.id != action.id) return;
    if (inline) setState(() => _inlineSubmitted = action.id);
    before?.call();
    widget.onAction!(
      action.id,
      FlarePluginActionPayload(
        selection: carry.selection,
        row: carry.row,
        formValues: values,
      ),
    );
  }

  void _syncForm() {
    final action = _formAction;
    final busy =
        widget.busy || (action != null && widget.busyActionId == action.id);
    _formBusy.value = busy;
    _form.value = _FormState(
      busy: busy,
      errors: _formSubmitted ? widget.formErrors : const [],
      error: _formSubmitted ? widget.error : null,
    );
  }

  void _openForm(
    FlarePluginAction action,
    FlarePluginActionPayload carry,
    VoidCallback? before,
  ) {
    widget.onInteractionChanged?.call(true);
    _formAction = action;
    _formCarry = carry;
    _formBefore = before;
    _formSubmitted = false;
    _syncForm();
    final inputs = _formInputs(action);
    _sheetFormKey = GlobalKey<FlarePluginFormState>();
    Widget form(BuildContext sheetContext) {
      _sheetContext = sheetContext;
      return ValueListenableBuilder<_FormState>(
        valueListenable: _form,
        builder: (context, state, _) => FlarePluginForm(
          key: _sheetFormKey,
          fileStates: widget.fileStates,
          onFileAction: widget.onFileAction,
          locationStates: widget.locationStates,
          onLocationAction: widget.onLocationAction,
          inputs: inputs,
          errors: state.errors,
          busy: state.busy,
          error: state.error,
          members: widget.members,
          membersLoading: widget.membersLoading,
          membersRevision: widget.membersRevision,
          membersError: widget.membersError,
          onMemberSearch: widget.onMemberSearch,
          onMembersRetry: widget.onMembersRetry,
          onSubmit: (values) {
            if (!mounted || _locked) return;
            _formSubmitted = true;
            _syncForm();
            // Every platform sends the carried selection with the values.
            _submitFormValues(
              action,
              values,
              carry: _formCarry,
              before: _formBefore,
            );
          },
          onCancel: () => Navigator.of(sheetContext).maybePop(),
        ),
      );
    }

    // R6: ≤ 4 plain fields on a sheet (a dialog off phones); more, or a
    // file, document, image or members input, as a page of its own.
    final Future<void> shown =
        flarePluginFormPlacement([
              for (final input in inputs) input.kind,
            ], inline: false) ==
            FlarePluginFormPlacement.page
        ? Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (routeContext) => ValueListenableBuilder<bool>(
                valueListenable: _formBusy,
                builder: (context, busy, child) =>
                    PopScope(canPop: !busy, child: child!),
                child: FlareScreen(
                  key: const ValueKey('flare-plugin-form-page'),
                  title: action.label,
                  onBack: () => Navigator.of(routeContext).maybePop(),
                  scroll: false,
                  surface: FlareScreenSurface.surface,
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: FlareSizes.componentFormColumnWidth,
                      ),
                      child: Builder(builder: form),
                    ),
                  ),
                ),
              ),
            ),
          )
        : FlareBottomSheet.show<void>(
            context,
            title: action.label,
            busy: _formBusy,
            builder: form,
          );
    shown.whenComplete(() {
      widget.onInteractionChanged?.call(false);
      _sheetContext = null;
      if (_formAction == action) {
        _formAction = null;
        _formCarry = const FlarePluginActionPayload();
        _formBefore = null;
        _formSubmitted = false;
      }
    });
  }

  void _closeForm() {
    final sheet = _sheetContext;
    _formAction = null;
    _formCarry = const FlarePluginActionPayload();
    _formBefore = null;
    _formSubmitted = false;
    if (sheet != null && sheet.mounted) {
      final route = ModalRoute.of(sheet);
      final navigator = Navigator.of(sheet);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // A successful action may already have pushed its next page. Remove
        // this form's route specifically instead of popping that new page.
        if (navigator.mounted && route != null && route.isActive) {
          navigator.removeRoute(route);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (flareHasResolvedPresentation(widget.view)) {
      return FlareResolvedPresentation(
        view: widget.view,
        fileStates: widget.fileStates,
        onFileAction: widget.onFileAction,
        busy: _locked,
        onRequest: (id) {
          final action = widget.view.actions
              .where((a) => a.id == id)
              .firstOrNull;
          if (action != null) _run(action, const FlarePluginActionPayload());
        },
      );
    }
    final colors = FlareColors.of(context);
    final view = widget.view;
    final children = <Widget>[];
    // The children that open a section (R1: 24 above them on a page).
    final sectionStarts = <int>{};
    final strings = FlareStrings.of(context);
    final reason = flarePluginReasonLine(
      view,
      strings,
      displayName: widget.displayName,
    );
    // A read-only copy runs nothing, even if a copy still carried actions.
    final readOnly = flarePluginReadOnly(view);
    final inlineAction = _inlineAction;
    final hasInlineFormCopy =
        (widget.inlineFormTitle?.trim().isNotEmpty ?? false) ||
        (widget.inlineFormDescription?.trim().isNotEmpty ?? false);
    final interactive = view.available && !readOnly;
    final roles =
        widget.embedded && widget.actionLayout == FlarePluginActionLayout.roles;
    // A card (R2.4) and a plugin page (R2) place their actions by role; the
    // account layout's embedded projections keep their own layouts.
    final places = !interactive || (widget.embedded && !roles)
        ? null
        : flarePluginActionPlaces(
            view,
            embedded: widget.embedded,
            inlineFormActionId: inlineAction?.id,
            archetype: widget.archetype,
          );
    final menuActions = !interactive
        ? const <FlarePluginAction>[]
        : places != null && !widget.embedded
        ? places.menu
        : view.menuActions;
    final keys = !interactive || roles
        ? <FlarePluginAction>[]
        : places != null
        ? places.footer
        : [
            for (final action in [
              ...view.actions,
              if (widget.embedded) ...menuActions,
            ])
              if (action.id != inlineAction?.id) action,
          ];
    final result = widget.embedded && view.available
        ? flarePluginResultOf(view)
        : null;
    final statusCard =
        widget.embedded &&
        view.available &&
        result == null &&
        flarePluginShowsStatusCard(view);
    final openDetail = widget.onOpenDetail;
    final detail =
        openDetail != null &&
            !readOnly &&
            flarePluginShowsDetailKey(view, embedded: widget.embedded)
        ? FlareButton(
            key: FlarePluginView.detailKey,
            label: strings.pluginViewDetail,
            variant: FlareButtonVariant.quiet,
            size: FlareControlSize.sm,
            appearance: FlareButtonAppearance.text,
            disabled: _locked,
            onPressed: openDetail,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(strings.pluginViewDetail),
                const SizedBox(width: FlareSizes.spacing3xs),
                const FlareIcon('chevron-right', size: FlareSizes.iconSizeSm),
              ],
            ),
          )
        : null;
    if (!widget.embedded) {
      children.add(
        _TitleRow(
          title: view.title,
          icon: widget.icon,
          detail: keys.isEmpty ? detail : null,
          menu: menuActions.isEmpty
              ? null
              : Builder(
                  builder: (context) => FlareIconButton(
                    key: FlarePluginView.menuKey,
                    icon: 'more',
                    semanticLabel: strings.pluginViewMore,
                    size: FlareControlSize.sm,
                    disabled: _keysOff,
                    onPressed: () => _openMenu(context, menuActions),
                  ),
                ),
        ),
      );
    } else if (!view.available && view.title.isNotEmpty) {
      // No title row: an unavailable view still says what it was.
      children.add(
        Text(
          view.title,
          key: const ValueKey('flare-plugin-unavailable-title'),
          style: TextStyle(
            fontSize: FlareSizes.fontSizeMd,
            color: colors.textSecondary,
          ),
        ),
      );
    }
    if (!view.available &&
        view.unavailableReason ==
            FlarePluginUnavailableReason.upgradeRequired) {
      // A contribution this build cannot draw: the line and, when a newer
      // build is offered, the update key.
      children.add(
        FlarePluginUpgradeNotice(
          status: widget.upgradeStatus,
          onUpdate: widget.onUpdate,
          busy: widget.upgradeBusy,
        ),
      );
    } else if (!view.available && reason != null) {
      children.add(_reasonLine(colors, reason, secondary: true));
    }
    if (view.available) {
      final flat = flarePluginFlatBlocks(view.blocks);
      // §6.1 status card: the toned field, the first text or note, the
      // steps and the first primary are drawn by the card, banners never.
      final cardField = statusCard
          ? (view.fields.where((f) => f.tone != null).firstOrNull ??
                view.fields.firstOrNull)
          : null;
      final cardText = statusCard
          ? flat.indexWhere(
              (e) =>
                  e.block is FlarePluginTextBlock ||
                  e.block is FlarePluginNoteBlock,
            )
          : -1;
      final cardSteps = statusCard
          ? flat.indexWhere((e) => e.block is FlarePluginStepsBlock)
          : -1;
      final cardPrimary = statusCard && interactive
          ? flarePluginTopLevelActions(view, embedded: true)
                .where((a) => a.style == FlarePluginActionStyle.primary)
                .firstOrNull
          : null;
      bool drawn(FlarePluginAction action) => action.id != cardPrimary?.id;
      // Overview: the quick keys close the card that holds the hero or stats.
      // R2.1: inside the overview card — the first hero takes them as its
      // footer; without a hero they close the stats' section.
      final heroAt = places?.archetype == FlarePluginPageArchetype.overview
          ? flat.indexWhere((e) => e.block is FlarePluginHeroBlock)
          : -1;
      final quickAt = heroAt >= 0
          ? -2
          : places?.archetype == FlarePluginPageArchetype.overview
          ? () {
              final at = flat.indexWhere(
                (e) =>
                    e.block is FlarePluginHeroBlock ||
                    e.block is FlarePluginStatsBlock,
              );
              final section = flat[at].section;
              return section == null
                  ? at
                  : flat.lastIndexWhere((e) => e.section == section);
            }()
          : -1;
      if (result != null) {
        final top = interactive
            ? flarePluginTopLevelActions(view, embedded: true)
            : const <FlarePluginAction>[];
        children.add(
          FlareResultView(
            key: const ValueKey('flare-plugin-result'),
            title: flarePluginStatusText(
              result.title,
              unmapped: result.unmapped,
              strings: strings,
              where: 'result',
            ),
            tone: result.unmapped ? FlarePluginTone.neutral : result.tone,
            amount: result.amount == null
                ? null
                : flarePluginFormatText(result.amount!, result.format, strings),
            description: result.description,
            details: view.fields,
            busy: _locked,
            // A phone page pins the done key itself (R7).
            onDone: widget.pinBar ? null : widget.onDone,
            secondaryLabel: top.firstOrNull?.label,
            onSecondary: top.isEmpty || _keysOff
                ? null
                : () => _run(top.first, const FlarePluginActionPayload()),
            actions: [
              for (final action in top.skip(1))
                _key(
                  action,
                  variant: FlareButtonVariant.secondary,
                  block: true,
                ),
            ],
          ),
        );
      } else if (statusCard) {
        // §6.1: a banner with a key (the journal's 处理) is not what the card
        // replaces; it leads, above the card.
        for (final entry in flat) {
          if (entry.block case final FlarePluginBannerBlock banner
              when banner.action != null) {
            children.add(
              FlarePluginBannerView(
                block: banner,
                busy: _locked,
                onAction: readOnly || widget.onAction == null
                    ? null
                    : (action) =>
                          _run(action, const FlarePluginActionPayload()),
              ),
            );
          }
        }
        children.add(
          _StatusCard(
            field: cardField,
            description: switch (cardText < 0 ? null : flat[cardText].block) {
              FlarePluginTextBlock(:final text) => text,
              FlarePluginNoteBlock(:final text) => text,
              _ => null,
            },
            steps: cardSteps < 0
                ? null
                : flat[cardSteps].block as FlarePluginStepsBlock,
            primary: cardPrimary == null
                ? null
                : _key(cardPrimary, block: true, size: FlareControlSize.lg),
            caption: cardPrimary != null && widget.offline
                ? strings.pluginViewAvailableOnline
                : null,
          ),
        );
        final rest = [
          for (final field in view.fields)
            if (!identical(field, cardField)) field,
        ];
        if (rest.isNotEmpty) children.add(_FieldsList(fields: rest));
      } else if (view.fields.isNotEmpty) {
        children.add(_FieldsList(fields: view.fields));
      }
      for (var i = 0; i < flat.length; i += 1) {
        final (:block, :section) = flat[i];
        // The children of a folded section are not drawn.
        if (section != null && _sectionCollapsed(flat, section)) continue;
        // What the result view or the status card already drew.
        if (block is FlarePluginResultBlock) continue;
        if (statusCard &&
            (i == cardText ||
                i == cardSteps ||
                block is FlarePluginBannerBlock)) {
          continue;
        }
        if (block is FlarePluginSectionBlock)
          sectionStarts.add(children.length);
        children.add(
          KeyedSubtree(
            key: ValueKey('flare-plugin-block-$i'),
            child: switch (block) {
              FlarePluginTextBlock() => _TextBlock(block: block),
              FlarePluginFieldsBlock() => _FieldsList(fields: block.fields),
              FlarePluginChoicesBlock() => _ChoicesBlock(
                block: block,
                selected: _shown(block, i),
                interactive: _interactive(block, i),
                capped: _capped(block, i),
                submitEnabled: _submitEnabled(block, i),
                submitLoading:
                    block.action != null &&
                    widget.busyActionId == block.action!.id,
                onPick: (option) => _pick(block, i, option),
                onSubmit: () =>
                    _submitChoices(block, i, _drafts[i] ?? const []),
              ),
              FlarePluginEntriesBlock() => _EntriesBlock(
                block: block,
                userOf: _userOf,
                viewerId: widget.viewerId,
                onSeeAll: widget.onOpenDetail,
              ),
              FlarePluginPeopleBlock() => _PeopleBlock(
                block: block,
                userOf: _userOf,
              ),
              FlarePluginStatusBlock() => _StatusBlock(block: block),
              FlarePluginProgressBlock() => _ProgressBlock(block: block),
              FlarePluginTimeBlock() => _TimeBlock(block: block),
              FlarePluginDividerBlock() => Divider(
                height: 1,
                thickness: 1,
                color: colors.borderSecondary,
              ),
              FlarePluginNoteBlock() => _NoteBlock(
                block: block,
                plain: section != null && block.tone == FlarePluginTone.info,
              ),
              FlarePluginRowsBlock() => _RowsBlock(
                block: block,
                labelRows: widget.labelRows,
                readOnly: readOnly,
                locked: _locked || widget.onAction == null,
                busyActionId: widget.busyActionId,
                rowInFlight: _rowInFlight,
                nameOf: (id) => _userOf(id).name,
                onAction: (action, row, input) => _runRow(action, row, input),
                onClearFilters: widget.onClearFilters,
                // R8: an empty list offers the page's create action.
                // (an overview already has it among its quick keys).
                emptyAction:
                    places?.archetype == FlarePluginPageArchetype.records
                    ? flarePluginTopLevelActions(view, embedded: true)
                          .where(
                            (a) => a.style == FlarePluginActionStyle.primary,
                          )
                          .map((a) => _key(a))
                          .firstOrNull
                    : null,
              ),
              FlarePluginSectionBlock() => FlarePluginSectionHeader(
                block: block,
                collapsed: _sectionCollapsed(flat, i),
                onToggle: () =>
                    setState(() => _folded[i] = !_sectionCollapsed(flat, i)),
              ),
              FlarePluginStatsBlock() => FlarePluginStatsView(block: block),
              FlarePluginChartBlock() => FlarePluginChartView(block: block),
              FlarePluginImageBlock() => FlarePluginImageView(
                block: block,
                resolve: widget.resolveImage,
              ),
              FlarePluginQrBlock() => FlarePluginQrView(
                block: block,
                busy: _locked,
                onRefresh: widget.onQrRefresh == null || readOnly
                    ? null
                    : () => _refreshQr(block),
              ),
              FlarePluginHeroBlock() => FlarePluginHeroView(
                block: block,
                busy: _locked,
                busyActionId: widget.busyActionId,
                footer: i == heroAt
                    ? _quickRow(places!.quick.where(drawn).toList(), strings)
                    : null,
                onAction: readOnly || widget.onAction == null
                    ? null
                    : (action) =>
                          _run(action, const FlarePluginActionPayload()),
              ),
              FlarePluginStepsBlock() => FlarePluginStepsView(block: block),
              FlarePluginBannerBlock() => FlarePluginBannerView(
                block: block,
                busy: _locked,
                onAction: readOnly || widget.onAction == null
                    ? null
                    : (action) =>
                          _run(action, const FlarePluginActionPayload()),
              ),
              FlarePluginTimelineBlock() => FlarePluginTimelineView(
                block: block,
              ),
              FlarePluginProtectedMediaBlock() => FlarePluginProtectedMediaView(
                block: block,
                states: widget.protectedMedia,
                busy: _locked,
                onRead: readOnly ? null : widget.onProtectedMediaRead,
              ),
              FlarePluginResultBlock() => const SizedBox.shrink(),
            },
          ),
        );
        if (i == quickAt) {
          children.add(_quickRow(places!.quick.where(drawn).toList(), strings));
        }
      }
      if (inlineAction != null) {
        children.add(
          Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              // R6 / G-14: the page's form column (560) at the start side;
              // the account flow layout's titled form keeps its 420
              // (spec/account-layout-vectors.json formWidth).
              constraints: BoxConstraints(
                maxWidth: hasInlineFormCopy
                    ? FlareSizes.primaryPaneMaxWidth
                    : FlareSizes.componentFormColumnWidth,
              ),
              child: SizedBox(
                key: const ValueKey('flare-plugin-inline-form-region'),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.inlineFormTitle case final title?
                        when title.trim().isNotEmpty) ...[
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: FlareSizes.fontSizeXl,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: FlareSizes.spacingSm),
                    ],
                    if (widget.inlineFormDescription case final description?
                        when description.trim().isNotEmpty) ...[
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: FlareSizes.fontSizeSm,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: FlareSizes.spacingMd),
                    ],
                    FlarePluginForm(
                      fileStates: widget.fileStates,
                      onFileAction: widget.onFileAction,
                      locationStates: widget.locationStates,
                      onLocationAction: widget.onLocationAction,
                      key: _inlineKey('${inlineAction.id}:$_inlineRevision'),
                      inputs: _formInputs(inlineAction),
                      embedded: true,
                      pinSubmit: widget.pinBar,
                      submitLabel: inlineAction.label,
                      busy: _locked,
                      errors: widget.formErrors,
                      error: widget.error,
                      members: widget.members,
                      membersLoading: widget.membersLoading,
                      membersRevision: widget.membersRevision,
                      membersError: widget.membersError,
                      onMemberSearch: widget.onMemberSearch,
                      onMembersRetry: widget.onMembersRetry,
                      onSubmit: (values) =>
                          _submitFormValues(inlineAction, values, inline: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      if (keys.isNotEmpty) {
        children.add(
          DecoratedBox(
            decoration: BoxDecoration(
              border: widget.embedded
                  ? null
                  : Border(top: BorderSide(color: colors.borderSecondary)),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: widget.embedded ? 0 : FlareSizes.spacing2xs,
              ),
              // List rows never take the primary's brand colour (R2.1).
              child: widget.actionLayout == FlarePluginActionLayout.list
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [..._listGroups(keys, strings), ?detail],
                    )
                  : widget.actionLayout == FlarePluginActionLayout.quick
                  ? _quickRow(keys, strings)
                  : widget.actionLayout == FlarePluginActionLayout.compact
                  ? Wrap(
                      spacing: FlareSizes.spacingSm,
                      runSpacing: FlareSizes.spacingSm,
                      children: [
                        for (final action in keys)
                          FlareButton(
                            key: ValueKey('flare-plugin-action-${action.id}'),
                            label: action.label,
                            variant: _variantOf(action),
                            size: FlareControlSize.sm,
                            maintainTouchTarget: true,
                            loading: widget.busyActionId == action.id,
                            disabled: _keysOff,
                            onPressed: () =>
                                _run(action, const FlarePluginActionPayload()),
                          ),
                        if (detail != null) detail,
                      ],
                    )
                  : OverflowBar(
                      spacing: FlareSizes.spacingSm,
                      overflowSpacing: FlareSizes.spacingSm,
                      alignment: MainAxisAlignment.spaceBetween,
                      overflowAlignment: OverflowBarAlignment.end,
                      children: [
                        Wrap(
                          spacing: FlareSizes.spacingMd,
                          runSpacing: FlareSizes.spacingSm,
                          children: [
                            for (final action in keys)
                              FlareButton(
                                key: ValueKey(
                                  'flare-plugin-action-${action.id}',
                                ),
                                label: action.label,
                                variant: _variantOf(action),
                                size: FlareControlSize.sm,
                                // A card's footer keys are kit buttons
                                // (R2.4); the text keys stay only for the
                                // embedded inline layout.
                                appearance: widget.embedded
                                    ? FlareButtonAppearance.text
                                    : FlareButtonAppearance.standard,
                                maintainTouchTarget: !widget.embedded,
                                loading: widget.busyActionId == action.id,
                                disabled: _keysOff,
                                onPressed: () => _run(
                                  action,
                                  const FlarePluginActionPayload(),
                                ),
                              ),
                          ],
                        ),
                        if (detail != null) detail,
                      ],
                    ),
            ),
          ),
        );
      }
      if (places != null && roles && result == null) {
        children.addAll(
          _placed(
            places,
            drawn,
            strings,
            quickAt: quickAt,
            inline: inlineAction,
          ),
        );
      }
      if (reason != null) {
        children.add(_reasonLine(colors, reason, secondary: false));
      }
    }
    final error = widget.error;
    if (widget.showError &&
        inlineAction == null &&
        error != null &&
        error.isNotEmpty) {
      children.add(
        FlareStatusBanner(text: error, tone: FlareStatusTone.danger),
      );
    }
    final body = Column(
      crossAxisAlignment:
          widget.actionLayout == FlarePluginActionLayout.compact &&
              inlineAction == null &&
              view.fields.isEmpty &&
              view.blocks.isEmpty
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i += 1) ...[
          // R1: a page's blocks 16 apart, its sections 24; a card keeps 12.
          if (i > 0)
            SizedBox(
              height: !widget.embedded
                  ? FlareSizes.spacingMd
                  : sectionStarts.contains(i)
                  ? FlareSizes.spacing2xl
                  : FlareSizes.spacingLg,
            ),
          children[i],
        ],
      ],
    );
    final content = Semantics(
      container: true,
      label: view.title,
      explicitChildNodes: true,
      child: body,
    );
    if (widget.embedded) return _inset(content);
    // The card width token, never wider than the parent allows (a tight
    // parent is loosened so the card keeps its width). A card kept in a sheet
    // takes the sheet's insets around its shell.
    return _inset(
      Align(
        alignment: AlignmentDirectional.topStart,
        widthFactor: 1,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FlareSizes.componentRichCardWidth,
          ),
          child: DecoratedBox(
            key: const ValueKey('flare-plugin-card'),
            decoration: BoxDecoration(
              color: colors.bgPrimary,
              borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
              border: Border.all(
                color: colors.borderSecondary.withValues(
                  alpha: colors.borderSecondary.a * 0.6,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(FlareSizes.spacingMd),
              child: SizedBox(
                width: double.infinity,
                child: switch (FlareCardQuote.maybeOf(context)) {
                  final quote? => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      quote,
                      const SizedBox(height: FlareSizes.spacingSm),
                      content,
                    ],
                  ),
                  null => content,
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── R2 placements ─────────────────────────────────────────────────────
  /// A kit key for a top-level action (R2): primary solid, danger, else
  /// secondary unless [variant] says otherwise.
  Widget _key(
    FlarePluginAction action, {
    FlareButtonVariant? variant,
    FlareControlSize size = FlareControlSize.md,
    bool block = false,
  }) => flarePluginDisabledReason(
    action,
    FlareButton(
      key: ValueKey('flare-plugin-action-${action.id}'),
      label: action.label,
      variant: variant ?? _variantOf(action),
      size: size,
      block: block,
      maintainTouchTarget: true,
      loading: widget.busyActionId == action.id,
      disabled: _keysOff || action.disabledReason != null,
      onPressed: () => runAction(action.id),
    ),
  );

  bool get _pc =>
      (MediaQuery.maybeSizeOf(context)?.width ?? 0) >=
      FlareSizes.appShellCompactMinWidth;

  Widget _offlineCaption(FlareStrings strings) => Padding(
    key: const ValueKey('flare-plugin-available-online'),
    padding: const EdgeInsets.only(top: FlareSizes.spacingXs),
    child: Text(
      strings.pluginViewAvailableOnline,
      style: TextStyle(
        fontSize: FlareTextRoles.caption.fontSize,
        color: FlareColors.of(context).textSecondary,
      ),
    ),
  );

  /// Overview quick keys (R2.1): phone equal widths 48 high, PC natural
  /// width ≥ component.actionMinWidth, 40 high.
  Widget _quickRow(List<FlarePluginAction> actions, FlareStrings strings) {
    if (actions.isEmpty) return const SizedBox.shrink();
    final row = _pc
        ? Wrap(
            spacing: FlareSizes.spacingSm,
            runSpacing: FlareSizes.spacingSm,
            children: [
              for (final action in actions)
                // The key itself is ≥ 120 (its touch slop centres a
                // narrower one in the box).
                IntrinsicWidth(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: FlareSizes.componentActionMinWidth,
                    ),
                    child: _key(action, block: true),
                  ),
                ),
            ],
          )
        : Row(
            children: [
              for (final (index, action) in actions.indexed) ...[
                if (index > 0) const SizedBox(width: FlareSizes.spacingSm),
                Expanded(
                  child: _key(action, size: FlareControlSize.lg, block: true),
                ),
              ],
            ],
          );
    return Column(
      key: const ValueKey('flare-plugin-quick'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      // R2.1: 16 above the row, which the card or the view's gap gives.
      children: [row, if (widget.offline) _offlineCaption(strings)],
    );
  }

  /// List rows of the kit settings list (R2.1): the label in primary text
  /// whatever the role, the action's icon when it has one, a chevron only on
  /// a destination; danger rows in the error colour, always confirmed.
  List<Widget> _listRows(
    List<FlarePluginAction> actions, {
    bool danger = false,
  }) {
    final colors = FlareColors.of(context);
    return [
      for (final (index, action) in actions.indexed) ...[
        if (index > 0)
          Divider(
            height: 1,
            indent: FlareSizes.spacingMd,
            color: colors.borderSecondary,
          ),
        KeyedSubtree(
          key: ValueKey('flare-plugin-action-${action.id}'),
          child: FlareSettingsRow(
            item: FlareSettingsItem(
              key: action.id,
              label: action.label,
              icon: action.icon,
              kind:
                  flarePluginActionRole(action) ==
                      FlarePluginActionRole.destination
                  ? FlareSettingKind.navigation
                  : FlareSettingKind.action,
              danger: danger || action.style == FlarePluginActionStyle.danger,
              disabled: _keysOff || action.disabledReason != null,
              detail: action.disabledReason,
              // R2.1: the danger card's rows stand alone, centred.
              centered: danger,
              busy: widget.busyActionId == action.id,
            ),
            onSelect: (_) => _run(
              action,
              const FlarePluginActionPayload(),
              confirmDanger:
                  danger || action.style == FlarePluginActionStyle.danger,
            ),
          ),
        ),
      ],
    ];
  }

  /// The account layout's service list (R2.1): list cards by `group`, the
  /// danger rows in a card of their own, last; 16 between cards.
  List<Widget> _listGroups(
    List<FlarePluginAction> actions,
    FlareStrings strings,
  ) {
    final danger = [
      for (final action in actions)
        if (action.style == FlarePluginActionStyle.danger) action,
    ];
    final cards = [
      for (final group in flarePluginListGroups([
        for (final action in actions)
          if (!danger.contains(action)) action,
      ]))
        _listCard(
          group.actions,
          key: ValueKey('flare-plugin-list-${group.group ?? 'all'}'),
          title: switch (group.group) {
            'common' => strings.pluginViewGroupCommon,
            'records' => strings.pluginViewGroupRecords,
            _ => null,
          },
        ),
      if (danger.isNotEmpty)
        _listCard(
          danger,
          key: const ValueKey('flare-plugin-list-danger'),
          danger: true,
        ),
    ];
    return [
      for (final (index, card) in cards.indexed) ...[
        if (index > 0) const SizedBox(height: FlareSizes.spacingLg),
        card,
      ],
    ];
  }

  /// A titled list card of actions (R2.1–R2.3).
  Widget _listCard(
    List<FlarePluginAction> actions, {
    Key? key,
    String? title,
    bool danger = false,
  }) {
    final colors = FlareColors.of(context);
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: FlareSizes.spacingSm),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: FlareTextRoles.section.fontSize,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: colors.bgPrimary,
            borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
            border: Border.all(color: colors.borderSecondary),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: _listRows(actions, danger: danger),
          ),
        ),
      ],
    );
  }

  /// Everything a page draws after its body (R2): the overview's list
  /// cards, a task's action row, a records page's command keys, the "more
  /// actions" card, the danger card.
  List<Widget> _placed(
    FlarePluginActionPlaces places,
    bool Function(FlarePluginAction) drawn,
    FlareStrings strings, {
    required int quickAt,
    FlarePluginAction? inline,
  }) {
    final out = <Widget>[];
    switch (places.archetype) {
      case FlarePluginPageArchetype.overview:
        if (quickAt == -1) {
          out.add(_quickRow(places.quick.where(drawn).toList(), strings));
        }
        for (final group in places.list) {
          final actions = group.actions.where(drawn).toList();
          if (actions.isEmpty) continue;
          out.add(
            _listCard(
              actions,
              key: ValueKey('flare-plugin-list-${group.group ?? 'all'}'),
              title: switch (group.group) {
                'common' => strings.pluginViewGroupCommon,
                'records' => strings.pluginViewGroupRecords,
                _ => null,
              },
            ),
          );
        }
      case FlarePluginPageArchetype.task:
        // The inline form keeps its own submit (its checks and uploads
        // stay with it); the page pins the rest on a phone.
        // shortcut: a phone's inline-form submit is not pinned; pin it once
        // FlarePluginForm exposes its submit state to the page.
        if (!widget.pinBar || inline != null) {
          final bar = [
            for (final action in places.bar)
              if (drawn(action) && action.id != inline?.id) action,
          ];
          final secondary = places.barSecondary.where(drawn).toList();
          if (bar.isNotEmpty || secondary.isNotEmpty) {
            out.add(
              FlarePluginTaskBar(
                key: const ValueKey('flare-plugin-task-bar'),
                primary: bar.firstOrNull,
                secondary: secondary,
                pinned: false,
                busyActionId: widget.busyActionId,
                disabled: _keysOff,
                offline: widget.offline,
                onRun: (action) => runAction(action.id),
              ),
            );
          }
        }
      case FlarePluginPageArchetype.records:
        final commands = places.commands.where(drawn).toList();
        if (commands.isNotEmpty) {
          out.add(
            Wrap(
              key: const ValueKey('flare-plugin-commands'),
              spacing: FlareSizes.spacingSm,
              runSpacing: FlareSizes.spacingSm,
              children: [
                for (final action in commands)
                  _key(action, variant: FlareButtonVariant.secondary),
              ],
            ),
          );
        }
        if (widget.offline &&
            (commands.isNotEmpty || places.header.isNotEmpty)) {
          out.add(_offlineCaption(strings));
        }
      case FlarePluginPageArchetype.card:
        break;
    }
    final more = places.more.where(drawn).toList();
    if (more.isNotEmpty) {
      out.add(
        _listCard(
          more,
          key: const ValueKey('flare-plugin-list-more'),
          title: strings.pluginViewMore,
        ),
      );
    }
    final danger = places.danger.where(drawn).toList();
    if (danger.isNotEmpty) {
      out.add(
        _listCard(
          danger,
          key: const ValueKey('flare-plugin-list-danger'),
          danger: true,
        ),
      );
    }
    return out;
  }

  /// The reason line: secondary under the title of an unavailable view,
  /// tertiary closing a read-only copy.
  Widget _reasonLine(
    FlareColors colors,
    String text, {
    required bool secondary,
  }) => Text(
    text,
    key: FlarePluginView.reasonKey,
    style: TextStyle(
      fontSize: FlareSizes.fontSizeMd,
      color: secondary ? colors.textSecondary : colors.textTertiary,
    ),
  );

  /// The card's ⋯ menu: one item per menu action, danger tone for a danger
  /// action; the chosen one runs like a button.
  Future<void> _openMenu(
    BuildContext anchor,
    List<FlarePluginAction> actions,
  ) async {
    if (_locked || widget.onAction == null) return;
    final strings = FlareStrings.of(context);
    final box = anchor.findRenderObject();
    final picked = await FlareActionMenu.show(
      anchor,
      label: strings.pluginViewMore,
      anchor: box is RenderBox && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : null,
      items: [
        for (final action in actions)
          FlareActionItem(
            id: action.id,
            label: action.label,
            danger: action.style == FlarePluginActionStyle.danger,
          ),
      ],
    );
    if (picked == null || !mounted) return;
    for (final action in actions) {
      if (action.id == picked) {
        await _run(action, const FlarePluginActionPayload());
        return;
      }
    }
  }

  /// [FlarePluginView.inset] around what the view draws (none adds nothing).
  Widget _inset(Widget child) {
    final inset = widget.inset;
    if (inset == FlarePluginViewInset.none) return child;
    return Padding(
      key: ValueKey('flare-plugin-inset-${inset.name}'),
      padding: flarePluginViewInsetPadding(inset),
      child: child,
    );
  }
}

/// The padding of [FlarePluginView.inset] (spec rules.inset): sheet is the
/// kit sheet's (md / lg / xl, as [FlarePluginForm]); sheetTop drops the
/// bottom one; none is zero.
EdgeInsets flarePluginViewInsetPadding(FlarePluginViewInset inset) =>
    switch (inset) {
      FlarePluginViewInset.none => EdgeInsets.zero,
      FlarePluginViewInset.sheet => const EdgeInsets.fromLTRB(
        FlareSizes.spacingLg,
        FlareSizes.spacingMd,
        FlareSizes.spacingLg,
        FlareSizes.spacingXl,
      ),
      FlarePluginViewInset.sheetTop => const EdgeInsets.fromLTRB(
        FlareSizes.spacingLg,
        FlareSizes.spacingMd,
        FlareSizes.spacingLg,
        0,
      ),
    };

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.title, this.icon, this.menu, this.detail});
  final String title;
  final String? icon;

  /// The ⋯ key of the menu actions, at the end of the row.
  final Widget? menu;
  final Widget? detail;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final glyph = icon;
    return Row(
      children: [
        if (glyph != null && flareIconNames.contains(glyph)) ...[
          FlareIcon(
            glyph,
            key: const ValueKey('flare-plugin-icon'),
            size: FlareSizes.iconSizeSm,
            color: colors.primaryText,
          ),
          const SizedBox(width: FlareSizes.spacingXs),
        ],
        Expanded(
          // R5: the title takes the rest of the row on one line.
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: FlareSizes.fontSizeSm,
              fontWeight: FontWeight.w500,
              height: FlareSizes.lineHeightSnug,
              color: colors.textSecondary,
            ),
          ),
        ),
        if (detail != null) ...[
          const SizedBox(width: FlareSizes.spacingSm),
          detail!,
        ],
        if (menu != null) ...[
          const SizedBox(width: FlareSizes.spacingXs),
          menu!,
        ],
      ],
    );
  }
}

class _FieldsList extends StatelessWidget {
  const _FieldsList({required this.fields});
  final List<FlarePluginField> fields;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    // R3: order and proof ids fold under References with a copy key each.
    final (:main, :references) = flarePluginReferenceSplit(fields);
    Widget row(FlarePluginField field, int index, {bool copy = false}) {
      final text = flarePluginFormatText(field.value, field.format, strings);
      return Padding(
        padding: EdgeInsets.only(top: index == 0 ? 0 : FlareSizes.spacingXs),
        child: Row(
          crossAxisAlignment: copy
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                field.label,
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeMd,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: FlareSizes.spacingMd),
            Expanded(
              flex: 2,
              child: field.tone != null || field.unmapped
                  ? Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _ToneTag(
                        key: ValueKey('flare-plugin-field-tag-${field.label}'),
                        text: text,
                        tone: field.tone ?? FlarePluginTone.neutral,
                        unmapped: field.unmapped,
                      ),
                    )
                  : Text(
                      text,
                      style: TextStyle(
                        fontSize: FlareSizes.fontSizeMd,
                        color: colors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
            ),
            if (copy)
              FlareIconButton(
                key: ValueKey('flare-plugin-copy-${field.label}'),
                icon: 'copy',
                size: FlareControlSize.sm,
                semanticLabel: strings.pluginViewCopyReference.replaceAll(
                  '{label}',
                  field.label,
                ),
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: field.value)),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, field) in main.indexed) row(field, index),
        if (references.isNotEmpty)
          _ReferencesGroup(
            title: strings.pluginViewReferences,
            children: [
              for (final (index, field) in references.indexed)
                row(field, index, copy: true),
            ],
          ),
      ],
    );
  }
}

/// The folded "单号与凭据" group (R3): a kit text key that opens the rows.
class _ReferencesGroup extends StatefulWidget {
  const _ReferencesGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  State<_ReferencesGroup> createState() => _ReferencesGroupState();
}

class _ReferencesGroupState extends State<_ReferencesGroup> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('flare-plugin-references'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      _TextKey(
        key: const ValueKey('flare-plugin-references-toggle'),
        label: widget.title,
        expanded: _open,
        onTap: () => setState(() => _open = !_open),
      ),
      if (_open) ...widget.children,
    ],
  );
}

/// A text-sized key whose touch target reaches the kit's minimum.
class _TextKey extends StatelessWidget {
  const _TextKey({super.key, required this.label, this.onTap, this.expanded});
  final String label;
  final VoidCallback? onTap;
  final bool? expanded;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Semantics(
      button: true,
      expanded: expanded,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: FlareSizes.touchTarget,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeMd,
                  color: colors.primaryText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextBlock extends StatefulWidget {
  const _TextBlock({required this.block});
  final FlarePluginTextBlock block;

  @override
  State<_TextBlock> createState() => _TextBlockState();
}

class _TextBlockState extends State<_TextBlock> {
  bool _expanded = false;

  @override
  void didUpdateWidget(_TextBlock old) {
    super.didUpdateWidget(old);
    if (old.block.text != widget.block.text) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final block = widget.block;
    final style = switch (block.style) {
      FlarePluginTextStyle.title => TextStyle(
        fontSize: FlareSizes.fontSize2xl,
        fontWeight: FontWeight.w600,
        height: FlareSizes.lineHeightSnug,
        color: colors.textPrimary,
      ),
      FlarePluginTextStyle.secondary => TextStyle(
        fontSize: FlareSizes.fontSizeMd,
        color: colors.textSecondary,
      ),
      FlarePluginTextStyle.body => TextStyle(
        fontSize: FlareSizes.fontSizeLg,
        height: FlareSizes.lineHeightNormal,
        color: colors.textPrimary,
      ),
    };
    final maxLines = block.maxLines;
    return LayoutBuilder(
      builder: (context, constraints) {
        var overflows = false;
        if (maxLines != null) {
          final painter =
              TextPainter(
                text: TextSpan(text: block.text, style: style),
                maxLines: maxLines,
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(
                maxWidth: constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : double.infinity,
              );
          overflows = painter.didExceedMaxLines;
          painter.dispose();
        }
        final clamp = maxLines != null && !_expanded;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              block.text,
              key: const ValueKey('flare-plugin-text'),
              style: style,
              maxLines: clamp ? maxLines : null,
              overflow: clamp ? TextOverflow.ellipsis : null,
            ),
            if (overflows)
              _TextKey(
                key: const ValueKey('flare-plugin-text-toggle'),
                label: _expanded ? strings.collapse : strings.expand,
                expanded: _expanded,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
          ],
        );
      },
    );
  }
}

class _ChoicesBlock extends StatelessWidget {
  const _ChoicesBlock({
    required this.block,
    required this.selected,
    required this.interactive,
    this.capped = const {},
    required this.submitEnabled,
    required this.submitLoading,
    required this.onPick,
    required this.onSubmit,
  });
  final FlarePluginChoicesBlock block;
  final List<int> selected;
  final bool interactive;

  /// Options the cap holds back: listed, dimmed and not tappable.
  final Set<int> capped;
  final bool submitEnabled;
  final bool submitLoading;
  final ValueChanged<int> onPick;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final chosen = selected.toSet();
    // The block's total is only the denominator of the shares (a voter count
    // or the sum of the counts): the kit cannot tell people from votes, so it
    // never draws it. How many took part is the plugin's to say.
    final footer = [
      ?flarePluginChoiceCapHint(block, strings),
      if (block.closed) strings.pluginViewEnded,
    ].join(' · ');
    final boxes = block.multiple && interactive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in block.options) ...[
          _ChoiceRow(
            key: ValueKey('flare-plugin-option-${option.index}'),
            option: option,
            showResults: block.showResults,
            selected: chosen.contains(option.index),
            box: boxes,
            capped: interactive && capped.contains(option.index),
            onTap: interactive && !capped.contains(option.index)
                ? () => onPick(option.index)
                : null,
          ),
          const SizedBox(height: FlareSizes.spacingXs),
        ],
        if (interactive && block.multiple && block.action != null)
          Padding(
            padding: const EdgeInsets.only(top: FlareSizes.spacingXs),
            child: FlareButton(
              key: const ValueKey('flare-plugin-choices-submit'),
              label: block.action!.label,
              variant: block.action!.style == FlarePluginActionStyle.danger
                  ? FlareButtonVariant.danger
                  : FlareButtonVariant.primary,
              block: true,
              loading: submitLoading,
              disabled: !submitEnabled || submitLoading,
              onPressed: onSubmit,
            ),
          ),
        if (footer.isNotEmpty)
          Text(
            footer,
            key: const ValueKey('flare-plugin-choices-footer'),
            style: TextStyle(
              fontSize: FlareSizes.fontSizeSm,
              color: colors.textTertiary,
            ),
          ),
      ],
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    super.key,
    required this.option,
    required this.showResults,
    required this.selected,
    required this.box,
    this.capped = false,
    this.onTap,
  });
  final FlarePluginChoice option;
  final bool showResults;
  final bool selected;
  final bool box;

  /// Held back by the cap: drawn at the disabled opacity, read as disabled.
  final bool capped;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final percent = (option.percent ?? 0).clamp(0, 100);
    final votes = strings.pluginViewVotesCount(
      option.count ?? 0,
      flareCopyLocaleOf(context),
    );
    final radius = BorderRadius.circular(FlareSizes.radiusMd);
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgPrimary,
          borderRadius: radius,
          border: Border.all(
            color: selected ? colors.borderSelected : colors.borderSecondary,
          ),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              if (showResults)
                Positioned.fill(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      key: const ValueKey('flare-plugin-option-bar'),
                      widthFactor: percent / 100,
                      heightFactor: 1,
                      child: ColoredBox(
                        color: Color.lerp(
                          colors.bgPrimary,
                          colors.primary,
                          0.14,
                        )!,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FlareSizes.spacing2sm,
                  vertical: FlareSizes.spacingSm,
                ),
                child: Row(
                  children: [
                    if (box) ...[
                      Container(
                        width: FlareSizes.iconSizeSm,
                        height: FlareSizes.iconSizeSm,
                        decoration: BoxDecoration(
                          color: selected ? colors.primary : null,
                          borderRadius: BorderRadius.circular(
                            FlareSizes.radiusXs,
                          ),
                          border: Border.all(
                            color: selected
                                ? colors.primary
                                : colors.borderPrimary,
                            width: 1.5,
                          ),
                        ),
                        child: selected
                            ? FlareIcon(
                                'check',
                                size: FlareSizes.fontSizeSm,
                                color: colors.bgPrimary,
                              )
                            : null,
                      ),
                      const SizedBox(width: FlareSizes.spacingSm),
                    ],
                    Expanded(
                      child: Text(
                        option.label,
                        style: TextStyle(
                          fontSize: FlareSizes.fontSizeMd,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (selected && !box) ...[
                      const SizedBox(width: FlareSizes.spacingXs),
                      FlareIcon(
                        'check',
                        key: const ValueKey('flare-plugin-option-check'),
                        size: FlareSizes.iconSizeSm,
                        color: colors.primaryText,
                      ),
                    ],
                    if (showResults) ...[
                      const SizedBox(width: FlareSizes.spacingSm),
                      Text(
                        '$percent%',
                        key: const ValueKey('flare-plugin-option-percent'),
                        style: TextStyle(
                          fontSize: FlareSizes.fontSizeSm,
                          color: colors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: FlareSizes.spacingXs),
                      Text(
                        votes,
                        key: const ValueKey('flare-plugin-option-votes'),
                        style: TextStyle(
                          fontSize: FlareSizes.fontSizeSm,
                          color: colors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final value = showResults ? '$percent%, $votes' : null;
    return Semantics(
      button: onTap != null && !box,
      checked: box ? selected : null,
      selected: selected,
      enabled: capped ? false : null,
      value: value,
      child: onTap == null
          ? (capped ? Opacity(opacity: FlareOpacity.disabled, child: row) : row)
          : Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap, borderRadius: radius, child: row),
            ),
    );
  }
}

class _EntriesBlock extends StatelessWidget {
  const _EntriesBlock({
    required this.block,
    required this.userOf,
    this.viewerId,
    this.onSeeAll,
  });
  final FlarePluginEntriesBlock block;
  final FlarePluginUser Function(String userId) userOf;
  final String? viewerId;
  final VoidCallback? onSeeAll;

  String? _name(FlarePluginEntry entry) {
    if (entry.name != null && entry.name!.isNotEmpty) return entry.name;
    final id = entry.userId;
    return id == null ? null : userOf(id).name;
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final empty = block.emptyText;
    final viewer = viewerId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < block.items.length; i++) ...[
          if (block.grouped && block.items[i].group != null)
            Padding(
              key: ValueKey('flare-plugin-entry-group-$i'),
              padding: EdgeInsets.only(
                top: i == 0 ? 0 : FlareSizes.spacingSm,
                bottom: FlareSizes.spacingXs,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  flarePluginEntryGroupHeader(
                    block.items[i].group!,
                    strings,
                    locale: flareCopyLocaleOf(context),
                  ),
                  style: TextStyle(
                    fontSize: FlareSizes.fontSizeSm,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          _row(
            context,
            colors,
            strings,
            block.items[i],
            i,
            me:
                viewer != null &&
                viewer.isNotEmpty &&
                block.items[i].userId == viewer,
          ),
        ],
        if (block.items.isEmpty && empty != null)
          Text(
            empty,
            style: TextStyle(
              fontSize: FlareSizes.fontSizeMd,
              color: colors.textTertiary,
            ),
          ),
        if (block.more)
          _TextKey(
            key: const ValueKey('flare-plugin-see-all'),
            label: strings.pluginViewSeeAll.replaceAll(
              '{count}',
              '${block.total}',
            ),
            onTap: onSeeAll,
          ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    FlareColors colors,
    FlareStrings strings,
    FlarePluginEntry entry,
    int position, {
    required bool me,
  }) {
    final name = _name(entry);
    return Padding(
      // A grouped list numbers within each group, so the position keys it.
      key: ValueKey(
        block.grouped
            ? 'flare-plugin-entry-row-$position'
            : 'flare-plugin-entry-${entry.index}',
      ),
      padding: const EdgeInsets.only(bottom: FlareSizes.spacingXs),
      child: Row(
        children: [
          if (block.numbered)
            SizedBox(
              width: FlareSizes.spacing2xl,
              child: Text(
                '${entry.index}.',
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeMd,
                  color: colors.textTertiary,
                ),
              ),
            ),
          if (entry.userId != null) ...[
            FlareAvatar(
              userId: entry.userId!,
              displayName: name ?? '',
              avatarUrl: userOf(entry.userId!).avatarUrl,
              size: FlareSizes.iconSizeLg,
            ),
            const SizedBox(width: FlareSizes.spacingSm),
          ],
          if (name != null) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: FlareSizes.componentRichCardCompactWidth / 2,
              ),
              child: Text(
                name,
                key: ValueKey('flare-plugin-entry-name-$position'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeMd,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: FlareSizes.spacingXs),
          ],
          if (me) ...[
            Container(
              key: ValueKey('flare-plugin-entry-me-$position'),
              padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingXs,
              ),
              decoration: BoxDecoration(
                color: colors.bgSelected,
                borderRadius: BorderRadius.circular(FlareSizes.radiusXs),
              ),
              child: Text(
                strings.pluginViewMe,
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeXs,
                  fontWeight: FontWeight.w500,
                  color: colors.primaryText,
                ),
              ),
            ),
            const SizedBox(width: FlareSizes.spacingXs),
          ],
          if (entry.badge case final badge?) ...[
            _ToneTag(
              key: ValueKey('flare-plugin-entry-badge-$position'),
              text: badge.text,
              tone: badge.tone,
              unmapped: badge.unmapped,
              maxWidth: FlareSizes.componentRichCardCompactWidth / 2,
            ),
            const SizedBox(width: FlareSizes.spacingXs),
          ],
          Expanded(
            child: Text(
              entry.text,
              key: ValueKey('flare-plugin-entry-text-$position'),
              style: TextStyle(
                fontSize: FlareSizes.fontSizeMd,
                color: colors.textPrimary,
              ),
            ),
          ),
          if (entry.timeMs case final timeMs?) ...[
            const SizedBox(width: FlareSizes.spacingXs),
            Text(
              flarePluginDateTime(timeMs, flarePluginNowMs(), strings),
              key: ValueKey('flare-plugin-entry-time-$position'),
              style: TextStyle(
                fontSize: FlareSizes.fontSizeSm,
                color: colors.textTertiary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A rows block on a plugin page (rules.pageRows): a list, one item per key
/// (the first kept) — the badge and the first cell, then the other cells
/// joined with " · ", and the row's action keys at the item's end. No rows:
/// the block's empty text, else pluginViewEmpty.
class _RowsBlock extends StatelessWidget {
  const _RowsBlock({
    required this.block,
    required this.labelRows,
    required this.readOnly,
    required this.locked,
    this.busyActionId,
    this.rowInFlight,
    required this.onAction,
    this.emptyAction,
    this.nameOf,
    this.onClearFilters,
  });
  final FlarePluginRowsBlock block;

  /// §5.8: the list is empty under a chosen filter.
  final VoidCallback? onClearFilters;

  /// A person cell's user as the host's directory names them.
  final String Function(String userId)? nameOf;

  /// The page's create action under an empty list (R8).
  final Widget? emptyAction;
  final bool labelRows;
  final bool readOnly;

  /// Busy, an action in flight, or no host for actions: the keys wait.
  final bool locked;
  final String? busyActionId;

  /// The row whose action ran last: its key spins while that action is in
  /// flight.
  final String? rowInFlight;
  final void Function(
    FlarePluginAction action,
    FlarePluginRow row,
    Object? input,
  )
  onAction;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final rows = flarePluginRowsOnce(block.rows);
    if (rows.isEmpty) {
      final clear = onClearFilters;
      // R8: the compact in-block empty state, with the create action; §5.8:
      // under a filter, say so and offer to clear it.
      return FlareEmptyState(
        key: FlarePluginView.rowsEmptyKey,
        compact: true,
        icon: block.icon ?? 'clock',
        title: clear != null
            ? strings.pluginViewFilterEmpty
            : block.emptyText ?? strings.pluginViewEmpty,
        actions: [
          if (clear != null)
            FlareButton(
              key: FlarePluginView.clearFiltersKey,
              label: strings.pluginViewClearFilter,
              variant: FlareButtonVariant.secondary,
              onPressed: clear,
            )
          else
            ?emptyAction,
        ],
      );
    }
    final nowMs = flarePluginNowMs();
    final days = flarePluginRowDayHeadings(
      FlarePluginRowsBlock(
        columns: block.columns,
        rows: rows,
        groupByDay: block.groupByDay,
      ),
      nowMs,
      strings,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i += 1) ...[
          if (days[i] case final day?)
            Padding(
              key: ValueKey('flare-plugin-row-day-$i'),
              padding: EdgeInsets.only(
                top: i == 0 ? 0 : FlareSizes.spacingMd,
                bottom: FlareSizes.spacingXs,
              ),
              child: KeyedSubtree(
                // §5.8: the page pins the heading it scrolled past.
                key: FlarePluginDayHeadings.maybeOf(context)?.keyFor(day),
                child: Semantics(
                  header: true,
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeSm,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            )
          else if (i > 0)
            Divider(height: 1, thickness: 1, color: colors.borderSecondary),
          _item(
            colors,
            strings,
            rows[i],
            nowMs,
            first: i == 0,
            last: i == rows.length - 1,
          ),
        ],
      ],
    );
  }

  /// [row] with its person cells written as names.
  FlarePluginRow _named(FlarePluginRow row) =>
      row.cells.any((cell) => cell.userId != null)
      ? FlarePluginRow(
          key: row.key,
          actions: row.actions,
          badge: row.badge,
          cells: [
            for (final cell in row.cells)
              if (cell.userId case final id?)
                FlarePluginRowCell(
                  text: (nameOf ?? flarePluginFallbackName)(id),
                  timeMs: cell.timeMs,
                  tone: cell.tone,
                  unmapped: cell.unmapped,
                )
              else
                cell,
          ],
        )
      : row;

  /// The row's action keys at its end.
  List<(FlarePluginAction, Object?)> _keysOf(FlarePluginRow row) => readOnly
      ? const []
      : [
          for (final offered in row.actions)
            for (final action
                in block.actions.where((a) => a.id == offered.id).take(1))
              (action, offered.input),
        ];

  /// rules.rowTap: the row's only key, when the whole row runs it instead.
  (FlarePluginAction, Object?)? _tapOf(
    FlarePluginRow row,
    List<(FlarePluginAction, Object?)> keys,
  ) =>
      row.actions.length == 1 &&
          keys.length == 1 &&
          flarePluginRowTaps(keys.single.$1)
      ? keys.single
      : null;

  /// rules.rowTap: [child] as one control (a button for screen readers) that
  /// runs [tap] and ends with chevron-right 16 — the spinner in its place
  /// while this row's action runs, as its key would; [child] itself without
  /// one.
  Widget _tappable(
    FlareColors colors,
    FlarePluginRow row,
    (FlarePluginAction, Object?)? tap,
    Widget child,
  ) => tap == null
      ? child
      : MergeSemantics(
          child: Semantics(
            button: true,
            enabled: !locked,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: locked ? null : () => onAction(tap.$1, row, tap.$2),
                child: Row(
                  children: [
                    Expanded(child: child),
                    const SizedBox(width: FlareSizes.spacingSm),
                    if (busyActionId == tap.$1.id && rowInFlight == row.key)
                      SizedBox.square(
                        key: ValueKey('flare-plugin-row-spinner:${row.key}'),
                        dimension: FlareSizes.iconSizeSm,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.textTertiary,
                        ),
                      )
                    else
                      FlareIcon(
                        'chevron-right',
                        key: ValueKey('flare-plugin-row-chevron:${row.key}'),
                        size: FlareSizes.iconSizeSm,
                        color: colors.textTertiary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );

  Widget _actionKeys(
    FlarePluginRow row,
    List<(FlarePluginAction, Object?)> keys,
  ) => Wrap(
    spacing: FlareSizes.spacingXs,
    runSpacing: FlareSizes.spacingXs,
    children: [
      for (final (action, input) in keys)
        FlareButton(
          key: FlarePluginView.rowActionKey(row.key, action.id),
          label: action.label,
          size: FlareControlSize.sm,
          variant: _variantOf(action),
          loading: busyActionId == action.id && rowInFlight == row.key,
          disabled: locked,
          onPressed: () => onAction(action, row, input),
        ),
    ],
  );

  /// A record (5.8, rules.rowsIcon): the icon circle, the title with its
  /// badge and the line under it, the value with its Tags at the end.
  Widget _record(
    FlareColors colors,
    FlareStrings strings,
    FlarePluginRow row,
    int nowMs, {
    required bool first,
    required bool last,
  }) {
    final record = flarePluginRecordLine(
      block,
      row,
      nowMs,
      strings,
      nameOf: nameOf,
    );
    final income = record.value.trimLeft().startsWith('+');
    final keys = _keysOf(row);
    final tap = _tapOf(row, keys);
    // §5.8: a record row is at least component.recordRowHeight (64) high.
    return ConstrainedBox(
      key: FlarePluginView.rowKey(row.key),
      constraints: const BoxConstraints(
        minHeight: FlareSizes.componentRecordRowHeight,
      ),
      child: _tappable(
        colors,
        row,
        tap,
        Semantics(
          container: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
            child: Row(
              children: [
                Container(
                  key: ValueKey('flare-plugin-row-icon:${row.key}'),
                  width: FlareSizes.componentRecordIconSize,
                  height: FlareSizes.componentRecordIconSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: income
                        ? colors.success.withValues(
                            alpha: FlareOpacity.tintWeak,
                          )
                        : colors.bgTertiary,
                  ),
                  child: FlareIcon(
                    block.icon!,
                    size: FlareSizes.iconSizeMd,
                    color: income ? colors.successText : colors.textSecondary,
                  ),
                ),
                const SizedBox(width: FlareSizes.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              record.title,
                              key: ValueKey(
                                'flare-plugin-row-title:${row.key}',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: FlareSizes.fontSizeXl,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          if (row.badge case final badge?) ...[
                            const SizedBox(width: FlareSizes.spacingXs),
                            _ToneTag(
                              key: ValueKey(
                                'flare-plugin-row-badge:${row.key}',
                              ),
                              text: badge.text,
                              tone: badge.tone,
                              unmapped: badge.unmapped,
                              maxWidth:
                                  FlareSizes.componentRichCardCompactWidth / 2,
                            ),
                          ],
                        ],
                      ),
                      if (record.line case final line?) ...[
                        const SizedBox(height: FlareSizes.spacing2xs),
                        Text(
                          line,
                          key: ValueKey('flare-plugin-row-line:${row.key}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: FlareSizes.fontSizeSm,
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: FlareSizes.spacingSm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // R10: a true minus at display time only.
                      record.value.replaceFirst(RegExp('^-'), '\u2212'),
                      key: ValueKey('flare-plugin-row-value:${row.key}'),
                      style: TextStyle(
                        fontSize: FlareSizes.fontSize2xl,
                        fontWeight: FontWeight.w600,
                        color: income ? colors.successText : colors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    for (final (index, cell) in record.tags.indexed)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: FlareSizes.spacing2xs,
                        ),
                        child: _ToneTag(
                          key: ValueKey(
                            'flare-plugin-row-status:${row.key}:$index',
                          ),
                          text: cell.text,
                          tone: cell.tone ?? FlarePluginTone.neutral,
                          unmapped: cell.unmapped,
                        ),
                      ),
                  ],
                ),
                if (tap == null && keys.isNotEmpty) ...[
                  const SizedBox(width: FlareSizes.spacingSm),
                  _actionKeys(row, keys),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(
    FlareColors colors,
    FlareStrings strings,
    FlarePluginRow original,
    int nowMs, {
    required bool first,
    required bool last,
  }) {
    if (block.icon != null && !labelRows) {
      return _record(
        colors,
        strings,
        original,
        nowMs,
        first: first,
        last: last,
      );
    }
    final row = _named(original);
    // R3: a status cell is a tag under the amount, not words in the line;
    // a completed (success) one says nothing (§5.8).
    final statusCells = [
      for (final cell in row.cells)
        if (cell.tone != null || cell.unmapped) cell,
    ];
    final tags = [
      for (final cell in statusCells)
        if (cell.unmapped || cell.tone != FlarePluginTone.success) cell,
    ];
    final lines = flarePluginRowLines(
      block,
      statusCells.isEmpty
          ? row
          : FlarePluginRow(
              key: row.key,
              cells: [
                for (final cell in row.cells)
                  statusCells.contains(cell)
                      ? const FlarePluginRowCell(text: '')
                      : cell,
              ],
            ),
      nowMs,
      strings,
    );
    final keys = _keysOf(row);
    final tap = labelRows ? null : _tapOf(row, keys);
    final badge = row.badge;
    final secondary = lines.secondary;
    // R10: a signed first line reads as an amount — income in success ink
    // with "+", spending with a true minus (U+2212, display only). Records
    // (the icon circle) are only a block that declares `icon` (§12.24).
    final sign = RegExp(r'^\s*([+\-\u2212])').firstMatch(lines.primary)?[1];
    final income = sign == '+';
    final amount = sign == null
        ? lines.primary
        : lines.primary.replaceFirst('-', '\u2212');
    final heading = Row(
      children: [
        if (badge != null) ...[
          _ToneTag(
            key: ValueKey('flare-plugin-row-badge:${row.key}'),
            text: badge.text,
            tone: badge.tone,
            unmapped: badge.unmapped,
            maxWidth: FlareSizes.componentRichCardCompactWidth / 2,
          ),
          const SizedBox(width: FlareSizes.spacingXs),
        ],
        Flexible(
          child: Text(
            amount,
            key: ValueKey('flare-plugin-row-primary:${row.key}'),
            style: TextStyle(
              fontSize: sign == null
                  ? FlareSizes.fontSizeMd
                  : FlareSizes.fontSize2xl,
              fontWeight: sign == null ? null : FontWeight.w600,
              color: income ? colors.successText : colors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelRows &&
            (block.columns.firstOrNull?.label.isNotEmpty ?? false)) ...[
          Text(
            block.columns.first.label,
            key: ValueKey('flare-plugin-row-caption:${row.key}'),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: FlareSizes.fontSizeSm,
            ),
          ),
          const SizedBox(height: FlareSizes.spacing2xs),
        ],
        heading,
        if (labelRows)
          Padding(
            padding: const EdgeInsets.only(top: FlareSizes.spacingSm),
            child: _FieldsList(
              fields: [
                for (final (index, column) in block.columns.indexed.skip(1))
                  if (row.cells.elementAtOrNull(index) case final cell?
                      when cell.text.isNotEmpty || cell.timeMs != null)
                    FlarePluginField(
                      label: column.label,
                      value:
                          column.format == FlarePluginColumnFormat.time &&
                              cell.timeMs != null
                          ? flarePluginDateTime(cell.timeMs!, nowMs, strings)
                          : cell.text,
                      format: cell.format,
                    ),
              ],
            ),
          )
        else if (secondary != null)
          Padding(
            padding: const EdgeInsets.only(top: FlareSizes.spacing2xs),
            child: Text(
              secondary,
              key: ValueKey('flare-plugin-row-secondary:${row.key}'),
              style: TextStyle(
                fontSize: FlareSizes.fontSizeSm,
                color: colors.textSecondary,
              ),
            ),
          ),
      ],
    );
    final actionKeys = _actionKeys(row, keys);
    return Padding(
      key: FlarePluginView.rowKey(row.key),
      padding: EdgeInsets.only(
        top: first ? 0 : FlareSizes.spacingSm,
        bottom: last ? 0 : FlareSizes.spacingSm,
      ),
      child: _tappable(
        colors,
        row,
        tap,
        Semantics(
          container: true,
          child: labelRows
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    content,
                    if (keys.isNotEmpty) ...[
                      const SizedBox(height: FlareSizes.spacingSm),
                      actionKeys,
                    ],
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: content),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(width: FlareSizes.spacingSm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final (index, cell) in tags.indexed)
                            _ToneTag(
                              key: ValueKey(
                                'flare-plugin-row-status:${row.key}:$index',
                              ),
                              text: cell.text,
                              tone: cell.tone ?? FlarePluginTone.neutral,
                              unmapped: cell.unmapped,
                            ),
                        ],
                      ),
                    ],
                    if (tap == null && keys.isNotEmpty) ...[
                      const SizedBox(width: FlareSizes.spacingSm),
                      actionKeys,
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

FlareButtonVariant _variantOf(FlarePluginAction action) =>
    switch (action.style) {
      FlarePluginActionStyle.danger => FlareButtonVariant.danger,
      FlarePluginActionStyle.primary => FlareButtonVariant.primary,
      null => FlareButtonVariant.secondary,
    };

Color _toneInk(FlareColors colors, FlarePluginTone? tone) =>
    switch (tone ?? FlarePluginTone.neutral) {
      FlarePluginTone.neutral => colors.textSecondary,
      FlarePluginTone.info => colors.infoText,
      FlarePluginTone.success => colors.successText,
      FlarePluginTone.warning => colors.warningText,
      FlarePluginTone.danger => colors.errorText,
    };

Color _toneSurface(FlareColors colors, FlarePluginTone? tone) => switch (tone ??
    FlarePluginTone.neutral) {
  FlarePluginTone.neutral => colors.bgTertiary,
  FlarePluginTone.info => Color.lerp(colors.bgPrimary, colors.info, 0.06)!,
  FlarePluginTone.success => Color.lerp(
    colors.bgPrimary,
    colors.success,
    0.06,
  )!,
  FlarePluginTone.warning => Color.lerp(
    colors.bgPrimary,
    colors.warning,
    0.06,
  )!,
  FlarePluginTone.danger => Color.lerp(colors.bgPrimary, colors.error, 0.06)!,
};

class _PeopleBlock extends StatelessWidget {
  const _PeopleBlock({required this.block, required this.userOf});
  final FlarePluginPeopleBlock block;
  final FlarePluginUser Function(String userId) userOf;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var g = 0; g < block.groups.length; g += 1)
          Padding(
            key: ValueKey('flare-plugin-people-$g'),
            padding: EdgeInsets.only(top: g == 0 ? 0 : FlareSizes.spacingXs),
            child: Row(
              children: [
                for (var i = 0; i < block.groups[g].userIds.length; i += 1)
                  Align(
                    widthFactor: i == block.groups[g].userIds.length - 1
                        ? 1
                        : 0.67,
                    alignment: AlignmentDirectional.centerStart,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.bgPrimary, width: 2),
                      ),
                      child: FlareAvatar(
                        key: ValueKey(
                          'flare-plugin-person-${block.groups[g].userIds[i]}',
                        ),
                        userId: block.groups[g].userIds[i],
                        displayName: userOf(block.groups[g].userIds[i]).name,
                        avatarUrl: userOf(block.groups[g].userIds[i]).avatarUrl,
                        size: FlareSizes.iconSizeLg,
                      ),
                    ),
                  ),
                if (block.groups[g].userIds.isNotEmpty)
                  const SizedBox(width: FlareSizes.spacingSm),
                Flexible(
                  child: Text(
                    block.groups[g].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeMd,
                      color: _toneInk(colors, block.groups[g].tone),
                    ),
                  ),
                ),
                const SizedBox(width: FlareSizes.spacingSm),
                Text(
                  '${block.groups[g].count}',
                  style: TextStyle(
                    fontSize: FlareSizes.fontSizeMd,
                    fontWeight: FontWeight.w600,
                    color: _toneInk(colors, block.groups[g].tone),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({required this.block});
  final FlarePluginStatusBlock block;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final label = block.label;
    final labelStyle = TextStyle(
      fontSize: FlareSizes.fontSizeMd,
      color: colors.textSecondary,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasBoundedWidth) {
          final padding =
              FlareSizes.spacing2xs * 2 +
              (label == null ? 0 : FlareSizes.spacingSm);
          final text =
              TextPainter(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    if (label != null) TextSpan(text: label, style: labelStyle),
                    TextSpan(
                      text: block.text,
                      style: const TextStyle(
                        fontSize: FlareSizes.fontSizeSm,
                        fontWeight: FontWeight.w500,
                        height: FlareSizes.lineHeightNormal,
                      ),
                    ),
                  ],
                ),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                maxLines: 1,
              )..layout(
                maxWidth: (constraints.maxWidth - padding)
                    .clamp(0.0, double.infinity)
                    .toDouble(),
              );
          final wraps = text.didExceedMaxLines;
          text.dispose();
          if (wraps) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (label != null) ...[
                  Text(label, style: labelStyle),
                  const SizedBox(height: FlareSizes.spacingSm),
                ],
                FlareStatusBanner(
                  key: const ValueKey('flare-plugin-status'),
                  text: flarePluginStatusText(
                    block.text,
                    unmapped: block.unmapped,
                    strings: FlareStrings.of(context),
                    where: label ?? 'status',
                  ),
                  tone: block.unmapped
                      ? FlareStatusTone.neutral
                      : FlareStatusTone.values.byName(block.tone.name),
                  dot: false,
                ),
              ],
            );
          }
        }
        return Row(
          children: [
            if (label != null) ...[
              Text(label, style: labelStyle),
              const SizedBox(width: FlareSizes.spacingSm),
            ],
            _ToneTag(
              key: const ValueKey('flare-plugin-status'),
              text: block.text,
              tone: block.tone,
              unmapped: block.unmapped,
            ),
          ],
        );
      },
    );
  }
}

/// The kit tag in a plugin tone — a status block's badge and an entry's or a
/// row's badge (rules.badge): the tone's ink on a 6% tint of the tone in the
/// primary surface (neutral: secondary text on the tertiary background) with
/// a hairline of the ink, caption size, one line, never a control.
class _ToneTag extends StatelessWidget {
  const _ToneTag({
    super.key,
    required this.text,
    required this.tone,
    this.maxWidth,
    this.unmapped = false,
  });
  final String text;
  final FlarePluginTone tone;

  /// Cut with an ellipsis past this width (a badge beside other words).
  final double? maxWidth;

  /// Outside the declared values: pluginView.unknownStatus, neutral, never
  /// the raw value (rules.statusValues).
  final bool unmapped;

  @override
  Widget build(BuildContext context) {
    final tag = FlareTag(
      label: flarePluginStatusText(
        text,
        unmapped: unmapped,
        strings: FlareStrings.of(context),
      ),
      tone: unmapped
          ? FlareStatusTone.neutral
          : FlareStatusTone.values.byName(tone.name),
    );
    final max = maxWidth;
    return max == null
        ? tag
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: max),
            child: tag,
          );
  }
}

/// Where a plugin page keeps its records' day headings (§5.8): a rows block
/// keys each heading here so the page can pin the one scrolled past.
class FlarePluginDayHeadings extends InheritedWidget {
  const FlarePluginDayHeadings({
    super.key,
    required this.keys,
    required super.child,
  });

  /// The headings drawn, by their words; the page owns the map so the keys
  /// stay across builds.
  final Map<String, GlobalKey> keys;

  /// A stable key for the heading [day].
  GlobalKey keyFor(String day) =>
      keys[day] ??= GlobalKey(debugLabel: 'flare-plugin-day:$day');

  static FlarePluginDayHeadings? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<FlarePluginDayHeadings>();

  @override
  bool updateShouldNotify(FlarePluginDayHeadings old) => false;
}

/// [key] with [action]'s disabled reason under it (R2.5), caption size.
Widget flarePluginDisabledReason(FlarePluginAction action, Widget key) {
  final reason = action.disabledReason;
  if (reason == null || reason.isEmpty) return key;
  return Builder(
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        key,
        Padding(
          padding: const EdgeInsets.only(top: FlareSizes.spacing2xs),
          child: Text(
            reason,
            key: ValueKey('flare-plugin-disabled-reason-${action.id}'),
            style: TextStyle(
              fontSize: FlareTextRoles.caption.fontSize,
              color: FlareColors.of(context).textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

/// A task page's action row (R2.2): the primary and up to two secondary
/// keys. [pinned] is the phone's bottom bar — primary-surface ground, a
/// hairline on top, the safe area under it, quiet keys above a full-width 48
/// primary; otherwise the PC row after the body — the primary (≥
/// component.actionMinWidth, 40 high) then secondary keys. Offline adds
/// pluginView.availableOnline under the primary.
class FlarePluginTaskBar extends StatelessWidget {
  const FlarePluginTaskBar({
    super.key,
    this.primary,
    this.secondary = const [],
    required this.pinned,
    this.busyActionId,
    this.disabled = false,
    this.offline = false,
    required this.onRun,
  });
  final FlarePluginAction? primary;
  final List<FlarePluginAction> secondary;
  final bool pinned;
  final String? busyActionId;
  final bool disabled;
  final bool offline;
  final ValueChanged<FlarePluginAction> onRun;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final pc =
        !pinned &&
        (MediaQuery.maybeSizeOf(context)?.width ?? 0) >=
            FlareSizes.appShellCompactMinWidth;
    Widget key(
      FlarePluginAction action, {
      required FlareButtonVariant variant,
      FlareControlSize size = FlareControlSize.md,
      FlareButtonAppearance appearance = FlareButtonAppearance.standard,
      bool block = false,
    }) => flarePluginDisabledReason(
      action,
      FlareButton(
        key: ValueKey('flare-plugin-action-${action.id}'),
        label: action.label,
        variant: variant,
        size: size,
        appearance: appearance,
        block: block,
        maintainTouchTarget: true,
        loading: busyActionId == action.id,
        disabled: disabled || offline || action.disabledReason != null,
        onPressed: () => onRun(action),
      ),
    );
    final caption = offline && primary != null
        ? Padding(
            padding: const EdgeInsets.only(top: FlareSizes.spacingXs),
            child: Text(
              strings.pluginViewAvailableOnline,
              key: const ValueKey('flare-plugin-available-online'),
              textAlign: pc ? TextAlign.start : TextAlign.center,
              style: TextStyle(
                fontSize: FlareTextRoles.caption.fontSize,
                color: colors.textSecondary,
              ),
            ),
          )
        : null;
    if (pc) {
      return Padding(
        padding: const EdgeInsets.only(top: FlareSizes.spacingSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: FlareSizes.spacingSm,
              runSpacing: FlareSizes.spacingSm,
              children: [
                if (primary case final action?)
                  IntrinsicWidth(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: FlareSizes.componentActionMinWidth,
                      ),
                      child: key(
                        action,
                        variant: _variantOf(action),
                        block: true,
                      ),
                    ),
                  ),
                for (final action in secondary)
                  key(action, variant: FlareButtonVariant.secondary),
              ],
            ),
            ?caption,
          ],
        ),
      );
    }
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (secondary.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final action in secondary)
                Flexible(
                  child: key(
                    action,
                    variant: FlareButtonVariant.quiet,
                    appearance: FlareButtonAppearance.text,
                  ),
                ),
            ],
          ),
        if (primary case final action?)
          key(
            action,
            variant: _variantOf(action),
            size: FlareControlSize.lg,
            block: true,
          ),
        ?caption,
      ],
    );
    if (!pinned) return body;
    return FlarePluginPinnedBar(child: body);
  }
}

/// A phone page's bottom bar (R2.2, R6, R7): primary-surface ground, a
/// hairline on top, md / lg insets and the safe area under it.
class FlarePluginPinnedBar extends StatelessWidget {
  const FlarePluginPinnedBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        border: Border(top: BorderSide(color: colors.borderSecondary)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FlareSizes.spacingLg,
            vertical: FlareSizes.spacingMd,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The status card of a verification page (§6.1): the tone icon 48, the
/// status field's words as the title (20/700), the description, the steps
/// across and the page's primary key.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    this.field,
    this.description,
    this.steps,
    this.primary,
    this.caption,
  });
  final FlarePluginField? field;
  final String? description;
  final FlarePluginStepsBlock? steps;
  final Widget? primary;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final field = this.field;
    final tone = field == null || field.unmapped
        ? FlarePluginTone.neutral
        : field.tone ?? FlarePluginTone.neutral;
    return Container(
      key: const ValueKey('flare-plugin-status-card'),
      padding: const EdgeInsets.all(FlareSizes.spacingLg),
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
        border: Border.all(color: colors.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              FlarePluginToneIcon(tone: tone, size: 48),
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (field != null)
                      Semantics(
                        header: true,
                        child: Text(
                          flarePluginStatusText(
                            flarePluginFormatText(
                              field.value,
                              field.format,
                              strings,
                            ),
                            unmapped: field.unmapped,
                            strings: strings,
                            where: field.label,
                          ),
                          style: TextStyle(
                            fontSize: FlareTextRoles.title.fontSize,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    if (description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: FlareSizes.spacingXs),
                      Text(
                        description!,
                        style: TextStyle(
                          fontSize: FlareSizes.fontSizeLg,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (steps case final steps?) ...[
            const SizedBox(height: FlareSizes.spacingLg),
            FlarePluginStepsView(block: steps),
          ],
          if (primary case final primary?) ...[
            const SizedBox(height: FlareSizes.spacingLg),
            primary,
          ],
          if (caption case final caption?)
            Padding(
              padding: const EdgeInsets.only(top: FlareSizes.spacingXs),
              child: Text(
                caption,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: FlareTextRoles.caption.fontSize,
                  color: colors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({required this.block});
  final FlarePluginProgressBlock block;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final label = block.label;
    final text = '${block.value}/${block.total}';
    return Semantics(
      label: label,
      value: text,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (label != null)
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeMd,
                      color: colors.textSecondary,
                    ),
                  ),
                )
              else
                const Spacer(),
              Text(
                text,
                key: const ValueKey('flare-plugin-progress-text'),
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeMd,
                  color: colors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: FlareSizes.spacingXs),
          ClipRRect(
            borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
            child: SizedBox(
              height: FlareSizes.spacing2xs,
              child: ColoredBox(
                color: colors.bgTertiary,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    key: const ValueKey('flare-plugin-progress-fill'),
                    widthFactor: block.percent.clamp(0, 100) / 100,
                    heightFactor: 1,
                    child: ColoredBox(color: colors.primary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBlock extends StatelessWidget {
  const _NoteBlock({required this.block, this.plain = false});
  final FlarePluginNoteBlock block;

  /// A section's info note (R1): a caption in secondary text, no tint.
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    if (plain) {
      return Text(
        block.text,
        key: const ValueKey('flare-plugin-note'),
        style: TextStyle(
          fontSize: FlareTextRoles.caption.fontSize,
          color: colors.textSecondary,
        ),
      );
    }
    return DecoratedBox(
      key: const ValueKey('flare-plugin-note'),
      decoration: BoxDecoration(
        color: _toneSurface(colors, block.tone),
        borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingSm,
          vertical: FlareSizes.spacingXs,
        ),
        child: Text(
          block.text,
          style: TextStyle(
            fontSize: FlareSizes.fontSizeMd,
            color: _toneInk(colors, block.tone),
          ),
        ),
      ),
    );
  }
}

/// A plugin time block: an instant or a range in the device's zone, counting
/// down to [FlarePluginTimeBlock.atMs] when asked — every second in the last
/// hour, every minute before, and "closed" once passed.
class _TimeBlock extends StatefulWidget {
  const _TimeBlock({required this.block});
  final FlarePluginTimeBlock block;

  @override
  State<_TimeBlock> createState() => _TimeBlockState();
}

class _TimeBlockState extends State<_TimeBlock> {
  Timer? _timer;

  @override
  void didUpdateWidget(_TimeBlock old) {
    super.didUpdateWidget(old);
    if (old.block.atMs != widget.block.atMs ||
        old.block.countdown != widget.block.countdown)
      _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule(int? refreshMs) {
    _timer?.cancel();
    if (refreshMs == null) return;
    _timer = Timer(Duration(milliseconds: refreshMs), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final block = widget.block;
    final now = flarePluginNowMs();
    final countdown = block.countdown
        ? flarePluginCountdown(block.atMs, now, strings)
        : null;
    _schedule(countdown?.refreshMs);
    final label = block.label;
    return Wrap(
      spacing: FlareSizes.spacingSm,
      runSpacing: FlareSizes.spacing3xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (label != null)
          Text(
            label,
            style: TextStyle(
              fontSize: FlareSizes.fontSizeMd,
              color: colors.textSecondary,
            ),
          ),
        Text(
          flarePluginTimeText(block.atMs, block.endMs, now, strings),
          key: const ValueKey('flare-plugin-time'),
          style: TextStyle(
            fontSize: FlareSizes.fontSizeMd,
            color: colors.textPrimary,
          ),
        ),
        if (countdown != null)
          Text(
            countdown.text,
            key: const ValueKey('flare-plugin-countdown'),
            style: TextStyle(
              fontSize: FlareSizes.fontSizeMd,
              color: countdown.refreshMs == null
                  ? colors.textTertiary
                  : colors.warningText,
            ),
          ),
      ],
    );
  }
}
