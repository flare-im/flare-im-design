import 'dart:async';

import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../models/plugin_view.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_action_menu.dart';
import 'flare_avatar.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_icon.dart';
import 'flare_icon_button.dart';
import 'flare_message_card_shell.dart';
import 'flare_plugin_form.dart';
import 'flare_scene_panels.dart';
import 'flare_status_banner.dart';

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
class FlarePluginView extends StatefulWidget {
  const FlarePluginView({
    super.key,
    required this.view,
    this.icon,
    this.displayName,
    this.viewerId,
    this.busy = false,
    this.busyActionId,
    this.error,
    this.embedded = false,
    this.inset = FlarePluginViewInset.none,
    this.resolveUser,
    this.members = const [],
    this.formErrors = const [],
    this.settleToken = 0,
    this.onAction,
    this.onOpenDetail,
  });

  final FlarePluginViewModel view;

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

  /// The host's validation errors for the open action form.
  final List<FlarePluginFormError> formErrors;

  /// The host's settle signal: incremented once per finished action, after
  /// that result's [error] / [formErrors] are set. Every change settles the
  /// optimistic choice and a submitted form (spec rules.settle).
  final int settleToken;
  final FlarePluginActionCallback? onAction;

  /// "See all" of an entries block, and the card's view details key: shown
  /// under the action keys when the view has a detail no entries block offers
  /// (spec rules.detailKey). Without it the card offers no view details key.
  final VoidCallback? onOpenDetail;

  /// The view details key (a test hook).
  static const Key detailKey = ValueKey('flare-plugin-detail-key');

  /// The ⋯ key of the card's menu actions (a test hook).
  static const Key menuKey = ValueKey('flare-plugin-menu-key');

  /// The reason line of an unavailable view or a read-only copy.
  static const Key reasonKey = ValueKey('flare-plugin-reason');

  @override
  State<FlarePluginView> createState() => _FlarePluginViewState();
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

class _FlarePluginViewState extends State<FlarePluginView> {
  final Map<String, FlarePluginUser?> _users = {};
  final Map<int, List<int>> _drafts = {};
  _Pending? _pending;

  FlarePluginAction? _formAction;
  // What the action carried when its form opened (a choices selection and its
  // optimistic mark): the form adds its values to it.
  FlarePluginActionPayload _formCarry = const FlarePluginActionPayload();
  VoidCallback? _formBefore;
  bool _formSubmitted = false;
  BuildContext? _sheetContext;
  final ValueNotifier<_FormState> _form = ValueNotifier(const _FormState());
  final ValueNotifier<bool> _formBusy = ValueNotifier(false);

  bool get _locked => widget.busy || widget.busyActionId != null;

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
    for (final block in widget.view.blocks) {
      if (block is FlarePluginPeopleBlock) {
        for (final group in block.groups) {
          yield* group.userIds;
        }
      } else if (block is FlarePluginEntriesBlock) {
        for (final entry in block.items) {
          if (entry.userId != null && entry.name == null) yield entry.userId!;
        }
      }
    }
  }

  FlarePluginUser _userOf(String userId) =>
      _users[userId] ?? FlarePluginUser(name: flarePluginFallbackName(userId));

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

  bool _submitEnabled(FlarePluginChoicesBlock block, int index) {
    final draft = _drafts[index] ?? _viewSelection(block);
    return draft.isNotEmpty && !_sameSet(draft, _viewSelection(block));
  }

  void _pick(FlarePluginChoicesBlock block, int index, int option) {
    if (!_interactive(block, index)) return;
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
  }) async {
    if (_locked || widget.onAction == null) return;
    final confirm = action.confirm;
    if (confirm != null && confirm.isNotEmpty) {
      final ok = await FlareDangerConfirm.show(
        context,
        title: action.label,
        description: confirm,
        confirmText: action.label,
      );
      if (!ok || !mounted) return;
    }
    if (action.form.isNotEmpty) {
      _openForm(action, payload, before);
      return;
    }
    before?.call();
    widget.onAction?.call(action.id, payload);
  }

  List<FlarePluginInput> _formInputs(FlarePluginAction action) => [
    for (final id in action.form)
      ...widget.view.inputs.where((input) => input.id == id).take(1),
  ];

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
    _formAction = action;
    _formCarry = carry;
    _formBefore = before;
    _formSubmitted = false;
    _syncForm();
    final inputs = _formInputs(action);
    FlareBottomSheet.show<void>(
      context,
      title: action.label,
      busy: _formBusy,
      builder: (sheetContext) {
        _sheetContext = sheetContext;
        return ValueListenableBuilder<_FormState>(
          valueListenable: _form,
          builder: (context, state, _) => FlarePluginForm(
            inputs: inputs,
            errors: state.errors,
            busy: state.busy,
            error: state.error,
            members: widget.members,
            onSubmit: (values) {
              _formSubmitted = true;
              _syncForm();
              // Every platform sends the carried selection with the values.
              _formBefore?.call();
              widget.onAction?.call(
                action.id,
                FlarePluginActionPayload(
                  selection: _formCarry.selection,
                  formValues: values,
                ),
              );
            },
            onCancel: () => Navigator.of(sheetContext).maybePop(),
          ),
        );
      },
    ).whenComplete(() {
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (sheet.mounted) Navigator.of(sheet).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final view = widget.view;
    final children = <Widget>[];
    final strings = FlareStrings.of(context);
    final reason = flarePluginReasonLine(
      view,
      strings,
      displayName: widget.displayName,
    );
    // A read-only copy runs nothing, even if a copy still carried actions.
    final readOnly = flarePluginReadOnly(view);
    final menuActions = view.available && !readOnly
        ? view.menuActions
        : const <FlarePluginAction>[];
    if (!widget.embedded) {
      children.add(
        _TitleRow(
          title: view.title,
          icon: widget.icon,
          menu: menuActions.isEmpty
              ? null
              : Builder(
                  builder: (context) => FlareIconButton(
                    key: FlarePluginView.menuKey,
                    icon: 'more',
                    semanticLabel: strings.pluginViewMore,
                    size: FlareControlSize.sm,
                    disabled: _locked || widget.onAction == null,
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
    if (!view.available && reason != null) {
      children.add(_reasonLine(colors, reason, secondary: true));
    }
    if (view.available) {
      if (view.fields.isNotEmpty)
        children.add(_FieldsList(fields: view.fields));
      for (var i = 0; i < view.blocks.length; i += 1) {
        final block = view.blocks[i];
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
              FlarePluginNoteBlock() => _NoteBlock(block: block),
            },
          ),
        );
      }
      // Embedded (no title row): the menu actions are keys after the actions.
      final keys = [
        if (!readOnly) ...view.actions,
        if (widget.embedded) ...menuActions,
      ];
      if (keys.isNotEmpty) {
        children.add(
          Wrap(
            spacing: FlareSizes.spacingSm,
            runSpacing: FlareSizes.spacingSm,
            children: [
              for (final action in keys)
                FlareButton(
                  key: ValueKey('flare-plugin-action-${action.id}'),
                  label: action.label,
                  variant: switch (action.style) {
                    FlarePluginActionStyle.danger => FlareButtonVariant.danger,
                    FlarePluginActionStyle.primary =>
                      FlareButtonVariant.primary,
                    null => FlareButtonVariant.secondary,
                  },
                  loading: widget.busyActionId == action.id,
                  disabled: _locked || widget.onAction == null,
                  onPressed: () =>
                      _run(action, const FlarePluginActionPayload()),
                ),
            ],
          ),
        );
      }
      final openDetail = widget.onOpenDetail;
      if (openDetail != null &&
          !readOnly &&
          flarePluginShowsDetailKey(view, embedded: widget.embedded)) {
        children.add(
          FlareButton(
            key: FlarePluginView.detailKey,
            label: FlareStrings.of(context).pluginViewDetail,
            variant: FlareButtonVariant.quiet,
            size: FlareControlSize.sm,
            block: true,
            disabled: _locked,
            onPressed: openDetail,
          ),
        );
      }
      if (reason != null) {
        children.add(_reasonLine(colors, reason, secondary: false));
      }
    }
    final error = widget.error;
    if (error != null && error.isNotEmpty) {
      children.add(
        FlareStatusBanner(text: error, tone: FlareStatusTone.danger),
      );
    }
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i += 1) ...[
          if (i > 0) const SizedBox(height: FlareSizes.spacingMd),
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
              border: Border.all(color: colors.borderSecondary),
              boxShadow: FlareShadows.of(Theme.of(context).brightness).card,
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

  /// The reason line: secondary under the title of an unavailable view,
  /// tertiary closing a read-only copy.
  Widget _reasonLine(FlareColors colors, String text, {required bool secondary}) =>
      Text(
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
  const _TitleRow({required this.title, this.icon, this.menu});
  final String title;
  final String? icon;

  /// The ⋯ key of the menu actions, at the end of the row.
  final Widget? menu;

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
          child: Text(
            title,
            style: TextStyle(
              fontSize: FlareSizes.fontSizeXl,
              fontWeight: FontWeight.w600,
              height: FlareSizes.lineHeightSnug,
              color: colors.textPrimary,
            ),
          ),
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < fields.length; i += 1)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : FlareSizes.spacingXs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    fields[i].label,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeMd,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: FlareSizes.spacingMd),
                Expanded(
                  flex: 2,
                  child: Text(
                    fields[i].value,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeMd,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
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
    required this.submitEnabled,
    required this.submitLoading,
    required this.onPick,
    required this.onSubmit,
  });
  final FlarePluginChoicesBlock block;
  final List<int> selected;
  final bool interactive;
  final bool submitEnabled;
  final bool submitLoading;
  final ValueChanged<int> onPick;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final chosen = selected.toSet();
    final footer = [
      if (block.closed) strings.pluginViewEnded,
      if (block.showResults && block.total != null)
        strings.pluginViewVotes.replaceAll('{count}', '${block.total}'),
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
            onTap: interactive ? () => onPick(option.index) : null,
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
    this.onTap,
  });
  final FlarePluginChoice option;
  final bool showResults;
  final bool selected;
  final bool box;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final percent = (option.percent ?? 0).clamp(0, 100);
    final votes = strings.pluginViewVotes.replaceAll(
      '{count}',
      '${option.count ?? 0}',
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
      value: value,
      child: onTap == null
          ? row
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
                  flarePluginEntryGroupHeader(block.items[i].group!, strings),
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
          Expanded(
            child: Text(
              entry.text,
              style: TextStyle(
                fontSize: FlareSizes.fontSizeMd,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return Row(
      children: [
        if (label != null) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: FlareSizes.fontSizeMd,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: FlareSizes.spacingSm),
        ],
        DecoratedBox(
          key: const ValueKey('flare-plugin-status'),
          decoration: BoxDecoration(
            color: _toneSurface(colors, block.tone),
            borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
            border: Border.all(
              color: _toneInk(colors, block.tone).withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacing2xs,
            ),
            child: Text(
              block.text,
              style: TextStyle(
                fontSize: FlareSizes.fontSizeSm,
                fontWeight: FontWeight.w500,
                height: FlareSizes.lineHeightNormal,
                color: _toneInk(colors, block.tone),
              ),
            ),
          ),
        ),
      ],
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
  const _NoteBlock({required this.block});
  final FlarePluginNoteBlock block;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
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
