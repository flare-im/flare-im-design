package com.flare.im.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

data class FlareTransferQueueItem(val id:String, val name:String, val state:FlareTransferState, val statusText:String,
    val progress:Float?=null, val actionLabels:Map<FlareTransferAction,String> = emptyMap(), val busy:Boolean=false)
fun retryableTransferIds(items:List<FlareTransferQueueItem>):List<String> = items.filter {
    it.state == FlareTransferState.Failed && !it.busy && !it.actionLabels[FlareTransferAction.Retry].isNullOrBlank()
}.map { it.id }

/** Bounded-height queue. Task persistence and operations belong to the host. */
@Suppress("NAME_SHADOWING")
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun TransferQueue(items:List<FlareTransferQueueItem>, loading:Boolean=false, error:String?=null,
    title:String?=null, emptyText:String?=null, retryFailedText:String?=null, reloadText:String?=null,
    onAction:((String,FlareTransferAction)->Unit)?=null, onRetryFailed:((List<String>)->Unit)?=null, onReload:(()->Unit)?=null) {
    val strings = flareStrings()
    val title = title ?: strings.transferQueue
    val emptyText = emptyText ?: strings.noTransfers
    val retryFailedText = retryFailedText ?: strings.retryFailedTransfers
    val reloadText = reloadText ?: strings.reload
    val ids=retryableTransferIds(items)
    Column(Modifier.fillMaxSize(), verticalArrangement=Arrangement.spacedBy(FlareSizes.spacingSm)) {
        FlowRow(horizontalArrangement=Arrangement.spacedBy(FlareSizes.spacingSm)) {
            Text("$title · ${items.size}",style=MaterialTheme.typography.titleMedium)
            if(ids.isNotEmpty() && onRetryFailed!=null) TextButton(onClick={onRetryFailed(ids.toList())},modifier=Modifier.defaultMinSize(minHeight=48.dp,minWidth=48.dp)) { Text("$retryFailedText (${ids.size})") }
        }
        if(loading) LinearProgressIndicator(Modifier.fillMaxWidth())
        if(error!=null) StatusBanner(error,tone=FlareStatusTone.Danger,actionText=reloadText,onAction=if(loading) null else onReload)
        if(items.isEmpty() && !loading && error==null) Text(emptyText,Modifier.padding(FlareSizes.spacingLg))
        LazyColumn(Modifier.weight(1f),verticalArrangement=Arrangement.spacedBy(FlareSizes.spacingSm)) {
            items(items,key={it.id}) { item ->
                TransferProgress(item.name,item.state,item.statusText,item.progress,item.actionLabels,item.busy,
                    onAction=if(onAction==null) null else { a -> onAction(item.id,a) })
            }
        }
    }
}
