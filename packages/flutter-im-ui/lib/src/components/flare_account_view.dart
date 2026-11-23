import 'package:flutter/material.dart';

import '../models/directory_data.dart'
    show FlareButtonVariant, FlareControlSize;
import '../models/plugin_layout.dart';
import '../models/plugin_view.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_empty_state.dart';
import 'flare_icon.dart';
import 'flare_icon_button.dart';
import 'flare_plugin_view.dart';
import 'flare_result_view.dart' show FlareDescriptionRows;
import 'flare_status_banner.dart';
import 'flare_tag.dart';

/// Explicit presentation of resolved account fields/rows; no money calculations.
enum FlarePluginPageAppearance { document, account }

@immutable
class FlareAccountEntry {
  const FlareAccountEntry(
    this.id,
    this.block,
    this.row, {
    this.separateBadge = false,
  });
  final String id;
  final FlarePluginRowsBlock block;
  final FlarePluginRow row;
  final bool separateBadge;
  String get amount => row.cells.isEmpty ? '' : row.cells.first.text;

  /// The first cell as drawn: money with its currency (R10), as Vue
  /// `flarePluginMoneyFormatted`; any other value as sent.
  String amountText(FlareStrings strings) => row.cells.isEmpty
      ? ''
      : flarePluginFormatText(
          row.cells.first.text,
          row.cells.first.format,
          strings,
        );
  String get title =>
      (separateBadge ? null : row.badge?.text) ??
      (row.cells.length > 1
          ? row.cells[1].text
          : block.columns.firstOrNull?.label ?? '');
  String get subtitle => [
    for (
      var i = separateBadge || row.badge == null ? 2 : 1;
      i < row.cells.length && i < 3;
      i++
    )
      if (block.columns.elementAtOrNull(i)?.format !=
          FlarePluginColumnFormat.time)
        row.cells[i].text,
  ].where((s) => s.isNotEmpty).join(' · ');
  int? get timeMs {
    for (var i = 0; i < row.cells.length; i++) {
      if (block.columns.elementAtOrNull(i)?.format ==
          FlarePluginColumnFormat.time) {
        return row.cells[i].timeMs;
      }
    }
    return null;
  }
}

List<FlareAccountEntry> flareAccountEntries(FlarePluginViewModel view) => [
  for (final (i, block) in view.blocks.indexed)
    if (block is FlarePluginRowsBlock)
      for (final row in flarePluginRowsOnce(block.rows))
        FlareAccountEntry(
          '$i/${row.key}',
          block,
          row,
          separateBadge:
              view.presentation?['props'] is Map &&
              (view.presentation!['props'] as Map)['rowBadgePlacement'] ==
                  'separate',
        ),
];

/// §5.2: with no account the page's key is the action that opens one — the
/// first primary action that collects a form; its progress key is the page
/// destination declared next to it (before it, else after), never a row's
/// own action (the SwiftUI kit reads the same rule).
({FlarePluginAction? create, FlarePluginAction? progress})
flareAccountSetupActions(FlarePluginViewModel view) {
  final rowActions = {
    for (final block in view.blocks.whereType<FlarePluginRowsBlock>())
      for (final action in block.actions) action.id,
  };
  final actions = [
    for (final action in flarePluginTopLevelActions(view, embedded: true))
      if (!rowActions.contains(action.id)) action,
  ];
  final create = actions
      .where(
        (a) => a.style == FlarePluginActionStyle.primary && a.form.isNotEmpty,
      )
      .firstOrNull;
  if (create == null) return (create: null, progress: null);
  final at = actions.indexOf(create);
  return (
    create: create,
    progress: [at - 1, at + 1]
        .where((i) => i >= 0 && i < actions.length)
        .map((i) => actions[i])
        .where(
          (a) => flarePluginActionRole(a) == FlarePluginActionRole.destination,
        )
        .firstOrNull,
  );
}

/// R12, §12.23: a structure-derived account (no presentation; a section
/// holding a maskable amount hero without actions, and exactly one rows block
/// of ≥ 2 columns) as the account renderer reads it — the twin of Vue
/// `flareAccountDocument`, iOS `flareAccountDocument` and Compose
/// `pluginAccountDocument`: the hero and the stats lead the fields, the
/// section's other blocks come first, and a `wallet` presentation names up
/// to two primary page actions and the rows' single page action. Any other
/// view comes back as it is.
@visibleForTesting
FlarePluginViewModel flareAccountDocument(FlarePluginViewModel view) {
  if (view.presentation != null) return view;
  bool maskable(FlarePluginBlock b) =>
      b is FlarePluginHeroBlock && b.amount && b.maskable;
  final head = view.blocks
      .whereType<FlarePluginSectionBlock>()
      .where((section) => section.blocks.any(maskable))
      .firstOrNull;
  final hero = head?.blocks.firstWhere(maskable) as FlarePluginHeroBlock?;
  final rows = view.blocks.whereType<FlarePluginRowsBlock>().toList();
  if (head == null ||
      hero == null ||
      hero.actions.isNotEmpty ||
      rows.length != 1 ||
      rows.single.columns.length < 2) {
    return view;
  }
  bool page(FlarePluginAction a) =>
      a.target?.kind == 'page' &&
      (a.confirm?.isEmpty ?? true) &&
      a.form.isEmpty;
  final entry = rows.single.actions.length == 1
      ? rows.single.actions.single
      : null;
  final slots = view.actions
      .where((a) => a.style == FlarePluginActionStyle.primary && page(a))
      .take(2)
      .toList();
  return FlarePluginViewModel(
    available: view.available,
    title: view.title,
    fields: [
      FlarePluginField(
        label: hero.label ?? '',
        value: hero.value,
        format: hero.format,
      ),
      for (final block in head.blocks)
        if (block is FlarePluginStatsBlock)
          for (final item in block.items)
            FlarePluginField(
              label: item.label,
              value: item.value,
              format: item.format,
            ),
      ...view.fields,
    ],
    actions: view.actions,
    blocks: [
      for (final block in head.blocks)
        if (!identical(block, hero) && block is! FlarePluginStatsBlock) block,
      for (final block in view.blocks)
        if (!identical(block, head)) block,
    ],
    inputs: view.inputs,
    detail: view.detail,
    nextCursor: view.nextCursor,
    menuActions: view.menuActions,
    unavailableReason: view.unavailableReason,
    minBuild: view.minBuild,
    presentation: {
      'renderer': 'account',
      'props': {
        'layout': 'wallet',
        'summaryTitle': (head.label?.isNotEmpty ?? false)
            ? head.label
            : view.title,
        if (entry != null && page(entry)) 'rowEntryAction': entry.id,
      },
      'actions': {
        for (final (index, action) in slots.indexed)
          index == 0 ? 'primary' : 'secondary': action.id,
      },
    },
  );
}

/// The first field is the headline. All amounts remain server-formatted text.
/// Existing PluginView owns confirmations/forms and emits the bound row unchanged.
class FlareAccountView extends StatefulWidget {
  const FlareAccountView({
    super.key,
    required this.view,
    this.busyActionId,
    this.error,
    this.formErrors = const [],
    this.fileStates = const {},
    this.onFileAction,
    this.members = const [],
    this.membersLoading = false,
    this.membersRevision = 0,
    this.membersError,
    this.onMemberSearch,
    this.onMembersRetry,
    this.settleToken = 0,
    this.offline = false,
    this.resolveUser,
    this.viewerId,
    this.onAction,
  });
  final FlarePluginViewModel view;

  /// The host's directory: person cells and entries read as names.
  final FlarePluginResolveUser? resolveUser;

  /// The viewer, whose own entries read 我.
  final String? viewerId;

  /// Every action is disabled, not hidden, while the host is offline (R8).
  final bool offline;
  final String? busyActionId;
  final String? error;
  final List<FlarePluginFormError> formErrors;
  final Map<String, FlarePluginFileState> fileStates;
  final ValueChanged<FlarePluginFileAction>? onFileAction;
  final List<FlarePluginMember> members;
  final bool membersLoading;

  /// An authoritative roster/permission invalidation, never an ordinary search result.
  final int membersRevision;
  final String? membersError;
  final ValueChanged<String>? onMemberSearch;
  final VoidCallback? onMembersRetry;
  final int settleToken;
  final FlarePluginActionCallback? onAction;
  @override
  State<FlareAccountView> createState() => _FlareAccountViewState();
}

class _FlareAccountViewState extends State<FlareAccountView> {
  /// The view as drawn: a structure-derived account reads as the wallet
  /// presentation (R12, §12.23).
  late FlarePluginViewModel _view = flareAccountDocument(widget.view);
  bool _hidden = false;
  final _names = <String, String>{};

  /// The action failure the reader closed (R8).
  String? _dismissedError;

  /// The view that runs the setup keys (§5.2).
  final _runner = GlobalKey<FlarePluginViewState>();
  final _revision = ValueNotifier(0);
  final _locked = ValueNotifier(false);
  bool _updateQueued = false;
  Map get _presentation {
    final props = _view.presentation?["props"];
    return props is Map ? props : const {};
  }

  @override
  void didUpdateWidget(covariant FlareAccountView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _view = flareAccountDocument(widget.view);
    if (_updateQueued) return;
    _updateQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateQueued = false;
      if (!mounted) return;
      _locked.value = widget.busyActionId != null;
      _revision.value++;
    });
  }

  @override
  void dispose() {
    _revision.dispose();
    _locked.dispose();
    super.dispose();
  }

  FlarePluginViewModel _projection({
    List<FlarePluginField> fields = const [],
    List<FlarePluginAction> actions = const [],
    List<FlarePluginBlock> blocks = const [],
  }) => FlarePluginViewModel(
    available: _view.available,
    title: _view.title,
    fields: fields,
    inputs: _view.inputs,
    actions: actions,
    blocks: blocks,
    unavailableReason: _view.unavailableReason,
  );
  Widget _actions(
    FlarePluginViewModel view, {
    Key? key,
    FlareAccountEntry? entry,
    FlarePluginActionLayout layout = FlarePluginActionLayout.inline,
    bool labelRows = false,
    String? inlineFormActionId,
    String? inlineFormTitle,
    String? inlineFormDescription,
    bool showError = true,
  }) => FlarePluginView(
    key: key,
    resolveUser: widget.resolveUser,
    viewerId: widget.viewerId,
    fileStates: widget.fileStates,
    onFileAction: widget.onFileAction,
    view: view,
    embedded: true,
    actionLayout: layout,
    labelRows: labelRows,
    inlineFormActionId: inlineFormActionId,
    inlineFormTitle: inlineFormTitle,
    inlineFormDescription: inlineFormDescription,
    showError: showError,
    offline: widget.offline,
    busyActionId: widget.busyActionId,
    error: widget.error,
    formErrors: widget.formErrors,
    members: widget.members,
    membersLoading: widget.membersLoading,
    membersRevision: widget.membersRevision,
    membersError: widget.membersError,
    onMemberSearch: widget.onMemberSearch,
    onMembersRetry: widget.onMembersRetry,
    settleToken: widget.settleToken,
    onAction: widget.onAction == null
        ? null
        : (id, payload) {
            final binding = entry?.row.actions
                .where((a) => a.id == id)
                .firstOrNull;
            widget.onAction!(
              id,
              FlarePluginActionPayload(
                selection: payload.selection,
                formValues: payload.formValues,
                row: entry == null
                    ? payload.row
                    : (key: entry.row.key, input: binding?.input),
              ),
            );
          },
  );

  List<FlarePluginAction> get _allActions {
    final seen = <String>{};
    return [
      for (final action in [..._view.actions, ..._view.menuActions])
        if (seen.add(action.id)) action,
    ];
  }

  List<FlarePluginAction> _boundActions(List<String> slots) {
    final bindings = _view.presentation?['actions'];
    if (bindings is! Map) return const [];
    final ids = <String>{};
    return [
      for (final slot in slots)
        for (final action in _allActions)
          if (action.id == bindings[slot] && ids.add(action.id)) action,
    ];
  }

  /// The overview card and the wallet cards (§5.1, R2.1): bg.primary,
  /// radius.card, a hairline border.
  Widget _surface(Widget child, FlareColors colors, {Key? key}) => Container(
    key: key,
    padding: const EdgeInsets.all(FlareSizes.spacingLg),
    decoration: BoxDecoration(
      color: colors.bgPrimary,
      borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
      border: Border.all(color: colors.borderSecondary),
    ),
    child: child,
  );

  Widget _copy(String key, FlareColors colors, {bool emphasis = false}) => Text(
    _presentation[key] as String,
    style: TextStyle(
      color: emphasis ? colors.primaryText : colors.textSecondary,
      fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
      fontSize: FlareSizes.fontSizeSm,
    ),
  );

  bool _hasCopy(String key) =>
      _presentation[key] is String &&
      (_presentation[key] as String).trim().isNotEmpty;

  bool _urgent(FlarePluginBlock block) {
    final (text, tone) = switch (block) {
      FlarePluginNoteBlock() => (block.text, block.tone),
      FlarePluginStatusBlock() => (block.text, block.tone),
      // §5.1: the pending-operations banner leads the page with its key.
      FlarePluginBannerBlock(tone: FlarePluginBannerTone.warning) => (
        block.text,
        FlarePluginTone.warning,
      ),
      FlarePluginBannerBlock(tone: FlarePluginBannerTone.danger) => (
        block.text,
        FlarePluginTone.danger,
      ),
      _ => ('', FlarePluginTone.neutral),
    };
    return text.trim().isNotEmpty &&
        (tone == FlarePluginTone.warning || tone == FlarePluginTone.danger);
  }

  Widget _sectionTitle(String title, FlareColors colors) => Padding(
    padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingMd),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: FlareSizes.fontSizeXl,
        ),
      ),
    ),
  );

  /// The service list (R2.1): list cards by `group`, the danger rows in a
  /// card of their own, last, every one confirmed.
  Widget _services(List<FlarePluginAction> actions, FlareColors colors) =>
      Column(
        key: const ValueKey('flare-account-services'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_hasCopy('servicesTitle'))
            _sectionTitle(_presentation['servicesTitle'] as String, colors)
          else
            const SizedBox(height: FlareSizes.spacingLg),
          _actions(
            _projection(actions: actions),
            layout: FlarePluginActionLayout.list,
            showError: false,
          ),
        ],
      );

  Widget _shortcuts(List<FlarePluginAction> actions, FlareColors colors) =>
      Column(
        key: const ValueKey('flare-account-shortcuts'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_hasCopy('shortcutsTitle'))
            _sectionTitle(_presentation['shortcutsTitle'] as String, colors)
          else
            const SizedBox(height: FlareSizes.spacingMd),
          _actions(
            _projection(actions: actions),
            layout: FlarePluginActionLayout.compact,
            showError: false,
          ),
        ],
      );

  /// The overview's quick keys (R2.1, §5.1 W-13): a phone's equal widths 48
  /// high, a PC's natural widths ≥ 120, 40 high.
  Widget _quick(List<FlarePluginAction> actions) => _actions(
    _projection(actions: actions),
    layout: FlarePluginActionLayout.quick,
    showError: false,
  );

  /// The eye of the hidden balance (R10, §12.4): a toggle key.
  Widget _eye(FlareStrings strings) => FlareIconButton(
    icon: _hidden ? 'eye-off' : 'eye',
    semanticLabel: _hidden
        ? strings.accountShowBalance
        : strings.accountHideBalance,
    toggled: _hidden,
    onPressed: () => setState(() => _hidden = !_hidden),
  );

  /// The overview card of a fields account and the ledger (R2.1): the first
  /// field as the lead amount (32/700, tabular) with the eye, the other
  /// fields under it, the quick keys at its foot.
  Widget _walletSummary(
    List<FlarePluginAction> actions,
    FlareColors colors,
    FlareStrings strings, {
    bool titled = true,
  }) {
    final fields = _view.fields;
    return _surface(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titled)
            Semantics(
              header: true,
              child: Text(
                _hasCopy('summaryTitle')
                    ? _presentation['summaryTitle'] as String
                    : _view.title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSizeXl,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (fields.isNotEmpty) ...[
            if (titled) const SizedBox(height: FlareSizes.spacingMd),
            Row(
              children: [
                Expanded(
                  child: Text(
                    fields.first.label,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: FlareSizes.fontSizeMd,
                    ),
                  ),
                ),
                _eye(strings),
              ],
            ),
            Semantics(
              label: _hidden
                  ? strings.accountBalanceHidden
                  : fields.first.value,
              excludeSemantics: true,
              child: Text(
                _hidden ? flarePluginMaskedValue : fields.first.value,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.componentAmountHeroFontSize,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (fields.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: FlareSizes.spacingMd),
                child: Wrap(
                  spacing: FlareSizes.spacingXl,
                  runSpacing: FlareSizes.spacingMd,
                  children: [
                    for (final field in fields.skip(1))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            field.label,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: FlareSizes.fontSizeSm,
                            ),
                          ),
                          Text(
                            _hidden ? flarePluginMaskedValue : field.value,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: FlareSizes.fontSize3xl,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: FlareSizes.spacingLg),
            _quick(actions),
          ],
        ],
      ),
      colors,
      key: const ValueKey('flare-account-summary'),
    );
  }

  Widget _flow(FlareColors colors) {
    final bound = _boundActions(const ['submit']);
    final submit = [
      ...bound,
      for (final action in _allActions)
        if (action.style == FlarePluginActionStyle.primary &&
            !bound.any((a) => a.id == action.id))
          action,
    ];
    final remaining = _allActions
        .where((a) => !submit.any((s) => s.id == a.id))
        .toList();
    final inlineAction = flarePluginInlineFormAction(
      _view,
      submit.length == 1 ? submit.single.id : null,
      interactive: widget.onAction != null,
    );
    String? copy(String key) {
      final value = _presentation[key];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    final resultLines = [
      if (copy('resultTitle') case final title?) title,
      if (copy('resultDescription') case final description?) description,
    ];
    final hasBlockingStatus = _view.blocks
        .whereType<FlarePluginStatusBlock>()
        .any(
          (block) =>
              block.text.trim().isNotEmpty &&
              (block.tone == FlarePluginTone.warning ||
                  block.tone == FlarePluginTone.danger),
        );
    final unavailable =
        submit.isEmpty &&
            copy('formTitle') != null &&
            resultLines.isEmpty &&
            !hasBlockingStatus
        ? copy('formUnavailableDescription')
        : null;
    return Column(
      key: const ValueKey('flare-account-flow'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasCopy('stepLabel') ||
            _hasCopy('summaryTitle') ||
            _hasCopy('description')) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasCopy('stepLabel'))
                _copy('stepLabel', colors, emphasis: true),
              if (_hasCopy('summaryTitle')) ...[
                if (_hasCopy('stepLabel'))
                  const SizedBox(height: FlareSizes.spacingSm),
                Semantics(
                  header: true,
                  child: Text(
                    _presentation['summaryTitle'] as String,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.fontSizeXl,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (_hasCopy('description')) ...[
                if (_hasCopy('stepLabel') || _hasCopy('summaryTitle'))
                  const SizedBox(height: FlareSizes.spacingSm),
                _copy('description', colors),
              ],
            ],
          ),
          const SizedBox(height: FlareSizes.spacingMd),
        ],
        if (resultLines.isNotEmpty || unavailable != null) ...[
          Semantics(
            liveRegion: true,
            child: FlareStatusBanner(
              key: const ValueKey('flare-account-result'),
              text: unavailable ?? resultLines.join('\n'),
              tone: switch (unavailable == null
                  ? _presentation['resultTone']
                  : null) {
                'info' => FlareStatusTone.info,
                'success' => FlareStatusTone.success,
                'warning' => FlareStatusTone.warning,
                'danger' => FlareStatusTone.danger,
                _ => FlareStatusTone.neutral,
              },
            ),
          ),
          const SizedBox(height: FlareSizes.spacingMd),
        ],
        _surface(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasCopy('sectionTitle')) ...[
                Semantics(
                  header: true,
                  child: Text(
                    _presentation['sectionTitle'] as String,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: FlareSizes.fontSizeXl,
                    ),
                  ),
                ),
                const SizedBox(height: FlareSizes.spacingMd),
              ],
              _actions(
                _projection(
                  fields: _view.fields,
                  blocks: _view.blocks,
                  actions: submit,
                ),
                layout: FlarePluginActionLayout.compact,
                labelRows: true,
                inlineFormActionId: inlineAction?.id,
                inlineFormTitle: _hasCopy('formTitle')
                    ? _presentation['formTitle'] as String
                    : null,
                inlineFormDescription: _hasCopy('formDescription')
                    ? _presentation['formDescription'] as String
                    : null,
                showError: false,
              ),
            ],
          ),
          colors,
          key: const ValueKey('flare-account-receipt'),
        ),
        if (remaining.isNotEmpty) _services(remaining, colors),
        if (inlineAction == null && (widget.error?.isNotEmpty ?? false)) ...[
          const SizedBox(height: FlareSizes.spacingMd),
          FlareStatusBanner(text: widget.error!, tone: FlareStatusTone.danger),
        ],
      ],
    );
  }

  /// W-06: account information is a row of a list card ("账户信息 ›") that
  /// opens its details as a description list in a panel.
  List<Widget> _informationWidgets(
    List<FlarePluginField> fields,
    List<FlarePluginBlock> blocks,
    FlareColors colors,
    FlareStrings strings,
  ) {
    if (fields.isEmpty && blocks.isEmpty) return const [];
    final title = _hasCopy('informationTitle')
        ? _presentation['informationTitle'] as String
        : strings.accountInformation;
    return [
      const SizedBox(height: FlareSizes.spacingLg),
      Container(
        decoration: BoxDecoration(
          color: colors.bgPrimary,
          borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
          border: Border.all(color: colors.borderSecondary),
        ),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          child: InkWell(
            key: const ValueKey('flare-account-information'),
            onTap: () => _information(title, fields, blocks),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: FlareSizes.touchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FlareSizes.spacingMd,
                  vertical: FlareSizes.spacingMd,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: FlareSizes.fontSizeLg,
                        ),
                      ),
                    ),
                    FlareIcon(
                      'chevron-right',
                      size: FlareSizes.iconSizeSm,
                      color: colors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Future<void> _information(
    String title,
    List<FlarePluginField> fields,
    List<FlarePluginBlock> blocks,
  ) => FlareBottomSheet.show<void>(
    context,
    title: title,
    showClose: true,
    listenable: _revision,
    builder: (inner) => SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(FlareSizes.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fields.isNotEmpty)
              FlareDescriptionRows(
                key: const ValueKey('flare-account-information-list'),
                fields: [
                  for (final field in fields)
                    FlarePluginField(
                      label: field.label,
                      value: _hidden ? flarePluginMaskedValue : field.value,
                      // R10: a derived hero or stat keeps its money format.
                      format: _hidden ? null : field.format,
                    ),
                ],
              ),
            if (fields.isNotEmpty && blocks.isNotEmpty)
              const SizedBox(height: FlareSizes.spacingLg),
            if (blocks.isNotEmpty)
              _actions(_projection(blocks: blocks), showError: false),
          ],
        ),
      ),
    ),
  );

  /// A cell as it is drawn (R3): a person as the name, a value outside its
  /// declared ones as the unknown status, never the raw value.
  String _cellText(FlarePluginRowCell cell, FlareStrings strings) =>
      switch (cell.userId) {
        final id? => _nameOf(id),
        null => flarePluginStatusText(
          cell.text,
          unmapped: cell.unmapped,
          strings: strings,
          where: 'account',
        ),
      };

  /// [entry] with its person cells named and its unmapped values read as
  /// the unknown status (R3).
  FlareAccountEntry _shown(FlareAccountEntry entry, FlareStrings strings) {
    final row = entry.row, badge = row.badge;
    return FlareAccountEntry(
      entry.id,
      entry.block,
      FlarePluginRow(
        key: row.key,
        actions: row.actions,
        badge: badge == null
            ? null
            : FlarePluginBadge(
                text: flarePluginStatusText(
                  badge.text,
                  unmapped: badge.unmapped,
                  strings: strings,
                  where: 'account',
                ),
                tone: badge.unmapped ? FlarePluginTone.neutral : badge.tone,
              ),
        cells: [
          for (final cell in row.cells)
            FlarePluginRowCell(
              text: _cellText(cell, strings),
              timeMs: cell.timeMs,
              tone: cell.unmapped ? FlarePluginTone.neutral : cell.tone,
            ),
        ],
      ),
      separateBadge: entry.separateBadge,
    );
  }

  /// A person's name from the host's directory, the id's tail until then.
  String _nameOf(String id) {
    final known = _names[id];
    if (known != null) return known;
    _names[id] = flarePluginFallbackName(id);
    final resolved = widget.resolveUser?.call(id);
    if (resolved is FlarePluginUser) {
      _names[id] = resolved.name;
    } else if (resolved is Future<FlarePluginUser?>) {
      resolved.then((user) {
        if (mounted && user != null) setState(() => _names[id] = user.name);
      }, onError: (Object _) {});
    }
    return _names[id]!;
  }

  /// A wallet card (§5.1). [pc] (§12.23): the wallet and its name, the
  /// balance and one foot line「状态 Tag · 查看明细 ›」— no balance label and
  /// no plain details.
  Widget _walletCard(
    FlareAccountEntry entry,
    FlareColors colors,
    FlareStrings strings, {
    Widget? footer,
    bool pc = false,
  }) {
    final shown = _shown(entry, strings);
    final title = shown.row.cells.elementAtOrNull(1)?.text ?? shown.title;
    final entryAction = _entryAction(entry);
    final metadata = [
      for (var i = 2; i < entry.row.cells.length; i++)
        if (entry.row.cells[i].text.isNotEmpty ||
            entry.row.cells[i].timeMs != null ||
            entry.row.cells[i].unmapped)
          i,
    ];
    Widget value(int i) {
      final cell = shown.row.cells[i];
      // R3 (W-04): a toned value (正常 / 冻结) is a status Tag.
      if (cell.tone != null || entry.row.cells[i].unmapped) {
        return FlareTag(
          label: cell.text,
          tone: FlareStatusTone.values.byName(
            (cell.tone ?? FlarePluginTone.neutral).name,
          ),
        );
      }
      return Text(
        _hidden
            ? flarePluginMaskedValue
            : entry.block.columns.elementAtOrNull(i)?.format ==
                      FlarePluginColumnFormat.time &&
                  cell.timeMs != null
            ? flarePluginDateTime(cell.timeMs!, flarePluginNowMs(), strings)
            : cell.text,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: FlareSizes.fontSizeLg,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // R3: the toned (or unmapped) cells, the statuses a PC card's foot shows.
    final statuses = [
      for (final i in metadata)
        if (shown.row.cells[i].tone != null || entry.row.cells[i].unmapped) i,
    ];
    Widget link(String label) => Text(
      label,
      style: TextStyle(
        color: colors.primaryText,
        fontSize: FlareSizes.fontSizeSm,
        fontWeight: FontWeight.w500,
      ),
    );
    final dot = Text('·', style: TextStyle(color: colors.textTertiary));

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            FlareIcon('wallet', color: colors.primaryText),
            const SizedBox(width: FlareSizes.spacingSm),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: FlareSizes.fontSize4xl,
                ),
              ),
            ),
            if (entryAction == null)
              FlareIcon(
                'chevron-right',
                size: FlareSizes.iconSizeSm,
                color: colors.textTertiary,
              ),
          ],
        ),
        const SizedBox(height: FlareSizes.spacingSm),
        if (!pc) ...[
          Text(
            entry.block.columns.firstOrNull?.label ?? '',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: FlareSizes.fontSizeSm,
            ),
          ),
          const SizedBox(height: FlareSizes.spacingXs),
        ],
        Semantics(
          excludeSemantics: true,
          label: _hidden
              ? strings.accountBalanceHidden
              : entry.amountText(strings),
          child: Text(
            _hidden ? flarePluginMaskedValue : entry.amountText(strings),
            // R10: the lead amount, 32/700, tabular.
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: FlareSizes.componentAmountHeroFontSize,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (pc && (statuses.isNotEmpty || entryAction != null)) ...[
          const SizedBox(height: FlareSizes.spacingSm),
          Wrap(
            key: ValueKey('account-entry-foot:${entry.id}'),
            spacing: FlareSizes.spacingXs,
            runSpacing: FlareSizes.spacingXs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (index, i) in statuses.indexed) ...[
                if (index > 0) dot,
                value(i),
              ],
              if (entryAction != null) ...[
                if (statuses.isNotEmpty) dot,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    link(entryAction.action.label),
                    FlareIcon(
                      'chevron-right',
                      size: FlareSizes.iconSizeSm,
                      color: colors.primaryText,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
        if (!pc && metadata.isNotEmpty) ...[
          const SizedBox(height: FlareSizes.spacingSm),
          LayoutBuilder(
            builder: (context, bounds) {
              final columns = metadata.length > 1 ? 2 : 1;
              final width =
                  (bounds.maxWidth - FlareSizes.spacingMd * (columns - 1)) /
                  columns;
              return Wrap(
                spacing: FlareSizes.spacingMd,
                runSpacing: FlareSizes.spacingSm,
                children: [
                  for (final i in metadata)
                    SizedBox(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.block.columns.elementAtOrNull(i)?.label ?? '',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: FlareSizes.fontSizeSm,
                            ),
                          ),
                          const SizedBox(height: FlareSizes.spacingXs),
                          value(i),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        if (!pc && entryAction != null) ...[
          const SizedBox(height: FlareSizes.spacingSm),
          Divider(height: 1, color: colors.borderSecondary),
          Padding(
            padding: const EdgeInsets.only(top: FlareSizes.spacingSm),
            child: Row(
              children: [
                Expanded(child: link(entryAction.action.label)),
                const SizedBox(width: FlareSizes.spacingSm),
                FlareIcon(
                  'chevron-right',
                  size: FlareSizes.iconSizeSm,
                  color: colors.primaryText,
                ),
              ],
            ),
          ),
        ],
      ],
    );
    // The card opens the wallet; its quick keys (the overview's, §5.1) sit
    // under the tappable part, never inside it.
    return Container(
      key: ValueKey('account-entry:${entry.id}'),
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
        border: Border.all(color: colors.borderSecondary),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.busyActionId == null
                  ? () => _activateEntry(entry.id)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(FlareSizes.spacingLg),
                child: body,
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FlareSizes.spacingLg,
                0,
                FlareSizes.spacingLg,
                FlareSizes.spacingLg,
              ),
              child: footer,
            ),
        ],
      ),
    );
  }

  /// §5.1: a wallet under "其他钱包" — its name 15 over its currency 12, the
  /// balance 16/600 tabular, a chevron.
  Widget _otherWallet(
    FlareAccountEntry entry,
    FlareColors colors,
    FlareStrings strings,
  ) {
    final shown = _shown(entry, strings);
    final name = shown.row.cells.elementAtOrNull(1)?.text ?? shown.title;
    final currency = [
      for (var i = 2; i < shown.row.cells.length; i++)
        if (shown.row.cells[i].tone == null &&
            shown.row.cells[i].timeMs == null &&
            shown.row.cells[i].text.isNotEmpty)
          shown.row.cells[i].text,
    ].firstOrNull;
    final enabled = widget.busyActionId == null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        key: ValueKey('account-entry:${entry.id}'),
        onTap: enabled ? () => _activateEntry(entry.id) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingMd,
              vertical: FlareSizes.spacingSm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: FlareSizes.fontSizeXl,
                        ),
                      ),
                      if (currency != null)
                        Text(
                          currency,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: FlareSizes.fontSizeSm,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: FlareSizes.spacingSm),
                Semantics(
                  label: _hidden ? strings.accountBalanceHidden : null,
                  excludeSemantics: _hidden,
                  child: Text(
                    _hidden
                        ? flarePluginMaskedValue
                        : entry.amountText(strings),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.fontSize2xl,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: FlareSizes.spacingSm),
                FlareIcon(
                  'chevron-right',
                  size: FlareSizes.iconSizeSm,
                  color: colors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// §5.2: no account yet — no balance and no top-up or withdrawal (W-01):
  /// the wallet in its tone circle, 开通钱包 20/700, the body, the opening key
  /// (a phone's full width 48, a PC's component.accountSetupActionWidth) and
  /// the opening requests' key under it.
  Widget _setup(
    FlareColors colors,
    FlareStrings strings,
    ({FlarePluginAction? create, FlarePluginAction? progress}) keys,
  ) {
    final pc =
        (MediaQuery.maybeSizeOf(context)?.width ?? 0) >=
        FlareSizes.appShellCompactMinWidth;
    final locked =
        widget.busyActionId != null ||
        widget.offline ||
        widget.onAction == null;
    Widget key(FlarePluginAction action, {required bool primary}) {
      final button = FlareButton(
        key: ValueKey('flare-account-setup-${action.id}'),
        label: action.label,
        variant: primary
            ? FlareButtonVariant.primary
            : FlareButtonVariant.secondary,
        size: primary ? FlareControlSize.lg : FlareControlSize.md,
        block: !pc,
        maintainTouchTarget: true,
        loading: widget.busyActionId == action.id,
        disabled: locked,
        onPressed: () => _runner.currentState?.runAction(action.id),
      );
      return pc
          ? SizedBox(
              width: FlareSizes.componentAccountSetupActionWidth,
              child: button,
            )
          : button;
    }

    return Padding(
      key: const ValueKey('flare-account-setup'),
      padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacing2xl),
      child: Column(
        crossAxisAlignment: pc
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.all(FlareSizes.spacingMd),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.bgSelected,
                ),
                child: FlareIcon(
                  'wallet',
                  size: FlareSizes.iconSizeLg,
                  color: colors.primaryText,
                ),
              ),
            ),
          ),
          const SizedBox(height: FlareSizes.spacingLg),
          Semantics(
            header: true,
            child: Text(
              strings.walletSetupTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: FlareTextRoles.title.fontSize,
                height: FlareTextRoles.title.lineHeight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: FlareSizes.spacingSm),
          Text(
            strings.walletSetupBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: FlareSizes.fontSizeMd,
            ),
          ),
          if (keys.create case final create?) ...[
            const SizedBox(height: FlareSizes.spacingXl),
            // The keys run through a view that holds them (forms,
            // confirmations, settles), drawn here at their own sizes.
            Offstage(
              child: _actions(
                _projection(actions: [create, ?keys.progress]),
                key: _runner,
                showError: false,
              ),
            ),
            key(create, primary: true),
            if (keys.progress case final progress?) ...[
              const SizedBox(height: FlareSizes.spacingSm),
              key(progress, primary: false),
            ],
            if (widget.offline)
              Padding(
                padding: const EdgeInsets.only(top: FlareSizes.spacingXs),
                child: Text(
                  strings.pluginViewAvailableOnline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: FlareTextRoles.caption.fontSize,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// R8: an action failure leads the page and can be closed.
  List<Widget> _errorBanner() {
    final error = widget.error;
    if (error == null || error.isEmpty || error == _dismissedError) {
      return const [];
    }
    return [
      FlareStatusBanner(
        key: const ValueKey('flare-account-error'),
        text: error,
        tone: FlareStatusTone.danger,
        dismissible: true,
        onDismiss: () => setState(() => _dismissedError = error),
      ),
      const SizedBox(height: FlareSizes.spacingMd),
    ];
  }

  Widget _wallet(FlareColors colors, FlareStrings strings) {
    final entries = flareAccountEntries(_view);
    final slots = _boundActions(const ['primary', 'secondary', 'tertiary']);
    // §5.1: a phone's overview card keeps the keys; a page link among them
    // (收款方式) goes to the list.
    final phone =
        (MediaQuery.maybeSizeOf(context)?.width ?? 0) <
        FlareSizes.appShellCompactMinWidth;
    final moved = [
      for (final action in slots)
        if (phone &&
            flarePluginActionRole(action) == FlarePluginActionRole.destination)
          action,
    ];
    final primary = [
      for (final action in slots)
        if (!moved.contains(action)) action,
    ];
    final shortcuts = _boundActions(const [
      'shortcutPrimary',
      'shortcutSecondary',
      'shortcutTertiary',
    ]).where((action) => !primary.any((p) => p.id == action.id)).toList();
    final setup = entries.isEmpty
        ? flareAccountSetupActions(_view)
        : (create: null, progress: null);
    final services = [
      ...moved,
      ..._allActions.where(
        (a) =>
            !slots.any((p) => p.id == a.id) &&
            !shortcuts.any((s) => s.id == a.id) &&
            a.id != setup.create?.id &&
            a.id != setup.progress?.id,
      ),
    ];
    final urgent = _view.blocks.where(_urgent).toList();
    final information = _view.blocks
        .where((b) => b is! FlarePluginRowsBlock && !urgent.contains(b))
        .toList();
    final title = _hasCopy('sectionTitle')
        ? _presentation['sectionTitle'] as String
        : _hasCopy('summaryTitle')
        ? _presentation['summaryTitle'] as String
        : _view.title;
    // Two equal columns when two cards of layout.primaryPaneMinWidth fit.
    int columnsOf(double width) =>
        entries.length > 1 &&
            width >= FlareSizes.primaryPaneMinWidth * 2 + FlareSizes.spacingMd
        ? 2
        : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._errorBanner(),
        if (urgent.isNotEmpty) ...[
          _actions(_projection(blocks: urgent), showError: false),
          const SizedBox(height: FlareSizes.spacingMd),
        ],
        if (entries.isEmpty)
          _setup(colors, strings, setup)
        else if (!phone)
          // §12.23: a PC has no title row (the page header names the page;
          // the section keeps it for the reader): the cards in two equal
          // columns, then the quick keys with the eye at the row's end.
          Semantics(
            container: true,
            explicitChildNodes: true,
            label: title,
            child: Column(
              key: const ValueKey('flare-account-summary'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, bounds) {
                    final columns = columnsOf(bounds.maxWidth);
                    final width =
                        (bounds.maxWidth -
                            FlareSizes.spacingMd * (columns - 1)) /
                        columns;
                    return Wrap(
                      spacing: FlareSizes.spacingMd,
                      runSpacing: FlareSizes.spacingMd,
                      children: [
                        for (final entry in entries)
                          SizedBox(
                            width: width,
                            child: _walletCard(
                              entry,
                              colors,
                              strings,
                              pc: true,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: FlareSizes.spacingLg),
                Row(
                  key: const ValueKey('flare-account-quick-row'),
                  children: [
                    Expanded(
                      child: primary.isEmpty
                          ? const SizedBox.shrink()
                          : _quick(primary),
                    ),
                    _eye(strings),
                  ],
                ),
              ],
            ),
          )
        else ...[
          Row(
            key: const ValueKey('flare-account-summary'),
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.fontSizeXl,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _eye(strings),
            ],
          ),
          const SizedBox(height: FlareSizes.spacingMd),
          LayoutBuilder(
            builder: (context, bounds) {
              final columns = columnsOf(bounds.maxWidth);
              final width =
                  (bounds.maxWidth - FlareSizes.spacingMd * (columns - 1)) /
                  columns;
              // §5.1: one column keeps the first wallet as the overview card
              // with the quick keys inside and lists the others under
              // "其他钱包"; the PC grid has its quick keys under it.
              if (columns == 1) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _walletCard(
                      entries.first,
                      colors,
                      strings,
                      footer: primary.isEmpty ? null : _quick(primary),
                    ),
                    if (entries.length > 1) ...[
                      const SizedBox(height: FlareSizes.spacingLg),
                      Semantics(
                        header: true,
                        child: Text(
                          strings.accountOtherWallets,
                          style: TextStyle(
                            fontSize: FlareTextRoles.section.fontSize,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: FlareSizes.spacingSm),
                      Container(
                        key: const ValueKey('flare-account-other-wallets'),
                        decoration: BoxDecoration(
                          color: colors.bgPrimary,
                          borderRadius: BorderRadius.circular(
                            FlareSizes.radiusCard,
                          ),
                          border: Border.all(color: colors.borderSecondary),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (final (index, entry)
                                in entries.skip(1).indexed) ...[
                              if (index > 0)
                                Divider(
                                  height: 1,
                                  indent: FlareSizes.spacingMd,
                                  color: colors.borderSecondary,
                                ),
                              _otherWallet(entry, colors, strings),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: FlareSizes.spacingMd,
                    runSpacing: FlareSizes.spacingMd,
                    children: [
                      for (final entry in entries)
                        SizedBox(
                          width: width,
                          child: _walletCard(entry, colors, strings),
                        ),
                    ],
                  ),
                  if (primary.isNotEmpty) ...[
                    const SizedBox(height: FlareSizes.spacingLg),
                    _quick(primary),
                  ],
                ],
              );
            },
          ),
        ],
        if (shortcuts.isNotEmpty) _shortcuts(shortcuts, colors),
        ..._informationWidgets(
          entries.isEmpty ? const [] : _view.fields,
          information,
          colors,
          strings,
        ),
        if (services.isNotEmpty) _services(services, colors),
      ],
    );
  }

  String _day(FlareAccountEntry entry, FlareStrings strings) {
    final ms = entry.timeMs;
    if (ms == null) return strings.accountOtherEntries;
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.fromMillisecondsSinceEpoch(flarePluginNowMs());
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return strings.accountToday;
    if (day == today.subtract(const Duration(days: 1)))
      return strings.accountYesterday;
    return flarePluginRenderPattern(
      date.year == now.year
          ? strings.accountDayFormat
          : strings.accountDayYearFormat,
      date,
    );
  }

  String _time(FlareAccountEntry entry) {
    final ms = entry.timeMs;
    if (ms == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  ({FlarePluginAction action, Object? input})? _entryAction(
    FlareAccountEntry entry,
  ) {
    final requested = _presentation['rowEntryAction'];
    final binding = entry.row.actions
        .where((action) => action.id == requested)
        .firstOrNull;
    final action = entry.block.actions
        .where((action) => action.id == requested)
        .firstOrNull;
    if (_view.available &&
        !flarePluginReadOnly(_view) &&
        widget.onAction != null &&
        !widget.offline &&
        binding != null &&
        action != null &&
        action.form.isEmpty &&
        !(action.confirm?.isNotEmpty ?? false)) {
      return (action: action, input: binding.input);
    }
    return null;
  }

  Future<void> _activateEntry(String id) async {
    if (!mounted || widget.busyActionId != null) return;
    final entry = flareAccountEntries(
      _view,
    ).where((entry) => entry.id == id).firstOrNull;
    if (entry == null) return;
    final direct = _entryAction(entry);
    if (direct != null) {
      widget.onAction!(
        direct.action.id,
        FlarePluginActionPayload(
          row: (key: entry.row.key, input: direct.input),
        ),
      );
      return;
    }
    await _open(id);
  }

  Future<void> _open(String id) async {
    final strings = FlareStrings.of(context);
    _locked.value = widget.busyActionId != null;
    await FlareBottomSheet.show<void>(
      context,
      title:
          (_presentation["detailTitle"] as String? ??
          _presentation["sectionTitle"] as String? ??
          strings.accountEntryDetails),
      titleHidden: true,
      busy: _locked,
      listenable: _revision,
      builder: (inner) {
        final entry = flareAccountEntries(
          _view,
        ).where((e) => e.id == id).firstOrNull;
        final colors = FlareColors.of(inner);
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(FlareSizes.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (_presentation["detailTitle"] as String? ??
                            _presentation["sectionTitle"] as String? ??
                            strings.accountEntryDetails),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FlareIconButton(
                      icon: 'close',
                      semanticLabel: strings.close,
                      disabled: widget.busyActionId != null,
                      onPressed: () => Navigator.of(inner).pop(),
                    ),
                  ],
                ),
                if (entry == null)
                  Text(
                    strings.accountEmpty,
                    style: TextStyle(color: colors.textSecondary),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: FlareSizes.spacingLg,
                    ),
                    child: Column(
                      children: [
                        if (entry.block.columns.firstOrNull?.label.isNotEmpty ??
                            false)
                          Text(
                            entry.block.columns.first.label,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: FlareSizes.fontSizeSm,
                            ),
                          ),
                        Text(
                          _hidden && _presentation['maskRowAmounts'] == true
                              ? '••••'
                              : entry.amountText(strings),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: FlareSizes.fontSize5xl,
                            fontWeight: FontWeight.w600,
                            color: entry.amount.startsWith('+')
                                ? colors.successText
                                : colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.row.badge != null)
                    _detailLine(
                      _presentation['rowBadgeLabel'] as String? ??
                          strings.accountType,
                      entry.row.badge!.text,
                      colors,
                    ),
                  for (var i = 1; i < entry.row.cells.length; i++)
                    _detailLine(
                      entry.block.columns.elementAtOrNull(i)?.label ?? '',
                      entry.block.columns.elementAtOrNull(i)?.format ==
                                  FlarePluginColumnFormat.time &&
                              entry.row.cells[i].timeMs != null
                          ? flarePluginDateTime(
                              entry.row.cells[i].timeMs!,
                              flarePluginNowMs(),
                              strings,
                            )
                          : entry.row.cells[i].text,
                      colors,
                    ),
                  _detailLine(
                    _presentation["rowKeyLabel"] as String? ??
                        strings.accountEntryId,
                    entry.row.key,
                    colors,
                  ),
                  _actions(
                    _projection(
                      actions: entry.block.actions
                          .where(
                            (a) => entry.row.actions.any((r) => r.id == a.id),
                          )
                          .toList(),
                    ),
                    entry: entry,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailLine(String label, String value, FlareColors colors) => Padding(
    padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: colors.textSecondary)),
        ),
        const SizedBox(width: FlareSizes.spacingMd),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
      ],
    ),
  );

  /// A ledger line (§5.8): 64 high; the 36 circle by the sign (income
  /// arrow-down on the success tint, spending send, else wallet), the title
  /// 15 over time · details 12, the amount 16/600 tabular with a true minus,
  /// a separate status Tag only when it is not success.
  Widget _ledgerRow(
    FlareAccountEntry entry,
    FlareColors colors,
    FlareStrings strings,
  ) {
    final shown = _shown(entry, strings);
    final amount = entry.amountText(strings).trimLeft();
    final income = amount.startsWith('+');
    final spending = amount.startsWith('-') || amount.startsWith('−');
    final masked = _hidden && _presentation['maskRowAmounts'] == true;
    final badge = shown.row.badge;
    final line = [
      _time(entry),
      shown.subtitle,
    ].where((part) => part.isNotEmpty).join(' · ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('account-entry:${entry.id}'),
        onTap: widget.busyActionId == null
            ? () => _activateEntry(entry.id)
            : null,
        // §5.8: at least component.recordRowHeight (64) high.
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FlareSizes.componentRecordRowHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
            child: LayoutBuilder(
              builder: (context, bounds) => Row(
                children: [
                  Container(
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
                      income
                          ? 'arrow-down'
                          : spending
                          ? 'send'
                          : 'wallet',
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
                        Text(
                          shown.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: FlareSizes.fontSizeXl,
                          ),
                        ),
                        if (line.isNotEmpty)
                          Text(
                            line,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: FlareSizes.fontSizeSm,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: FlareSizes.spacingSm),
                  // A very long amount wraps inside its share, never overflows.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: bounds.maxWidth * 0.42,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          masked
                              ? flarePluginMaskedValue
                              : amount.replaceFirst(RegExp('^-'), '−'),
                          style: TextStyle(
                            color: income
                                ? colors.successText
                                : colors.textPrimary,
                            fontSize: FlareSizes.fontSize2xl,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (entry.separateBadge &&
                            badge != null &&
                            badge.tone != FlarePluginTone.success)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: FlareSizes.spacing2xs,
                            ),
                            child: FlareTag(
                              key: ValueKey('account-entry-badge:${entry.id}'),
                              label: badge.text,
                              tone: FlareStatusTone.values.byName(
                                badge.tone.name,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The ledger (§5.8): day headings 12/600 secondary that the page pins,
  /// the lines under them, the compact empty state.
  List<Widget> _ledger(FlareColors colors, FlareStrings strings) {
    final entries = flareAccountEntries(_view);
    if (entries.isEmpty) {
      return [
        FlareEmptyState(
          compact: true,
          title: _hasCopy('emptyTitle')
              ? _presentation['emptyTitle'] as String
              : strings.accountEmpty,
          description: _hasCopy('emptyDescription')
              ? _presentation['emptyDescription'] as String
              : strings.accountEmptyDescription,
          icon: 'clock',
        ),
      ];
    }
    final grouped = _presentation['groupByDate'] != false;
    final headings = FlarePluginDayHeadings.maybeOf(context);
    final keyed = <String>{};
    final out = <Widget>[];
    String? last;
    for (final entry in entries) {
      final day = _day(entry, strings);
      if (grouped && day != last) {
        out.add(
          Padding(
            padding: EdgeInsets.only(
              top: last == null ? 0 : FlareSizes.spacingMd,
              bottom: FlareSizes.spacingXs,
            ),
            // The page pins the heading it scrolled past (one key a day).
            child: KeyedSubtree(
              key: keyed.add(day) ? headings?.keyFor(day) : null,
              child: Semantics(
                header: true,
                child: Text(
                  day,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: FlareSizes.fontSizeSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
        last = day;
      }
      out.add(_ledgerRow(entry, colors, strings));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (!_view.available) return _actions(_view);
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final layout = _presentation['layout'];
    if (layout == 'flow') return _flow(colors);
    if (layout == 'wallet') return _wallet(colors, strings);
    final fields = _view.fields;
    final structured = layout == 'ledger';
    // R2.1: the ledger's bound slots, else the overview places of the page.
    final places = flarePluginActionPlaces(
      _view,
      embedded: true,
      archetype: FlarePluginPageArchetype.overview,
    );
    final quick = structured
        ? _boundActions(const ['primary', 'secondary', 'tertiary'])
        : places.quick;
    final services = structured
        ? _allActions.where((a) => !quick.any((q) => q.id == a.id)).toList()
        : [for (final group in places.list) ...group.actions, ...places.danger];
    final urgent = _view.blocks
        .where(
          (b) => structured
              ? _urgent(b)
              : b is FlarePluginNoteBlock &&
                    (b.tone == FlarePluginTone.warning ||
                        b.tone == FlarePluginTone.danger),
        )
        .toList();
    final information = _view.blocks
        .where((b) => b is! FlarePluginRowsBlock && !urgent.contains(b))
        .toList();
    final hasSummary = fields.isNotEmpty || (structured && quick.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._errorBanner(),
        if (structured &&
            (_hasCopy('contextLabel') || _hasCopy('description'))) ...[
          if (_hasCopy('contextLabel'))
            KeyedSubtree(
              key: const ValueKey('flare-account-context'),
              child: Text(
                _presentation['contextLabel'] as String,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSizeMd,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (_hasCopy('description')) ...[
            if (_hasCopy('contextLabel'))
              const SizedBox(height: FlareSizes.spacingSm),
            _copy('description', colors),
          ],
          const SizedBox(height: FlareSizes.spacingMd),
        ],
        if (urgent.isNotEmpty) ...[
          _actions(_projection(blocks: urgent), showError: false),
          const SizedBox(height: FlareSizes.spacingMd),
        ],
        if (hasSummary)
          _walletSummary(quick, colors, strings, titled: structured)
        else if (quick.isNotEmpty)
          _quick(quick),
        if (fields.isNotEmpty || _hasCopy('sectionTitle'))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingMd),
            child: Semantics(
              header: true,
              child: Text(
                _hasCopy('sectionTitle')
                    ? _presentation['sectionTitle'] as String
                    : strings.accountTransactions,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: FlareSizes.fontSize3xl,
                ),
              ),
            ),
          ),
        ..._ledger(colors, strings),
        ..._informationWidgets(
          structured ? fields.skip(1).toList() : const [],
          information,
          colors,
          strings,
        ),
        if (services.isNotEmpty) _services(services, colors),
      ],
    );
  }
}
