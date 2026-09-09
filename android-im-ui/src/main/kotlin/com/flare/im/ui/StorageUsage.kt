package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.roundToInt

/**
 * One storage category as the host measured it. [id] must be stable — it is
 * echoed in every callback.
 */
data class FlareStorageCategory(
    val id: String,
    val label: String,
    /**
     * Bytes this category occupies. `null` (or any non-finite or negative value)
     * means "not measured yet" — the row says so instead of printing 0 B, and
     * draws no share bar.
     */
    val bytes: Double? = null,
    /** How many files make up the category; omitted when the host does not count them. */
    val fileCount: Int? = null,
    /** Host can clear this category. `false` hides the clear button entirely. */
    val clearable: Boolean = false,
    /** This category's clear command is in flight — that row alone locks. */
    val busy: Boolean = false,
    /** Why this category's last clear failed; kept until the host dismisses it. */
    val error: String? = null,
)

/** Result of [storageTotals]. */
data class FlareStorageTotals(
    /** Sum of the categories whose size is actually known. */
    val knownBytes: Double,
    /** At least one category has no measured size, so [knownBytes] is a floor. */
    val hasUnknown: Boolean,
    /** What to display as the total: the host's `totalBytes` when usable, else [knownBytes]. */
    val total: Double,
)

private val storageUnits = listOf("KB", "MB", "GB", "TB")

private fun isKnownBytes(value: Double?): Boolean =
    value != null && value.isFinite() && value >= 0

/**
 * Human byte size, or `null` when the size is not known.
 *
 * The rules are identical on all four platforms and deliberately
 * locale-invariant, so one snapshot reads the same on web, Flutter, iOS and
 * Android: unknown (`null` / NaN / infinite / negative) → `null`; below 1024 →
 * `"N B"`; then 1024 per step through KB, MB, GB, TB with one decimal. TB is
 * the last unit, matching `MessageContentView`'s attachment formatter.
 *
 * [locale] is accepted so hosts can thread their locale through; digits and unit
 * suffixes are the same in every locale on purpose — the same storage snapshot
 * must never read differently on two of the user's devices.
 */
fun formatBytes(bytes: Double?, locale: String? = null): String? {
    if (!isKnownBytes(bytes)) return null
    val value = bytes!!
    val rounded = value.roundToInt()
    if (rounded < 1024) return "$rounded B"
    var scaled = value / 1024
    var unit = 0
    while (scaled >= 1024 && unit < storageUnits.size - 1) {
        scaled /= 1024
        unit += 1
    }
    return "%.1f %s".format(java.util.Locale.ROOT, scaled, storageUnits[unit])
}

/**
 * What to show as the overall footprint — same rule set as the other platforms.
 *
 * [FlareStorageTotals.knownBytes] only sums the categories that actually have a
 * size and [FlareStorageTotals.hasUnknown] says whether anything was left out,
 * so the panel can label its own sum "at least" instead of passing a partial sum
 * off as the truth. A usable host `totalBytes` wins; an unusable one falls back
 * to the sum.
 */
fun storageTotals(
    categories: List<FlareStorageCategory>,
    totalBytes: Double? = null,
): FlareStorageTotals {
    var knownBytes = 0.0
    var hasUnknown = false
    for (category in categories) {
        if (isKnownBytes(category.bytes)) knownBytes += category.bytes!! else hasUnknown = true
    }
    return FlareStorageTotals(
        knownBytes = knownBytes,
        hasUnknown = hasUnknown,
        total = if (isKnownBytes(totalBytes)) totalBytes!! else knownBytes,
    )
}

/**
 * This category's share of [total], in 0..1, or `null` when it cannot be drawn:
 * the size is unknown, or the total is zero/unknown. A missing bar is the honest
 * answer — a zero-width bar would read as "this category is empty".
 */
fun storageShare(bytes: Double?, total: Double?): Double? {
    if (!isKnownBytes(bytes) || !isKnownBytes(total) || total!! <= 0) return null
    val share = bytes!! / total
    return if (share > 1) 1.0 else share
}

/**
 * Whether to offer a clear button at all. The host must say the category is
 * clearable, and a category measured at exactly 0 bytes offers nothing to clear.
 * An unknown size keeps the button: not having measured it is not evidence that
 * it is empty.
 */
fun canClearStorage(category: FlareStorageCategory?): Boolean {
    if (category == null || !category.clearable) return false
    return category.bytes != 0.0
}

/** `{count}` is replaced with the category's file count; a missing count renders nothing. */
internal fun storageFileCountLabel(template: String, count: Int?): String? {
    if (count == null || count < 0) return null
    return template.replace("{count}", count.toString())
}

/** The sum is only a floor when this panel computed it and something is unmeasured. */
internal fun storageTotalIsFloor(totals: FlareStorageTotals, totalBytes: Double?): Boolean =
    totals.hasUnknown && !isKnownBytes(totalBytes)

/**
 * Storage management — the "storage space" section of the settings page.
 *
 * The host measures the categories and says which ones it can clear; this panel
 * only shows the snapshot and dispatches the intent. Clearing is irreversible,
 * so the button carries danger colour + icon, but the second confirmation is
 * **not** here: the host wraps [onClear] in DangerConfirm. A category whose size
 * the host has not measured reads [unknownText], never 0 B.
 * Spec: Profile/StorageUsage (`StorageUsage`).
 */
@Composable
fun StorageUsage(
    /** Per-category snapshot; ids must be stable and are echoed in every callback. */
    categories: List<FlareStorageCategory>,
    /** Host-measured overall footprint; omitted, the panel sums what it knows. */
    totalBytes: Double? = null,
    /** Free space left on the device, when the host can read it. */
    deviceFreeBytes: Double? = null,
    /** First measurement in flight — renders a skeleton, never a fake empty list. */
    loading: Boolean = false,
    /** Whole-snapshot failure; already-known categories stay on screen. */
    error: String? = null,
    /** BCP-47 tag threaded through to [formatBytes]; sizes read the same in every locale. */
    locale: String? = null,
    title: String = "存储空间",
    unknownText: String = "未知",
    atLeastText: String = "至少",
    clearText: String = "清理",
    clearingText: String = "清理中",
    totalText: String = "总计",
    deviceFreeText: String = "可用空间",
    reloadText: String = "重新统计",
    retryText: String = "失败重试",
    dismissErrorText: String = "忽略此错误",
    loadingText: String = "正在统计存储占用",
    emptyText: String = "没有可统计的存储分类",
    fileCountText: String = "{count} 个文件",
    onClear: ((String) -> Unit)? = null,
    onReload: (() -> Unit)? = null,
    /** `null` dismisses the whole-snapshot error; an id dismisses that category's. */
    onDismissError: ((String?) -> Unit)? = null,
) {
    val colors = flareColors()
    val totals = storageTotals(categories, totalBytes)
    fun sizeText(bytes: Double?): String = formatBytes(bytes, locale) ?: unknownText
    val totalValue = sizeText(totals.total)
    val totalLabel =
        if (storageTotalIsFloor(totals, totalBytes)) "$atLeastText $totalValue" else totalValue
    val freeLabel = formatBytes(deviceFreeBytes, locale)
    val showSkeleton = loading && categories.isEmpty()
    val showEmpty = !loading && error == null && categories.isEmpty()

    Column(
        Modifier.fillMaxWidth()
            .clip(RoundedCornerShape(FlareSizes.radiusLg))
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusLg))
            .padding(FlareSizes.spacingMd)
            .semantics { contentDescription = title },
    ) {
        Row(
            Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingSm),
            verticalAlignment = Alignment.Top,
        ) {
            Column(Modifier.weight(1f)) {
                Text(
                    title,
                    color = colors.textPrimary,
                    fontSize = FlareSizes.fontSizeLg.value.sp,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    if (freeLabel == null) "$totalText $totalLabel"
                    else "$totalText $totalLabel · $deviceFreeText $freeLabel",
                    color = colors.textSecondary,
                    fontSize = FlareSizes.fontSizeSm.value.sp,
                )
            }
            if (onReload != null) {
                TextAction(
                    icon = Icons.Outlined.Refresh,
                    label = reloadText,
                    enabled = !loading,
                    colors = colors,
                    onClick = onReload,
                )
            }
        }

        if (loading) {
            Row(
                Modifier.padding(bottom = FlareSizes.spacingSm)
                    .semantics { contentDescription = loadingText },
                verticalAlignment = Alignment.CenterVertically,
            ) {
                CircularProgressIndicator(
                    Modifier.size(14.dp),
                    color = colors.textTertiary,
                    strokeWidth = 2.dp,
                )
                Spacer(Modifier.width(5.dp))
                Text(loadingText, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp)
            }
        }

        // The whole snapshot failed: what is already known stays on screen and the
        // banner offers a re-measure.
        if (error != null) {
            Row(
                Modifier.fillMaxWidth()
                    .padding(bottom = FlareSizes.spacingSm)
                    .clip(RoundedCornerShape(FlareSizes.radiusSm))
                    .background(colors.error.copy(alpha = 0.08f))
                    .padding(horizontal = 8.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Outlined.ErrorOutline, null, Modifier.size(14.dp), tint = colors.error)
                Spacer(Modifier.width(6.dp))
                Text(
                    error,
                    color = colors.error,
                    fontSize = FlareSizes.fontSizeSm.value.sp,
                    modifier = Modifier.weight(1f),
                )
                if (onReload != null) {
                    TextAction(Icons.Outlined.Refresh, reloadText, !loading, colors, onReload)
                }
                if (onDismissError != null) {
                    Icon(
                        Icons.Outlined.Close,
                        null,
                        Modifier.size(20.dp)
                            .clip(RoundedCornerShape(FlareSizes.radiusSm))
                            .clickable(role = Role.Button, onClickLabel = dismissErrorText) {
                                onDismissError(null)
                            }
                            .padding(3.dp),
                        tint = colors.textSecondary,
                    )
                }
            }
        }

        when {
            // A first measurement in progress — placeholder rows, never an empty-list message.
            showSkeleton -> Column(Modifier.fillMaxWidth()) {
                repeat(3) {
                    Column(
                        Modifier.fillMaxWidth()
                            .heightIn(min = FlareSizes.touchTarget)
                            .padding(vertical = FlareSizes.spacingSm),
                    ) {
                        Box(
                            Modifier.width(120.dp).height(14.dp)
                                .clip(RoundedCornerShape(FlareSizes.radiusSm))
                                .background(colors.bgSecondary),
                        )
                        Spacer(Modifier.height(6.dp))
                        Box(
                            Modifier.fillMaxWidth().height(8.dp)
                                .clip(RoundedCornerShape(FlareSizes.radiusSm))
                                .background(colors.bgSecondary),
                        )
                    }
                }
            }

            showEmpty -> Text(
                emptyText,
                color = colors.textSecondary,
                fontSize = FlareSizes.fontSizeMd.value.sp,
                modifier = Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacingMd),
            )

            else -> LazyColumn(Modifier.fillMaxWidth().heightIn(max = 420.dp)) {
                itemsIndexed(categories, key = { _, category -> category.id }) { index, category ->
                    if (index > 0) HorizontalDivider(color = colors.borderSecondary)
                    StorageRow(
                        category = category,
                        share = storageShare(category.bytes, totals.total),
                        sizeText = sizeText(category.bytes),
                        files = storageFileCountLabel(fileCountText, category.fileCount),
                        canClear = canClearStorage(category) && onClear != null,
                        colors = colors,
                        clearText = clearText,
                        clearingText = clearingText,
                        retryText = retryText,
                        dismissErrorText = dismissErrorText,
                        onClear = onClear,
                        onDismissError = onDismissError,
                    )
                }
            }
        }
    }
}

@Composable
private fun StorageRow(
    category: FlareStorageCategory,
    share: Double?,
    sizeText: String,
    files: String?,
    canClear: Boolean,
    colors: FlareColors,
    clearText: String,
    clearingText: String,
    retryText: String,
    dismissErrorText: String,
    onClear: ((String) -> Unit)?,
    onDismissError: ((String?) -> Unit)?,
) {
    Column(Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacingSm)) {
        Row(
            Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                Modifier.size(32.dp).clip(CircleShape).background(colors.primary.copy(alpha = 0.10f)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Outlined.Description, null, Modifier.size(18.dp), tint = colors.primary)
            }
            Spacer(Modifier.width(FlareSizes.spacingMd))
            Column(Modifier.weight(1f)) {
                Text(
                    category.label,
                    color = colors.textPrimary,
                    fontSize = FlareSizes.fontSizeLg.value.sp,
                    fontWeight = FontWeight.Medium,
                )
                Text(
                    if (files == null) sizeText else "$sizeText · $files",
                    color = colors.textSecondary,
                    fontSize = FlareSizes.fontSizeSm.value.sp,
                )
            }
            Spacer(Modifier.width(FlareSizes.spacingSm))
            if (category.busy) {
                Row(
                    Modifier.semantics { contentDescription = clearingText },
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    CircularProgressIndicator(
                        Modifier.size(14.dp),
                        color = colors.textTertiary,
                        strokeWidth = 2.dp,
                    )
                    Spacer(Modifier.width(5.dp))
                    Text(
                        clearingText,
                        color = colors.textTertiary,
                        fontSize = FlareSizes.fontSizeSm.value.sp,
                    )
                }
            } else if (canClear) {
                // Clearing is irreversible: danger colour **and** a trash icon, never
                // colour alone. The confirmation belongs to the host, not to this row.
                Row(
                    Modifier.heightIn(min = FlareSizes.touchTarget)
                        .clip(RoundedCornerShape(FlareSizes.radiusMd))
                        .background(colors.error.copy(alpha = 0.08f))
                        .border(
                            1.dp,
                            colors.error.copy(alpha = 0.40f),
                            RoundedCornerShape(FlareSizes.radiusMd),
                        )
                        .clickable(role = Role.Button, onClickLabel = "$clearText ${category.label}") {
                            onClear?.invoke(category.id)
                        }
                        .padding(horizontal = 10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Outlined.Delete, null, Modifier.size(14.dp), tint = colors.error)
                    Spacer(Modifier.width(4.dp))
                    Text(clearText, color = colors.error, fontSize = FlareSizes.fontSizeMd.value.sp)
                }
            }
        }

        if (share != null) {
            LinearProgressIndicator(
                progress = { share.toFloat() },
                modifier = Modifier.fillMaxWidth()
                    .padding(start = 44.dp, top = FlareSizes.spacingXs)
                    .height(4.dp)
                    .clip(RoundedCornerShape(FlareSizes.radiusFull)),
                color = colors.primary,
                trackColor = colors.bgSecondary,
            )
        }

        val rowError = category.error
        if (rowError != null) {
            Row(
                Modifier.fillMaxWidth()
                    .padding(start = 44.dp, top = FlareSizes.spacingXs)
                    .clip(RoundedCornerShape(FlareSizes.radiusSm))
                    .background(colors.error.copy(alpha = 0.08f))
                    .padding(horizontal = 8.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Outlined.ErrorOutline, null, Modifier.size(14.dp), tint = colors.error)
                Spacer(Modifier.width(6.dp))
                Text(
                    rowError,
                    color = colors.error,
                    fontSize = FlareSizes.fontSizeSm.value.sp,
                    modifier = Modifier.weight(1f),
                )
                if (canClear && !category.busy) {
                    TextAction(Icons.Outlined.Refresh, retryText, true, colors) {
                        onClear?.invoke(category.id)
                    }
                }
                if (onDismissError != null) {
                    Icon(
                        Icons.Outlined.Close,
                        null,
                        Modifier.size(20.dp)
                            .clip(RoundedCornerShape(FlareSizes.radiusSm))
                            .clickable(role = Role.Button, onClickLabel = dismissErrorText) {
                                onDismissError(category.id)
                            }
                            .padding(3.dp),
                        tint = colors.textSecondary,
                    )
                }
            }
        }
    }
}

@Composable
private fun TextAction(
    icon: ImageVector,
    label: String,
    enabled: Boolean,
    colors: FlareColors,
    onClick: () -> Unit,
) {
    Row(
        Modifier.clip(RoundedCornerShape(FlareSizes.radiusSm))
            .alpha(if (enabled) 1f else 0.5f)
            .clickable(enabled = enabled, role = Role.Button, onClickLabel = label) { onClick() }
            .padding(horizontal = 8.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, Modifier.size(14.dp), tint = colors.textPrimary)
        Spacer(Modifier.width(4.dp))
        Text(label, color = colors.textPrimary, fontSize = FlareSizes.fontSizeSm.value.sp)
    }
}
