package com.flare.im.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertHasClickAction
import androidx.compose.ui.test.assertHeightIsAtLeast
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.assertIsOff
import androidx.compose.ui.test.assertIsNotSelected
import androidx.compose.ui.test.assertIsOn
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.assertIsToggleable
import androidx.compose.ui.test.assertWidthIsAtLeast
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performClick
import androidx.compose.ui.unit.Dp
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

/**
 * Icon-only controls in a real semantics tree: each is found by its localized name, has the role
 * TalkBack announces, reports its state when it is a toggle, and is a node of at least the touch target.
 */
class IconControlAccessibilityInteractionTest {
    @get:Rule val compose = createComposeRule()
    private val strings = FlareStrings()

    private fun SemanticsNodeInteraction.assertRole(role: Role): SemanticsNodeInteraction =
        assert(SemanticsMatcher.expectValue(SemanticsProperties.Role, role))

    private fun SemanticsNodeInteraction.assertButton(): SemanticsNodeInteraction =
        assertHasClickAction().assertRole(Role.Button)

    private fun SemanticsNodeInteraction.assertTouchTarget(min: Dp = FlareSizes.touchTarget): SemanticsNodeInteraction =
        assertWidthIsAtLeast(min).assertHeightIsAtLeast(min)

    @Test fun composerToolbarKeysAreNamedButtonsAndRichTextIsAToggle() {
        compose.setContent { FlareThemeProvider { Composer(onSend = {}, onEmoji = {}, onImage = {}) } }
        // The composer keeps its 44 dp keys so that seven fit a 320 dp screen.
        for (name in listOf(strings.composerEmoji, strings.composerMention, strings.composerImage, strings.composerExpandInput)) {
            compose.onNodeWithContentDescription(name).assertButton().assertTouchTarget(FlareSizes.touchTargetMin)
        }
        compose.onNodeWithContentDescription(strings.composerRichText).assertIsToggleable().assertIsOff().performClick()
        compose.onNodeWithContentDescription(strings.composerRichText).assertIsOn()
    }

    @Test fun imagePreviewNamesCloseAndDownload() {
        var closes = 0
        var downloads = 0
        compose.setContent {
            FlareThemeProvider { ImagePreview(show = true, imageSrc = "", onClose = { closes++ }, onDownload = { downloads++ }) }
        }
        compose.onNodeWithContentDescription(strings.imagePreviewClose).assertButton().assertTouchTarget().performClick()
        compose.onNodeWithContentDescription(strings.download).assertButton().assertTouchTarget().performClick()
        compose.runOnIdle {
            assertEquals(1, closes)
            assertEquals(1, downloads)
        }
    }

    @Test fun voiceRecordingBarNamesCancelAndSend() {
        // The recording dot blinks forever; the test clock cancels infinite animations, so idle is reached.
        var cancels = 0
        var sends = 0
        compose.setContent {
            FlareThemeProvider { VoiceRecordingBar(durationLabel = "00:03", onCancel = { cancels++ }, onSend = { sends++ }) }
        }
        compose.onNodeWithContentDescription(strings.voiceRecordingCancel).assertButton().assertTouchTarget().performClick()
        compose.onNodeWithContentDescription(strings.voiceRecordingSend).assertButton().assertTouchTarget().performClick()
        compose.runOnIdle {
            assertEquals(1, cancels)
            assertEquals(1, sends)
        }
    }

    @Test fun messageBatchToolbarExitIsANamedButtonDisabledWhileBusy() {
        var exits = 0
        var busy by mutableStateOf(false)
        compose.setContent {
            FlareThemeProvider {
                MessageBatchToolbar(
                    selectedIds = listOf("a", "b"), total = 5,
                    capabilities = MessageBatchCapabilities(delete = true), busy = busy, onExit = { exits++ },
                )
            }
        }
        compose.onNodeWithContentDescription(strings.exitMultiSelect).assertButton().assertTouchTarget().performClick()
        compose.runOnIdle {
            assertEquals(1, exits)
            busy = true
        }
        compose.onNodeWithContentDescription(strings.exitMultiSelect).assertIsNotEnabled()
    }

    @Test fun callControlsReportDeviceStateAndNameHangUp() {
        var muted by mutableStateOf(false)
        var hangUps = 0
        compose.setContent {
            FlareThemeProvider {
                CallControls(
                    muted = muted,
                    mode = FlareCallMode.Audio,
                    onToggleMute = { muted = !muted },
                    onToggleSpeaker = {},
                    onHangup = { hangUps++ },
                )
            }
        }
        compose.onNodeWithContentDescription(strings.microphone).assertRole(Role.Switch).assertIsOn().assertTouchTarget().performClick()
        compose.onNodeWithContentDescription(strings.microphone).assertIsOff()
        compose.onNodeWithContentDescription(strings.speaker).assertRole(Role.Switch).assertIsOff()
        compose.onNodeWithContentDescription(strings.hangUp).assertButton().assertTouchTarget().performClick()
        compose.runOnIdle { assertEquals(1, hangUps) }
        // The caption under a key repeats its name and stays out of the accessibility tree.
        compose.onAllNodesWithText(strings.microphone).assertCountEquals(0)
    }

    @Test fun videoCallControlsReportTheCameraAsASwitch() {
        var cameraOn by mutableStateOf(true)
        compose.setContent {
            FlareThemeProvider {
                CallControls(cameraOn = cameraOn, mode = FlareCallMode.Video, onToggleCamera = { cameraOn = !cameraOn }, onToggleMute = {}, onHangup = {})
            }
        }
        compose.onNodeWithContentDescription(strings.camera).assertRole(Role.Switch).assertIsOn().assertTouchTarget().performClick()
        compose.onNodeWithContentDescription(strings.camera).assertIsOff()
        compose.onNodeWithContentDescription(strings.microphone).assertRole(Role.Switch).assertIsOn()
    }

    @Test fun callDockNamesTheMicrophoneSwitchReturnToCallAndHangUp() {
        var muted by mutableStateOf(false)
        var expands = 0
        var hangUps = 0
        compose.setContent {
            FlareThemeProvider {
                CallDock(title = "Ann", muted = muted, onExpand = { expands++ }, onToggleMute = { muted = !muted }, onHangup = { hangUps++ })
            }
        }
        // The device toggle is named by the device, and on means the microphone is capturing.
        compose.onNodeWithContentDescription(strings.microphone).assertRole(Role.Switch).assertIsOn().assertTouchTarget().performClick()
        compose.onNodeWithContentDescription(strings.microphone).assertIsOff()
        compose.onAllNodesWithContentDescription("静音").assertCountEquals(0)
        // The dock's main button returns to the full call.
        compose.onNode(SemanticsMatcher("click label ${strings.callReturn}") { node ->
            node.config.getOrNull(SemanticsActions.OnClick)?.label == strings.callReturn
        }).assertRole(Role.Button).performClick()
        compose.onNodeWithContentDescription(strings.hangUp).assertButton().assertTouchTarget().performClick()
        compose.runOnIdle {
            assertEquals(1, expands)
            assertEquals(1, hangUps)
        }
    }

    @Test fun voicePlayerPlayKeyIsANamedTouchTargetAroundItsDisc() {
        var playing by mutableStateOf(false)
        compose.setContent {
            FlareThemeProvider { VoicePlayer(durationLabel = "0:12", playing = playing, onToggle = { playing = !playing }) }
        }
        compose.onNodeWithContentDescription(strings.play).assertButton().assertTouchTarget().performClick()
        compose.onNodeWithContentDescription(strings.pause).assertButton().assertTouchTarget()
    }

    @Test fun emojiCategoryTabsAreNamedTabsWithTouchTargets() {
        compose.setContent {
            FlareThemeProvider {
                EmojiPicker(categories = listOf(EmojiCategory("smileys", "笑脸", "😀", listOf("😀")), EmojiCategory("animals", "动物", "🐶", listOf("🐶"))))
            }
        }
        compose.onNodeWithContentDescription("笑脸").assertRole(Role.Tab).assertIsSelected().assertTouchTarget()
        compose.onNodeWithContentDescription("动物").assertRole(Role.Tab).assertIsNotSelected().assertTouchTarget().performClick()
        compose.onNodeWithContentDescription("动物").assertIsSelected()
    }

    @Test fun taskCheckboxAndFileDownloadAreNamedControls() {
        var done by mutableStateOf(false)
        var downloads = 0
        compose.setContent {
            FlareThemeProvider {
                Column {
                    TaskMessage(title = "Ship the release", done = done, onToggle = { done = !done })
                    FileMessage(name = "spec.pdf", size = "2 MB", onDownload = { downloads++ })
                }
            }
        }
        compose.onNodeWithContentDescription("Ship the release").assertRole(Role.Checkbox).assertIsOff().assertTouchTarget().performClick()
        compose.onNodeWithContentDescription("Ship the release").assertIsOn()
        compose.onNodeWithContentDescription(strings.download).assertButton().assertTouchTarget().performClick()
        compose.runOnIdle { assertEquals(1, downloads) }
    }
}
