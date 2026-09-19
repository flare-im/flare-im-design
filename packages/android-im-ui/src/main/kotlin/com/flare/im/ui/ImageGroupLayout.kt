package com.flare.im.ui

/**
 * How an image-group (album) body lays out its images: square tiles in [columns] columns, [visible] of them drawn,
 * and the last drawn tile reading `+more` when there are more images than tiles. The rule is shared with the
 * other three kits (`spec/image-group-layout-vectors.json`).
 */
data class FlareImageGroupLayout(val columns: Int, val visible: Int, val more: Int) {
    /** Whether the tile at [index] is the covered last one. */
    fun covers(index: Int): Boolean = more > 0 && index == visible - 1
}

/** At most this many tiles are drawn. */
const val FLARE_IMAGE_GROUP_MAX_VISIBLE = 9

fun flareImageGroupLayout(count: Int): FlareImageGroupLayout {
    if (count <= 0) return FlareImageGroupLayout(0, 0, 0)
    return FlareImageGroupLayout(
        columns = if (count == 4) 2 else minOf(count, 3),
        visible = minOf(count, FLARE_IMAGE_GROUP_MAX_VISIBLE),
        more = if (count > FLARE_IMAGE_GROUP_MAX_VISIBLE) count - FLARE_IMAGE_GROUP_MAX_VISIBLE + 1 else 0,
    )
}

/** The name TalkBack reads for the tile at [index] of an album of [count] images. */
internal fun flareImageGroupTileLabel(index: Int, count: Int, layout: FlareImageGroupLayout, strings: FlareStrings): String =
    if (layout.covers(index)) strings.messageImageGroupItemMore(index + 1, count, layout.more)
    else strings.messageImageGroupItem(index + 1, count)
