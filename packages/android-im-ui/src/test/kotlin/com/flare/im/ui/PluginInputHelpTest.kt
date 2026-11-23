package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** R6: the help line a plugin form draws under an input, as the core translated it; none without it. */
class PluginInputHelpTest {
    @Test fun anInputCarriesItsHelpAndNoneWithoutIt() {
        val view = PluginViewModel.fromJson(
            """{"available":true,"title":"","inputs":[
                {"id":"name","kind":"text","label":"Name","help":"英文、数字或 _ : - .，最多 128 个字符"},
                {"id":"note","kind":"text","label":"Note"},
                {"id":"blank","kind":"toggle","label":"Blank","help":"  "}]}""",
        )
        assertEquals("英文、数字或 _ : - .，最多 128 个字符", view.inputs[0].help)
        assertNull(view.inputs[1].help)
        assertNull(view.inputs[2].help, "a blank help draws nothing")
    }
}
