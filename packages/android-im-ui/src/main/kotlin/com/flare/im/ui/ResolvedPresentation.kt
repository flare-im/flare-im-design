package com.flare.im.ui

import androidx.compose.runtime.Composable

private fun Any?.props(): Map<*, *> = this as? Map<*, *> ?: emptyMap<Any, Any>()
private fun Any?.words(): String = this as? String ?: ""
/**
 * The compiled-in renderer this kit still draws (its vocabulary's `renderers`): the red packet card. The payment
 * confirmation is the host capability `paymentConfirmation` now ([FlarePaymentConfirmation], drawn by the host for the
 * engine's confirmPayment request); `redPacket.pay` and `payment.confirm` draw as plain views like the composer, the
 * detail, the account page and the QR renderer.
 */
internal fun hasResolvedPresentation(view: PluginViewModel): Boolean =
 view.available && view.presentation?.get("renderer") == "redPacket.card"
/** Visual composition over resolved values. Requests are opaque IDs of visible actions. */
@Composable
internal fun ResolvedPresentation(view: PluginViewModel, busy: Boolean, onRequest: (String)->Unit) {
 val p=view.presentation?.get("props").props()
 val bound=view.presentation?.get("actions").props()
 fun action(name:String)=view.actions.firstOrNull { it.id==bound[name] }
 val unknown=p["journal"].props()["known"]==false
 fun request(name:String){action(name)?.let { if(!busy&&!unknown)onRequest(it.id) }}
 RedPacketCard(blessing=p["blessing"].words(),kind=FlareRedPacketKind.entries.firstOrNull { it.name.equals(p["kind"].words(),true) }?:FlareRedPacketKind.Normal,
  state=flareRedPacketCardState(FlareRedPacketStatus.entries.firstOrNull { it.wire==p["status"] }?:FlareRedPacketStatus.Open,p["claimedByMe"]==true,if(p["canClaim"]==false)FlareRedPacketTapAction.Details else FlareRedPacketTapAction.Open),busy=busy,disabled=action("open")==null,brandName=p["brandName"].words(),onOpen={request("open")})
}
