package com.flare.im.ui

/** A file input's policy. File I/O and transport remain with the host and Core SDK. */
data class PluginFileUpload(val prepareOperation: String, val completeOperation: String, val purpose: String)
data class PluginFileConfiguration(val accept: List<String>, val maxBytes: Int, val upload: PluginFileUpload)
data class PluginInputShowWhen(val field: String, val anyOf: List<String>)

enum class PluginFilePhase { Empty, Selected, Uploading, Uploaded, Failed }
enum class PluginFileActionKind { Choose, Retry, Cancel, Replace, Remove, Preview, Invalidate }

/** No file bytes, private URL, token or platform URI belongs in component state. */
data class PluginFileState(
    val scope: String,
    val generation: Int,
    val phase: PluginFilePhase,
    val value: Map<String, String>? = null,
    val fileName: String? = null,
    val progress: Double? = null,
    val error: String? = null,
    val preview: Boolean = false,
    val previewLoading: Boolean = false,
)

data class PluginFileAction(
    val action: PluginFileActionKind,
    val inputId: String,
    val input: PluginInput,
    val scope: String,
    val generation: Int,
    val formValues: Map<String, Any?>,
)

/** Accept exactly the stable reference. Never interpret a URL or an arbitrary map as a completed upload. */
fun pluginFileReference(value: Any?): Map<String, String>? {
    val map = value as? Map<*, *> ?: return null
    if (map.keys != setOf("fileId")) return null
    val id = map["fileId"] as? String ?: return null
    if (!id.matches(Regex("[A-Za-z0-9][A-Za-z0-9_.:-]{0,127}"))) return null
    return mapOf("fileId" to id)
}

/** A late answer is never adopted by a new form instance or file intent. */
internal fun pluginFileCurrent(state: PluginFileState?, scope: String, generation: Int): PluginFileState? =
    state?.takeIf { it.scope == scope && it.generation == generation }

internal fun pluginFilePending(state: PluginFileState?): Boolean =
    state?.phase in setOf(PluginFilePhase.Selected, PluginFilePhase.Uploading, PluginFilePhase.Failed)

internal fun PluginInput.visibleIn(draft: Map<String, Any?>): Boolean =
    showWhen?.let { condition -> (draft[condition.field] as? String)?.let { it in condition.anyOf } ?: false } ?: true
