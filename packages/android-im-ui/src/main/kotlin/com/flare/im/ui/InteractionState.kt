package com.flare.im.ui

enum class FlareComposerInteractionMode {
    Idle, Typing, Mentioning, Replying, Editing, Uploading, Recording, Sending,
    SendBlocked, Offline, ReadOnly, SlowMode, PermissionDenied,
}

enum class FlareComposerInteractionAction { Type, Send, Newline, Attach, Mention, Reply, Edit, Record, Cancel, Retry }

data class FlareComposerInteractionInput(
    val hasText: Boolean = false,
    val mentioning: Boolean = false,
    val replying: Boolean = false,
    val editing: Boolean = false,
    val uploading: Boolean = false,
    val recording: Boolean = false,
    val sending: Boolean = false,
    val sendBlocked: Boolean = false,
    val online: Boolean = true,
    val readOnly: Boolean = false,
    val slowMode: Boolean = false,
    val permissionGranted: Boolean = true,
)

fun resolveComposerMode(input: FlareComposerInteractionInput): FlareComposerInteractionMode = when {
    input.readOnly -> FlareComposerInteractionMode.ReadOnly
    !input.permissionGranted -> FlareComposerInteractionMode.PermissionDenied
    !input.online -> FlareComposerInteractionMode.Offline
    input.slowMode -> FlareComposerInteractionMode.SlowMode
    input.sendBlocked -> FlareComposerInteractionMode.SendBlocked
    input.sending -> FlareComposerInteractionMode.Sending
    input.recording -> FlareComposerInteractionMode.Recording
    input.uploading -> FlareComposerInteractionMode.Uploading
    input.editing -> FlareComposerInteractionMode.Editing
    input.mentioning -> FlareComposerInteractionMode.Mentioning
    input.replying -> FlareComposerInteractionMode.Replying
    input.hasText -> FlareComposerInteractionMode.Typing
    else -> FlareComposerInteractionMode.Idle
}

fun composerAllowedActions(mode: FlareComposerInteractionMode): Set<FlareComposerInteractionAction> = when (mode) {
    FlareComposerInteractionMode.ReadOnly -> emptySet()
    FlareComposerInteractionMode.PermissionDenied -> setOf(FlareComposerInteractionAction.Cancel)
    FlareComposerInteractionMode.Offline -> setOf(FlareComposerInteractionAction.Type, FlareComposerInteractionAction.Newline, FlareComposerInteractionAction.Attach, FlareComposerInteractionAction.Cancel, FlareComposerInteractionAction.Retry)
    FlareComposerInteractionMode.SlowMode, FlareComposerInteractionMode.SendBlocked -> setOf(FlareComposerInteractionAction.Type, FlareComposerInteractionAction.Newline, FlareComposerInteractionAction.Attach, FlareComposerInteractionAction.Mention, FlareComposerInteractionAction.Cancel)
    FlareComposerInteractionMode.Sending -> setOf(FlareComposerInteractionAction.Cancel)
    FlareComposerInteractionMode.Recording -> setOf(FlareComposerInteractionAction.Send, FlareComposerInteractionAction.Cancel)
    FlareComposerInteractionMode.Uploading -> setOf(FlareComposerInteractionAction.Type, FlareComposerInteractionAction.Newline, FlareComposerInteractionAction.Attach, FlareComposerInteractionAction.Cancel)
    FlareComposerInteractionMode.Editing, FlareComposerInteractionMode.Mentioning, FlareComposerInteractionMode.Replying -> setOf(FlareComposerInteractionAction.Type, FlareComposerInteractionAction.Newline, FlareComposerInteractionAction.Send, FlareComposerInteractionAction.Attach, FlareComposerInteractionAction.Mention, FlareComposerInteractionAction.Cancel)
    else -> setOf(FlareComposerInteractionAction.Type, FlareComposerInteractionAction.Send, FlareComposerInteractionAction.Newline, FlareComposerInteractionAction.Attach, FlareComposerInteractionAction.Mention, FlareComposerInteractionAction.Reply, FlareComposerInteractionAction.Edit, FlareComposerInteractionAction.Record)
}

enum class FlareMessageInteractionMode { Normal, Hover, Selected, MultiSelected, Sending, Sent, Delivered, Read, Failed, Retrying, Edited, Recalled, Deleted, Ephemeral, Expired }

fun resolveMessageMode(
    lifecycle: FlareMessageLifecycle,
    hovered: Boolean = false,
    selected: Boolean = false,
    multiSelect: Boolean = false,
    retrying: Boolean = false,
): FlareMessageInteractionMode = when {
    lifecycle.mutation == FlareMessageMutationState.Deleted -> FlareMessageInteractionMode.Deleted
    lifecycle.ephemeral == FlareMessageEphemeralState.Expired -> FlareMessageInteractionMode.Expired
    lifecycle.mutation == FlareMessageMutationState.Recalled -> FlareMessageInteractionMode.Recalled
    retrying -> FlareMessageInteractionMode.Retrying
    lifecycle.send == FlareMessageSendState.Failed || lifecycle.transfer == FlareTransferState.Failed -> FlareMessageInteractionMode.Failed
    lifecycle.ephemeral != FlareMessageEphemeralState.None -> FlareMessageInteractionMode.Ephemeral
    lifecycle.mutation == FlareMessageMutationState.Edited -> FlareMessageInteractionMode.Edited
    multiSelect && selected -> FlareMessageInteractionMode.MultiSelected
    selected -> FlareMessageInteractionMode.Selected
    hovered -> FlareMessageInteractionMode.Hover
    lifecycle.send == FlareMessageSendState.Sending || lifecycle.send == FlareMessageSendState.Draft -> FlareMessageInteractionMode.Sending
    lifecycle.read == FlareMessageReadState.Read -> FlareMessageInteractionMode.Read
    lifecycle.delivery != FlareMessageLifecycleDeliveryState.ServerAccepted -> FlareMessageInteractionMode.Delivered
    lifecycle.send == FlareMessageSendState.Sent -> FlareMessageInteractionMode.Sent
    else -> FlareMessageInteractionMode.Normal
}

enum class FlareMessageCapability {
    Reply, Reaction, Copy, Forward, MergeForward, MultiSelect, Edit, Delete, Recall,
    Pin, Unpin, Save, Translate, Report, Retry, OpenThread, JumpToQuote,
}

data class FlareMessageCapabilityInput(
    val lifecycle: FlareMessageLifecycle,
    val own: Boolean,
    val canModerate: Boolean = false,
    val supportsCopy: Boolean = true,
    val supportsSave: Boolean = false,
    val supportsTranslate: Boolean = false,
    val supportsMergeForward: Boolean = false,
    val reportable: Boolean = true,
    val pinned: Boolean = false,
    val hasThread: Boolean = false,
    val hasQuote: Boolean = false,
)

fun resolveMessageCapabilities(input: FlareMessageCapabilityInput): Set<FlareMessageCapability> {
    val lifecycle = input.lifecycle
    val terminal = lifecycle.mutation == FlareMessageMutationState.Deleted ||
        lifecycle.mutation == FlareMessageMutationState.Recalled ||
        lifecycle.ephemeral == FlareMessageEphemeralState.Expired
    val failed = lifecycle.send == FlareMessageSendState.Failed || lifecycle.transfer == FlareTransferState.Failed
    if (terminal) return if (input.canModerate) setOf(FlareMessageCapability.Delete) else emptySet()
    return buildSet {
        add(FlareMessageCapability.MultiSelect)
        if (input.own || input.canModerate) add(FlareMessageCapability.Delete)
        if (failed) {
            if (input.own) add(FlareMessageCapability.Retry)
        } else {
            addAll(setOf(FlareMessageCapability.Reply, FlareMessageCapability.Reaction, FlareMessageCapability.Forward))
            add(if (input.pinned) FlareMessageCapability.Unpin else FlareMessageCapability.Pin)
            if (input.supportsMergeForward) add(FlareMessageCapability.MergeForward)
            if (input.hasThread) add(FlareMessageCapability.OpenThread)
            if (input.hasQuote) add(FlareMessageCapability.JumpToQuote)
            if (input.supportsCopy) add(FlareMessageCapability.Copy)
            if (input.supportsSave) add(FlareMessageCapability.Save)
            if (input.supportsTranslate) add(FlareMessageCapability.Translate)
            if (input.own && lifecycle.send == FlareMessageSendState.Sent) addAll(setOf(FlareMessageCapability.Edit, FlareMessageCapability.Recall))
            if (!input.own && input.reportable) add(FlareMessageCapability.Report)
        }
    }
}

enum class FlareMessageActionGroup { Primary, Organize, Message, Destructive }
enum class FlareMessageActionPresentation { ContextMenu, HoverToolbar, CommandPalette, ActionSheet, BottomSheet }
data class FlareMessageAction(val id: FlareMessageCapability, val group: FlareMessageActionGroup, val destructive: Boolean, val promoted: Boolean)

fun resolveMessageActions(input: FlareMessageCapabilityInput, presentation: FlareMessageActionPresentation): List<FlareMessageAction> {
    val primary = setOf(FlareMessageCapability.Reply, FlareMessageCapability.Reaction, FlareMessageCapability.Copy, FlareMessageCapability.Forward, FlareMessageCapability.OpenThread)
    val organize = setOf(FlareMessageCapability.Pin, FlareMessageCapability.Unpin, FlareMessageCapability.Save, FlareMessageCapability.Translate, FlareMessageCapability.MultiSelect, FlareMessageCapability.MergeForward)
    val destructive = setOf(FlareMessageCapability.Recall, FlareMessageCapability.Delete, FlareMessageCapability.Report)
    return resolveMessageCapabilities(input).map { id ->
        FlareMessageAction(
            id,
            when (id) { in destructive -> FlareMessageActionGroup.Destructive; in organize -> FlareMessageActionGroup.Organize; in primary -> FlareMessageActionGroup.Primary; else -> FlareMessageActionGroup.Message },
            id in destructive,
            presentation == FlareMessageActionPresentation.HoverToolbar && id in primary,
        )
    }
}

data class FlareSelectionState(val selectedIds: Set<String> = emptySet(), val anchorId: String? = null)
sealed interface FlareSelectionEvent
data class FlareSelectionToggle(val id: String) : FlareSelectionEvent
data class FlareSelectionReplace(val id: String) : FlareSelectionEvent
data class FlareSelectionExtend(val id: String, val orderedIds: List<String>) : FlareSelectionEvent
data object FlareSelectionClear : FlareSelectionEvent

fun reduceSelection(state: FlareSelectionState, event: FlareSelectionEvent): FlareSelectionState = when (event) {
    FlareSelectionClear -> FlareSelectionState()
    is FlareSelectionReplace -> FlareSelectionState(setOf(event.id), event.id)
    is FlareSelectionToggle -> FlareSelectionState(state.selectedIds.toMutableSet().apply { if (!add(event.id)) remove(event.id) }, event.id)
    is FlareSelectionExtend -> {
        val anchor = state.anchorId?.let(event.orderedIds::indexOf) ?: -1
        val target = event.orderedIds.indexOf(event.id)
        if (anchor < 0 || target < 0) FlareSelectionState(setOf(event.id), event.id)
        else FlareSelectionState(event.orderedIds.subList(minOf(anchor, target), maxOf(anchor, target) + 1).toSet(), state.anchorId)
    }
}

enum class FlareDesktopShortcutAction { Search, CommandPalette, NewConversation, FocusComposer, Send, Newline, CloseOverlay, PreviousConversation, NextConversation, ToggleDetails, Reply, Edit, Delete, Copy, Forward, OpenThread }
enum class FlareDesktopShortcutScope { Global, Composer, Conversation }

fun resolveDesktopShortcut(key: String, primary: Boolean = false, alt: Boolean = false, shift: Boolean = false, scope: FlareDesktopShortcutScope = FlareDesktopShortcutScope.Global): FlareDesktopShortcutAction? {
    val normalized = key.lowercase()
    return when {
        normalized == "escape" -> FlareDesktopShortcutAction.CloseOverlay
        primary && normalized == "k" -> FlareDesktopShortcutAction.CommandPalette
        primary && normalized == "f" -> FlareDesktopShortcutAction.Search
        primary && normalized == "n" -> FlareDesktopShortcutAction.NewConversation
        primary && shift && normalized == "d" -> FlareDesktopShortcutAction.ToggleDetails
        alt && normalized == "arrowup" -> FlareDesktopShortcutAction.PreviousConversation
        alt && normalized == "arrowdown" -> FlareDesktopShortcutAction.NextConversation
        scope == FlareDesktopShortcutScope.Composer && normalized == "enter" -> if (primary) FlareDesktopShortcutAction.Send else FlareDesktopShortcutAction.Newline
        scope == FlareDesktopShortcutScope.Conversation && primary && normalized == "c" -> FlareDesktopShortcutAction.Copy
        scope == FlareDesktopShortcutScope.Conversation && !primary && !alt && normalized == "r" -> FlareDesktopShortcutAction.Reply
        scope == FlareDesktopShortcutScope.Conversation && !primary && !alt && normalized == "e" -> FlareDesktopShortcutAction.Edit
        scope == FlareDesktopShortcutScope.Conversation && !primary && !alt && normalized == "f" -> FlareDesktopShortcutAction.Forward
        scope == FlareDesktopShortcutScope.Conversation && !primary && !alt && normalized == "t" -> FlareDesktopShortcutAction.OpenThread
        scope == FlareDesktopShortcutScope.Conversation && normalized in setOf("delete", "backspace") -> FlareDesktopShortcutAction.Delete
        else -> null
    }
}

enum class FlareSwipeIntent { None, Reply, ConversationLeading, ConversationTrailing }

fun resolveSwipeIntent(deltaX: Float, deltaY: Float, message: Boolean, rtl: Boolean = false, multiSelect: Boolean = false, threshold: Float = 56f): FlareSwipeIntent {
    if (multiSelect || kotlin.math.abs(deltaX) < threshold || kotlin.math.abs(deltaX) < kotlin.math.abs(deltaY) * 1.25f) return FlareSwipeIntent.None
    val leading = if (rtl) deltaX < 0 else deltaX > 0
    return if (message) {
        if (leading) FlareSwipeIntent.Reply else FlareSwipeIntent.None
    } else if (leading) FlareSwipeIntent.ConversationLeading else FlareSwipeIntent.ConversationTrailing
}
