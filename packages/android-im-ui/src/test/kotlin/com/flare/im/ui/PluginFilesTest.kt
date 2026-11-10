package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PluginFilesTest {
    private val kind = PluginInput("kind", PluginInputKind.Select, "Type", default = "alipay",
        choices = listOf(PluginInputChoice("alipay", "Alipay"), PluginInputChoice("wechat", "WeChat"), PluginInputChoice("bank", "Bank")))
    private val code = PluginInput("code", PluginInputKind.File, "Code", required = true,
        file = PluginFileConfiguration(listOf("image/png", "image/jpeg"), 5_242_880,
            PluginFileUpload("plugin.material.prepare", "plugin.material.complete", "payoutCode")),
        showWhen = PluginInputShowWhen("kind", listOf("alipay", "wechat")))
    private val bank = PluginInput("bank", PluginInputKind.Text, "Bank", required = true, default = "old bank",
        showWhen = PluginInputShowWhen("kind", listOf("bank")))
    private val inputs = listOf(kind, code, bank)

    @Test fun `file parsing preserves a stable policy and conditional form declaration`() {
        val view = PluginViewModel.fromJson("""{"available":true,"inputs":[{"id":"kind","kind":"select","label":"Type","default":"alipay","choices":[{"value":"alipay","label":"Alipay"}]},{"id":"code","kind":"file","label":"Code","required":true,"file":{"accept":["image/png"],"maxBytes":5242880,"upload":{"prepareOperation":"plugin.material.prepare","completeOperation":"plugin.material.complete","purpose":"payoutCode"}},"showWhen":{"field":"kind","anyOf":["alipay"]}}]}""")
        val input = view.inputs.single { it.id == "code" }
        assertEquals(PluginInputKind.File, input.kind)
        assertEquals(listOf("image/png"), input.file?.accept)
        assertEquals(5_242_880, input.file?.maxBytes)
        assertEquals("payoutCode", input.file?.upload?.purpose)
        assertEquals(PluginInputShowWhen("kind", listOf("alipay")), input.showWhen)
    }

    @Test fun `only an exact completed reference can enter form values`() {
        for (value in listOf("https://example.test/proof.png", mapOf("url" to "https://example.test"),
            mapOf("fileId" to "id", "grant" to "secret"), mapOf("fileId" to ""), mapOf("fileId" to "https://example.test/proof"))) {
            assertNull(pluginFileReference(value))
            assertEquals(PluginFormIssue.InvalidType, PluginFormRules.check(code, value))
        }
        val valid = mapOf("fileId" to "file-1")
        assertEquals(valid, pluginFileReference(valid))
        assertNull(PluginFormRules.check(code, valid))
    }

    @Test fun `hidden required inputs never validate or submit even if injected into a draft`() {
        val draft = mapOf("kind" to "bank", "bank" to "Bank A", "code" to mapOf("fileId" to "old-code"))
        assertTrue(PluginFormRules.check(inputs, draft).isEmpty())
        assertEquals(mapOf("kind" to "bank", "bank" to "Bank A"), PluginFormRules.values(inputs, draft))
        val hidden = PluginFormState.initial(inputs, null)
        assertFalse(hidden.draft.containsKey("bank"))
    }

    @Test fun `controller changes clear dependent defaults and errors even while still visible`() {
        val original = PluginFormState.initial(inputs, mapOf("code" to mapOf("fileId" to "first-code")))
        val changed = original.copy(attempted = true).set("kind", "wechat", inputs)
        assertNull(changed.draft["code"])
        assertNull(changed.draft["bank"])
        assertNull(changed.errorText(code, listOf(PluginFormError("code", PluginFormIssue.InvalidType)), FlareStrings()))
        assertNull(changed.submit(inputs).second)
        val bankType = changed.set("kind", "bank", inputs)
        assertNull(bankType.draft["bank"]) // The default is not revived at submit or a later type switch.
        assertNull(bankType.submit(inputs).second)
        assertEquals(mapOf("kind" to "bank", "bank" to "Bank B"), bankType.set("bank", "Bank B").submit(inputs).second)
    }

    @Test fun `late file answers cannot match another form or a newer intent`() {
        val uploaded = PluginFileState("form-a", 3, PluginFilePhase.Uploaded, mapOf("fileId" to "file-1"))
        assertEquals(uploaded, pluginFileCurrent(uploaded, "form-a", 3))
        assertNull(pluginFileCurrent(uploaded, "form-b", 3))
        assertNull(pluginFileCurrent(uploaded, "form-a", 4))
        assertTrue(pluginFilePending(uploaded.copy(phase = PluginFilePhase.Selected)))
        assertTrue(pluginFilePending(uploaded.copy(phase = PluginFilePhase.Uploading)))
        assertTrue(pluginFilePending(uploaded.copy(phase = PluginFilePhase.Failed)))
        assertFalse(pluginFilePending(uploaded))
        assertFalse(pluginFilePending(uploaded.copy(phase = PluginFilePhase.Empty)))
    }
}
