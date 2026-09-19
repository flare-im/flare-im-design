package com.flare.im.ui

enum class FlareMessageSendState { Draft, Sending, Sent, Failed }
enum class FlareMessageLifecycleDeliveryState { ServerAccepted, Delivered, PartiallyDelivered }
enum class FlareMessageReadState { Unread, PartiallyRead, Read }
enum class FlareMessageMutationState { Normal, Edited, Recalled, Deleted }
enum class FlareMessageEphemeralState { None, ReadOnce, BurnAfterRead, Expired }

/** UI-facing lifecycle projection mapped from authoritative host state. */
data class FlareMessageLifecycle(
    val transfer: FlareTransferState = FlareTransferState.Idle,
    val send: FlareMessageSendState = FlareMessageSendState.Sent,
    val delivery: FlareMessageLifecycleDeliveryState = FlareMessageLifecycleDeliveryState.ServerAccepted,
    val read: FlareMessageReadState = FlareMessageReadState.Unread,
    val mutation: FlareMessageMutationState = FlareMessageMutationState.Normal,
    val ephemeral: FlareMessageEphemeralState = FlareMessageEphemeralState.None,
) {
    val visualStatus: FlareMessageDeliveryStatus
        get() = when {
            send == FlareMessageSendState.Failed || transfer == FlareTransferState.Failed ->
                FlareMessageDeliveryStatus.Failed
            send == FlareMessageSendState.Draft || transfer == FlareTransferState.Queued ->
                FlareMessageDeliveryStatus.Pending
            send == FlareMessageSendState.Sending || transfer == FlareTransferState.Transferring ||
                transfer == FlareTransferState.Paused -> FlareMessageDeliveryStatus.Sending
            read == FlareMessageReadState.Read -> FlareMessageDeliveryStatus.Read
            delivery == FlareMessageLifecycleDeliveryState.Delivered ||
                delivery == FlareMessageLifecycleDeliveryState.PartiallyDelivered -> FlareMessageDeliveryStatus.Delivered
            else -> FlareMessageDeliveryStatus.Sent
        }
}
