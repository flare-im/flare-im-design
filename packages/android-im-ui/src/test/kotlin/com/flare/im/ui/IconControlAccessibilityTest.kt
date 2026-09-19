package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Icon-only controls as TalkBack meets them, checked without a UI: each draws a registry glyph, reads
 * a localized name that says what pressing it does, reports its state when it is a toggle, and is
 * disabled rather than hidden while the component is busy. The composables render exactly these specs
 * through FlareIconControl (a node of at least 48 dp with a button or switch role), so a spec is the
 * control's accessibility contract.
 */
class IconControlAccessibilityTest {
    private val zh = FlareStrings()
    private val en = FlareStrings {
        composerEmoji = "Emoji"
        composerMention = "Mention"
        composerVoice = "Voice"
        composerImage = "Image"
        composerRichText = "Rich text"
        composerMore = "More features"
        composerExpandInput = "Expand input"
        composerCollapseInput = "Collapse input"
        imagePreviewClose = "Close preview"
        download = "Download"
        voiceRecordingCancel = "Cancel recording"
        voiceRecordingSend = "Send voice message"
        selectAll = "Select all"
        forwardEach = "Forward one by one"
        forwardMerged = "Forward as one"
        delete = "Delete"
        exitMultiSelect = "Exit multi-select"
        microphone = "Microphone"
        camera = "Camera"
        flipCamera = "Flip camera"
        speaker = "Speaker"
        addMember = "Add people"
        hangUp = "Hang up"
    }

    private fun assertNamedWithRegistryGlyphs(controls: List<FlareIconControlSpec>) {
        for (c in controls) {
            assertTrue(c.icon in flareIconNames, "${c.id} draws the registry glyph `${c.icon}`")
            assertTrue(c.label.isNotBlank(), "${c.id} has a name")
            assertFalse(c.label.equals(c.id, ignoreCase = true) || c.label == c.icon, "${c.id} is named in words, not by an id")
        }
        assertEquals(controls.size, controls.map { it.id }.toSet().size, "one spec per control")
    }

    private fun labels(controls: List<FlareIconControlSpec>) = controls.map { it.label }

    // MARK: composer toolbar

    private fun composer(
        strings: FlareStrings = zh,
        disabled: Boolean = false,
        canVoice: Boolean = true,
        richMode: Boolean = false,
        panelOpen: Boolean = false,
    ) = composerToolKeys(
        strings, disabled = disabled, canEmoji = true, canVoice = canVoice, canImage = true, canMore = true,
        richMode = richMode, panelOpen = panelOpen,
    )

    @Test fun composerToolbarKeysAreNamedLocalizedAndStateful() {
        val keys = composer()
        assertNamedWithRegistryGlyphs(keys)
        assertEquals(listOf("emoji", "mention", "voice", "image", "richText", "more"), keys.map { it.id })
        assertEquals(listOf("emoji", "mention", "mic", "image", "rich-text", "add"), keys.map { it.icon })
        assertEquals(listOf("表情", "提及", "语音", "图片", "富文本", "更多"), labels(keys))
        assertEquals(
            listOf("Emoji", "Mention", "Voice", "Image", "Rich text", "More features"),
            labels(composer(en)),
        )
        // Rich text is the one toggle, and it reports whether rich mode is on.
        assertEquals(listOf(null, null, null, null, false, null), keys.map { it.checked })
        assertEquals(true, composer(richMode = true).single { it.id == "richText" }.checked)
        // The more key shows close while the panel is open; its name stays what the key is.
        assertEquals("close", composer(panelOpen = true).single { it.id == "more" }.icon)
        // Voice is offered only when the host can take a recording.
        assertTrue(composer(canVoice = false).none { it.id == "voice" })
        // A disabled composer keeps every key, each announced as disabled.
        assertTrue(composer(disabled = true).none { it.enabled })
    }

    @Test fun composerExpandKeySaysWhatHappensNext() {
        val grow = composerExpandKey(zh, disabled = false, expanded = false)
        val shrink = composerExpandKey(zh, disabled = false, expanded = true)
        assertNamedWithRegistryGlyphs(listOf(grow))
        assertEquals("expand" to "展开输入框", grow.icon to grow.label)
        assertEquals("collapse" to "收起输入框", shrink.icon to shrink.label)
        assertEquals("Collapse input", composerExpandKey(en, disabled = false, expanded = true).label)
        assertFalse(composerExpandKey(zh, disabled = true, expanded = false).enabled)
    }

    // MARK: image preview

    @Test fun imagePreviewClosesAndDownloadsByName() {
        val controls = imagePreviewControls(zh, canDownload = true, downloading = false)
        assertNamedWithRegistryGlyphs(controls)
        assertEquals(listOf("close" to "关闭预览", "download" to "下载"), controls.map { it.icon to it.label })
        assertEquals(listOf("Close preview", "Download"), labels(imagePreviewControls(en, canDownload = true, downloading = false)))
        // No download handler, or a download already running: close stays, the download button does not.
        assertEquals(listOf("close"), imagePreviewControls(zh, canDownload = false, downloading = false).map { it.id })
        assertEquals(listOf("close"), imagePreviewControls(zh, canDownload = true, downloading = true).map { it.id })
        assertTrue(controls.all { it.checked == null && it.enabled })
    }

    // MARK: voice recording bar

    @Test fun voiceRecordingBarCancelsAndSendsByName() {
        val controls = voiceRecordingBarControls(zh, cancelling = false)
        assertNamedWithRegistryGlyphs(controls)
        assertEquals(listOf("delete" to "取消录音", "send" to "发送语音"), controls.map { it.icon to it.label })
        assertEquals(listOf("Cancel recording", "Send voice message"), labels(voiceRecordingBarControls(en, cancelling = false)))
        // While the gesture is cancelling, the send button gives way to the release hint.
        assertEquals(listOf("cancel"), voiceRecordingBarControls(zh, cancelling = true).map { it.id })
    }

    // MARK: message batch toolbar

    @Test fun messageBatchToolbarExitIsNamedAndOnlyDisabledWhileBusy() {
        val everything = MessageBatchCapabilities(forwardEach = true, forwardMerged = true, delete = true)
        val controls = messageBatchToolbarControls(zh, listOf("a", "b"), total = 5, capabilities = everything, busy = false)
        assertNamedWithRegistryGlyphs(controls)
        val exit = controls.last()
        assertEquals(FlareIconControlSpec("exit", "close", "退出多选", enabled = true), exit)
        assertEquals(
            "Exit multi-select",
            messageBatchToolbarControls(en, listOf("a", "b"), total = 5, capabilities = everything, busy = false).last().label,
        )
        assertEquals(listOf("check", "close", "forward", "merge-forward", "delete", "close"), controls.map { it.icon })
        // Nothing selected: exit still works, the batch actions and the clear do not.
        val none = messageBatchToolbarControls(zh, emptyList(), total = 5, capabilities = everything, busy = false)
        assertEquals(listOf(true, false, false, false, false, true), none.map { it.enabled })
        // Merging needs two messages.
        assertFalse(
            messageBatchToolbarControls(zh, listOf("a"), total = 5, capabilities = everything, busy = false)
                .single { it.id == "ForwardMerged" }.enabled,
        )
        // Busy: every control stays on screen and is announced as disabled.
        assertTrue(
            messageBatchToolbarControls(zh, listOf("a", "b"), total = 5, capabilities = everything, busy = true)
                .none { it.enabled },
        )
        // Only what the host declares is drawn at all.
        assertEquals(
            listOf("selectAll", "clearSelection", "Delete", "exit"),
            messageBatchToolbarControls(zh, listOf("a"), total = 5, capabilities = MessageBatchCapabilities(delete = true), busy = false)
                .map { it.id },
        )
    }

    // MARK: call controls

    @Test fun videoCallControlsNameEveryKeyAndReportDeviceState() {
        val live = callControlKeys(zh, muted = false, cameraOn = true, speakerOn = false, mode = FlareCallMode.Video, canAddMember = true)
        assertNamedWithRegistryGlyphs(live)
        assertEquals(listOf("microphone", "camera", "flipCamera", "addMember", "hangUp"), live.map { it.id })
        assertEquals(listOf("mic", "video", "switch-camera", "person-add", "end-call"), live.map { it.icon })
        assertEquals(listOf("麦克风", "摄像头", "翻转", "加成员", "挂断"), labels(live))
        assertEquals(listOf(true, true, null, null, null), live.map { it.checked })

        val muted = callControlKeys(en, muted = true, cameraOn = false, speakerOn = false, mode = FlareCallMode.Video, canAddMember = false)
        assertEquals(listOf("mic-off", "camera-off", "switch-camera", "end-call"), muted.map { it.icon })
        assertEquals(listOf("Microphone", "Camera", "Flip camera", "Hang up"), labels(muted))
        assertEquals(listOf(false, false, null, null), muted.map { it.checked })
    }

    @Test fun audioCallControlsSwapCameraForSpeaker() {
        val off = callControlKeys(zh, muted = false, cameraOn = true, speakerOn = false, mode = FlareCallMode.Audio, canAddMember = false)
        assertNamedWithRegistryGlyphs(off)
        assertEquals(listOf("microphone", "speaker", "hangUp"), off.map { it.id })
        assertEquals("speaker-off" to false, off[1].icon to off[1].checked)
        val on = callControlKeys(zh, muted = false, cameraOn = true, speakerOn = true, mode = FlareCallMode.Audio, canAddMember = false)
        assertEquals("speaker" to true, on[1].icon to on[1].checked)
        // Hang up is a button with the end-call glyph, never a toggle.
        assertEquals(FlareIconControlSpec("hangUp", "end-call", "挂断"), on.last())
    }

    @Test fun callDockMuteAndHangUpAreNamedAndStateful() {
        val (mic, hangUp) = callDockControls(zh, muted = true)
        assertNamedWithRegistryGlyphs(listOf(mic, hangUp))
        assertEquals(FlareIconControlSpec("microphone", "mic-off", "麦克风", checked = false), mic)
        assertEquals(FlareIconControlSpec("hangUp", "end-call", "挂断"), hangUp)
        assertEquals(true to "mic", callDockControls(zh, muted = false).first().let { it.checked to it.icon })
    }

    @Test fun iconControlLabelsAreKitStringsWithChineseDefaults() {
        assertEquals("最小化通话", zh.callMinimize)
        assertEquals("返回通话", zh.callReturn)
        assertEquals("移除图片", zh.removeImage)
        assertEquals("暂停", zh.pause)
        assertEquals("添加成员", zh.momentsVisibilityRuleListAdd)
        assertEquals("正在加载表情", zh.emojiStickerPickerLoading)
        val overridden = FlareStrings {
            callMinimize = "Minimize call"
            removeImage = "Remove image"
            pause = "Pause"
        }
        assertEquals(listOf("Minimize call", "Remove image", "Pause"), listOf(overridden.callMinimize, overridden.removeImage, overridden.pause))
        assertEquals("正在加载表情", overridden.emojiStickerPickerLoading, "an unset key keeps its default")
    }
}
