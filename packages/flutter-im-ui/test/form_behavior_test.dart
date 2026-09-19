import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

// DoD 20 —— spec/form-keyboard-contract.json 的向量表。四端跑同一批 id，
// tooling/check-form-keyboard.mjs 会在某一端不再验某条时报红。
typedef _Case = ({
  String id,
  String key,
  bool shift,
  bool composing,
  bool popupOpen,
  bool submitOnEnter,
  FlareFormKeyboardIntent intent,
});

_Case _c(
  String id,
  String key,
  FlareFormKeyboardIntent intent, {
  bool shift = false,
  bool composing = false,
  bool popupOpen = false,
  bool submitOnEnter = false,
}) => (
  id: id,
  key: key,
  shift: shift,
  composing: composing,
  popupOpen: popupOpen,
  submitOnEnter: submitOnEnter,
  intent: intent,
);

void main() {
  final vectors = <_Case>[
    _c('enter.submits', 'Enter', FlareFormKeyboardIntent.submit, submitOnEnter: true),
    _c('enter.withoutSubmitMode', 'Enter', FlareFormKeyboardIntent.none),
    _c('enter.composing', 'Enter', FlareFormKeyboardIntent.none, composing: true, submitOnEnter: true),
    _c('tab.forward', 'Tab', FlareFormKeyboardIntent.tabForward),
    _c('tab.backward', 'Tab', FlareFormKeyboardIntent.tabBackward, shift: true),
    _c('tab.composing', 'Tab', FlareFormKeyboardIntent.none, composing: true),
    _c('escape.closesPopup', 'Escape', FlareFormKeyboardIntent.closePopup, popupOpen: true),
    _c('escape.withoutPopup', 'Escape', FlareFormKeyboardIntent.none),
    _c('escape.composing', 'Escape', FlareFormKeyboardIntent.none, composing: true, popupOpen: true),
    _c('arrowDown.nextOption', 'ArrowDown', FlareFormKeyboardIntent.nextOption, popupOpen: true),
    _c('arrowUp.previousOption', 'ArrowUp', FlareFormKeyboardIntent.previousOption, popupOpen: true),
    _c('arrowDown.composing', 'ArrowDown', FlareFormKeyboardIntent.none, composing: true, popupOpen: true),
    _c('arrowDown.withoutPopup', 'ArrowDown', FlareFormKeyboardIntent.none),
    _c('home.firstOption', 'Home', FlareFormKeyboardIntent.firstOption, popupOpen: true),
    _c('end.lastOption', 'End', FlareFormKeyboardIntent.lastOption, popupOpen: true),
    _c('pageDown.pageForward', 'PageDown', FlareFormKeyboardIntent.pageForward, popupOpen: true),
    _c('pageUp.pageBackward', 'PageUp', FlareFormKeyboardIntent.pageBackward, popupOpen: true),
    _c('unknownKey', 'F13', FlareFormKeyboardIntent.none, popupOpen: true),
  ];

  for (final v in vectors) {
    test(v.id, () {
      expect(
        resolveFormKeyboardIntent(
          v.key,
          shift: v.shift,
          composing: v.composing,
          popupOpen: v.popupOpen,
          submitOnEnter: v.submitOnEnter,
        ),
        v.intent,
      );
    });
  }

  test('输入法组字时每个键都归输入法', () {
    // 守卫是无条件的：组字中的 Tab 不能把焦点从半个词上挪走，Escape 也属于输入法。
    for (final key in [
      'Enter',
      'Tab',
      'Escape',
      'ArrowDown',
      'ArrowUp',
      'Home',
      'End',
      'PageDown',
      'PageUp',
    ]) {
      expect(
        resolveFormKeyboardIntent(
          key,
          shift: true,
          composing: true,
          popupOpen: true,
          submitOnEnter: true,
        ),
        FlareFormKeyboardIntent.none,
        reason: key,
      );
    }
  });

  test('键名大小写不敏感', () {
    expect(
      resolveFormKeyboardIntent('enter', submitOnEnter: true),
      FlareFormKeyboardIntent.submit,
    );
    expect(
      resolveFormKeyboardIntent('ARROWDOWN', popupOpen: true),
      FlareFormKeyboardIntent.nextOption,
    );
  });
}
