import SwiftUI

/// The compiled-in renderer this kit still draws (its vocabulary's `renderers`): the red packet card. The payment
/// confirmation is the host capability `paymentConfirmation` now (``FlarePaymentConfirmation``, drawn by the host for
/// the engine's confirmPayment request); `redPacket.pay` and `payment.confirm` draw as plain views like the composer,
/// the detail, the account page and the QR renderer.
func flareHasResolvedPresentation(_ view: PluginViewModel) -> Bool {
    guard view.available, let p = view.presentation else { return false }
    return p.renderer == "redPacket.card"
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
        RedPacketCardView(blessing: text("blessing"), kind: FlareRedPacketKind(rawValue: text("kind")),
            state: flareRedPacketCardState(status: FlareRedPacketStatus(rawValue: text("status")) ?? .open,
                claimedByMe: p["claimedByMe"]?.boolValue == true, tapAction: p["canClaim"]?.boolValue == false ? .details : .open),
            disabled: bound("open") == nil, busy: busy, brandName: text("brandName"), onOpen: { request("open") })
    }
}
