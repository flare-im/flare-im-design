package com.flare.im.ui

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class InteractionStateTest {
    @Test fun `composer precedence and actions are deterministic`() {
        assertEquals(FlareComposerInteractionMode.ReadOnly, resolveComposerMode(FlareComposerInteractionInput(readOnly = true, recording = true, online = false)))
        assertEquals(FlareComposerInteractionMode.PermissionDenied, resolveComposerMode(FlareComposerInteractionInput(permissionGranted = false, online = false)))
        assertFalse(composerAllowedActions(FlareComposerInteractionMode.Offline).contains(FlareComposerInteractionAction.Send))
    }

    @Test fun `message lifecycle outranks hover`() {
        assertEquals(FlareMessageInteractionMode.Recalled, resolveMessageMode(FlareMessageLifecycle(mutation = FlareMessageMutationState.Recalled), hovered = true))
        assertEquals(FlareMessageInteractionMode.Read, resolveMessageMode(FlareMessageLifecycle(read = FlareMessageReadState.Read)))
    }

    @Test fun `selection shortcuts and gestures are stable`() {
        val anchor = reduceSelection(FlareSelectionState(), FlareSelectionReplace("b"))
        val range = reduceSelection(anchor, FlareSelectionExtend("d", listOf("a", "b", "c", "d")))
        assertEquals(setOf("b", "c", "d"), range.selectedIds)
        assertEquals(FlareDesktopShortcutAction.CommandPalette, resolveDesktopShortcut("k", primary = true))
        assertEquals(FlareSwipeIntent.None, resolveSwipeIntent(80f, 70f, message = true))
        assertEquals(FlareSwipeIntent.Reply, resolveSwipeIntent(80f, 8f, message = true))
    }

    @Test fun `message capabilities follow ownership and terminal lifecycle`() {
        val own = resolveMessageCapabilities(FlareMessageCapabilityInput(FlareMessageLifecycle(), own = true))
        assert(own.contains(FlareMessageCapability.Edit))
        assertFalse(own.contains(FlareMessageCapability.Report))
        val recalled = resolveMessageCapabilities(
            FlareMessageCapabilityInput(
                FlareMessageLifecycle(mutation = FlareMessageMutationState.Recalled),
                own = true,
            ),
        )
        assertEquals(emptySet<FlareMessageCapability>(), recalled)
    }

    @Test fun `extended actions and shortcuts share the capability contract`() {
        val actions = resolveMessageCapabilities(
            FlareMessageCapabilityInput(
                FlareMessageLifecycle(), own = true, pinned = true,
                hasThread = true, hasQuote = true, supportsMergeForward = true,
            ),
        )
        assert(actions.containsAll(setOf(
            FlareMessageCapability.Unpin, FlareMessageCapability.OpenThread,
            FlareMessageCapability.JumpToQuote, FlareMessageCapability.MergeForward,
        )))
        assertEquals(FlareDesktopShortcutAction.Forward, resolveDesktopShortcut("f", scope = FlareDesktopShortcutScope.Conversation))
        assertEquals(FlareDesktopShortcutAction.OpenThread, resolveDesktopShortcut("t", scope = FlareDesktopShortcutScope.Conversation))
    }

    @Test fun `action presentation stays downstream of availability`() {
        val actions = resolveMessageActions(
            FlareMessageCapabilityInput(FlareMessageLifecycle(), own = false),
            FlareMessageActionPresentation.HoverToolbar,
        )
        assert(actions.single { it.id == FlareMessageCapability.Reply }.promoted)
        assertEquals(FlareMessageActionGroup.Destructive, actions.single { it.id == FlareMessageCapability.Report }.group)
    }
}
