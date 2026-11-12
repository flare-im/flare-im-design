package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The wallet pages as plain blocks (`spec/wallet-flow-vectors.json`, the resolved views the wallet contract draws): every
 * block of every sample reads, the balance hero can be hidden and the transaction list groups by day.
 */
class WalletFlowVectorsTest {
    private fun cases(): List<Map<*, *>> {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/wallet-flow-vectors.json")
            if (candidate.isFile) return ((FlareJson.parse(candidate.readText()) as Map<*, *>)["cases"] as List<*>).map { it as Map<*, *> }
            dir = dir.parentFile
        }
        error("spec/wallet-flow-vectors.json not found")
    }

    @Test
    fun everyWalletSampleReadsWhole() {
        val cases = cases()
        assertTrue(cases.isNotEmpty())
        for (sample in cases) {
            val id = "${sample["id"]}/${sample["variant"]}/${sample["locale"]}"
            val raw = sample["view"] as Map<*, *>
            val view = PluginPageViewModel.fromMap(raw).view
            assertEquals((raw["blocks"] as? List<*>)?.size ?: 0, view.blocks.size, id)
            val blocks = view.blocks.flatMap { if (it is PluginSectionBlock) listOf(it) + it.blocks else listOf(it) }
            for (block in blocks) {
                if (block is PluginHeroBlock) assertTrue(block.maskable, "$id: the balance hides")
                if (block is PluginRowsBlock && sample["page"] == "flare.wallet.page.history") assertTrue(block.groupByDay, "$id: grouped by day")
            }
        }
    }
}
