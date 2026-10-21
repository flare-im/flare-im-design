package com.flare.im.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable

/** Core SDK resolves the same data-only UI contract on every platform. */
data class PluginViewField(val label: String, val value: String)
data class PluginViewAction(val id: String, val label: String)
data class PluginViewModel(val available: Boolean, val title: String,
    val fields: List<PluginViewField>, val actions: List<PluginViewAction>)

@Composable
fun PluginView(view: PluginViewModel, busy: Boolean = false, onAction: ((String) -> Unit)? = null) {
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
        Text(view.title)
        if (view.available) {
            view.fields.forEach { field -> Column { Text(field.label); Text(field.value) } }
            view.actions.forEach { action ->
                Button(label = action.label, variant = FlareButtonVariant.Secondary,
                    disabled = busy || onAction == null, onClick = { onAction?.invoke(action.id) })
            }
        }
    }
}
