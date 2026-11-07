package com.flare.im.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import coil.compose.SubcomposeAsyncImage
import coil.request.CachePolicy
import coil.request.ImageRequest
import coil.size.Precision
import coil.size.Scale

/** Bounded rendering for host-owned private bytes; no URL, disk or shared memory cache. */
@Composable
fun PrivateMemoryImage(
    bytes: ByteArray,
    contentDescription: String,
    modifier: Modifier = Modifier,
    maxPixelSize: Int = 1024,
) {
    require(maxPixelSize > 0)
    val context = LocalContext.current
    val colors = flareColors()
    val model = remember(context, bytes, maxPixelSize) {
        ImageRequest.Builder(context).data(bytes)
            .size(maxPixelSize, maxPixelSize).scale(Scale.FIT).precision(Precision.EXACT)
            .memoryCachePolicy(CachePolicy.DISABLED).diskCachePolicy(CachePolicy.DISABLED)
            .networkCachePolicy(CachePolicy.DISABLED).build()
    }
    SubcomposeAsyncImage(
        model = model, contentDescription = contentDescription,
        modifier = modifier, contentScale = ContentScale.Fit,
        loading = { Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(color = colors.primary)
        } },
        error = { Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            FlareIcon("image", size = FlareSizes.iconSizeXl, tint = colors.textTertiary)
        } },
    )
}
