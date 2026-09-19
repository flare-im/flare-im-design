# Desktop Form Behavior

## Architecture

The existing controls remain the primitives. Missing names are compositions:

| Product need | Library composition |
|---|---|
| SearchInput | Input plus search intent and clear action |
| Combobox / Autocomplete | Input plus Select popup, filtering, active descendant, and FormField |
| DateTimePicker | DatePicker plus TimePicker in one FormField |
| NumberInput | Input plus numeric parsing and Stepper where increment controls are useful |
| PasswordInput | Input plus suffix visibility action; the host owns credential policy |
| OTPInput | Input with one logical value and optional segmented presentation |
| FilePicker | Button/Input trigger plus native file adapter |
| DropZone | Focusable/pointer drop pattern plus FilePicker fallback |
| ValidationMessage | FormField error/description region |

This avoids a second form system and keeps native pickers native.

## Contract

All controls expose default, hover, focus, pressed, filled, invalid, disabled, read-only, and loading when applicable. `resolveFormKeyboardIntent` is implemented on Vue, Flutter, Compose, and SwiftUI for Tab/Shift+Tab, Escape, Enter, arrows, Home/End, Page Up/Down, and IME composition protection.

Popup controls restore focus to their trigger. Enter never submits during composition. Disabled controls suppress intent; read-only text remains selectable. Error text is programmatically associated with its field and describes recovery. Long forms scroll the focused control into view and large text may increase row height.
