import 'dart:async';

import 'package:flutter/material.dart';

import '../models/capability_ui.dart';
import '../models/contact_picker.dart';
import '../models/directory_data.dart'
    show FlareButtonVariant, FlareControlSize;
import '../models/plugin_view.dart';
import '../models/red_packet.dart';
import '../models/red_packet_page.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_contact_picker.dart';
import 'flare_plugin_view.dart';
import 'flare_red_packet_composer.dart';
import 'flare_red_packet_detail.dart';
import 'flare_red_packet_open_sheet.dart';
import 'flare_red_packet_review.dart';
import 'flare_status_banner.dart';

/// A plugin page drawn by the kit's red packet components (docs/plugin-experience.md
/// §4, §11 「从 + 到详情都是红包版式」): `FlarePluginPage` draws it for a view whose
/// presentation renderer is `redPacket.compose` ([FlareRedPacketComposer], sends
/// the bound submit with the form values), `redPacket.review`
/// ([FlareRedPacketReview], the send confirmation) or `redPacket.detail`
/// ([FlareRedPacketDetail] with [FlareRedPacketOpenSheet] over it while the bound
/// claim is offered). Which page it is comes from the renderer, never the plugin
/// id ([flareRedPacketComposePlan], [flareRedPacketDetailPlan]); the actions the
/// page does not run itself (cancel, recovery) draw below as the generic list.
///
/// Actions go out through [onAction] like any page action; the host settles
/// them and, on success, the page re-reads (R4): a claimed packet's claim goes,
/// so the sheet closes onto the details.
class FlareRedPacketPage extends StatefulWidget {
  const FlareRedPacketPage({
    super.key,
    required this.view,
    this.busyActionId,
    this.refreshing = false,
    this.error,
    this.formErrors = const [],
    this.settleToken = 0,
    this.members = const [],
    this.memberCount,
    this.membersLoading = false,
    this.membersError,
    this.membersRevision = 0,
    this.onMemberSearch,
    this.onMembersRetry,
    this.resolveUser,
    this.viewerId,
    this.nowMs,
    this.onAction,
    this.onRefresh,
    this.onBack,
  });

  final FlarePluginViewModel view;
  final String? busyActionId;
  final bool refreshing;

  /// The settled action's failure.
  final String? error;
  final List<FlarePluginFormError> formErrors;
  final int settleToken;

  /// Who an exclusive packet may go to; also names the people shown.
  final List<FlarePluginMember> members;

  /// The group's size counting the viewer, from the host's own group or
  /// conversation data (never the length of [members]).
  final int? memberCount;
  final bool membersLoading;
  final String? membersError;
  final int membersRevision;
  final ValueChanged<String>? onMemberSearch;
  final VoidCallback? onMembersRetry;
  final FlarePluginResolveUser? resolveUser;
  final String? viewerId;

  /// The details' clock (tests); null reads the plugin view clock.
  final int? nowMs;
  final FlarePluginActionCallback? onAction;

  /// Read the page again (after a claim whose outcome is unknown).
  final VoidCallback? onRefresh;

  /// Close the page (the open sheet's close key).
  final VoidCallback? onBack;

  /// The details' claim key, shown once the sheet was set aside (tests).
  static const Key claimKey = ValueKey('flare-red-packet-page-claim');

  /// The exclusive recipient key (tests).
  static const Key recipientKey = ValueKey('flare-red-packet-page-recipient');

  @override
  State<FlareRedPacketPage> createState() => _FlareRedPacketPageState();
}

typedef _Issue = ({FlareRedPacketField field, String text});

class _FlareRedPacketPageState extends State<FlareRedPacketPage> {
  // Compose.
  FlareRedPacketKind _kind = FlareRedPacketKind.normal;
  String _amount = '';
  int _count = 1;
  String _greeting = '';
  FlarePluginMember? _recipient;
  bool _attempted = false;
  bool _hostErrors = true;
  FlareRedPacketField? _focus;
  final _memberRevision = ValueNotifier(0);
  // Detail.
  bool _dismissed = false;
  Map<String, FlarePluginUser> _people = const {};
  String _peopleKey = '';
  int _peopleEpoch = 0;
  // Always on: the overlay child is empty until the sheet opens.
  final _sheet = OverlayPortalController()..show();

  FlareRedPacketComposePlan? get _compose =>
      flareRedPacketComposePlan(widget.view);
  FlareRedPacketDetailPlan? get _detail =>
      flareRedPacketDetailPlan(widget.view);
  bool get _busy => widget.busyActionId != null || widget.refreshing;

  @override
  void initState() {
    super.initState();
    _reset();
    _resolvePeople();
  }

  @override
  void didUpdateWidget(FlareRedPacketPage old) {
    super.didUpdateWidget(old);
    final before = flareRedPacketComposePlan(old.view)?.action.id;
    if (_compose?.action.id != before) _reset();
    if (old.membersRevision != widget.membersRevision) _recipient = null;
    if (old.settleToken != widget.settleToken) _hostErrors = true;
    if (!identical(old.members, widget.members) ||
        old.membersLoading != widget.membersLoading ||
        old.membersRevision != widget.membersRevision ||
        old.membersError != widget.membersError) {
      // The open picker reads current props.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _memberRevision.value++;
      });
    }
    _resolvePeople();
  }

  @override
  void dispose() {
    _peopleEpoch++;
    _memberRevision.dispose();
    super.dispose();
  }

  void _reset() {
    final plan = _compose;
    _kind = plan?.kinds.first ?? FlareRedPacketKind.normal;
    _amount = '';
    _count = 1;
    _greeting = plan?.greetingDefault ?? '';
    _recipient = null;
    _attempted = false;
    _focus = null;
  }

  void _edit(VoidCallback change) => setState(() {
    change();
    _hostErrors = false;
  });

  // ── compose ───────────────────────────────────────────────────────────────

  String? _totalMinor(FlareRedPacketComposePlan plan) {
    final minor = flareRedPacketAmountMinor(_amount, plan.scale);
    if (minor == null) return null;
    if (_kind != FlareRedPacketKind.normal || plan.kinds.length == 1) {
      return minor;
    }
    return (BigInt.parse(minor) * BigInt.from(_count > 0 ? _count : 0))
        .toString();
  }

  Map<String, Object?> _draft(FlareRedPacketComposePlan plan) {
    final greeting = _greeting.trim();
    return {
      'kind': _kind.name,
      'amount': _amount,
      'shareCount':
          _kind == FlareRedPacketKind.exclusive || plan.kinds.length == 1
          ? 1
          : _count,
      'greeting': greeting.isEmpty ? plan.greetingDefault : _greeting,
      'designatedUserIds': [?_recipient?.userId],
    };
  }

  static FlareRedPacketField _fieldFor(String input) => switch (input) {
    'amount' => FlareRedPacketField.amount,
    'shareCount' => FlareRedPacketField.count,
    'greeting' => FlareRedPacketField.greeting,
    'designatedUserIds' => FlareRedPacketField.recipient,
    _ => FlareRedPacketField.form,
  };

  String _issueText(
    FlareRedPacketComposePlan plan,
    FlarePluginFormIssue issue,
    String inputId,
    FlareStrings strings,
  ) {
    // §4.2: a missing exclusive recipient reads 请选择发给谁, not "<label>: 必填" (as Vue, Compose).
    if (_fieldFor(inputId) == FlareRedPacketField.recipient &&
        (issue == FlarePluginFormIssue.required ||
            issue == FlarePluginFormIssue.tooFewItems)) {
      return strings.packetChooseRecipient;
    }
    final input = plan.inputs.where((i) => i.id == inputId).firstOrNull;
    final text = flarePluginIssueText(issue, input, strings);
    return input == null ? text : '${input.label}: $text';
  }

  String _rangeText(FlareRedPacketComposePlan plan, FlareStrings strings) {
    final rules = plan.money.money;
    return strings.pluginFormMoneyRange
        .replaceAll('{min}', rules?.min ?? '')
        .replaceAll('{max}', rules?.max ?? '')
        .replaceAll('{currency}', plan.currency);
  }

  _Issue? _validation(FlareRedPacketComposePlan plan, FlareStrings strings) {
    final draft = _draft(plan);
    for (final input in flarePluginVisibleInputs(plan.inputs, draft)) {
      final value = draft[input.id];
      final count =
          input.id == 'shareCount' && input.kind == FlarePluginInputKind.number;
      if (count && value is int) {
        final limits = [
          if (input.max case final max? when max > 0) max.toInt(),
          ?plan.maxRecipients,
        ];
        if (limits.isNotEmpty) {
          final max = limits.reduce((a, b) => a < b ? a : b);
          if (value > max) {
            return (
              field: FlareRedPacketField.count,
              text: strings.packetCountLimit.replaceAll('{n}', '$max'),
            );
          }
        }
      }
      // The composer's empty count is 0; the generic check only asks for a
      // number, so the declared range is checked here before any payment.
      final issue = count
          ? (value is! int || value <= 0
                ? FlarePluginFormIssue.required
                : (input.min != null && value < input.min!) ||
                      (input.max != null && value > input.max!)
                ? FlarePluginFormIssue.outOfRange
                : null)
          : flarePluginCheckInput(input, value);
      if (issue == null) continue;
      if (input.kind == FlarePluginInputKind.money &&
          input.money?.min != null &&
          input.money?.max != null) {
        return (field: _fieldFor(input.id), text: _rangeText(plan, strings));
      }
      return (
        field: _fieldFor(input.id),
        text: _issueText(plan, issue, input.id, strings),
      );
    }
    final max = plan.money.money?.max;
    final maxMinor = max == null
        ? null
        : flareRedPacketAmountMinor(max, plan.scale);
    final total = _totalMinor(plan);
    if (total != null &&
        maxMinor != null &&
        BigInt.parse(total) > BigInt.parse(maxMinor)) {
      return (
        field: FlareRedPacketField.amount,
        text: '${strings.packetFieldTotal}: ${_rangeText(plan, strings)}',
      );
    }
    return null;
  }

  _Issue? _shownIssue(FlareRedPacketComposePlan plan, FlareStrings strings) {
    final error = widget.error;
    if (error != null && error.isNotEmpty) {
      return (field: FlareRedPacketField.form, text: error);
    }
    if (_hostErrors && widget.formErrors.isNotEmpty) {
      final first = widget.formErrors.first;
      return (
        field: _fieldFor(first.input),
        text: _issueText(plan, first.issue, first.input, strings),
      );
    }
    return _attempted ? _validation(plan, strings) : null;
  }

  void _submit(FlareRedPacketComposePlan plan, FlareStrings strings) {
    if (_busy) return;
    final issue = _validation(plan, strings);
    setState(() {
      _attempted = true;
      if (issue != null && issue.field != FlareRedPacketField.form) {
        _focus = issue.field;
      }
    });
    if (issue != null) return;
    widget.onAction?.call(
      plan.action.id,
      FlarePluginActionPayload(
        formValues: flarePluginFormValues(plan.inputs, _draft(plan)),
      ),
    );
  }

  Future<void> _pickRecipient(FlareStrings strings) async {
    if (_busy) return;
    final revision = widget.membersRevision;
    widget.onMemberSearch?.call('');
    final picked = await FlareBottomSheet.show<List<FlareContactPickerEntry>>(
      context,
      title: strings.packetFieldRecipient,
      fill: true,
      listenable: _memberRevision,
      builder: (sheetContext) => FlareContactPicker(
        groups: [
          FlareContactPickerGroup(
            id: 'members',
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
        title: strings.packetFieldRecipient,
        loading: widget.membersLoading,
        error: widget.membersError,
        onSearch: widget.onMemberSearch,
        onRetry: widget.onMembersRetry,
        onSelect: (chosen) => Navigator.of(sheetContext).pop(chosen),
        onCancel: () => Navigator.of(sheetContext).pop(),
      ),
    );
    final entry = picked?.firstOrNull;
    if (entry == null || !mounted || revision != widget.membersRevision) return;
    _edit(
      () => _recipient = FlarePluginMember(
        userId: entry.userId,
        name: entry.name,
        avatarUrl: entry.avatarUrl,
      ),
    );
  }

  Widget _composer(FlareRedPacketComposePlan plan, FlareStrings strings) {
    final issue = _shownIssue(plan, strings);
    final total =
        flareRedPacketMoney(
          _totalMinor(plan) ?? '0',
          plan.scale,
          plan.currency,
        ) ??
        '';
    final symbol = flareRedPacketCurrencySymbols[plan.currency.toUpperCase()];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?_notes(),
        FlareRedPacketComposer(
          kinds: plan.kinds,
          kind: _kind,
          amount: _amount,
          currencyExponent: plan.scale,
          currencySymbol: symbol,
          count: _count,
          greeting: _greeting,
          // A group's head count under the count row (packetGroupMembers).
          memberCount: plan.kinds.length > 1 ? widget.memberCount : null,
          total: total,
          busy: _busy,
          error: issue?.text,
          errorField: issue?.field,
          focusField: _focus,
          submitLabel: plan.action.label.isEmpty ? null : plan.action.label,
          recipient: FlareButton(
            key: FlareRedPacketPage.recipientKey,
            label: _recipient?.name ?? strings.select,
            size: FlareControlSize.sm,
            variant: FlareButtonVariant.text,
            disabled: _busy,
            onPressed: () => unawaited(_pickRecipient(strings)),
          ),
          onKindChange: (kind) => _edit(() => _kind = kind),
          onAmountChange: (amount) => _edit(() => _amount = amount),
          onCountChange: (count) => _edit(() => _count = count),
          onGreetingChange: (greeting) => _edit(() => _greeting = greeting),
          onSubmit: () => _submit(plan, strings),
        ),
      ],
    );
  }

  /// The plugin's own warnings (a danger or warning note) above the page.
  Widget? _notes() {
    final notes = [
      for (final block in widget.view.blocks)
        if (block is FlarePluginNoteBlock &&
            (block.tone == FlarePluginTone.danger ||
                block.tone == FlarePluginTone.warning))
          block,
    ];
    return notes.isEmpty
        ? null
        : FlarePluginView(
            view: FlarePluginViewModel(
              available: true,
              title: '',
              blocks: notes,
            ),
            embedded: true,
            showError: false,
          );
  }

  // ── review ────────────────────────────────────────────────────────────────

  Widget _review(FlareRedPacketReviewPlan plan, FlareStrings strings) {
    final kind = switch (plan.kind) {
      FlareRedPacketKind.lucky => strings.packetKindLucky,
      FlareRedPacketKind.normal => strings.packetKindNormal,
      FlareRedPacketKind.exclusive => strings.packetKindExclusive,
      null => null,
    };
    final shares = plan.shareCount;
    final kindLabel =
        plan.kindLabel ??
        (kind == null
            ? null
            : shares == null
            ? kind
            : '$kind · ${'$shares ${strings.packetCountUnit}'.trim()}');
    final error = widget.error ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?_notes(),
        FlareRedPacketReview(
          amount:
              flarePaymentAmountText(plan.amount, plan.currency ?? '') ??
              plan.amount,
          kindLabel: kindLabel,
          blessing: plan.blessing,
          submitLabel: plan.action.label.isEmpty ? null : plan.action.label,
          busy: _busy,
          error: error.isEmpty ? null : error,
          onSubmit: () {
            if (!_busy) {
              widget.onAction?.call(
                plan.action.id,
                const FlarePluginActionPayload(),
              );
            }
          },
        ),
      ],
    );
  }

  // ── detail ────────────────────────────────────────────────────────────────

  void _resolvePeople() {
    final plan = _detail;
    if (plan == null) return;
    final ids = <String>{
      if (plan.senderId.isNotEmpty) plan.senderId,
      for (final claim in plan.claims) claim.id,
      ...plan.designatedUserIds,
    };
    final key = ids.join('\u0000');
    if (key == _peopleKey) return;
    _peopleKey = key;
    final epoch = ++_peopleEpoch;
    unawaited(() async {
      final found = <String, FlarePluginUser>{};
      for (final id in ids) {
        final local = widget.members.where((m) => m.userId == id).firstOrNull;
        if (local != null) {
          found[id] = FlarePluginUser(
            name: local.name,
            avatarUrl: local.avatarUrl,
          );
          continue;
        }
        try {
          final user = await widget.resolveUser?.call(id);
          if (user != null) found[id] = user;
        } catch (_) {
          // An unknown name reads as the kit's unknown user.
        }
      }
      if (mounted && epoch == _peopleEpoch) setState(() => _people = found);
    }());
  }

  String _name(String id, FlareStrings strings) =>
      _people[id]?.name ?? strings.displayNameUnknownUser;

  void _claim(FlarePluginAction action) {
    if (!_busy)
      widget.onAction?.call(action.id, const FlarePluginActionPayload());
  }

  void _reviewDetails() {
    setState(() => _dismissed = true);
    if ((widget.error ?? '').isNotEmpty && !_busy) widget.onRefresh?.call();
  }

  Widget _details(FlareRedPacketDetailPlan plan, FlareStrings strings) {
    final details = plan.details;
    final error = widget.error ?? '';
    final claim = plan.claimAction;
    final wallet = plan.walletAction;
    final sender = _people[plan.senderId];
    final designated = plan.designatedUserIds.firstOrNull;
    final open = claim != null && !_dismissed;
    final kindLabel = switch (details.kind) {
      FlareRedPacketKind.lucky => strings.packetKindLucky,
      FlareRedPacketKind.normal => strings.packetKindNormal,
      FlareRedPacketKind.exclusive => strings.packetKindExclusive,
    };
    return OverlayPortal(
      controller: _sheet,
      overlayChildBuilder: (_) => !open
          ? const SizedBox.shrink()
          : Positioned.fill(
              child: FlareRedPacketOpenSheet(
                senderName: _name(plan.senderId, strings),
                senderAvatar: sender?.avatarUrl,
                blessing: details.greeting,
                kindLabel: kindLabel,
                state: _busy
                    ? FlareRedPacketOpenState.opening
                    : error.isNotEmpty
                    ? FlareRedPacketOpenState.error
                    : FlareRedPacketOpenState.ready,
                message: error.isEmpty ? null : error,
                reviewOnError: widget.onRefresh != null,
                onOpen: () => _claim(claim),
                onViewDetails: _reviewDetails,
                onClose: widget.onBack,
              ),
            ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error.isNotEmpty) ...[
            FlareStatusBanner(
              text: plan.paidClaimPending
                  ? strings.packetClaimPendingReview
                  : error,
              tone: plan.paidClaimPending
                  ? FlareStatusTone.warning
                  : FlareStatusTone.danger,
            ),
            const SizedBox(height: FlareSizes.spacingMd),
          ],
          FlareRedPacketDetail(
            senderName: _name(plan.senderId, strings),
            senderAvatar: sender?.avatarUrl,
            details: details,
            designatedName: designated == null
                ? null
                : _people[designated]?.name,
            claims: [
              for (final row in plan.claims)
                FlareRedPacketClaim(
                  id: row.id,
                  name: _name(row.id, strings),
                  avatar: _people[row.id]?.avatarUrl,
                  amountMinor: row.amountMinor,
                  claimedAtMs: row.claimedAtMs,
                  best: row.best,
                ),
            ],
            nowMs: widget.nowMs,
            onDeposited: wallet == null || _busy
                ? null
                : () => widget.onAction?.call(
                    wallet.id,
                    const FlarePluginActionPayload(),
                  ),
          ),
          if (claim != null && _dismissed) ...[
            const SizedBox(height: FlareSizes.spacingLg),
            FlareButton(
              key: FlareRedPacketPage.claimKey,
              label: claim.label,
              block: true,
              loading: _busy,
              onPressed: () => setState(() => _dismissed = false),
            ),
          ],
        ],
      ),
    );
  }

  /// The actions this page does not run itself, as the generic list.
  Widget? _rest(List<String> owned) {
    final view = widget.view;
    final actions = view.actions.where((a) => !owned.contains(a.id)).toList();
    final menu = view.menuActions.where((a) => !owned.contains(a.id)).toList();
    if (actions.isEmpty && menu.isEmpty) return null;
    return FlarePluginView(
      view: FlarePluginViewModel(
        available: view.available,
        title: '',
        actions: actions,
        menuActions: menu,
        inputs: view.inputs,
        unavailableReason: view.unavailableReason,
      ),
      embedded: true,
      actionLayout: FlarePluginActionLayout.list,
      showError: false,
      busyActionId: widget.busyActionId,
      formErrors: widget.formErrors,
      settleToken: widget.settleToken,
      resolveUser: widget.resolveUser,
      viewerId: widget.viewerId,
      members: widget.members,
      membersLoading: widget.membersLoading,
      membersRevision: widget.membersRevision,
      membersError: widget.membersError,
      onMemberSearch: widget.onMemberSearch,
      onMembersRetry: widget.onMembersRetry,
      onAction: widget.onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final compose = _compose;
    final review = compose == null
        ? flareRedPacketReviewPlan(widget.view)
        : null;
    final detail = compose == null && review == null ? _detail : null;
    final Widget body;
    final List<String> owned;
    if (compose != null) {
      body = _composer(compose, strings);
      owned = [compose.action.id];
    } else if (review != null) {
      body = _review(review, strings);
      owned = review.ownedActionIds;
    } else if (detail != null) {
      body = _details(detail, strings);
      owned = detail.ownedActionIds;
    } else {
      // Not a red packet page: the host draws the generic document instead.
      return const SizedBox.shrink();
    }
    final rest = _rest(owned);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        if (rest != null) ...[
          const SizedBox(height: FlareSizes.spacingLg),
          rest,
        ],
      ],
    );
  }
}
