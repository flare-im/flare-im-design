package com.flare.im.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.unit.dp

enum class FlareCallDeviceKind { Microphone, Speaker, Camera }
data class FlareCallDevice(val id:String,val label:String,val disabled:Boolean=false)
data class FlareCallDeviceGroup(val kind:FlareCallDeviceKind,val label:String,val selectedId:String?=null,val devices:List<FlareCallDevice>,val busy:Boolean=false) {
    val uniqueDevices get()=devices.filter{it.id.isNotEmpty()}.distinctBy{it.id}
}
@Composable
fun CallDevicePicker(groups:List<FlareCallDeviceGroup>,permission:FlareCapabilityState,permissionText:String,actionText:String?=null,placeholder:String="选择设备",onSelect:((FlareCallDeviceKind,String)->Unit)?=null,onPermissionAction:(()->Unit)?=null) {
    Column(verticalArrangement=Arrangement.spacedBy(12.dp)) {
        CapabilityBoundary(state=permission,text=permissionText,actionText=actionText,onAction=onPermissionAction){Text(permissionText)}
        groups.forEach { group -> key(group.kind) {
            val devices=group.uniqueDevices
            val enabled=permission==FlareCapabilityState.Available&&!group.busy&&devices.any{!it.disabled}&&onSelect!=null
            var expanded by remember { mutableStateOf(false) }
            LaunchedEffect(enabled) { if(!enabled) expanded=false }
            Column {
                Text(group.label)
                Box {
                    OutlinedButton(onClick={expanded=true},enabled=enabled,modifier=Modifier.fillMaxWidth().heightIn(min=48.dp).semantics { contentDescription=group.label }) {
                        Text(devices.find{it.id==group.selectedId}?.label?:placeholder)
                    }
                    DropdownMenu(expanded=expanded&&enabled,onDismissRequest={expanded=false}) {
                        devices.forEach { device -> DropdownMenuItem(text={Text(device.label)},enabled=!device.disabled,modifier=Modifier.heightIn(min=48.dp),onClick={expanded=false;if(enabled&&!device.disabled)onSelect?.invoke(group.kind,device.id)}) }
                    }
                }
            }
        } }
    }
}
