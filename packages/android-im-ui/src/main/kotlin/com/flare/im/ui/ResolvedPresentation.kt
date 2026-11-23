package com.flare.im.ui

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.material3.Text
import androidx.compose.ui.Modifier

private fun Any?.props(): Map<*, *> = this as? Map<*, *> ?: emptyMap<Any, Any>()
private fun Any?.words(): String = this as? String ?: ""
/**
 * The compiled-in renderer this kit still draws (its vocabulary's `renderers`): the red packet card. The payment
 * confirmation is the host capability `paymentConfirmation` now ([FlarePaymentConfirmation], drawn by the host for the
 * engine's confirmPayment request); `redPacket.pay` and `payment.confirm` draw as plain views like the composer, the
 * detail and the account page. A scan code page (`flare.qr`) is a plain view too, with its code drawn above it
 * ([pluginQrPresentationProps], [PluginQrPresentation]). The page renderers `redPacket.compose` and `redPacket.detail`
 * are not drawn here: [FlarePluginPage] draws them as [RedPacketPage] ([redPacketPagePlan]).
 */
internal fun hasResolvedPresentation(view: PluginViewModel): Boolean =
 view.available && view.presentation?.get("renderer") in setOf("redPacket.card", "redPacket.review")
/** Visual composition over resolved values. Requests are opaque IDs of visible actions. */
@Composable
internal fun ResolvedPresentation(view: PluginViewModel, busy: Boolean, onRequest: (String)->Unit, busyActionId: String? = null, error: String? = null) {
 val p=view.presentation?.get("props").props()
 val bound=view.presentation?.get("actions").props()
 fun action(name:String)=view.actions.firstOrNull { it.id==bound[name] }
 // 4.3: the send step of a red packet. Props: amount (formatted), kindLabel, blessing; actions.submit (else the first primary).
 if (view.presentation?.get("renderer") == "redPacket.review") {
  val submit = action("submit") ?: view.actions.firstOrNull { it.style == PluginActionStyle.Primary }
  RedPacketReview(amount = p["amount"].words(), kindLabel = (p["kindLabel"] as? String), blessing = (p["blessing"] as? String),
   submitLabel = submit?.label, busy = submit != null && busyActionId == submit.id, error = error,
   onSubmit = submit?.takeIf { !busy }?.let { { onRequest(it.id) } })
  return
 }
 val unknown=p["journal"].props()["known"]==false
 fun request(name:String){action(name)?.let { if(!busy&&!unknown)onRequest(it.id) }}
 RedPacketCard(blessing=p["blessing"].words(),kind=FlareRedPacketKind.entries.firstOrNull { it.name.equals(p["kind"].words(),true) }?:FlareRedPacketKind.Normal,
  state=flareRedPacketCardState(FlareRedPacketStatus.entries.firstOrNull { it.wire==p["status"] }?:FlareRedPacketStatus.Open,p["claimedByMe"]==true,if(p["canClaim"]==false)FlareRedPacketTapAction.Details else FlareRedPacketTapAction.Open),busy=busy,disabled=action("open")==null,brandName=p["brandName"].words(),onOpen={request("open")})
}

/**
 * A scan code page (`flare.qr`): the presentation's props while the view is available, else null. The view itself
 * draws as the plain view (it keeps its fields, blocks and actions); the code goes above it.
 */
internal fun pluginQrPresentationProps(view: PluginViewModel): Map<*, *>? =
    view.presentation?.takeIf { view.available && it["renderer"] == "flare.qr" }?.let { it["props"].props() }

/** Remaining validity derives only from elapsed monotonic time since the resolved view was received. */
internal fun pluginQrRemainingMs(ttlMs: Long, receivedAtNanos: Long, nowNanos: Long): Long =
    (ttlMs - ((nowNanos - receivedAtNanos).coerceAtLeast(0L) / 1_000_000L)).coerceAtLeast(0L)

@Composable
internal fun PluginQrPresentation(props: Map<*, *>, receivedAtNanos: Long?, encodeQr: (suspend (String) -> String)?) {
    val token = (props["token"] as? String)?.takeIf { it.isNotBlank() } ?: return
    val receipt = receivedAtNanos ?: remember(props) { System.nanoTime() }
    val ttl = (props["ttlMs"] as? Number)?.toLong()?.coerceAtLeast(0L)
    var remaining by remember(receipt, ttl) { mutableStateOf(ttl?.let { pluginQrRemainingMs(it, receipt, System.nanoTime()) }) }
    val encoder by rememberUpdatedState(encodeQr)
    var payload by remember(token, receipt) { mutableStateOf<String?>(null) }
    var encoding by remember(token, receipt) { mutableStateOf(true) }
    LaunchedEffect(token, receipt) {
        payload = try { encoder?.invoke(token) } catch (cancelled: kotlinx.coroutines.CancellationException) { throw cancelled } catch (_: Exception) { null }
        encoding = false
    }
    LaunchedEffect(receipt, ttl) {
        if (ttl == null) return@LaunchedEffect
        do {
            remaining = pluginQrRemainingMs(ttl, receipt, System.nanoTime())
            if (remaining == 0L) break
            kotlinx.coroutines.delay(minOf(250L, remaining ?: 250L))
        } while (true)
    }
    val strings = flareStrings()
    Column(Modifier.fillMaxWidth(), horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
        when {
            remaining == 0L -> Text(strings.scanCodeExpired, color = flareColors().textSecondary)
            encoding -> androidx.compose.material3.CircularProgressIndicator()
            payload == null -> Text(strings.qrCardUnavailable, color = flareColors().textSecondary)
            else -> FlareQrMatrix(payload, strings.qrCode, Modifier.widthIn(max = androidx.compose.ui.unit.Dp(280f)))
        }
        (props["caption"] as? String)?.takeIf { it.isNotBlank() }?.let { Text(it, color = flareColors().textSecondary) }
    }
}
