package com.flare.im.ui

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.material3.Text
import androidx.compose.ui.Modifier

private fun Any?.props(): Map<*, *> = this as? Map<*, *> ?: emptyMap<Any, Any>()
private fun Any?.words(): String = this as? String ?: ""
/**
 * The compiled-in renderers this kit still draws (its vocabulary's `renderers`): the red packet card and the payment
 * confirmation. The composer, the detail, the account page and the QR renderer moved to blocks and draw as plain views.
 */
internal fun hasResolvedPresentation(view: PluginViewModel): Boolean =
 view.available && view.presentation?.get("renderer") in listOf("redPacket.card","redPacket.pay","payment.confirm")
/** Visual composition over resolved values. Requests are opaque IDs of visible actions. */
@Composable
internal fun ResolvedPresentation(view: PluginViewModel, busy: Boolean, error: String?, formErrors: List<PluginFormError>, members: List<PluginMember>, settleToken: Int,
 resolveUser: (suspend (String)->PluginUser?)?, onAction: ((String,PluginActionPayload)->Unit)?, onRequest: (String)->Unit,
    membersLoading: Boolean = false,
    membersError: String? = null,
    onMemberSearch: ((String) -> Unit)? = null,
    onMembersRetry: (() -> Unit)? = null,
    membersRevision: Int = 0,
    resolveImage: (suspend (PluginImageSource) -> String?)? = null,
    onQrRefresh: ((PluginQrRefresh) -> Unit)? = null,
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
 var paying by remember { mutableStateOf(true) }
 val remainder=view.copy(presentation=null,title="",fields=if(renderer in listOf("redPacket.pay","payment.confirm"))view.fields else emptyList(),detail=false,
  blocks=if(renderer=="redPacket.card")emptyList() else view.blocks,actions=view.actions.filter { it.id !in bound.values })
 Column(Modifier.fillMaxWidth(),verticalArrangement=Arrangement.spacedBy(FlareSizes.spacingMd)) {
  when(renderer) {
   "redPacket.card" -> RedPacketCard(blessing=p["blessing"].words(),kind=FlareRedPacketKind.entries.firstOrNull { it.name.equals(p["kind"].words(),true) }?:FlareRedPacketKind.Normal,
    state=flareRedPacketCardState(FlareRedPacketStatus.entries.firstOrNull { it.wire==p["status"] }?:FlareRedPacketStatus.Open,p["claimedByMe"]==true,if(p["canClaim"]==false)FlareRedPacketTapAction.Details else FlareRedPacketTapAction.Open),busy=busy,disabled=action("open")==null,brandName=p["brandName"].words(),onOpen={request("open")})
   "redPacket.pay", "payment.confirm" -> action("confirm")?.let { a ->
    Button(label=a.label,disabled=busy||paymentBlocked,onClick={paying=true})
    if(paying&&!paymentBlocked)RedPacketPayConfirm(confirmLabel=a.label,amount=p["amount"].words(),methodLabel=p["methodLabel"].words(),busy=busy,onCancel={paymentPassword="";paying=false},
      confirmDisabled=!passwordValid,
      credential=if(passwordInput==null)null else ({Input(value=paymentPassword,onValueChange={paymentPassword=it.take(6)},placeholder=passwordInput.placeholder?:passwordInput.label,disabled=busy,secure=true)}),
      onConfirm={if(passwordValid&&!busy&&!paymentBlocked){paying=false;if(passwordInput!=null){val value=paymentPassword;paymentPassword="";onAction?.invoke(a.id,PluginActionPayload(formValues=mapOf(passwordInput.id to value)))}else request("confirm")}})
   }
  }
  if(renderer!="redPacket.card")PluginView(view=remainder,embedded=true,busy=busy,error=error,formErrors=formErrors,members=members, membersLoading = membersLoading, membersError = membersError, onMemberSearch = onMemberSearch, onMembersRetry = onMembersRetry, membersRevision = membersRevision, settleToken=settleToken,resolveUser=resolveUser,onAction=onAction,
   // The blocks under a pay sheet draw images and refresh QR codes as any view does.
   resolveImage=resolveImage,onQrRefresh=onQrRefresh)
 }
}
