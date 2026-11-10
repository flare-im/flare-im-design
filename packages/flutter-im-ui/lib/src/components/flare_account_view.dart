import 'package:flutter/material.dart';

import '../models/plugin_view.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_empty_state.dart';
import 'flare_icon.dart';
import 'flare_icon_button.dart';
import 'flare_plugin_view.dart';
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
    this.onAction,
  });
  final FlarePluginViewModel view;
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
  bool _hidden = false;
  bool _information = false;
  final _revision = ValueNotifier(0);
  final _locked = ValueNotifier(false);
  Map get _presentation {
    final props = widget.view.presentation?["props"];
    return props is Map ? props : const {};
  }

  @override
  void didUpdateWidget(covariant FlareAccountView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _locked.value = widget.busyActionId != null;
    _revision.value++;
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
    available: widget.view.available,
    title: widget.view.title,
    fields: fields,
    inputs: widget.view.inputs,
    actions: actions,
    blocks: blocks,
    unavailableReason: widget.view.unavailableReason,
  );
  Widget _actions(
    FlarePluginViewModel view, {
    FlareAccountEntry? entry,
    FlarePluginActionLayout layout = FlarePluginActionLayout.inline,
    bool labelRows = false,
    String? inlineFormActionId,
    String? inlineFormTitle,
    String? inlineFormDescription,
    bool showError = true,
  }) => FlarePluginView(
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
      for (final action in [...widget.view.actions, ...widget.view.menuActions])
        if (seen.add(action.id)) action,
    ];
  }

  List<FlarePluginAction> _boundActions(List<String> slots) {
    final bindings = widget.view.presentation?['actions'];
    if (bindings is! Map) return const [];
    final ids = <String>{};
    return [
      for (final slot in slots)
        for (final action in _allActions)
          if (action.id == bindings[slot] && ids.add(action.id)) action,
    ];
  }

  Widget _surface(
    Widget child,
    FlareColors colors, {
    Key? key,
    bool outlined = false,
  }) => Container(
    key: key,
    padding: const EdgeInsets.all(FlareSizes.spacingLg),
    decoration: BoxDecoration(
      color: colors.bgSecondary,
      borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
      border: outlined ? Border.all(color: colors.borderSecondary) : null,
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

  Widget _services(List<FlarePluginAction> actions, FlareColors colors) =>
      Column(
        key: const ValueKey('flare-account-services'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_hasCopy('servicesTitle'))
            _sectionTitle(_presentation['servicesTitle'] as String, colors)
          else
            const SizedBox(height: FlareSizes.spacingMd),
          _surface(
            _actions(
              _projection(actions: actions),
              layout: FlarePluginActionLayout.list,
              showError: false,
            ),
            colors,
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

  Widget _walletSummary(
    List<FlarePluginAction> actions,
    FlareColors colors,
    FlareStrings strings, {
    bool showDescription = true,
  }) => _surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          overflowAlignment: OverflowBarAlignment.start,
          spacing: FlareSizes.spacingMd,
          overflowSpacing: FlareSizes.spacingMd,
          children: [
            Semantics(
              header: true,
              child: Text(
                _hasCopy('summaryTitle')
                    ? _presentation['summaryTitle'] as String
                    : widget.view.title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSizeXl,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (actions.isNotEmpty)
              _actions(
                _projection(actions: actions),
                layout: FlarePluginActionLayout.compact,
                showError: false,
              ),
          ],
        ),
        if (showDescription && _hasCopy('description')) ...[
          const SizedBox(height: FlareSizes.spacingSm),
          _copy('description', colors),
        ],
        if (widget.view.fields.isNotEmpty) ...[
          Divider(height: FlareSizes.spacingXl, color: colors.borderSecondary),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.view.fields.first.label,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              const SizedBox(width: FlareSizes.spacingSm),
              Expanded(
                child: Semantics(
                  label: _hidden
                      ? strings.accountBalanceHidden
                      : widget.view.fields.first.value,
                  excludeSemantics: true,
                  child: Text(
                    _hidden ? '••••' : widget.view.fields.first.value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.fontSize3xl,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              FlareIconButton(
                icon: _hidden ? 'eye-off' : 'eye',
                semanticLabel: _hidden
                    ? strings.accountShowBalance
                    : strings.accountHideBalance,
                onPressed: () => setState(() => _hidden = !_hidden),
              ),
            ],
          ),
        ],
      ],
    ),
    colors,
    key: const ValueKey('flare-account-summary'),
  );

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
      widget.view,
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
    final hasBlockingStatus = widget.view.blocks
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
                  fields: widget.view.fields,
                  blocks: widget.view.blocks,
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

  List<Widget> _informationWidgets(
    List<FlarePluginField> fields,
    List<FlarePluginBlock> blocks,
    FlareColors colors,
    FlareStrings strings, {
    bool showError = false,
  }) => [
    if (fields.isNotEmpty || blocks.isNotEmpty) ...[
      Semantics(
        header: true,
        button: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
          child: InkWell(
            key: const ValueKey('flare-account-information'),
            onTap: () => setState(() => _information = !_information),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: FlareSizes.spacingMd,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _hasCopy('informationTitle')
                          ? _presentation['informationTitle'] as String
                          : strings.accountInformation,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                  FlareIcon(
                    _information ? 'chevron-up' : 'chevron-down',
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      if (_information)
        _actions(
          _projection(
            fields: [
              for (final field in fields)
                FlarePluginField(
                  label: field.label,
                  value: _hidden ? '••••' : field.value,
                ),
            ],
            blocks: blocks,
          ),
          showError: showError,
        ),
    ],
  ];

  Widget _walletCard(
    FlareAccountEntry entry,
    FlareColors colors,
    FlareStrings strings,
  ) {
    final title = entry.row.cells.elementAtOrNull(1)?.text ?? entry.title;
    final entryAction = _entryAction(entry);
    final metadata = [
      for (var i = 2; i < entry.row.cells.length; i++)
        if (entry.row.cells[i].text.isNotEmpty ||
            entry.row.cells[i].timeMs != null)
          i,
    ];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('account-entry:${entry.id}'),
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        onTap: widget.busyActionId == null
            ? () => _activateEntry(entry.id)
            : null,
        child: _surface(
          Column(
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
              Text(
                entry.block.columns.firstOrNull?.label ?? '',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: FlareSizes.fontSizeSm,
                ),
              ),
              const SizedBox(height: FlareSizes.spacingXs),
              Semantics(
                excludeSemantics: true,
                label: _hidden ? strings.accountBalanceHidden : entry.amount,
                child: Text(
                  _hidden ? '••••' : entry.amount,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: FlareSizes.fontSize5xl,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (metadata.isNotEmpty) ...[
                const SizedBox(height: FlareSizes.spacingSm),
                LayoutBuilder(
                  builder: (context, bounds) {
                    final columns = metadata.length > 1 ? 2 : 1;
                    final width =
                        (bounds.maxWidth -
                            FlareSizes.spacingMd * (columns - 1)) /
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
                                  entry.block.columns
                                          .elementAtOrNull(i)
                                          ?.label ??
                                      '',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: FlareSizes.fontSizeSm,
                                  ),
                                ),
                                const SizedBox(height: FlareSizes.spacingXs),
                                Text(
                                  _hidden
                                      ? '••••'
                                      : entry.block.columns
                                                    .elementAtOrNull(i)
                                                    ?.format ==
                                                FlarePluginColumnFormat.time &&
                                            entry.row.cells[i].timeMs != null
                                      ? flarePluginDateTime(
                                          entry.row.cells[i].timeMs!,
                                          flarePluginNowMs(),
                                          strings,
                                        )
                                      : entry.row.cells[i].text,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: FlareSizes.fontSizeLg,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
              if (entryAction != null) ...[
                const SizedBox(height: FlareSizes.spacingSm),
                Divider(height: 1, color: colors.borderSecondary),
                Padding(
                  padding: const EdgeInsets.only(top: FlareSizes.spacingSm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entryAction.action.label,
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: FlareSizes.fontSizeSm,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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
          ),
          colors,
          outlined: true,
        ),
      ),
    );
  }

  Widget _wallet(FlareColors colors, FlareStrings strings) {
    final entries = flareAccountEntries(widget.view);
    final primary = _boundActions(const ['primary', 'secondary', 'tertiary']);
    final shortcuts = _boundActions(const [
      'shortcutPrimary',
      'shortcutSecondary',
      'shortcutTertiary',
    ]).where((action) => !primary.any((p) => p.id == action.id)).toList();
    final services = _allActions
        .where(
          (a) =>
              !primary.any((p) => p.id == a.id) &&
              !shortcuts.any((s) => s.id == a.id),
        )
        .toList();
    final urgent = widget.view.blocks.where(_urgent).toList();
    final information = widget.view.blocks
        .where((b) => b is! FlarePluginRowsBlock && !urgent.contains(b))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entries.isEmpty)
          _walletSummary(primary, colors, strings, showDescription: false)
        else ...[
          Column(
            key: const ValueKey('flare-account-summary'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.start,
                spacing: FlareSizes.spacingMd,
                overflowSpacing: FlareSizes.spacingMd,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      _hasCopy('sectionTitle')
                          ? _presentation['sectionTitle'] as String
                          : _hasCopy('summaryTitle')
                          ? _presentation['summaryTitle'] as String
                          : widget.view.title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: FlareSizes.fontSizeXl,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: FlareSizes.spacingSm,
                    runSpacing: FlareSizes.spacingSm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (primary.isNotEmpty)
                        _actions(
                          _projection(actions: primary),
                          layout: FlarePluginActionLayout.compact,
                          showError: false,
                        ),
                      FlareIconButton(
                        icon: _hidden ? 'eye-off' : 'eye',
                        semanticLabel: _hidden
                            ? strings.accountShowBalance
                            : strings.accountHideBalance,
                        onPressed: () => setState(() => _hidden = !_hidden),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
        if (urgent.isNotEmpty) ...[
          const SizedBox(height: FlareSizes.spacingMd),
          _actions(_projection(blocks: urgent), showError: false),
        ],
        if (widget.error?.isNotEmpty ?? false) ...[
          const SizedBox(height: FlareSizes.spacingMd),
          FlareStatusBanner(text: widget.error!, tone: FlareStatusTone.danger),
        ],
        if (entries.isNotEmpty) ...[
          const SizedBox(height: FlareSizes.spacingMd),
          LayoutBuilder(
            builder: (context, bounds) {
              final columns =
                  entries.length > 1 &&
                      bounds.maxWidth >=
                          FlareSizes.primaryPaneMinWidth * 2 +
                              FlareSizes.spacingMd
                  ? 2
                  : 1;
              final width =
                  (bounds.maxWidth - FlareSizes.spacingMd * (columns - 1)) /
                  columns;
              return Wrap(
                spacing: FlareSizes.spacingMd,
                runSpacing: FlareSizes.spacingMd,
                children: [
                  for (final entry in entries)
                    SizedBox(
                      width: width,
                      child: _walletCard(entry, colors, strings),
                    ),
                ],
              );
            },
          ),
        ] else
          FlareEmptyState(
            title: _hasCopy('emptyTitle')
                ? _presentation['emptyTitle'] as String
                : strings.accountEmpty,
            description: _hasCopy('emptyDescription')
                ? _presentation['emptyDescription'] as String
                : strings.accountEmptyDescription,
            icon: 'wallet',
          ),
        if (shortcuts.isNotEmpty) _shortcuts(shortcuts, colors),
        ..._informationWidgets(
          widget.view.fields,
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
    if (widget.view.available &&
        !flarePluginReadOnly(widget.view) &&
        widget.onAction != null &&
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
      widget.view,
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
          widget.view,
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
                              : entry.amount,
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

  @override
  Widget build(BuildContext context) {
    if (!widget.view.available) return _actions(widget.view);
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final layout = _presentation['layout'];
    if (layout == 'flow') return _flow(colors);
    if (layout == 'wallet') return _wallet(colors, strings);
    final structured = layout == 'ledger';
    final primary = _boundActions(const ['primary', 'secondary', 'tertiary']);
    final services = _allActions
        .where((action) => !primary.any((a) => a.id == action.id))
        .toList();
    final entries = flareAccountEntries(widget.view);
    final presentation = widget.view.presentation?['props'] is Map
        ? widget.view.presentation!['props'] as Map
        : const {};
    final urgent = widget.view.blocks
        .where(
          (b) => structured
              ? _urgent(b)
              : b is FlarePluginNoteBlock &&
                    (b.tone == FlarePluginTone.warning ||
                        b.tone == FlarePluginTone.danger),
        )
        .toList();
    final information = widget.view.blocks
        .where((b) => b is! FlarePluginRowsBlock && !urgent.contains(b))
        .toList();
    final groups = <({String label, List<FlareAccountEntry> entries})>[];
    for (final entry in entries) {
      final label = _day(entry, strings);
      if (groups.isEmpty || groups.last.label != label)
        groups.add((label: label, entries: []));
      groups.last.entries.add(entry);
    }
    final fields = widget.view.fields;
    final hasSummary =
        structured &&
        (layout != 'ledger' || fields.isNotEmpty || primary.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        if (structured && urgent.isNotEmpty) ...[
          _actions(_projection(blocks: urgent), showError: false),
          const SizedBox(height: FlareSizes.spacingMd),
        ],
        if (hasSummary)
          _walletSummary(primary, colors, strings, showDescription: false)
        else if (fields.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(FlareSizes.spacingLg),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fields.first.label,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    FlareIconButton(
                      icon: _hidden ? 'eye-off' : 'eye',
                      semanticLabel: _hidden
                          ? strings.accountShowBalance
                          : strings.accountHideBalance,
                      onPressed: () => setState(() => _hidden = !_hidden),
                    ),
                  ],
                ),
                Semantics(
                  label: _hidden
                      ? strings.accountBalanceHidden
                      : fields.first.value,
                  excludeSemantics: true,
                  child: Text(
                    _hidden ? '••••' : fields.first.value,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.componentRedPacketAmountFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (fields.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: FlareSizes.spacingLg),
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
                                _hidden ? '••••' : field.value,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (!structured && urgent.isNotEmpty) ...[
          _actions(_projection(blocks: urgent), showError: !structured),
        ],
        if (!structured)
          _actions(
            _projection(
              actions: [...widget.view.actions, ...widget.view.menuActions],
            ),
          ),
        if (fields.isNotEmpty || presentation['sectionTitle'] is String)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingMd),
            child: Semantics(
              header: true,
              child: Text(
                (widget.view.presentation?['props'] is Map &&
                        (widget.view.presentation!['props']
                                as Map)['sectionTitle']
                            is String)
                    ? (widget.view.presentation!['props']
                              as Map)['sectionTitle']
                          as String
                    : strings.accountTransactions,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: FlareSizes.fontSize3xl,
                ),
              ),
            ),
          ),
        if (entries.isEmpty)
          FlareEmptyState(
            title: presentation['emptyTitle'] is String
                ? presentation['emptyTitle'] as String
                : strings.accountEmpty,
            description: presentation['emptyDescription'] is String
                ? presentation['emptyDescription'] as String
                : strings.accountEmptyDescription,
            icon: 'wallet',
          ),
        for (final group in groups) ...[
          if (presentation['groupByDate'] != false)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: FlareSizes.spacingSm,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  group.label,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: FlareSizes.fontSizeSm,
                  ),
                ),
              ),
            ),
          for (final entry in group.entries)
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('account-entry:${entry.id}'),
                onTap: widget.busyActionId == null
                    ? () => _activateEntry(entry.id)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: FlareSizes.spacingMd,
                  ),
                  child: LayoutBuilder(
                    builder: (context, bounds) => Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(FlareSizes.spacingSm),
                          decoration: BoxDecoration(
                            color: colors.bgSecondary,
                            borderRadius: BorderRadius.circular(
                              FlareSizes.radiusMd,
                            ),
                          ),
                          child: FlareIcon(
                            'wallet',
                            color: entry.amount.startsWith('+')
                                ? colors.successText
                                : colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: FlareSizes.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (entry.separateBadge &&
                                  entry.row.badge != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: FlareSizes.spacing2xs,
                                  ),
                                  child: FlareTag(
                                    key: ValueKey(
                                      'account-entry-badge:${entry.id}',
                                    ),
                                    label: entry.row.badge!.text,
                                    tone: FlareStatusTone.values.byName(
                                      entry.row.badge!.tone.name,
                                    ),
                                  ),
                                ),
                              if (entry.subtitle.isNotEmpty)
                                Text(
                                  entry.subtitle,
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
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: bounds.maxWidth * 0.42,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _hidden &&
                                        presentation['maskRowAmounts'] == true
                                    ? '••••'
                                    : entry.amount,
                                style: TextStyle(
                                  color: entry.amount.startsWith('+')
                                      ? colors.successText
                                      : colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _time(entry),
                                style: TextStyle(
                                  color: colors.textTertiary,
                                  fontSize: FlareSizes.fontSizeSm,
                                ),
                              ),
                            ],
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
            ),
        ],
        ..._informationWidgets(
          structured ? fields.skip(1).toList() : const [],
          information,
          colors,
          strings,
          showError: !structured,
        ),
        if (structured && services.isNotEmpty) _services(services, colors),
        if (structured && (widget.error?.isNotEmpty ?? false)) ...[
          const SizedBox(height: FlareSizes.spacingMd),
          FlareStatusBanner(text: widget.error!, tone: FlareStatusTone.danger),
        ],
      ],
    );
  }
}
