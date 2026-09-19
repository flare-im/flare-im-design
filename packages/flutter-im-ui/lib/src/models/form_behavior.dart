enum FlareFormControlState {
  idle,
  hover,
  focus,
  pressed,
  filled,
  invalid,
  disabled,
  readOnly,
  loading,
}

enum FlareFormKeyboardIntent {
  none,
  tabForward,
  tabBackward,
  submit,
  closePopup,
  nextOption,
  previousOption,
  firstOption,
  lastOption,
  pageForward,
  pageBackward,
}

FlareFormKeyboardIntent resolveFormKeyboardIntent(
  String key, {
  bool shift = false,
  bool composing = false,
  bool popupOpen = false,
  bool submitOnEnter = false,
}) {
  // While an IME composition is open the IME owns the keyboard — Enter commits a
  // candidate, Escape cancels the composition, Tab and the arrows walk the
  // candidate window. Composing short-circuits everything.
  if (composing) return FlareFormKeyboardIntent.none;
  final normalized = key.toLowerCase();
  if (normalized == 'tab')
    return shift
        ? FlareFormKeyboardIntent.tabBackward
        : FlareFormKeyboardIntent.tabForward;
  if (normalized == 'escape' && popupOpen)
    return FlareFormKeyboardIntent.closePopup;
  if (normalized == 'enter' && submitOnEnter)
    return FlareFormKeyboardIntent.submit;
  if (!popupOpen) return FlareFormKeyboardIntent.none;
  return switch (normalized) {
    'arrowdown' => FlareFormKeyboardIntent.nextOption,
    'arrowup' => FlareFormKeyboardIntent.previousOption,
    'home' => FlareFormKeyboardIntent.firstOption,
    'end' => FlareFormKeyboardIntent.lastOption,
    'pagedown' => FlareFormKeyboardIntent.pageForward,
    'pageup' => FlareFormKeyboardIntent.pageBackward,
    _ => FlareFormKeyboardIntent.none,
  };
}
