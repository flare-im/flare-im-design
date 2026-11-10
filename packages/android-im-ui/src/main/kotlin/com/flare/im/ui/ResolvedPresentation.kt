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
 resolveUser: (suspend (String)->PluginUser?)?, onAction: ((String,PluginActionPayload)->Unit)?, onRequest: (String)->Unit,
    membersLoading: Boolean = false,
    membersError: String? = null,
    onMemberSearch: ((String) -> Unit)? = null,
    onMembersRetry: (() -> Unit)? = null,
    membersRevision: Int = 0,
) {
 val p=view.presentation?.get("props").props()
 val renderer=view.presentation?.get("renderer")
 val bound=view.presentation?.get("actions").props()
 fun action(name:String)=view.actions.firstOrNull { it.id==(bound[name] ?: if(name=="confirm")bound["authorize"] else null) }
 val unknown=p["journal"].props()["known"]==false
 var paymentPassword by remember { mutableStateOf("") }
 val passwordInput=view.inputs.firstOrNull { it.kind==PluginInputKind.Password && (action("confirm")?.form?.contains(it.id)==true) }
 val passwordValid=passwordInput==null||Regex("^[0-9]{6}$").matches(paymentPassword)
 val paymentBlocked=unknown||(!error.isNullOrBlank()&&passwordInput==null)
 fun request(name:String){action(name)?.let { if(!busy&&!unknown&&!(name=="confirm"&&paymentBlocked))onRequest(it.id) }}
 val strings=flareStrings()
 var recipient by remember { mutableStateOf<PluginMember?>(null) }
 var choosingRecipient by remember { mutableStateOf(false) }
 var recipientRevision by remember { mutableStateOf(membersRevision) }
 var memberGeneration by remember { mutableStateOf(membersRevision) }
 val currentMembers by rememberUpdatedState(members)
 val currentMemberLoading by rememberUpdatedState(membersLoading)
 val currentMemberError by rememberUpdatedState(membersError)
 val currentMemberRevision by rememberUpdatedState(membersRevision)
 val currentBlocked by rememberUpdatedState(busy || unknown)
 var kind by remember { mutableStateOf(FlareRedPacketKind.Normal) }
 var amount by remember { mutableStateOf("") }
 var count by remember { mutableStateOf(1) }
 var greeting by remember { mutableStateOf(view.inputs.firstOrNull { it.id=="greeting" }?.default.words()) }
 val kinds = when(p["conversationType"]) {
  "single" -> listOf(FlareRedPacketKind.Normal)
  "group" -> FlareRedPacketKind.entries
  else -> emptyList()
 }
 LaunchedEffect(p["conversationType"]) { if(kind !in kinds)kind=FlareRedPacketKind.Normal;recipient=null;choosingRecipient=false }
 LaunchedEffect(membersRevision) { if(memberGeneration!=membersRevision) { memberGeneration=membersRevision;recipient=null;choosingRecipient=false } }
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
    state=flareRedPacketCardState(FlareRedPacketStatus.entries.firstOrNull { it.wire==p["status"] }?:FlareRedPacketStatus.Open,p["claimedByMe"]==true,if(p["canClaim"]==false)FlareRedPacketTapAction.Details else FlareRedPacketTapAction.Open),busy=busy,disabled=action("open")==null,brandName=p["brandName"].words(),onOpen={request("open")})
   "redPacket.composer" -> {
    val asset=p["funding"].props()
     val exponent=(asset["currencyExponent"] as? Number)?.toInt()?:2
     val minor=flareRedPacketAmountMinor(amount,exponent)
     val shares=if(kind==FlareRedPacketKind.Exclusive||p["conversationType"]=="single")1 else count
     val total=if(minor!=null&&minor.length<=64)flareRedPacketAmountText((BigInteger(minor)*BigInteger.valueOf(if(kind==FlareRedPacketKind.Normal)shares.toLong() else 1)).toString(),exponent).orEmpty() else ""
     val recipientInput=view.inputs.firstOrNull { it.id=="designatedUserIds" }
     val recipientLabel=recipientInput?.label?:strings.packetFieldRecipient
     RedPacketComposer(kinds=kinds,kind=kind,amount=amount,total="${asset["currency"].words()} $total",count=count,greeting=greeting,currencyExponent=exponent,
      busy=busy,locked=unknown||action("submit")==null||kinds.isEmpty()||(kind==FlareRedPacketKind.Exclusive&&recipient==null),error=if(formErrors.isEmpty())null else strings.pluginFormInvalid,submitLabel=action("submit")?.label,
      recipient={Button(label=recipient?.name?:strings.select,variant=FlareButtonVariant.Secondary,disabled=busy||unknown||(onMemberSearch==null&&members.isEmpty()),onClick={recipientRevision=membersRevision;choosingRecipient=true;onMemberSearch?.invoke("")})},onKindChange={kind=it},onAmountChange={amount=it},onCountChange={count=it},onGreetingChange={greeting=it},
      onSubmit={action("submit")?.let { a->if(!busy&&!unknown&&kind in kinds&&(kind!=FlareRedPacketKind.Exclusive||recipient!=null))onAction?.invoke(a.id,PluginActionPayload(formValues=mapOf("designatedUserIds" to if(kind==FlareRedPacketKind.Exclusive)listOfNotNull(recipient?.userId) else emptyList<String>(),"kind" to kind.name.lowercase(),"decimalAmount" to amount,"shareCount" to shares,"greeting" to greeting))) }})
     if(choosingRecipient)BottomSheet(onClose={choosingRecipient=false},title=recipientLabel,titleHidden=true) {
      ContactPicker(groups=listOf(FlareContactPickerGroup(FlareContactPickerGroup.GROUP_MEMBERS,recipientLabel,members.map { FlareContactPickerEntry(it.userId,it.name,it.avatarUrl) })),multiple=false,title=recipientLabel,
       onSearch=onMemberSearch,loading=membersLoading,error=membersError,onRetry=onMembersRetry,
       onSelect={entries->if(choosingRecipient&&!currentBlocked&&!currentMemberLoading&&currentMemberError.isNullOrBlank()&&currentMemberRevision==recipientRevision) { val id=entries.firstOrNull()?.userId;recipient=currentMembers.firstOrNull { it.userId==id };choosingRecipient=false }},onCancel={choosingRecipient=false})
     }
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
    if(paying&&!paymentBlocked)RedPacketPayConfirm(confirmLabel=a.label,amount=p["amount"].words(),methodLabel=p["methodLabel"].words(),busy=busy,onCancel={paymentPassword="";paying=false},
      confirmDisabled=!passwordValid,
      credential=if(passwordInput==null)null else ({Input(value=paymentPassword,onValueChange={paymentPassword=it.take(6)},placeholder=passwordInput.placeholder?:passwordInput.label,disabled=busy,secure=true)}),
      onConfirm={if(passwordValid&&!busy&&!paymentBlocked){paying=false;if(passwordInput!=null){val value=paymentPassword;paymentPassword="";onAction?.invoke(a.id,PluginActionPayload(formValues=mapOf(passwordInput.id to value)))}else request("confirm")}})
   }
  }
  if(renderer!="redPacket.card")PluginView(view=remainder,embedded=true,busy=busy,error=error,formErrors=formErrors,members=members, membersLoading = membersLoading, membersError = membersError, onMemberSearch = onMemberSearch, onMembersRetry = onMembersRetry, membersRevision = membersRevision, settleToken=settleToken,resolveUser=resolveUser,onAction=onAction)
 }
}
