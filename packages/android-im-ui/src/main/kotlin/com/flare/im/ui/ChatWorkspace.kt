package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.HorizontalDivider
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics

/** Coherent Context -> Header -> Timeline -> Composer chat surface. */
@Composable
fun ChatWorkspace(
    header: @Composable () -> Unit,
    timeline: @Composable () -> Unit,
    contextBanner: (@Composable () -> Unit)? = null,
    composer: (@Composable () -> Unit)? = null,
    semanticLabel: String? = null,
) {
    val colors = flareColors()
    Column(
        Modifier.fillMaxSize().background(colors.bgSecondary)
            .then(if (semanticLabel != null) Modifier.semantics { contentDescription = semanticLabel } else Modifier),
    ) {
        if (contextBanner != null) {
            Box(Modifier.background(colors.bgPrimary).padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm)) {
                contextBanner()
            }
        }
        header()
        Box(Modifier.weight(1f)) { timeline() }
        if (composer != null) {
            HorizontalDivider(color = colors.borderPrimary)
            Box(Modifier.background(colors.bgPrimary)) { composer() }
        }
    }
}
