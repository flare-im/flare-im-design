package com.flare.im.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

enum class FlareCapabilityState { Loading, Available, Unavailable, Denied, Failed }
data class FlareSceneAction(val id:String,val label:String,val destructive:Boolean=false,val disabled:Boolean=false)
data class FlareSceneEntry(val id:String,val title:String,val detail:String,val badge:String?=null,val busy:Boolean=false,val actions:List<FlareSceneAction> = emptyList(),val error:String?=null)
data class FlareDeviceSessionEntry(val entry:FlareSceneEntry,val current:Boolean=false)
enum class FlareMediaAvailability { Available, Expired, Unavailable }
enum class FlareMediaKind { Image, Video, Audio, File }
data class FlareMediaEntry(val entry:FlareSceneEntry,val kind:FlareMediaKind,val availability:FlareMediaAvailability)
data class FlareNotificationPreference(val id:String,val title:String,val detail:String,val value:Boolean,val enabled:Boolean,val busy:Boolean=false)

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun SceneList(title:String,items:List<FlareSceneEntry>,loading:Boolean=false,error:String?=null,onAction:((String,String)->Unit)?=null,onReload:(()->Unit)?=null) {
 val strings = flareStrings()
 Column(Modifier.fillMaxWidth(),verticalArrangement=Arrangement.spacedBy(FlareSizes.spacingSm)) {
  Text(title,style=MaterialTheme.typography.titleMedium)
  if(loading) LinearProgressIndicator(Modifier.fillMaxWidth())
  if(error!=null) StatusBanner(error,tone=FlareStatusTone.Danger,actionText=strings.retry,onAction=if(loading)null else onReload)
  if(items.isEmpty()&&!loading&&error==null) Text(strings.noContent,Modifier.padding(FlareSizes.spacingLg))
  items.forEach { item ->
   Column(Modifier.fillMaxWidth().padding(vertical=FlareSizes.spacingMd)) {
    Text(item.title,style=MaterialTheme.typography.titleSmall)
    item.badge?.let { Text(it) };Text(item.detail)
    item.error?.let { StatusBanner(it,tone=FlareStatusTone.Danger) }
    if(item.busy) LinearProgressIndicator(Modifier.fillMaxWidth())
    FlowRow(horizontalArrangement=Arrangement.spacedBy(FlareSizes.spacingSm)) { item.actions.filter { it.label.isNotBlank() }.forEach { a ->
     TextButton(onClick={onAction?.invoke(item.id,a.id)},enabled=!item.busy&&!a.disabled&&onAction!=null,modifier=Modifier.defaultMinSize(minWidth=48.dp,minHeight=48.dp)) { Text(a.label,color=if(a.destructive)MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary) }
    } }
   }
  }
 }
}
@Suppress("NAME_SHADOWING")
@Composable
fun MemberPanel(items:List<FlareSceneEntry>,title:String?=null,loading:Boolean=false,error:String?=null,onAction:((String,String)->Unit)?=null,onReload:(()->Unit)?=null) {
 val strings = flareStrings()
 val title = title ?: strings.groupMembers
 SceneList(title,items,loading,error,onAction,onReload) }
@Suppress("NAME_SHADOWING")
@Composable
fun DeviceSessions(items:List<FlareDeviceSessionEntry>,title:String?=null,currentText:String?=null,loading:Boolean=false,error:String?=null,onAction:((String,String)->Unit)?=null,onReload:(()->Unit)?=null) {
 val strings = flareStrings()
 val title = title ?: strings.loginDevices
 val currentText = currentText ?: strings.currentDevice
 SceneList(title,items.map { if(it.current) it.entry.copy(badge=currentText,actions=emptyList()) else it.entry },loading,error,onAction,onReload)
}
@Suppress("NAME_SHADOWING")
@Composable
fun MediaCenter(items:List<FlareMediaEntry>,transfers:List<FlareTransferQueueItem>?=null,title:String?=null,loading:Boolean=false,error:String?=null,onAction:((String,String)->Unit)?=null,onReload:(()->Unit)?=null,onTransferAction:((String,FlareTransferAction)->Unit)?=null,onRetryFailed:((List<String>)->Unit)?=null) {
 val strings = flareStrings()
 val title = title ?: strings.filesAndMedia
 Column { SceneList(title,items.map { i -> i.entry.copy(actions=i.entry.actions.filter { i.availability==FlareMediaAvailability.Available || it.id!="open" }) },loading,error,onAction,onReload)
  if(transfers!=null) Box(Modifier.height(400.dp)) { TransferQueue(transfers,onAction=onTransferAction,onRetryFailed=onRetryFailed) }
 }
}
@Composable
fun CapabilityBoundary(state:FlareCapabilityState,text:String,actionText:String?=null,onAction:(()->Unit)?=null,content:@Composable ()->Unit) {
 if(state==FlareCapabilityState.Available) content() else Column {
  if(state==FlareCapabilityState.Loading) LinearProgressIndicator(Modifier.fillMaxWidth())
  StatusBanner(text,tone=if(state==FlareCapabilityState.Failed)FlareStatusTone.Danger else FlareStatusTone.Neutral,actionText=actionText,onAction=if(state==FlareCapabilityState.Loading)null else onAction)
 }
}
@Suppress("NAME_SHADOWING")
@Composable
fun NotificationPreferences(items:List<FlareNotificationPreference>,permission:FlareCapabilityState,permissionText:String,permissionActionText:String?=null,title:String?=null,onChange:((String,Boolean)->Unit)?=null,onPermissionAction:(()->Unit)?=null) {
 val strings = flareStrings()
 val title = title ?: strings.notificationSettings
 Column {
  Text(title,style=MaterialTheme.typography.titleMedium)
  CapabilityBoundary(permission,permissionText,permissionActionText,onPermissionAction){Text(permissionText)}
  items.forEach { i -> Row(Modifier.fillMaxWidth().padding(vertical=FlareSizes.spacingMd)) {
   Column(Modifier.weight(1f)) {Text(i.title);Text(i.detail)}
   Switch(checked=i.value,onCheckedChange={onChange?.invoke(i.id,it)},enabled=permission==FlareCapabilityState.Available&&i.enabled&&!i.busy&&onChange!=null)
  } }
 }
}
/**
 * Confirmation before something destructive or irreversible: what happens ([description]), to what ([target]),
 * cancel and a danger confirm. Spec: Overlay/DangerConfirm. Hosted in [BottomSheet] with the automatic
 * presentation — a bottom sheet on the phone form factor (stacked full-width keys, danger last) and a centered
 * [Modal] elsewhere (keys at the trailing end) — like Vue and Flutter. Closing by the scrim, back or Escape is a
 * cancel; while [busy] nothing closes it and both keys are disabled. A failure shows [error], announced at once.
 */
@Suppress("NAME_SHADOWING")
@Composable
fun DangerConfirm(title:String,description:String,target:String,busy:Boolean=false,error:String?=null,confirmText:String?=null,cancelText:String?=null,onConfirm:()->Unit,onCancel:()->Unit) {
 val strings = flareStrings()
 val colors = flareColors()
 val confirmText = confirmText ?: strings.confirmAction
 val cancelText = cancelText ?: strings.cancel
 BottomSheet(onClose = { if (!busy) onCancel() }, title = title, dismissible = !busy) {
  val stacked = LocalFlareOverlaySurface.current == FlareOverlaySurfaceKind.Sheet
  Column(
   Modifier.fillMaxWidth().weight(1f, fill = false).verticalScroll(rememberScrollState())
    .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
   verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
  ) {
   Text(description, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg)
   if (target.isNotBlank()) Text(target, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg, fontWeight = FontWeight.SemiBold)
   error?.let { Text(it, color = colors.errorText, fontSize = FlareSizes.fontSizeMd, modifier = Modifier.semantics { liveRegion = LiveRegionMode.Assertive }) }
  }
  val cancel: @Composable () -> Unit = { Button(label = cancelText, variant = FlareButtonVariant.Secondary, disabled = busy, block = stacked, onClick = onCancel) }
  val confirm: @Composable () -> Unit = { Button(label = confirmText, variant = FlareButtonVariant.Danger, disabled = busy, loading = busy, block = stacked, onClick = onConfirm) }
  if (stacked) {
   Column(Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) { cancel(); confirm() }
  } else {
   Row(Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm, Alignment.End)) { cancel(); confirm() }
  }
 }
}
