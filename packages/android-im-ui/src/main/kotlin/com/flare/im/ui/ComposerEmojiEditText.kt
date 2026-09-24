package com.flare.im.ui

import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.Typeface
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.text.Editable
import android.text.InputType
import android.text.Spanned
import android.text.TextWatcher
import android.text.style.DynamicDrawableSpan
import android.text.style.ImageSpan
import android.util.TypedValue
import android.view.Gravity
import android.widget.EditText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.disabled
import androidx.compose.ui.semantics.editableText
import androidx.compose.ui.semantics.focused
import androidx.compose.ui.semantics.insertTextAtCursor
import androidx.compose.ui.semantics.isEditable
import androidx.compose.ui.semantics.requestFocus
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.setText
import androidx.compose.ui.semantics.text
import androidx.compose.ui.semantics.textSelectionRange
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView

/**
 * Native editable composer field whose storage remains `[emoji_key]` while
 * Android draws the bundled image over that range. Copy, drafts, typing
 * signals and send callbacks therefore keep the wire-format token.
 */
@Composable
internal fun FlareComposerEmojiEditText(
    value: String,
    onValueChange: (String) -> Unit,
    enabled: Boolean,
    placeholder: String,
    expanded: Boolean,
    textColor: Color,
    hintColor: Color,
    fontWeight: FontWeight,
    fontStyle: FontStyle,
    textDecoration: TextDecoration,
    modifier: Modifier = Modifier,
    emojiSize: Dp = 26.dp,
) {
    val catalogLoaded = rememberCatalogLoaded()
    val catalogRevision by FlareEmojiStickerCatalog.revision.collectAsState()
    val currentOnValueChange = rememberUpdatedState(onValueChange)
    val emojiSizePx = with(LocalDensity.current) { emojiSize.roundToPx() }
    val editorHolder = remember { arrayOfNulls<FlareEmojiEditText>(1) }
    var focusedState by remember { mutableStateOf(false) }
    val selection = editorHolder[0]?.let {
        TextRange(it.selectionStart.coerceAtLeast(0), it.selectionEnd.coerceAtLeast(0))
    } ?: TextRange(value.length)
    val accessibleModifier = modifier.semantics {
        editableText = AnnotatedString(value)
        text = AnnotatedString(if (value.isEmpty()) placeholder else value)
        textSelectionRange = selection
        focused = focusedState
        if (!enabled) {
            disabled()
        } else {
            isEditable = true
            requestFocus { editorHolder[0]?.requestFocus() ?: false }
            setText { replacement ->
                currentOnValueChange.value(replacement.text)
                true
            }
            insertTextAtCursor { insertion ->
                val field = editorHolder[0]
                val start = field?.selectionStart?.coerceAtLeast(0)?.coerceAtMost(value.length)
                    ?: value.length
                val end = field?.selectionEnd?.coerceAtLeast(start)?.coerceAtMost(value.length)
                    ?: start
                currentOnValueChange.value(value.replaceRange(start, end, insertion.text))
                true
            }
        }
    }

    AndroidView(
        modifier = accessibleModifier,
        factory = { context ->
            FlareEmojiEditText(context).apply {
                editorHolder[0] = this
                setOnFocusChangeListener { _, focused -> focusedState = focused }
                rawTextChanged = { currentOnValueChange.value(it) }
            }
        },
        update = { field ->
            field.rawTextChanged = { currentOnValueChange.value(it) }
            field.update(
                raw = value,
                enabled = enabled,
                hint = placeholder,
                expanded = expanded,
                textColor = textColor.toArgb(),
                hintColor = hintColor.toArgb(),
                bold = fontWeight >= FontWeight.Bold,
                italic = fontStyle == FontStyle.Italic,
                strike = textDecoration.contains(TextDecoration.LineThrough),
                underline = textDecoration.contains(TextDecoration.Underline),
                renderEmoji = catalogLoaded,
                emojiSizePx = emojiSizePx,
                catalogRevision = catalogRevision,
            )
        },
    )
}

private class FlareEmojiEditText(context: Context) : EditText(context) {
    var rawTextChanged: (String) -> Unit = {}

    private var syncing = false
    private val emojiDrawableStates = mutableMapOf<String, Drawable.ConstantState>()
    private var appliedCatalogRevision = -1

    init {
        background = null
        gravity = Gravity.TOP or Gravity.START
        inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE or
            InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
        isSingleLine = false
        includeFontPadding = false
        setPadding(0, 0, 0, 0)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
        addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) = Unit
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) = Unit
            override fun afterTextChanged(editable: Editable?) {
                if (syncing || editable == null) return
                rawTextChanged(editable.toString())
            }
        })
    }

    fun update(
        raw: String,
        enabled: Boolean,
        hint: String,
        expanded: Boolean,
        textColor: Int,
        hintColor: Int,
        bold: Boolean,
        italic: Boolean,
        strike: Boolean,
        underline: Boolean,
        renderEmoji: Boolean,
        emojiSizePx: Int,
        catalogRevision: Int,
    ) {
        isEnabled = enabled
        this.hint = hint
        setTextColor(textColor)
        setHintTextColor(hintColor)
        minLines = if (expanded) 9 else 1
        maxLines = if (expanded) 14 else 5
        typeface = Typeface.create(
            Typeface.DEFAULT,
            when {
                bold && italic -> Typeface.BOLD_ITALIC
                bold -> Typeface.BOLD
                italic -> Typeface.ITALIC
                else -> Typeface.NORMAL
            },
        )
        paint.isStrikeThruText = strike
        paint.isUnderlineText = underline

        if (text.toString() != raw) {
            val oldSelection = selectionStart.coerceAtLeast(0)
            syncing = true
            setText(raw)
            setSelection(oldSelection.coerceAtMost(raw.length))
            syncing = false
        }
        if (appliedCatalogRevision != catalogRevision) {
            appliedCatalogRevision = catalogRevision
            emojiDrawableStates.clear()
        }
        applyEmojiSpans(renderEmoji, emojiSizePx)
    }

    private fun applyEmojiSpans(renderEmoji: Boolean, emojiSizePx: Int) {
        val editable = text ?: return
        editable.getSpans(0, editable.length, FlareComposerEmojiImageSpan::class.java)
            .forEach(editable::removeSpan)
        if (!renderEmoji || editable.isEmpty()) return

        flareInlineEmojiRuns(editable.toString(), FlareEmojiStickerCatalog::hasEmojiKey).forEach { run ->
            val drawable = emojiDrawable(run.key, emojiSizePx) ?: return@forEach
            editable.setSpan(
                FlareComposerEmojiImageSpan(drawable),
                run.start,
                run.end,
                Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
            )
        }
    }

    private fun emojiDrawable(key: String, sizePx: Int): Drawable? {
        val state = emojiDrawableStates[key] ?: runCatching {
            val preview = FlareEmojiStickerCatalog.emojiStaticPreviewBytes(key)
            val bitmap = if (preview != null) {
                BitmapFactory.decodeByteArray(preview, 0, preview.size)
            } else {
                context.assets.open("${FlareEmojiStickerCatalog.ASSET_ROOT}/emoji/$key.webp").use(BitmapFactory::decodeStream)
            }
            bitmap?.let { BitmapDrawable(resources, it).constantState }
        }.getOrNull()?.also { emojiDrawableStates[key] = it }
        return state?.newDrawable(resources)?.mutate()?.apply { setBounds(0, 0, sizePx, sizePx) }
    }
}

private class FlareComposerEmojiImageSpan(drawable: Drawable) :
    ImageSpan(drawable, DynamicDrawableSpan.ALIGN_CENTER)
