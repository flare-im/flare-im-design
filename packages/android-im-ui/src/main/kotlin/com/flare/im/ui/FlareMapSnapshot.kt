package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage

/**
 * The map area of a location card and of the location picker: the drawn map ground ([FlareMapPlaceholder]) under the
 * static map, so a picture still loading, or failing, leaves the map, never a hole. Once the picture shows, the map
 * data's credit ([locationMapAttribution]: OpenStreetMap's for osm, none for amap) sits in its bottom-right corner as a
 * small line of secondary text on a translucent ground, at most 60% of the width so it stays clear of the centre marker.
 */
@Composable
internal fun FlareMapSnapshot(url: String?, provider: FlareLocationProvider, modifier: Modifier = Modifier, pin: Boolean = true) {
    val strings = flareStrings()
    var shown by remember(url) { mutableStateOf(false) }
    Box(modifier) {
        FlareMapPlaceholder(Modifier.matchParentSize(), pin = pin)
        if (!url.isNullOrBlank()) {
            AsyncImage(
                model = url, contentDescription = null, modifier = Modifier.matchParentSize(), contentScale = ContentScale.Crop,
                onSuccess = { shown = true }, onError = { shown = false },
            )
        }
        locationMapAttribution(provider, shown && !url.isNullOrBlank(), strings)?.let { text ->
            Box(Modifier.matchParentSize(), contentAlignment = Alignment.BottomEnd) {
                Box(Modifier.fillMaxWidth(0.6f), contentAlignment = Alignment.BottomEnd) { FlareMapAttribution(text) }
            }
        }
    }
}

/** The map data's credit in the corner of a static map. */
@Composable
internal fun FlareMapAttribution(text: String) {
    val colors = flareColors()
    Text(
        text, color = colors.textSecondary, fontSize = FlareSizes.fontSize2xs, maxLines = 1, overflow = TextOverflow.Ellipsis,
        modifier = Modifier.clip(RoundedCornerShape(topStart = FlareSizes.radiusXs)).background(colors.bgPrimary.copy(alpha = 0.72f))
            .padding(horizontal = FlareSizes.spacingXs, vertical = 0.dp),
    )
}
