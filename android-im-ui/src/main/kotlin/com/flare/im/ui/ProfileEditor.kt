package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.PhotoCamera
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/**
 * Profile editor — avatar, name and signature fields with save / cancel.
 * Spec: Profile/ProfileEditor (`ProfileEditor`).
 */
@Composable
fun ProfileEditor(
    user: UserProfile,
    busy: Boolean = false,
    onSave: ((name: String, signature: String) -> Unit)? = null,
    onCancel: (() -> Unit)? = null,
    onPickAvatar: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var name by remember { mutableStateOf(user.name) }
    var signature by remember { mutableStateOf(user.signature ?: "") }

    Column(Modifier.fillMaxWidth().padding(FlareSizes.spacingLg)) {
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            Box(contentAlignment = Alignment.BottomEnd) {
                Avatar(userId = user.id, displayName = name.ifEmpty { user.name }, size = 80.dp)
                Box(
                    Modifier.size(28.dp).clip(CircleShape).background(colors.primary)
                        .clickable { onPickAvatar?.invoke() },
                    contentAlignment = Alignment.Center,
                ) { Icon(Icons.Outlined.PhotoCamera, "更换头像", tint = Color.White, modifier = Modifier.size(16.dp)) }
            }
        }
        Spacer(Modifier.height(FlareSizes.spacingLg))
        Text("昵称", color = colors.textSecondary)
        Input(value = name, onValueChange = { name = it }, placeholder = "昵称", maxLength = 24, clearable = true)
        Spacer(Modifier.height(FlareSizes.spacingMd))
        Text("个性签名", color = colors.textSecondary)
        Input(value = signature, onValueChange = { signature = it }, placeholder = "介绍一下自己", multiline = true, maxLength = 60)
        Spacer(Modifier.height(FlareSizes.spacingLg))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
            OutlinedButton(onClick = { onCancel?.invoke() }, modifier = Modifier.weight(1f)) { Text("取消") }
            Button(
                onClick = { onSave?.invoke(name, signature) },
                enabled = name.isNotBlank() && !busy,
                colors = ButtonDefaults.buttonColors(containerColor = colors.primary),
                modifier = Modifier.weight(1f),
            ) {
                if (busy) CircularProgressIndicator(Modifier.size(18.dp), color = Color.White, strokeWidth = 2.dp)
                else Text("保存")
            }
        }
    }
}
