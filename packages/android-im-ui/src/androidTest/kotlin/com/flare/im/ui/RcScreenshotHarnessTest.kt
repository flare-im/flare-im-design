package com.flare.im.ui

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Rect
import androidx.activity.ComponentActivity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class RcScreenshotHarnessTest {
    @get:Rule val compose = createAndroidComposeRule<ComponentActivity>()

    @Test fun lightComponents() = capture("rc-components-light", dark = false, fontScale = 1f)

    @Test fun darkComponents() = capture("rc-components-dark", dark = true, fontScale = 1f)

    @Test fun largeTextComponents() = capture("rc-components-large-text", dark = false, fontScale = 2f)

    /** The vocabulary 2 plugin blocks and the upgrade notice (spec/plugin-view-vectors.json → blocks2, upgradeNotice). */
    @Test fun pluginBlocksLight() = capture("plugin-blocks2-light", listOf("Open tasks", "Update the app to view this")) {
        PluginBlocksFixture(dark = false)
    }

    @Test fun pluginBlocksDark() = capture("plugin-blocks2-dark", listOf("Open tasks", "Update the app to view this")) {
        PluginBlocksFixture(dark = true)
    }

    private fun capture(name: String, dark: Boolean, fontScale: Float) =
        capture(name, listOf("Continue", "A stable outgoing message with a readable delivery state.")) { RcComponentsFixture(dark, fontScale) }

    private fun capture(name: String, shown: List<String>, content: @Composable () -> Unit) {
        compose.setContent { content() }
        compose.waitForIdle()
        shown.forEach { compose.onNodeWithText(it).assertIsDisplayed() }
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val screen = instrumentation.uiAutomation.takeScreenshot()
        val visibleFrame = Rect()
        compose.activityRule.scenario.onActivity { activity ->
            activity.window.decorView.getWindowVisibleDisplayFrame(visibleFrame)
        }
        val actual = Bitmap.createBitmap(
            screen,
            visibleFrame.left,
            visibleFrame.top,
            visibleFrame.width(),
            visibleFrame.height(),
        )
        val output = File(instrumentation.targetContext.getExternalFilesDir(null), "$name.png")
        FileOutputStream(output).use { actual.compress(Bitmap.CompressFormat.PNG, 100, it) }
        shell(instrumentation, "mkdir -p /sdcard/Download/flare-im-ui-goldens")
        shell(instrumentation, "cp ${output.absolutePath} /sdcard/Download/flare-im-ui-goldens/$name.png")

        if (InstrumentationRegistry.getArguments().getString("compareBaselines") == "true") {
            val expected = instrumentation.context.assets.open("goldens/$name.png").use(BitmapFactory::decodeStream)
            assertEquals("$name width", expected.width, actual.width)
            assertEquals("$name height", expected.height, actual.height)
            val expectedPixels = IntArray(expected.width * expected.height)
            val actualPixels = IntArray(actual.width * actual.height)
            expected.getPixels(expectedPixels, 0, expected.width, 0, 0, expected.width, expected.height)
            actual.getPixels(actualPixels, 0, actual.width, 0, 0, actual.width, actual.height)
            var rawDiffs = 0
            var significantDiffs = 0
            for (index in expectedPixels.indices) {
                val expectedPixel = expectedPixels[index]
                val actualPixel = actualPixels[index]
                if (expectedPixel == actualPixel) continue
                rawDiffs += 1
                val maxChannelDelta = maxOf(
                    kotlin.math.abs((expectedPixel ushr 24 and 0xff) - (actualPixel ushr 24 and 0xff)),
                    kotlin.math.abs((expectedPixel ushr 16 and 0xff) - (actualPixel ushr 16 and 0xff)),
                    kotlin.math.abs((expectedPixel ushr 8 and 0xff) - (actualPixel ushr 8 and 0xff)),
                    kotlin.math.abs((expectedPixel and 0xff) - (actualPixel and 0xff)),
                )
                if (maxChannelDelta > 2) significantDiffs += 1
            }
            assertTrue("$name raw pixel drift: $rawDiffs", rawDiffs <= expectedPixels.size * 0.005)
            assertEquals("$name significant pixel drift", 0, significantDiffs)
        }
    }

    private fun shell(instrumentation: android.app.Instrumentation, command: String) {
        instrumentation.uiAutomation.executeShellCommand(command).use { descriptor ->
            FileInputStream(descriptor.fileDescriptor).use { it.readBytes() }
        }
    }
}

@Composable
private fun RcComponentsFixture(dark: Boolean, fontScale: Float) {
    val currentDensity = LocalDensity.current
    CompositionLocalProvider(
        LocalDensity provides Density(currentDensity.density, fontScale),
        LocalFlareStrings provides FlareStrings { messageEdited = "Edited" },
    ) {
        FlareThemeProvider(if (dark) FlareThemeMode.Dark else FlareThemeMode.Light) {
            val colors = flareColors()
            var input by remember { mutableStateOf("RC input") }
            Box(
                Modifier.testTag("rc-components").fillMaxSize().background(colors.bgPrimary).statusBarsPadding(),
                contentAlignment = Alignment.TopCenter,
            ) {
              Column(
                Modifier.width(360.dp).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
              ) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(label = "Continue", onClick = {})
                    Button(label = "Retry", variant = FlareButtonVariant.Secondary, onClick = {})
                }
                Input(value = input, onValueChange = { input = it }, placeholder = "Message", clearable = true)
                ConversationRow(
                    item = ConversationRowData(
                        id = "rc-conversation",
                        title = "Design review",
                        preview = "Latest message remains readable",
                        timestampLabel = "23:59",
                        unreadCount = 12,
                    ),
                    active = true,
                    onSelect = {},
                )
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    FlareMessageDeliveryStatus.entries.forEach { MessageStatus(it) }
                }
                MessageMeta(
                    timestamp = "23:59",
                    edited = true,
                    status = FlareMessageDeliveryStatus.Read,
                )
                MessageBubble(
                    message = FlareMessageData(
                        id = "rc-message",
                        senderId = "self",
                        senderName = "You",
                        content = FlareTextContent("A stable outgoing message with a readable delivery state."),
                        timeLabel = "23:59",
                        status = FlareMessageDeliveryStatus.Read,
                        edited = true,
                    ),
                    currentUserId = "self",
                )
                Spacer(Modifier.padding(top = 2.dp))
                Composer(placeholder = "Write a message", onSend = {})
              }
            }
        }
    }
}

/** Every vocabulary 2 block an embedded plugin view draws, then the upgrade notice as a card line and as a page. */
internal const val PLUGIN_BLOCKS_FIXTURE = """{"available":true,"title":"Task board","blocks":[
  {"kind":"hero","label":"Balance","value":"1,250.00","amount":true,"tone":"brand","subtitle":"Updated just now",
   "actions":[{"id":"top-up","label":"Top up"},{"id":"withdraw","label":"Withdraw"}]},
  {"kind":"stats","items":[{"label":"Open tasks","value":"12","trend":{"text":"+3","direction":"up"}},
   {"label":"Members","value":"12345","format":{"kind":"count","count":12345}},
   {"label":"Avg. time","value":"7500000","format":{"kind":"duration","ms":7500000},"tone":"warning"}]},
  {"kind":"chart","chartKind":"bar","series":[{"label":"Done","points":[{"label":"Mon","value":3,"text":"3"},{"label":"Tue","value":5,"text":"5"},{"label":"Wed","value":2,"text":"2"}]},
   {"label":"Open","points":[{"label":"Mon","value":1,"text":"1"},{"label":"Tue","value":2,"text":"2"},{"label":"Wed","value":4,"text":"4"}]}]},
  {"kind":"chart","chartKind":"donut","series":[{"points":[{"label":"Done","value":6,"text":"6"},{"label":"Open","value":3,"text":"3"},{"label":"Late","value":1,"text":"1"}]}]},
  {"kind":"steps","items":[{"label":"Submitted","state":"done"},{"label":"Review","state":"current"},{"label":"Approved","state":"pending"}]},
  {"kind":"banner","tone":"warning","text":"Two tasks are overdue","action":{"id":"view","label":"View"}},
  {"kind":"section","label":"Details","collapsed":false,"blocks":[{"kind":"fields","fields":[{"label":"Owner","value":"Ann"}]}]},
  {"kind":"qr","value":"flare://task/42","label":"Share board","caption":"Scan to open"}
]}"""

@Composable
private fun PluginBlocksFixture(dark: Boolean) {
    CompositionLocalProvider(LocalFlareStrings provides flareStringsEnglish()) {
        FlareThemeProvider(if (dark) FlareThemeMode.Dark else FlareThemeMode.Light) {
            val colors = flareColors()
            Box(
                Modifier.testTag("plugin-blocks2").fillMaxSize().background(colors.bgPrimary).statusBarsPadding()
                    .verticalScroll(rememberScrollState()),
                contentAlignment = Alignment.TopCenter,
            ) {
                Column(Modifier.width(360.dp).padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    PluginView(view = PluginViewModel.fromJson(PLUGIN_BLOCKS_FIXTURE), embedded = true, onAction = { _, _ -> })
                    PluginView(
                        view = PluginViewModel.fromJson("""{"available":false,"title":"Task board","unavailableReason":"upgrade_required","minBuild":41020}"""),
                        upgradeStatus = PluginUpgradeStatus(available = true, build = 41020), onUpdate = {},
                    )
                    FlarePluginUpgradeNotice(FlarePluginUpgradeVariant.Page, title = "Task board", status = PluginUpgradeStatus(available = false))
                }
            }
        }
    }
}
