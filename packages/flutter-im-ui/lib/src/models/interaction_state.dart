import 'message_lifecycle.dart';
import '../components/flare_transfer_progress.dart';

enum FlareComposerInteractionMode {
  idle,
  typing,
  mentioning,
  replying,
  editing,
  uploading,
  recording,
  sending,
  sendBlocked,
  offline,
  readOnly,
  slowMode,
  permissionDenied,
}

enum FlareComposerInteractionAction {
  type,
  send,
  newline,
  attach,
  mention,
  reply,
  edit,
  record,
  cancel,
  retry,
}

class FlareComposerInteractionInput {
  const FlareComposerInteractionInput({
    this.hasText = false,
    this.mentioning = false,
    this.replying = false,
    this.editing = false,
    this.uploading = false,
    this.recording = false,
    this.sending = false,
    this.sendBlocked = false,
    this.online = true,
    this.readOnly = false,
    this.slowMode = false,
    this.permissionGranted = true,
  });
  final bool hasText, mentioning, replying, editing, uploading, recording;
  final bool sending,
      sendBlocked,
      online,
      readOnly,
      slowMode,
      permissionGranted;
}

FlareComposerInteractionMode resolveComposerMode(
  FlareComposerInteractionInput input,
) {
  if (input.readOnly) return FlareComposerInteractionMode.readOnly;
  if (!input.permissionGranted)
    return FlareComposerInteractionMode.permissionDenied;
  if (!input.online) return FlareComposerInteractionMode.offline;
  if (input.slowMode) return FlareComposerInteractionMode.slowMode;
  if (input.sendBlocked) return FlareComposerInteractionMode.sendBlocked;
  if (input.sending) return FlareComposerInteractionMode.sending;
  if (input.recording) return FlareComposerInteractionMode.recording;
  if (input.uploading) return FlareComposerInteractionMode.uploading;
  if (input.editing) return FlareComposerInteractionMode.editing;
  if (input.mentioning) return FlareComposerInteractionMode.mentioning;
  if (input.replying) return FlareComposerInteractionMode.replying;
  return input.hasText
      ? FlareComposerInteractionMode.typing
      : FlareComposerInteractionMode.idle;
}

Set<FlareComposerInteractionAction> composerAllowedActions(
  FlareComposerInteractionMode mode,
) {
  const base = {
    FlareComposerInteractionAction.type,
    FlareComposerInteractionAction.send,
    FlareComposerInteractionAction.newline,
    FlareComposerInteractionAction.attach,
    FlareComposerInteractionAction.mention,
    FlareComposerInteractionAction.reply,
    FlareComposerInteractionAction.edit,
    FlareComposerInteractionAction.record,
  };
  return switch (mode) {
    FlareComposerInteractionMode.readOnly => const {},
    FlareComposerInteractionMode.permissionDenied => const {
      FlareComposerInteractionAction.cancel,
    },
    FlareComposerInteractionMode.offline => const {
      FlareComposerInteractionAction.type,
      FlareComposerInteractionAction.newline,
      FlareComposerInteractionAction.attach,
      FlareComposerInteractionAction.cancel,
      FlareComposerInteractionAction.retry,
    },
    FlareComposerInteractionMode.slowMode ||
    FlareComposerInteractionMode.sendBlocked => const {
      FlareComposerInteractionAction.type,
      FlareComposerInteractionAction.newline,
      FlareComposerInteractionAction.attach,
      FlareComposerInteractionAction.mention,
      FlareComposerInteractionAction.cancel,
    },
    FlareComposerInteractionMode.sending => const {
      FlareComposerInteractionAction.cancel,
    },
    FlareComposerInteractionMode.recording => const {
      FlareComposerInteractionAction.send,
      FlareComposerInteractionAction.cancel,
    },
    FlareComposerInteractionMode.uploading => const {
      FlareComposerInteractionAction.type,
      FlareComposerInteractionAction.newline,
      FlareComposerInteractionAction.attach,
      FlareComposerInteractionAction.cancel,
    },
    FlareComposerInteractionMode.editing ||
    FlareComposerInteractionMode.mentioning ||
    FlareComposerInteractionMode.replying => const {
      FlareComposerInteractionAction.type,
      FlareComposerInteractionAction.newline,
      FlareComposerInteractionAction.send,
      FlareComposerInteractionAction.attach,
      FlareComposerInteractionAction.mention,
      FlareComposerInteractionAction.cancel,
    },
    _ => base,
  };
}

enum FlareMessageInteractionMode {
  normal,
  hover,
  selected,
  multiSelected,
  sending,
  sent,
  delivered,
  read,
  failed,
  retrying,
  edited,
  recalled,
  deleted,
  ephemeral,
  expired,
}

FlareMessageInteractionMode resolveMessageMode(
  FlareMessageLifecycle lifecycle, {
  bool hovered = false,
  bool selected = false,
  bool multiSelect = false,
  bool retrying = false,
}) {
  if (lifecycle.mutation == FlareMessageMutationState.deleted)
    return FlareMessageInteractionMode.deleted;
  if (lifecycle.ephemeral == FlareMessageEphemeralState.expired)
    return FlareMessageInteractionMode.expired;
  if (lifecycle.mutation == FlareMessageMutationState.recalled)
    return FlareMessageInteractionMode.recalled;
  if (retrying) return FlareMessageInteractionMode.retrying;
  if (lifecycle.send == FlareMessageSendState.failed ||
      lifecycle.transfer == FlareTransferState.failed)
    return FlareMessageInteractionMode.failed;
  if (lifecycle.ephemeral != FlareMessageEphemeralState.none)
    return FlareMessageInteractionMode.ephemeral;
  if (lifecycle.mutation == FlareMessageMutationState.edited)
    return FlareMessageInteractionMode.edited;
  if (multiSelect && selected) return FlareMessageInteractionMode.multiSelected;
  if (selected) return FlareMessageInteractionMode.selected;
  if (hovered) return FlareMessageInteractionMode.hover;
  if (lifecycle.send == FlareMessageSendState.sending ||
      lifecycle.send == FlareMessageSendState.draft)
    return FlareMessageInteractionMode.sending;
  if (lifecycle.read == FlareMessageReadState.read)
    return FlareMessageInteractionMode.read;
  if (lifecycle.delivery != FlareMessageLifecycleDeliveryState.serverAccepted)
    return FlareMessageInteractionMode.delivered;
  return lifecycle.send == FlareMessageSendState.sent
      ? FlareMessageInteractionMode.sent
      : FlareMessageInteractionMode.normal;
}

enum FlareMessageCapability {
  reply,
  reaction,
  copy,
  forward,
  mergeForward,
  multiSelect,
  edit,
  delete,
  recall,
  pin,
  unpin,
  save,
  translate,
  report,
  retry,
  openThread,
  jumpToQuote,
}

class FlareMessageCapabilityInput {
  const FlareMessageCapabilityInput({
    required this.lifecycle,
    required this.own,
    this.canModerate = false,
    this.supportsCopy = true,
    this.supportsSave = false,
    this.supportsTranslate = false,
    this.supportsMergeForward = false,
    this.reportable = true,
    this.pinned = false,
    this.hasThread = false,
    this.hasQuote = false,
  });
  final FlareMessageLifecycle lifecycle;
  final bool own, canModerate, supportsCopy, supportsSave, supportsTranslate;
  final bool supportsMergeForward, reportable, pinned, hasThread, hasQuote;
}

Set<FlareMessageCapability> resolveMessageCapabilities(
  FlareMessageCapabilityInput input,
) {
  final lifecycle = input.lifecycle;
  final terminal =
      lifecycle.mutation == FlareMessageMutationState.deleted ||
      lifecycle.mutation == FlareMessageMutationState.recalled ||
      lifecycle.ephemeral == FlareMessageEphemeralState.expired;
  final failed =
      lifecycle.send == FlareMessageSendState.failed ||
      lifecycle.transfer == FlareTransferState.failed;
  if (terminal) return input.canModerate ? {FlareMessageCapability.delete} : {};
  final result = <FlareMessageCapability>{FlareMessageCapability.multiSelect};
  if (input.own || input.canModerate) result.add(FlareMessageCapability.delete);
  if (failed) {
    if (input.own) result.add(FlareMessageCapability.retry);
  } else {
    result.addAll({
      FlareMessageCapability.reply,
      FlareMessageCapability.reaction,
      FlareMessageCapability.forward,
    });
    result.add(
      input.pinned ? FlareMessageCapability.unpin : FlareMessageCapability.pin,
    );
    if (input.supportsMergeForward)
      result.add(FlareMessageCapability.mergeForward);
    if (input.hasThread) result.add(FlareMessageCapability.openThread);
    if (input.hasQuote) result.add(FlareMessageCapability.jumpToQuote);
    if (input.supportsCopy) result.add(FlareMessageCapability.copy);
    if (input.supportsSave) result.add(FlareMessageCapability.save);
    if (input.supportsTranslate) result.add(FlareMessageCapability.translate);
    if (input.own && lifecycle.send == FlareMessageSendState.sent) {
      result.addAll({
        FlareMessageCapability.edit,
        FlareMessageCapability.recall,
      });
    }
    if (!input.own && input.reportable)
      result.add(FlareMessageCapability.report);
  }
  return result;
}

enum FlareMessageActionGroup { primary, organize, message, destructive }

enum FlareMessageActionPresentation {
  contextMenu,
  hoverToolbar,
  commandPalette,
  actionSheet,
  bottomSheet,
}

class FlareMessageAction {
  const FlareMessageAction({
    required this.id,
    required this.group,
    required this.destructive,
    required this.promoted,
  });
  final FlareMessageCapability id;
  final FlareMessageActionGroup group;
  final bool destructive, promoted;
}

List<FlareMessageAction> resolveMessageActions(
  FlareMessageCapabilityInput input,
  FlareMessageActionPresentation presentation,
) {
  const primary = {
    FlareMessageCapability.reply,
    FlareMessageCapability.reaction,
    FlareMessageCapability.copy,
    FlareMessageCapability.forward,
    FlareMessageCapability.openThread,
  };
  const organize = {
    FlareMessageCapability.pin,
    FlareMessageCapability.unpin,
    FlareMessageCapability.save,
    FlareMessageCapability.translate,
    FlareMessageCapability.multiSelect,
    FlareMessageCapability.mergeForward,
  };
  const destructive = {
    FlareMessageCapability.recall,
    FlareMessageCapability.delete,
    FlareMessageCapability.report,
  };
  return resolveMessageCapabilities(input)
      .map(
        (id) => FlareMessageAction(
          id: id,
          group: destructive.contains(id)
              ? FlareMessageActionGroup.destructive
              : organize.contains(id)
              ? FlareMessageActionGroup.organize
              : primary.contains(id)
              ? FlareMessageActionGroup.primary
              : FlareMessageActionGroup.message,
          destructive: destructive.contains(id),
          promoted:
              presentation == FlareMessageActionPresentation.hoverToolbar &&
              primary.contains(id),
        ),
      )
      .toList(growable: false);
}

class FlareSelectionState {
  const FlareSelectionState({this.selectedIds = const {}, this.anchorId});
  final Set<String> selectedIds;
  final String? anchorId;
}

sealed class FlareSelectionEvent {
  const FlareSelectionEvent();
}

class FlareSelectionToggle extends FlareSelectionEvent {
  const FlareSelectionToggle(this.id);
  final String id;
}

class FlareSelectionReplace extends FlareSelectionEvent {
  const FlareSelectionReplace(this.id);
  final String id;
}

class FlareSelectionExtend extends FlareSelectionEvent {
  const FlareSelectionExtend(this.id, this.orderedIds);
  final String id;
  final List<String> orderedIds;
}

class FlareSelectionClear extends FlareSelectionEvent {
  const FlareSelectionClear();
}

FlareSelectionState reduceSelection(
  FlareSelectionState state,
  FlareSelectionEvent event,
) {
  if (event is FlareSelectionClear) return const FlareSelectionState();
  if (event is FlareSelectionReplace)
    return FlareSelectionState(selectedIds: {event.id}, anchorId: event.id);
  if (event is FlareSelectionToggle) {
    final next = {...state.selectedIds};
    next.contains(event.id) ? next.remove(event.id) : next.add(event.id);
    return FlareSelectionState(selectedIds: next, anchorId: event.id);
  }
  final extend = event as FlareSelectionExtend;
  final anchor = state.anchorId == null
      ? -1
      : extend.orderedIds.indexOf(state.anchorId!);
  final target = extend.orderedIds.indexOf(extend.id);
  if (anchor < 0 || target < 0)
    return FlareSelectionState(selectedIds: {extend.id}, anchorId: extend.id);
  final start = anchor < target ? anchor : target;
  final end = anchor > target ? anchor : target;
  return FlareSelectionState(
    selectedIds: extend.orderedIds.sublist(start, end + 1).toSet(),
    anchorId: state.anchorId,
  );
}

enum FlareDesktopShortcutAction {
  search,
  commandPalette,
  newConversation,
  focusComposer,
  send,
  newline,
  closeOverlay,
  previousConversation,
  nextConversation,
  toggleDetails,
  reply,
  edit,
  delete,
  copy,
  forward,
  openThread,
}

enum FlareDesktopShortcutScope { global, composer, conversation }

FlareDesktopShortcutAction? resolveDesktopShortcut(
  String key, {
  bool primary = false,
  bool alt = false,
  bool shift = false,
  FlareDesktopShortcutScope scope = FlareDesktopShortcutScope.global,
}) {
  final normalized = key.toLowerCase();
  if (normalized == 'escape') return FlareDesktopShortcutAction.closeOverlay;
  if (primary && normalized == 'k')
    return FlareDesktopShortcutAction.commandPalette;
  if (primary && normalized == 'f') return FlareDesktopShortcutAction.search;
  if (primary && normalized == 'n')
    return FlareDesktopShortcutAction.newConversation;
  if (primary && shift && normalized == 'd')
    return FlareDesktopShortcutAction.toggleDetails;
  if (alt && normalized == 'arrowup')
    return FlareDesktopShortcutAction.previousConversation;
  if (alt && normalized == 'arrowdown')
    return FlareDesktopShortcutAction.nextConversation;
  if (scope == FlareDesktopShortcutScope.composer && normalized == 'enter')
    return primary
        ? FlareDesktopShortcutAction.send
        : FlareDesktopShortcutAction.newline;
  if (scope == FlareDesktopShortcutScope.conversation &&
      primary &&
      normalized == 'c')
    return FlareDesktopShortcutAction.copy;
  if (scope == FlareDesktopShortcutScope.conversation &&
      !primary &&
      !alt &&
      normalized == 'r')
    return FlareDesktopShortcutAction.reply;
  if (scope == FlareDesktopShortcutScope.conversation &&
      !primary &&
      !alt &&
      normalized == 'e')
    return FlareDesktopShortcutAction.edit;
  if (scope == FlareDesktopShortcutScope.conversation &&
      !primary &&
      !alt &&
      normalized == 'f')
    return FlareDesktopShortcutAction.forward;
  if (scope == FlareDesktopShortcutScope.conversation &&
      !primary &&
      !alt &&
      normalized == 't')
    return FlareDesktopShortcutAction.openThread;
  if (scope == FlareDesktopShortcutScope.conversation &&
      (normalized == 'delete' || normalized == 'backspace'))
    return FlareDesktopShortcutAction.delete;
  return null;
}

enum FlareSwipeIntent { none, reply, conversationLeading, conversationTrailing }

FlareSwipeIntent resolveSwipeIntent({
  required double deltaX,
  required double deltaY,
  required bool message,
  bool rtl = false,
  bool multiSelect = false,
  double threshold = 56,
}) {
  if (multiSelect ||
      deltaX.abs() < threshold ||
      deltaX.abs() < deltaY.abs() * 1.25)
    return FlareSwipeIntent.none;
  final leading = rtl ? deltaX < 0 : deltaX > 0;
  if (message) return leading ? FlareSwipeIntent.reply : FlareSwipeIntent.none;
  return leading
      ? FlareSwipeIntent.conversationLeading
      : FlareSwipeIntent.conversationTrailing;
}
