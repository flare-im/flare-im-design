# Resolved wallet and red packet presentation

All four Kits compose existing AccountView, RedPacketCard, RedPacketComposer,
RedPacketOpenSheet, RedPacketDetail and RedPacketPayConfirm components. Web and
Tauri share Vue. Apps retain their existing generic plugin hosts and SDK callbacks.

The plugin protocol owns `UiDocument.presentation`: `renderer`, translated `labels`,
bounded JSON-pointer `bindings` and callback-name to declared-action-ID `actions`.
Rust resolves these to `presentation: {renderer, props, actions}`. Display props are
limited to 64 KiB; hidden/unauthorized action references are omitted. Read-only
copies have no presentation callbacks; unavailable views have no presentation.
Unknown renderers and oversized projections retain the generic document path.
The extension cannot load code, call URLs, infer permissions or bypass SDK validation.

| Renderer | Kit composition | Semantic callbacks |
| --- | --- | --- |
| `account` | AccountView inside PluginPage | Existing row/page actions |
| `redPacket.card` | RedPacketCard | `open` |
| `redPacket.composer` | Existing funding form then RedPacketComposer | `submit` |
| `redPacket.detail` | RedPacketDetail and OpenSheet | `open` |
| `redPacket.pay` | RedPacketPayConfirm | `confirm` |
| `payment.confirm` | RedPacketPayConfirm with supplied confirm label | `confirm` or `authorize` |

Funding choices remain strict `{value,label}` records. Display currency metadata
travels separately; it does not add keys to SDK choices. Amounts use integer strings
and a 0–12 currency exponent. The server remains authoritative for limits, funding
eligibility, recipient visibility, expiration, fees, authorization and settlement.
No cross-currency balance is added. Claims contain only server-projected visible
records; the Kit never guesses a winner or reveals hidden amounts.

The original SDK action path retains form/confirmation handling and its operation
journal. An unknown result locks fresh payment/submission and retains original-order
recovery. Busy, error, read-only and offline signals remain visible. Existing
`resolveUser` callbacks supply names and avatars with the standard ID fallback.

Regression sources are `spec/financial-presentation-vectors.json` and
`spec/red-packet-vectors.json`. Component tests are distinct from deployed UI acceptance.
