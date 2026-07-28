package com.flare.im.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf

/**
 * 组件内联文案（无障碍标签、状态提示、空态等）。
 *
 * 这些串原先直接写死在组件调用里，宿主无法覆盖——对一个跨端组件库而言等于把界面语言
 * 焊死。改为环境值后默认仍是中文，需要其他语言的宿主在根部覆盖即可：
 *
 * ```kotlin
 * CompositionLocalProvider(LocalFlareStrings provides FlareStrings(send = "Send")) {
 *     App()
 * }
 * ```
 *
 * 取值方式与 [flareColors] 一致（composable 访问器），故组件里无需逐层传参。
 * 已有 `FlareXxxLabels` 参数的组件不受影响，两者可共存。
 */
data class FlareStrings(
    // 通话
    val microphone: String = "麦克风",
    val camera: String = "摄像头",
    val flipCamera: String = "翻转",
    val speaker: String = "扬声器",
    val hangUp: String = "挂断",
    val callWaitingAnswer: String = "等待对方接听…",
    val callCalling: String = "正在呼叫…",
    val callRinging: String = "正在响铃…",
    val callConnected: String = "已接通",
    // 输入区
    val send: String = "发送",
    val cancelReply: String = "取消回复",
    // 空态
    val noContacts: String = "暂无联系人",
)

val LocalFlareStrings = staticCompositionLocalOf { FlareStrings() }

/** 当前生效的组件文案。宿主可用 [LocalFlareStrings] 覆盖。 */
@Composable
@ReadOnlyComposable
fun flareStrings(): FlareStrings = LocalFlareStrings.current
