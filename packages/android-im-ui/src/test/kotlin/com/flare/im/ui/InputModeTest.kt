package com.flare.im.ui

import androidx.compose.ui.text.input.KeyboardType
import org.junit.Assert.assertEquals
import org.junit.Test

/** The Input `inputMode` option (spec Input `inputmode`) picks the platform keyboard; money inputs ask for decimals. */
class InputModeTest {
    @Test
    fun everyModeMapsToItsKeyboard() {
        val expected = mapOf(
            FlareInputMode.Text to KeyboardType.Text,
            FlareInputMode.Search to KeyboardType.Text,
            FlareInputMode.Numeric to KeyboardType.Number,
            FlareInputMode.Decimal to KeyboardType.Decimal,
            FlareInputMode.Tel to KeyboardType.Phone,
            FlareInputMode.Email to KeyboardType.Email,
            FlareInputMode.Url to KeyboardType.Uri,
        )
        assertEquals(FlareInputMode.entries.toSet(), expected.keys)
        for ((mode, keyboard) in expected) assertEquals(mode.name, keyboard, mode.keyboardType())
    }

    @Test
    fun moneyScaleZeroAsksForDigitsOnly() {
        assertEquals(0, PluginMoneyRules(currency = "JPY", scale = 0).effectiveScale)
        assertEquals(2, PluginMoneyRules(currency = "CNY").effectiveScale)
    }
}
