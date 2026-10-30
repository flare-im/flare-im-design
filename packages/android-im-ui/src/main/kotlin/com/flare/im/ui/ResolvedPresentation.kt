package com.flare.im.ui

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.material3.Text
import androidx.compose.ui.Modifier
import java.math.BigInteger

private fun Any?.props(): Map<*, *> = this as? Map<*, *> ?: emptyMap<Any, Any>()
private fun Any?.words(): String = this as? String ?: ""
internal fun hasResolvedPresentation(view: PluginViewModel): Boolean {
 val kind=view.presentation?.get("renderer")
 return view.available && kind in listOf("redPacket.card","redPacket.composer","redPacket.detail","redPacket.pay","payment.confirm") && (kind!="redPacket.detail" || view.presentation?.get("props").props()["details"] is Map<*, *>)
}
/** Visual composition over resolved values. Requests are opaque IDs of visible actions. */
@Composable
internal fun ResolvedPresentation(view: PluginViewModel, busy: Boolean, error: String?, formErrors: List<PluginFormError>, members: List<PluginMember>, settleToken: Int,
 resolveUser: (suspend (String)->PluginUser?)?, onAction: ((String,PluginActionPayload)->Unit)?, onRequest: (String)->Unit) {
 val p=view.presentation?.get("props").props()
 val renderer=view.presentation?.get("renderer")
 val bound=view.presentation?.get("actions").props()
 fun action(name:String)=view.actions.firstOrNull { it.id==(bound[name] ?: if(name=="confirm")bound["authorize"] else null) }
 val unknown=p["journal"].props()["known"]==false
 val paymentBlocked=unknown||!error.isNullOrBlank()
 fun request(name:String){action(name)?.let { if(!busy&&!unknown&&!(name=="confirm"&&paymentBlocked))onRequest(it.id) }}
 val strings=flareStrings()
 var recipient by remember { mutableStateOf("") }
 var kind by remember { mutableStateOf(FlareRedPacketKind.Normal) }
 var amount by remember { mutableStateOf("") }
 var count by remember { mutableStateOf(1) }
 var greeting by remember { mutableStateOf(view.inputs.firstOrNull { it.id=="greeting" }?.default.words()) }
 var envelope by remember { mutableStateOf(false) }
 var paying by remember { mutableStateOf(true) }
 var people by remember { mutableStateOf<Map<String,PluginUser>>(emptyMap()) }
 val claims=(p["claims"] as? List<*>)?.map { it.props() }.orEmpty()
 val ids=listOf(p["senderId"].words())+claims.map { it["id"].words() }
 LaunchedEffect(ids,resolveUser) { val resolve=resolveUser?:return@LaunchedEffect; for(id in ids.distinct().filter { it.isNotEmpty() }) { val u=try { resolve(id) } catch(cancelled: kotlinx.coroutines.CancellationException) { throw cancelled } catch(_:Exception) { null };if(u!=null)people=people+(id to u) } }
 fun person(id:String)=people[id]?:PluginUser(PluginViewFormat.fallbackName(id))
 val sender=person(p["senderId"].words())
 val remainder=view.copy(presentation=null,title="",fields=if(renderer in listOf("redPacket.pay","payment.confirm"))view.fields else emptyList(),detail=false,
  blocks=if(renderer=="redPacket.card")emptyList() else view.blocks,actions=view.actions.filter { it.id !in bound.values })
 Column(Modifier.fillMaxWidth(),verticalArrangement=Arrangement.spacedBy(FlareSizes.spacingMd)) {
  when(renderer) {
   "redPacket.card" -> RedPacketCard(blessing=p["blessing"].words(),kind=FlareRedPacketKind.entries.firstOrNull { it.name.equals(p["kind"].words(),true) }?:FlareRedPacketKind.Normal,
    state=flareRedPacketCardState(FlareRedPacketStatus.entries.firstOrNull { it.wire==p["status"] }?:FlareRedPacketStatus.Open,p["claimedByMe"]==true,if(p["canClaim"]==false)FlareRedPacketTapAction.Details else FlareRedPacketTapAction.Open),busy=busy,disabled=action("open")==null,onOpen={request("open")})
   "redPacket.composer" -> {
    val asset=p["funding"].props()
     val exponent=(asset["currencyExponent"] as? Number)?.toInt()?:2
     val minor=flareRedPacketAmountMinor(amount,exponent)
     val total=if(minor!=null&&minor.length<=64)flareRedPacketAmountText((BigInteger(minor)*BigInteger.valueOf(if(kind==FlareRedPacketKind.Normal)count.toLong() else 1)).toString(),exponent).orEmpty() else ""
     RedPacketComposer(kinds=FlareRedPacketKind.entries,kind=kind,amount=amount,total="${asset["currency"].words()} $total",count=count,greeting=greeting,currencyExponent=exponent,
      busy=busy,locked=unknown||action("submit")==null,error=if(formErrors.isEmpty())null else strings.pluginFormInvalid,submitLabel=action("submit")?.label,
      recipient={Input(value=recipient,onValueChange={recipient=it},placeholder=view.inputs.firstOrNull { it.id=="designatedUserId" }?.label,disabled=busy||unknown,maxLength=128)},onKindChange={kind=it},onAmountChange={amount=it},onCountChange={count=it},onGreetingChange={greeting=it},
      onSubmit={action("submit")?.let { a->if(!busy&&!unknown)onAction?.invoke(a.id,PluginActionPayload(formValues=mapOf("designatedUserId" to if(kind==FlareRedPacketKind.Exclusive)recipient else "","kind" to kind.name.lowercase(),"decimalAmount" to amount,"shareCount" to if(kind==FlareRedPacketKind.Exclusive)1 else count,"greeting" to greeting))) }})
   }
   "redPacket.detail" -> {
    val d=p["details"].props()
    fun number(k:String)=(d[k] as? Number)?.toLong()?:0L
    val details=FlareRedPacketDetailsView(viewerRole=FlareRedPacketViewerRole.fromWire(d["viewerRole"] as? String)?:FlareRedPacketViewerRole.Ineligible,
     status=FlareRedPacketStatus.entries.firstOrNull { it.wire==d["status"] }?:FlareRedPacketStatus.Open,kind=FlareRedPacketKind.entries.firstOrNull { it.name.equals(d["kind"].words(),true) }?:FlareRedPacketKind.Normal,
     greeting=d["greeting"].words(),currency=d["currency"].words(),currencyExponent=number("currencyExponent").toInt(),claimedCount=number("claimedCount").toInt(),shareCount=number("shareCount").toInt(),createdAtMs=number("createdAtMs"),expiresAtMs=number("expiresAtMs"),claimsListed=d["claimsListed"]==true,
     totalMinor=d["totalMinor"] as? String,claimedMinor=d["claimedMinor"] as? String,refundedMinor=d["refundedMinor"] as? String,myAmountMinor=d["myAmountMinor"] as? String)
    RedPacketDetail(senderName=sender.name,senderAvatar=sender.avatarUrl,details=details,claims=claims.map { c->val id=c["id"].words();val user=person(id);FlareRedPacketClaim(id,user.name,c["amountMinor"].words(),(c["claimedAtMs"] as? Number)?.toLong()?:0L,user.avatarUrl,c["best"]==true) })
    action("open")?.let { Button(label=it.label,disabled=busy||unknown,onClick={envelope=true}) }
    if(envelope)RedPacketOpenSheet(senderName=sender.name,senderAvatar=sender.avatarUrl,blessing=details.greeting,onClose={envelope=false},onViewDetails={envelope=false},onOpen={envelope=false;request("open")})
   }
   "redPacket.pay", "payment.confirm" -> action("confirm")?.let { a ->
    Button(label=a.label,disabled=busy||paymentBlocked,onClick={paying=true})
    if(paying&&!paymentBlocked)RedPacketPayConfirm(confirmLabel=a.label,amount=p["amount"].words(),methodLabel=p["methodLabel"].words(),busy=busy,onCancel={paying=false},onConfirm={paying=false;request("confirm")})
   }
  }
  if(renderer!="redPacket.card")PluginView(view=remainder,embedded=true,busy=busy,error=error,formErrors=formErrors,members=members,settleToken=settleToken,resolveUser=resolveUser,onAction=onAction)
 }
}
