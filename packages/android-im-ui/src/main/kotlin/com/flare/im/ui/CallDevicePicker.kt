package com.flare.im.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.unit.dp

enum class FlareCallDeviceKind { Microphone, Speaker, Camera }
data class FlareCallDevice(val id:String,val label:String,val disabled:Boolean=false)
data class FlareCallDeviceGroup(val kind:FlareCallDeviceKind,val label:String,val selectedId:String?=null,val devices:List<FlareCallDevice>,val busy:Boolean=false) {
    val uniqueDevices get()=devices.filter{it.id.isNotEmpty()}.distinctBy{it.id}
}
@Suppress("NAME_SHADOWING")
@Composable
fun CallDevicePicker(groups:List<FlareCallDeviceGroup>,permission:FlareCapabilityState,permissionText:String,actionText:String?=null,placeholder:String?=null,onSelect:((FlareCallDeviceKind,String)->Unit)?=null,onPermissionAction:(()->Unit)?=null) {
    val strings = flareStrings()
    val placeholder = placeholder ?: strings.selectDevice
    Column(Modifier.widthIn(max = FlareSizes.componentCallDevicePanelWidth), verticalArrangement=Arrangement.spacedBy(FlareSizes.spacingMd)) {
        CapabilityBoundary(state=permission,text=permissionText,actionText=actionText,onAction=onPermissionAction){Text(permissionText)}
        groups.forEach { group -> key(group.kind) {
            val devices=group.uniqueDevices
            val enabled=permission==FlareCapabilityState.Available&&!group.busy&&devices.any{!it.disabled}&&onSelect!=null
            var expanded by remember { mutableStateOf(false) }
            LaunchedEffect(enabled) { if(!enabled) expanded=false }
            Column {
                // 3.6: a group switching devices shows a small spinner after its title.
                Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                    Text(group.label, fontSize = FlareSizes.fontSizeSm, color = flareColors().callOnStageSecondary)
                    if (group.busy) CircularProgressIndicator(Modifier.size(FlareSizes.iconSizeSm).semantics { contentDescription = strings.loading }, strokeWidth = 2.dp)
                }
                Box {
                    OutlinedButton(onClick={expanded=true},enabled=enabled,modifier=Modifier.fillMaxWidth().heightIn(min=48.dp).semantics { contentDescription=group.label }) {
                        Text(devices.find{it.id==group.selectedId}?.label?:placeholder)
                    }
                    DropdownMenu(expanded=expanded&&enabled,onDismissRequest={expanded=false}) {
                        // 3.6: one choice per group — the chosen device ends with check 16 and reads as selected.
                        devices.forEach { device ->
                            val chosen = device.id == group.selectedId
                            DropdownMenuItem(
                                text = { Text(device.label, maxLines = 1, overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis) },
                                trailingIcon = if (chosen) ({ FlareIcon("check", size = FlareSizes.iconSizeSm) }) else null,
                                enabled = !device.disabled,
                                modifier = Modifier.heightIn(min = 48.dp).semantics { role = Role.RadioButton; selected = chosen },
                                onClick = { expanded = false; if (enabled && !device.disabled) onSelect?.invoke(group.kind, device.id) },
                            )
                        }
                    }
                }
            }
        } }
    }
}
