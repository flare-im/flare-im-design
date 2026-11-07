package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * `spec/update-prompt-vectors.json`, the table the four kits run: what the host read in, what the prompt, the bar and the
 * version panel show out ([flareUpdatePrompt], [flareProgressBarValue], [flareVersionPanel] and
 * [flareVersionChannelText]), and their words in both languages.
 */
class UpdatePromptTest {
    private val table = SpecTables.table("update-prompt-vectors.json")

    private fun wire(value: Enum<*>?): String? = value?.name?.replaceFirstChar { it.lowercase() }

    private fun form(name: String) = FlareUpdatePromptForm.entries.first { wire(it) == name }

    private fun progress(raw: Map<*, *>?): FlareUpdateProgress? =
        raw?.let { FlareUpdateProgress(it.long("received")!!, it.long("total")) }

    @Test
    fun `the prompt reads the table`() {
        val cases = table.items("cases")
        assertTrue(cases.size >= 25)
        cases.forEach { vector ->
            val name = vector.str("name")
            val input = vector.obj("input")!!
            val want = vector.obj("expect")!!
            val model = flareUpdatePrompt(
                form = form(input.str("form")!!),
                mandatory = input.bool("mandatory") ?: false,
                state = input.str("state"),
                progress = progress(input.obj("progress")),
                errorCode = input.str("errorCode"),
                retryable = input.bool("retryable") ?: true,
                sizeBytes = input.long("sizeBytes"),
                canContinueReadOnly = input.bool("canContinueReadOnly") ?: false,
                reason = input.str("reason"),
            )
            assertEquals(want.str("phase"), wire(model.phase), name)
            assertEquals(want.bool("forced"), model.forced, name)
            assertEquals(want.bool("dismissible"), model.dismissible, name)
            assertEquals(want.str("live"), wire(model.live), name)
            assertEquals(want.str("title"), wire(model.title), name)
            assertEquals(want.str("message"), wire(model.message), name)
            assertEquals(want["actions"], model.actions.map { wire(it) }, name)
            assertEquals(want.bool("notes"), model.notes, name)
            val bar = want.obj("progress")
            if (bar == null) {
                assertNull(model.progress, name)
            } else {
                assertEquals((bar["value"] as? Number)?.toDouble(), model.progress?.value, name)
                assertEquals(bar.int("percent"), model.progress?.percent, name)
            }
        }
    }

    @Test
    fun `an error code reads as the table says`() {
        table.items("failures").forEach { vector ->
            assertEquals(vector.str("message"), wire(flareUpdateFailure(vector.str("errorCode"))))
        }
    }

    @Test
    fun `the version line reads as the table says`() {
        table.items("versions").forEach { vector ->
            assertEquals(vector.bool("shown"), flareUpdateVersionShown(vector.str("version")))
        }
    }

    @Test
    fun `a bar value reads as the table says`() {
        table.items("progressBar").forEach { vector ->
            val shown = flareProgressBarValue((vector["value"] as? Number)?.toDouble(), vector.bool("indeterminate")!!)
            assertEquals((vector["shown"] as? Number)?.toDouble(), shown.value)
            assertEquals(vector.int("percent"), shown.percent)
        }
        assertEquals(FlareProgressBarValue.None, flareProgressBarValue(Double.NaN))
        assertEquals(FlareProgressBarValue.None, flareProgressBarValue(Double.POSITIVE_INFINITY))
    }

    @Test
    fun `the version panel reads the table`() {
        table.items("versionPanel").forEach { vector ->
            val model = flareVersionPanel(vector.str("updateState"))
            assertEquals(vector.str("row"), wire(model.row))
            assertEquals(vector.str("action"), wire(model.action))
            assertEquals(vector.str("detail"), wire(model.detail))
        }
    }

    @Test
    fun `a channel reads as the table says`() {
        table.items("channels").forEach { vector ->
            assertEquals(vector.str("text"), wire(flareVersionChannelText(vector.str("channel"))))
        }
    }

    @Test
    fun `the words come from the strings table in both languages`() {
        val zh = FlareStrings()
        val en = flareStringsEnglish()
        assertEquals("立即更新", FlareUpdatePromptAction.Update.label(zh))
        assertEquals("Update now", FlareUpdatePromptAction.Update.label(en))
        assertEquals("前往官网下载", FlareUpdatePromptAction.Fallback.label(zh))
        assertEquals("前往应用商店", FlareUpdatePromptAction.Fallback.label(zh, FlareUpdateFallbackTarget.Store))
        assertEquals("当前是计费网络，这次下载约 50.0 MB", FlareUpdatePromptMessage.Metered.label(zh, "50.0 MB"))
        assertEquals("这个版本已撤回，请更新。", FlareUpdatePromptMessage.Reason.label(zh, reason = "这个版本已撤回，请更新。"))
        assertEquals("测试版", flareVersionChannelLabel("beta", zh))
        assertEquals("nightly", flareVersionChannelLabel("nightly", zh))
        FlareUpdatePromptMessage.entries.forEach { message ->
            assertTrue(message.label(zh, "1 MB", "Withdrawn").isNotEmpty())
            assertTrue(message.label(en, "1 MB", "Withdrawn").isNotEmpty())
        }
    }
}
