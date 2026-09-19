package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.FormatListBulleted
import androidx.compose.material.icons.rounded.Code
import androidx.compose.material.icons.rounded.FormatBold
import androidx.compose.material.icons.rounded.FormatItalic
import androidx.compose.material.icons.rounded.Link
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.sp

data class FlareRichMarkdownLabels(
    val bold: String = "加粗",
    val italic: String = "斜体",
    val code: String = "代码",
    val list: String = "列表",
    val link: String = "链接",
)

/**
 * The rich (RichDoc/Markdown) text field with a formatting bar, optional live
 * preview, and length limit. Spec: Composer/RichMarkdownInput
 * (`RichMarkdownInput`). Used inside [Composer].
 */
@Composable
fun RichMarkdownInput(
    value: String,
    onValueChange: (String) -> Unit,
    disabled: Boolean = false,
    formattingPreview: Boolean = false,
    showFormatBar: Boolean = true,
    maxLength: Int? = null,
    placeholder: String = "",
    labels: FlareRichMarkdownLabels = FlareRichMarkdownLabels(),
) {
    val colors = flareColors()
    Column(Modifier.fillMaxWidth()) {
        if (showFormatBar && !disabled) {
            Row {
                fmt(Icons.Rounded.FormatBold, labels.bold) { onValueChange(wrap(value, "**", "**")) }
                fmt(Icons.Rounded.FormatItalic, labels.italic) { onValueChange(wrap(value, "*", "*")) }
                fmt(Icons.Rounded.Code, labels.code) { onValueChange(wrap(value, "`", "`")) }
                fmt(Icons.AutoMirrored.Rounded.FormatListBulleted, labels.list) { onValueChange("$value\n- ") }
                fmt(Icons.Rounded.Link, labels.link) { onValueChange(wrap(value, "[", "](url)")) }
            }
        }
        TextField(
            value = value, onValueChange = onValueChange, enabled = !disabled,
            placeholder = { Text(placeholder, color = colors.textTertiary) },
            maxLines = 6,
            colors = TextFieldDefaults.colors(
                focusedContainerColor = Color.Transparent,
                unfocusedContainerColor = Color.Transparent,
                disabledContainerColor = Color.Transparent,
            ),
            modifier = Modifier.fillMaxWidth(),
        )
        if (maxLength != null) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                Text("${value.length}/$maxLength", fontSize = FlareSizes.fontSizeXs.value.sp,
                    color = if (value.length >= maxLength) colors.errorText else colors.textTertiary)
            }
        }
        if (formattingPreview && value.isNotBlank()) {
            HorizontalDivider(color = colors.borderSecondary)
            MarkdownPreview(content = value)
        }
    }
}

@Composable
private fun fmt(icon: ImageVector, label: String, onClick: () -> Unit) {
    IconButton(onClick = onClick, modifier = Modifier, enabled = true) { Icon(icon, label) }
}

private fun wrap(text: String, l: String, r: String): String = if (text.isEmpty()) l + r else l + text + r
