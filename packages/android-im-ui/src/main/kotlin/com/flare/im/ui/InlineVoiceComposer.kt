package com.flare.im.ui

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaPlayer
import android.media.MediaRecorder
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.RequiresPermission
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder

/** PCM capture keeps pause/resume lossless and produces a playable WAV preview. */
private class VoiceCapture(private val directory: File) {
    private val pcm = ByteArrayOutputStream()
    @Volatile var recording = false; private set
    private var recorder: AudioRecord? = null
    private var worker: Thread? = null
    var path: File? = null; private set
    var player: MediaPlayer? = null
    val durationMs: Int get() = synchronized(pcm) { pcm.size() * 1000 / 32000 }
    @RequiresPermission(Manifest.permission.RECORD_AUDIO)
    fun start() {
        player?.pause()
        val size = maxOf(4096, AudioRecord.getMinBufferSize(16000, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT))
        val audio = AudioRecord(MediaRecorder.AudioSource.MIC, 16000, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, size)
        if (audio.state != AudioRecord.STATE_INITIALIZED) { audio.release(); error("Microphone unavailable") }
        recorder = audio; audio.startRecording(); recording = true
        worker = Thread {
            val buffer = ByteArray(size)
            while (recording) {
                val n = audio.read(buffer, 0, buffer.size)
                if (n <= 0) { recording = false; break }
                synchronized(pcm) { val remaining = 2080000 - pcm.size(); if (remaining > 0) pcm.write(buffer, 0, minOf(n, remaining)) }
                if (durationMs >= 65000) recording = false
            }
        }.also { it.start() }
    }
    fun pause(): File {
        recording = false
        runCatching { recorder?.stop() }; worker?.join(500); worker = null
        recorder?.release(); recorder = null
        player?.release(); player = null
        val bytes = synchronized(pcm) { pcm.toByteArray() }
        val file = path ?: File.createTempFile("flare-voice-", ".wav", directory).also { path = it }
        val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
        header.put("RIFF".toByteArray()).putInt(bytes.size + 36).put("WAVEfmt ".toByteArray()).putInt(16).putShort(1).putShort(1)
        header.putInt(16000).putInt(32000).putShort(2).putShort(16).put("data".toByteArray()).putInt(bytes.size)
        file.outputStream().use { it.write(header.array()); it.write(bytes) }
        return file
    }
    fun preview() {
        val file = path ?: return
        if (player?.isPlaying == true) { player?.pause(); return }
        if (player == null) player = MediaPlayer().apply { setDataSource(file.path); prepare() }
        player?.start()
    }
    fun clear(keepFile: Boolean = false) {
        recording = false; runCatching { recorder?.stop() }; worker?.join(500); worker = null
        recorder?.release(); recorder = null; player?.release(); player = null
        if (!keepFile) path?.delete(); path = null
        synchronized(pcm) { pcm.reset() }
    }
}

@Composable
fun InlineVoiceComposer(
    conversationKey: String,
    disabled: Boolean = false,
    onKeyboard: () -> Unit,
    onSend: suspend (path: String, durationMs: Int) -> Boolean,
) {
    val context = LocalContext.current
    val colors = flareColors()
    val capture = remember(conversationKey) { VoiceCapture(context.cacheDir) }
    val scope = rememberCoroutineScope()
    var active by remember(conversationKey) { mutableStateOf(true) }
    var pendingPermission by remember(conversationKey) { mutableStateOf(false) }
    var recording by remember(conversationKey) { mutableStateOf(false) }
    var paused by remember(conversationKey) { mutableStateOf(false) }
    var sending by remember(conversationKey) { mutableStateOf(false) }
    var elapsed by remember(conversationKey) { mutableIntStateOf(0) }
    var playing by remember(conversationKey) { mutableStateOf(false) }
    var error by remember(conversationKey) { mutableStateOf<String?>(null) }
    val strings = flareStrings()
    fun start() {
        if (context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            error = strings.inlineVoiceComposerAllowMicrophone
            return
        }
        try { capture.start(); recording = true; paused = false; playing = false; error = null } catch (e: Exception) { capture.clear(); error = e.message }
    }
    fun pause() { try { capture.pause(); recording = false; paused = true; elapsed = capture.durationMs } catch (e: Exception) { error = e.message; capture.clear(); recording = false } }
    val permission = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (active && pendingPermission && !disabled) { pendingPermission = false; if (granted) start() else error = strings.inlineVoiceComposerAllowMicrophone }
    }
    DisposableEffect(capture) {
        val owner = context as? LifecycleOwner
        val observer = LifecycleEventObserver { _, event -> if (event == Lifecycle.Event.ON_STOP && recording) pause() }
        owner?.lifecycle?.addObserver(observer)
        onDispose { active = false; owner?.lifecycle?.removeObserver(observer); capture.clear(keepFile = sending) }
    }
    LaunchedEffect(disabled) { if (disabled) { pendingPermission = false; capture.clear(keepFile = sending); recording = false; paused = false; elapsed = 0 } }
    LaunchedEffect(recording, playing) {
        while (recording || playing) {
            delay(100); elapsed = capture.durationMs; playing = capture.player?.isPlaying == true
            if (recording && !capture.recording) pause()
        }
    }
    Column {
        Row(Modifier.fillMaxWidth().border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusCard)).background(colors.bgPrimary, RoundedCornerShape(FlareSizes.radiusCard)).padding(horizontal = 3.dp, vertical = FlareSizes.spacing2xs), verticalAlignment = Alignment.CenterVertically) {
            @Composable fun control(icon: androidx.compose.ui.graphics.vector.ImageVector, name: String, enabled: Boolean = !sending, accent: Boolean = false, click: () -> Unit) {
                IconButton(onClick = click, enabled = enabled, modifier = Modifier.size(44.dp)) { Icon(icon, name, Modifier.size(20.dp), tint = if (accent) colors.primaryText else colors.textSecondary) }
            }
            control(flareIconVector("keyboard"), strings.inlineVoiceComposerKeyboard) { pendingPermission = false; capture.clear(); onKeyboard() }
            if (!paused) control(flareIconVector(if (recording) "pause" else "mic"), if (recording) strings.inlineVoiceComposerPause else strings.inlineVoiceComposerStart, !disabled && !sending && !pendingPermission, true) {
                if (recording) pause() else if (context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) start() else { pendingPermission = true; permission.launch(Manifest.permission.RECORD_AUDIO) }
            } else control(flareIconVector(if (playing) "pause" else "play"), strings.inlineVoiceComposerPreview) { try { capture.preview(); playing = capture.player?.isPlaying == true } catch (e: Exception) { error = e.message } }
            Canvas(Modifier.weight(1f).height(28.dp)) {
                var x = 2f
                while (x < size.width) { val h = 4 + x.toInt() % 20; drawLine(if (recording || paused) colors.primary.copy(alpha = .45f) else colors.borderPrimary, Offset(x, (size.height-h)/2), Offset(x, (size.height+h)/2), 2f); x += 6f }
            }
            Text("%02d:%02d".format(elapsed / 60000, elapsed / 1000 % 60), fontSize = 11.sp, color = colors.textSecondary)
            if (paused) {
                control(flareIconVector("mic"), strings.inlineVoiceComposerResume, !sending && elapsed < 65000, true) { start() }
                control(flareIconVector("delete"), strings.inlineVoiceComposerDiscard) { capture.clear(); paused = false; elapsed = 0; playing = false }
                control(flareIconVector("send"), strings.send, !sending && !disabled && elapsed >= 250, true) {
                    sending = true; capture.player?.pause(); playing = false
                    scope.launch { try { if (onSend(capture.path!!.path, elapsed)) { capture.clear(keepFile = true); onKeyboard() } else error = strings.inlineVoiceComposerSendFailed } catch (e: Exception) { error = e.message } finally { sending = false } }
                }
            }
        }
        error?.let { Text(it, color = colors.errorText, fontSize = 12.sp) }
    }
}
