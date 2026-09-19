package com.flare.im.ui

enum class FlareFormControlState { Idle, Hover, Focus, Pressed, Filled, Invalid, Disabled, ReadOnly, Loading }
enum class FlareFormKeyboardIntent { None, TabForward, TabBackward, Submit, ClosePopup, NextOption, PreviousOption, FirstOption, LastOption, PageForward, PageBackward }

fun resolveFormKeyboardIntent(
    key: String,
    shift: Boolean = false,
    composing: Boolean = false,
    popupOpen: Boolean = false,
    submitOnEnter: Boolean = false,
): FlareFormKeyboardIntent {
    // While an IME composition is open the IME owns the keyboard — Enter commits a
    // candidate, Escape cancels the composition, Tab and the arrows walk the
    // candidate window. Composing short-circuits everything.
    if (composing) return FlareFormKeyboardIntent.None
    val normalized = key.lowercase()
    if (normalized == "tab") return if (shift) FlareFormKeyboardIntent.TabBackward else FlareFormKeyboardIntent.TabForward
    if (normalized == "escape" && popupOpen) return FlareFormKeyboardIntent.ClosePopup
    if (normalized == "enter" && submitOnEnter) return FlareFormKeyboardIntent.Submit
    if (!popupOpen) return FlareFormKeyboardIntent.None
    return when (normalized) {
        "arrowdown" -> FlareFormKeyboardIntent.NextOption
        "arrowup" -> FlareFormKeyboardIntent.PreviousOption
        "home" -> FlareFormKeyboardIntent.FirstOption
        "end" -> FlareFormKeyboardIntent.LastOption
        "pagedown" -> FlareFormKeyboardIntent.PageForward
        "pageup" -> FlareFormKeyboardIntent.PageBackward
        else -> FlareFormKeyboardIntent.None
    }
}

/**
 * The text a capped field keeps when the user types past [maxLength].
 *
 * Clamping keeps the field and the state in sync. Dropping the update — what the
 * composer and the input used to do — leaves the IME composing against a value
 * the state no longer holds, and CJK input silently loses characters at the
 * boundary. `null` means no cap.
 */
fun composerTextWithinLimit(next: String, maxLength: Int?): String =
    if (maxLength != null && next.length > maxLength) next.take(maxLength) else next
