import SwiftUI

/// The compiled-in renderers a card or document draws in place: the red packet card and review. The send page and
/// the details (`redPacket.compose`, `redPacket.detail`) are page renderers ``FlarePluginPage`` draws with
/// ``RedPacketPageView``. The payment confirmation is the host capability `paymentConfirmation` now
/// (``FlarePaymentConfirmation``, drawn by the host for the engine's confirmPayment request); `redPacket.pay` and
/// `payment.confirm` draw as plain views like the account page and the QR renderer.
func flareHasResolvedPresentation(_ view: PluginViewModel) -> Bool {
    guard view.available, let p = view.presentation else { return false }
    // A review that does not map (an unconfirmed original command, no send key) reads as its plain document, so the
    // confirm page keeps its warning, status and recovery action.
    return p.renderer == "redPacket.card" || (p.renderer == "redPacket.review" && FlareRedPacketPagePlan.review(view) != nil)
}

/// Compiled-in Kit composition. Values are resolved, actions are opaque IDs; no SDK or target interpretation.
struct ResolvedPresentationView: View {
    let view: PluginViewModel
    let busy: Bool
    let onRequest: (String) -> Void
    init(view: PluginViewModel, busy: Bool, onRequest: @escaping (String) -> Void) {
        self.view = view; self.busy = busy; self.onRequest = onRequest
    }
    private var p: [String: PluginJSONValue] { view.presentation?.props ?? [:] }
    private var unknown: Bool { p["journal"]?["known"]?.boolValue == false }
    private func text(_ key: String) -> String { p[key]?.stringValue ?? "" }
    private func bound(_ name: String) -> PluginViewAction? {
        view.actions.first { $0.id == view.presentation?.actions[name] }
    }
    private func request(_ name: String) { if !busy, !unknown, let a = bound(name) { onRequest(a.id) } }
    var body: some View {
        if view.presentation?.renderer == "redPacket.review" {
            // §4.3: the red packet's own review instead of a purple hero page. A plain decimal with its currency gets
            // the symbol (R10); an amount the plugin already formatted draws as it came.
            RedPacketReviewView(amount: FlarePaymentRules.amountText(text("amount"), currency: text("currency")) ?? text("amount"),
                                kindLabel: text("kindLabel"), blessing: text("blessing"),
                                submitLabel: text("submitLabel").isEmpty ? nil : text("submitLabel"),
                                busy: busy, error: text("error").isEmpty ? nil : text("error"),
                                onSubmit: bound("submit") == nil || unknown ? nil : { request("submit") })
        } else {
            card
        }
    }

    private var card: some View {
        RedPacketCardView(blessing: text("blessing"), kind: FlareRedPacketKind(rawValue: text("kind")),
            state: flareRedPacketCardState(status: FlareRedPacketStatus(rawValue: text("status")) ?? .open,
                claimedByMe: p["claimedByMe"]?.boolValue == true, tapAction: p["canClaim"]?.boolValue == false ? .details : .open),
            disabled: bound("open") == nil, busy: busy, brandName: text("brandName"), onOpen: { request("open") })
    }
}
