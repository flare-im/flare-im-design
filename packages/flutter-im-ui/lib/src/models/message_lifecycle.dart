import '../components/flare_message_status.dart';
import '../components/flare_transfer_progress.dart';

enum FlareMessageSendState { draft, sending, sent, failed }

enum FlareMessageLifecycleDeliveryState {
  serverAccepted,
  delivered,
  partiallyDelivered,
}

enum FlareMessageReadState { unread, partiallyRead, read }

enum FlareMessageMutationState { normal, edited, recalled, deleted }

enum FlareMessageEphemeralState { none, readOnce, burnAfterRead, expired }

/// UI-facing lifecycle projection mapped from authoritative host state.
class FlareMessageLifecycle {
  const FlareMessageLifecycle({
    this.transfer = FlareTransferState.idle,
    this.send = FlareMessageSendState.sent,
    this.delivery = FlareMessageLifecycleDeliveryState.serverAccepted,
    this.read = FlareMessageReadState.unread,
    this.mutation = FlareMessageMutationState.normal,
    this.ephemeral = FlareMessageEphemeralState.none,
  });

  final FlareTransferState transfer;
  final FlareMessageSendState send;
  final FlareMessageLifecycleDeliveryState delivery;
  final FlareMessageReadState read;
  final FlareMessageMutationState mutation;
  final FlareMessageEphemeralState ephemeral;

  FlareMessageDeliveryStatus get visualStatus {
    if (send == FlareMessageSendState.failed ||
        transfer == FlareTransferState.failed) {
      return FlareMessageDeliveryStatus.failed;
    }
    if (send == FlareMessageSendState.draft ||
        transfer == FlareTransferState.queued) {
      return FlareMessageDeliveryStatus.pending;
    }
    if (send == FlareMessageSendState.sending ||
        transfer == FlareTransferState.transferring ||
        transfer == FlareTransferState.paused) {
      return FlareMessageDeliveryStatus.sending;
    }
    if (read == FlareMessageReadState.read)
      return FlareMessageDeliveryStatus.read;
    if (delivery == FlareMessageLifecycleDeliveryState.delivered ||
        delivery == FlareMessageLifecycleDeliveryState.partiallyDelivered) {
      return FlareMessageDeliveryStatus.delivered;
    }
    return FlareMessageDeliveryStatus.sent;
  }
}
