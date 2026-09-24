package com.flare.im.ui

import android.text.style.ImageSpan
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import androidx.activity.ComponentActivity
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ComposerEmojiEditTextInstrumentedTest {
    @get:Rule
    val compose = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun knownTokenDrawsImageSpanWhileEditableValueStaysRaw() {
        compose.setContent {
            FlareComposerEmojiEditText(
                value = "[alien] [not_a_pack_key]",
                onValueChange = {},
                enabled = true,
                placeholder = "",
                expanded = false,
                textColor = Color.Black,
                hintColor = Color.Gray,
                fontWeight = FontWeight.Normal,
                fontStyle = FontStyle.Normal,
                textDecoration = TextDecoration.None,
                emojiSize = 26.dp,
            )
        }

        compose.waitUntil(timeoutMillis = 10_000) {
            compose.activity.findEditText()
                ?.text
                ?.getSpans(0, "[alien]".length, ImageSpan::class.java)
                ?.size == 1
        }

        compose.runOnIdle {
            val editor = requireNotNull(compose.activity.findEditText())
            assertEquals("[alien] [not_a_pack_key]", editor.text.toString())
            val spans = editor.text.getSpans(0, editor.text.length, ImageSpan::class.java)
            assertEquals(1, spans.size)
            assertEquals(0, editor.text.getSpanStart(spans.single()))
            assertEquals("[alien]".length, editor.text.getSpanEnd(spans.single()))
            assertTrue(editor.text.toString().contains("[not_a_pack_key]"))
        }
    }
}

private fun ComponentActivity.findEditText(): EditText? {
    fun find(view: View): EditText? {
        if (view is EditText) return view
        if (view is ViewGroup) {
            for (index in 0 until view.childCount) {
                find(view.getChildAt(index))?.let { return it }
            }
        }
        return null
    }
    return find(window.decorView)
}
