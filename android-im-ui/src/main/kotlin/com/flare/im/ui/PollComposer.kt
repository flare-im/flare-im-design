package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.CheckBox
import androidx.compose.material.icons.outlined.CheckBoxOutlineBlank
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Create-a-poll form. Spec: Composer/PollComposer. */
@Composable
fun PollComposer(
    maxOptions: Int = 10,
    onSubmit: ((question: String, options: List<String>, multiple: Boolean) -> Unit)? = null,
    onCancel: (() -> Unit)? = null,
) {
    val colors = flareColors()
    var question by remember { mutableStateOf("") }
    val options = remember { mutableStateListOf("", "") }
    var multiple by remember { mutableStateOf(false) }
    val filled = options.map { it.trim() }.filter { it.isNotEmpty() }
    val canSubmit = question.trim().isNotEmpty() && filled.size >= 2

    Column(
        Modifier.width(320.dp).clip(RoundedCornerShape(FlareSizes.radiusXl)).background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text(flareStrings().createPoll, color = colors.textPrimary, fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSizeLg.value.sp)
            Spacer(Modifier.weight(1f))
            Icon(Icons.Outlined.Close, contentDescription = flareStrings().cancel, tint = colors.textTertiary,
                modifier = Modifier.size(18.dp).clickable { onCancel?.invoke() })
        }
        Box(Modifier.fillMaxWidth().padding(bottom = 4.dp)) {
            BasicTextField(
                value = question, onValueChange = { question = it }, singleLine = true,
                textStyle = TextStyle(color = colors.textPrimary, fontSize = 15.sp, fontWeight = FontWeight.Medium),
                cursorBrush = SolidColor(colors.primary), modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
                decorationBox = { inner ->
                    if (question.isEmpty()) Text(flareStrings().pollQuestionHint, color = colors.textTertiary, fontSize = 15.sp)
                    inner()
                },
            )
            Box(Modifier.fillMaxWidth().height(1.5.dp).background(colors.borderPrimary).align(Alignment.BottomCenter))
        }
        options.forEachIndexed { i, value ->
            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgSecondary)
                    .padding(start = 12.dp, end = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                BasicTextField(
                    value = value, onValueChange = { options[i] = it }, singleLine = true,
                    textStyle = TextStyle(color = colors.textPrimary, fontSize = 14.sp),
                    cursorBrush = SolidColor(colors.primary), modifier = Modifier.weight(1f).padding(vertical = 9.dp),
                    decorationBox = { inner ->
                        if (value.isEmpty()) Text(flareStrings().pollOptionHint(i + 1), color = colors.textTertiary, fontSize = 14.sp)
                        inner()
                    },
                )
                if (options.size > 2) {
                    Icon(Icons.Outlined.Close, contentDescription = flareStrings().removeOption, tint = colors.textTertiary,
                        modifier = Modifier.size(16.dp).padding(4.dp).clickable { options.removeAt(i) })
                }
            }
        }
        if (options.size < maxOptions) {
            Row(
                Modifier.clickable { options.add("") },
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Outlined.Add, contentDescription = null, tint = colors.primary, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(4.dp))
                Text(flareStrings().addOption, color = colors.primary, fontSize = 13.sp)
            }
        }
        Row(
            Modifier.clickable { multiple = !multiple },
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(if (multiple) Icons.Outlined.CheckBox else Icons.Outlined.CheckBoxOutlineBlank,
                contentDescription = null, tint = if (multiple) colors.primary else colors.textTertiary, modifier = Modifier.size(16.dp))
            Spacer(Modifier.width(6.dp))
            Text(flareStrings().allowMultiple, color = colors.textSecondary, fontSize = 13.sp)
        }
        Box(
            Modifier.fillMaxWidth().height(40.dp).clip(RoundedCornerShape(FlareSizes.radiusLg))
                .background(if (canSubmit) colors.primary else colors.bgSecondary)
                .then(if (canSubmit) Modifier.clickable { onSubmit?.invoke(question.trim(), filled, multiple) } else Modifier),
            contentAlignment = Alignment.Center,
        ) {
            Text(flareStrings().submitPoll, color = if (canSubmit) Color.White else colors.textTertiary,
                fontWeight = FontWeight.SemiBold, fontSize = FlareSizes.fontSizeMd.value.sp)
        }
    }
}
