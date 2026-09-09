package com.flare.im.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
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
 Column(Modifier.fillMaxWidth(),verticalArrangement=Arrangement.spacedBy(8.dp)) {
  Text(title,style=MaterialTheme.typography.titleMedium)
  if(loading) LinearProgressIndicator(Modifier.fillMaxWidth())
  if(error!=null) StatusBanner(error,tone=FlareStatusTone.Danger,actionText="重试",onAction=if(loading)null else onReload)
  if(items.isEmpty()&&!loading&&error==null) Text("暂无内容",Modifier.padding(16.dp))
  items.forEach { item ->
   Column(Modifier.fillMaxWidth().padding(vertical=12.dp)) {
    Text(item.title,style=MaterialTheme.typography.titleSmall)
    item.badge?.let { Text(it) };Text(item.detail)
    item.error?.let { StatusBanner(it,tone=FlareStatusTone.Danger) }
    if(item.busy) LinearProgressIndicator(Modifier.fillMaxWidth())
    FlowRow(horizontalArrangement=Arrangement.spacedBy(8.dp)) { item.actions.filter { it.label.isNotBlank() }.forEach { a ->
     TextButton(onClick={onAction?.invoke(item.id,a.id)},enabled=!item.busy&&!a.disabled&&onAction!=null,modifier=Modifier.defaultMinSize(minWidth=48.dp,minHeight=48.dp)) { Text(a.label,color=if(a.destructive)MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary) }
    } }
   }
  }
 }
}
@Composable
fun MemberPanel(items:List<FlareSceneEntry>,title:String="群成员",loading:Boolean=false,error:String?=null,onAction:((String,String)->Unit)?=null,onReload:(()->Unit)?=null) { SceneList(title,items,loading,error,onAction,onReload) }
@Composable
fun DeviceSessions(items:List<FlareDeviceSessionEntry>,title:String="登录设备",currentText:String="当前设备",loading:Boolean=false,error:String?=null,onAction:((String,String)->Unit)?=null,onReload:(()->Unit)?=null) {
 SceneList(title,items.map { if(it.current) it.entry.copy(badge=currentText,actions=emptyList()) else it.entry },loading,error,onAction,onReload)
}
@Composable
fun MediaCenter(items:List<FlareMediaEntry>,transfers:List<FlareTransferQueueItem>?=null,title:String="文件与媒体",loading:Boolean=false,error:String?=null,onAction:((String,String)->Unit)?=null,onReload:(()->Unit)?=null,onTransferAction:((String,FlareTransferAction)->Unit)?=null,onRetryFailed:((List<String>)->Unit)?=null) {
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
@Composable
fun NotificationPreferences(items:List<FlareNotificationPreference>,permission:FlareCapabilityState,permissionText:String,permissionActionText:String?=null,title:String="通知设置",onChange:((String,Boolean)->Unit)?=null,onPermissionAction:(()->Unit)?=null) {
 Column {
  Text(title,style=MaterialTheme.typography.titleMedium)
  CapabilityBoundary(permission,permissionText,permissionActionText,onPermissionAction){Text(permissionText)}
  items.forEach { i -> Row(Modifier.fillMaxWidth().padding(vertical=12.dp)) {
   Column(Modifier.weight(1f)) {Text(i.title);Text(i.detail)}
   Switch(checked=i.value,onCheckedChange={onChange?.invoke(i.id,it)},enabled=permission==FlareCapabilityState.Available&&i.enabled&&!i.busy&&onChange!=null)
  } }
 }
}
@Composable
fun DangerConfirm(title:String,description:String,target:String,busy:Boolean=false,error:String?=null,confirmText:String="确认",cancelText:String="取消",onConfirm:()->Unit,onCancel:()->Unit) {
 AlertDialog(onDismissRequest={if(!busy)onCancel()},title={Text(title)},text={Column(Modifier.verticalScroll(rememberScrollState())) {Text(description);Text(target,style=MaterialTheme.typography.titleSmall);error?.let {Text(it)}}},
 confirmButton={TextButton(onClick=onConfirm,enabled=!busy,modifier=Modifier.defaultMinSize(minHeight=48.dp,minWidth=48.dp)){Text(confirmText,color=MaterialTheme.colorScheme.error)}},dismissButton={TextButton(onClick=onCancel,enabled=!busy,modifier=Modifier.defaultMinSize(minHeight=48.dp,minWidth=48.dp)){Text(cancelText)}})
}
