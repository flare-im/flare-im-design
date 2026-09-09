package com.flare.im.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDirection
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** What to show for a message this client cannot render. Spec: Message/UnknownMessage. */
data class FlareUnknownMessagePresentation(
    /** Human title: the host's label, else the generic "unsupported type" wording. */
    val title: String,
    /** Human body: the sender's fallback text, else the generic hint. */
    val body: String,
    /** Raw content type for the diagnostic row; empty means render no diagnostic. */
    val diagnostic: String,
    /** True when [body] is the sender's real fallback rather than the generic hint. */
    val hasSummary: Boolean,
)

/**
 * Deterministic and side-effect free, so the four platforms cannot drift on
 * which string wins. The raw type token is never promoted to the body: a reader
 * who sees only `[flare.poll.v2]` learns nothing and it reads as a rendering bug.
 */
fun unknownMessagePresentation(
    contentType: String? = null,
    label: String? = null,
    summary: String? = null,
    hint: String,
    unsupportedText: String,
): FlareUnknownMessagePresentation {
    val cleanLabel = label.orEmpty().trim()
    val cleanSummary = summary.orEmpty().trim()
    return FlareUnknownMessagePresentation(
        title = cleanLabel.ifEmpty { unsupportedText.trim() },
        body = cleanSummary.ifEmpty { hint.trim() },
        diagnostic = contentType.orEmpty().trim(),
        hasSummary = cleanSummary.isNotEmpty(),
    )
}

/** Body for a message whose content type this client cannot render. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun UnknownMessage(
    contentType: String? = null,
    label: String? = null,
    summary: String? = null,
    isSelf: Boolean = false,
    actionText: String = "",
    onAction: (() -> Unit)? = null,
    hint: String = "当前版本无法显示这条消息",
    unsupportedText: String = "不支持的消息类型",
    diagnosticLabel: String = "消息类型",
) {
    val colors = flareColors()
    val p = unknownMessagePresentation(contentType, label, summary, hint, unsupportedText)
    // No handler (or no label) means the host cannot act, so no button is offered.
    val showsAction = onAction != null && actionText.isNotBlank()
    val secondary = if (isSelf) Color.Unspecified else colors.textSecondary
    val tertiary = if (isSelf) Color.Unspecified else colors.textTertiary

    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            FlareIcon("info", size = 16.dp, tint = secondary.takeIf { it != Color.Unspecified })
            Text(
                p.title,
                color = secondary,
                fontSize = FlareSizes.fontSizeMd.value.sp,
                fontWeight = FontWeight.SemiBold,
            )
        }
        Text(
            p.body,
            color = if (isSelf) Color.Unspecified else colors.textPrimary,
            fontSize = FlareSizes.fontSizeLg.value.sp,
        )
        if (p.diagnostic.isNotEmpty()) {
            FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(diagnosticLabel, color = tertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
                Text(
                    p.diagnostic,
                    color = tertiary,
                    style = TextStyle(
                        fontSize = FlareSizes.fontSizeSm.value.sp,
                        fontFamily = FontFamily.Monospace,
                        textDirection = TextDirection.Ltr,
                    ),
                )
            }
        }
        if (showsAction) {
            OutlinedButton(
                onClick = { onAction?.invoke() },
                modifier = Modifier.padding(top = 2.dp).defaultMinSize(minHeight = 48.dp),
                shape = RoundedCornerShape(FlareSizes.radiusMd),
                border = BorderStroke(1.dp, colors.borderPrimary),
            ) {
                Text(actionText, fontSize = FlareSizes.fontSizeMd.value.sp)
            }
        }
    }
}
