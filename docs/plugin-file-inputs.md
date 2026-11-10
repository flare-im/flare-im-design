# Plugin file fields and dependent inputs

`PluginForm` renders the SDK-resolved `file` input using the kit's controlled upload surface. The same rules apply to Vue (Web and Tauri), Flutter, SwiftUI and Compose. The kit does not pick files, make network requests, resolve private grants or decide business authorization.

A file input declares its server policy:

```json
{"id":"proof","kind":"file","label":"充值凭证","required":true,"file":{"accept":["image/png","image/jpeg"],"maxBytes":5242880,"upload":{"prepareOperation":"<resolved operation>","completeOperation":"<resolved operation>","purpose":"<resolved purpose>"}}}
```

The form value is exactly `{"fileId":"<opaque private material ID>"}`. `fileId` is an ASCII resource ID matching `^[A-Za-z0-9_:-]{1,128}$`. A URL, raw string, bytes, token, grant or object with extra keys is not a file value. The host invokes the SDK's file-upload capability using the resolved page, input, current form values and picked bytes. Only completed server material becomes an uploaded value. Reaching 100 percent transport progress does not complete the form value.

The kit accepts a `fileStates` map keyed by input ID. Its host-only state is:

- `scope`, `generation`: exact mounted-form and field-operation tickets.
- `phase`: `empty`, `selected`, `uploading`, `uploaded` or `failed`.
- Optional `value`, `fileName`, percentage `progress`, localized `error`, `preview` capability and `previewLoading`.

Vue emits `file-action`; Flutter accepts `onFileAction`. The typed `FlarePluginFileAction` carries `action`, `inputId`, the resolved `input`, `scope`, `generation` and current cleaned visible `formValues`. Actions are `choose`, `retry`, `cancel`, `replace`, `remove`, `preview` and `invalidate`. Flutter's state value is `FlarePluginFileValue(fileId: ...)`; `toJson()` produces the wire object. SwiftUI and Compose expose equivalent typed callbacks.

The host owns the picker. Choosing/retrying/replacing increments the ticket and blocks submit while work is pending. Cancel/remove/controller changes invalidate the ticket; they do not delete remote material. Preview preserves the current receipt and ticket. Return every state update with both exact tickets; old generations, old scopes and updates for hidden fields are ignored. A dismissed picker may restore a prior uploaded state with the new ticket. A failed/interrupted transfer remains retryable. Disposing or resetting the form emits invalidation, and a new mount/reset receives a new scope. The host also fences page, session and identity lifetimes.

`preview` only enables a host preview intent. A prefilled valid receipt does not itself enable private preview. Plugin file state has no URL field. Hosts may display a short-lived local blob or local bytes after access checks. Private payout/recharge materials must not become public attachment URLs. Client wallet content uses safe attachment metadata, while authorized staff preview uses the existing protected-media surface; this change does not introduce a new protected-media client block.

`showWhen: {"field":"kind","anyOf":["alipay","wechat"]}` references an earlier unconditional select in the same form. Only visible fields are rendered, validated and submitted. Defaults seed the initial draft once. Every actual controlling-select value change clears all dependent values, errors and file state, even when both old and new values keep a dependent field visible (for example Alipay to Wechat). Submission never restores a cleared default. The host and server must still reject irrelevant fields and stale material-purpose mismatches.

Any selected, uploading or failed file blocks submit, including optional files. Empty optional fields may be omitted; required empty files show the standard required error. Type/size rejection uses `pluginFileRejected`; incomplete upload uses `pluginFileFailed`. The policy's formats and maximum size are shown as one compact hint. `spec/plugin-file-input-vectors.json` provides shared visible-value and strict-receipt vectors; Vue and Flutter lifecycle tests cover ticket and controller changes.

Flutter `FlareFileUpload` uses the same compact media-region height as Vue (`touchTargetMin × 2.5`) and wraps its natural content height. The optional `FlareImageUploadSlot.previewHeight` enables this composition; omitting it preserves the existing 1.6 photo aspect ratio.

A normal page refresh may release the host transfer controller while keeping the same form mounted. A matching completed receipt and file name remain in that form, with preview disabled because its host-owned bytes or URL may have been released. Pending, failed and invalid receipts never become uploaded through this fallback. Explicit removal, dependent-field invalidation and form scope reset discard the receipt. Hosts must unmount or reset the form on authentication or route-context changes.
