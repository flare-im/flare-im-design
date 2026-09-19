public enum FlareFormControlState: String, Sendable { case idle, hover, focus, pressed, filled, invalid, disabled, readOnly, loading }
public enum FlareFormKeyboardIntent: String, Sendable { case none, tabForward, tabBackward, submit, closePopup, nextOption, previousOption, firstOption, lastOption, pageForward, pageBackward }

public func resolveFormKeyboardIntent(
    _ key: String,
    shift: Bool = false,
    composing: Bool = false,
    popupOpen: Bool = false,
    submitOnEnter: Bool = false
) -> FlareFormKeyboardIntent {
    // While an IME composition is open the IME owns the keyboard — Enter commits a
    // candidate, Escape cancels the composition, Tab and the arrows walk the
    // candidate window. Composing short-circuits everything.
    if composing { return .none }
    let key = key.lowercased()
    if key == "tab" { return shift ? .tabBackward : .tabForward }
    if key == "escape" && popupOpen { return .closePopup }
    if key == "enter" && submitOnEnter { return .submit }
    if !popupOpen { return .none }
    switch key {
    case "arrowdown": return .nextOption
    case "arrowup": return .previousOption
    case "home": return .firstOption
    case "end": return .lastOption
    case "pagedown": return .pageForward
    case "pageup": return .pageBackward
    default: return .none
    }
}
