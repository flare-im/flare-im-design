import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('message lifecycle projects to a complete visual status', () {
    expect(
      const FlareMessageLifecycle().visualStatus,
      FlareMessageDeliveryStatus.sent,
    );
    expect(
      const FlareMessageLifecycle(
        transfer: FlareTransferState.failed,
      ).visualStatus,
      FlareMessageDeliveryStatus.failed,
    );
    expect(
      const FlareMessageLifecycle(
        read: FlareMessageReadState.read,
      ).visualStatus,
      FlareMessageDeliveryStatus.read,
    );
    expect(
      const FlareMessageLifecycle(
        send: FlareMessageSendState.sending,
      ).visualStatus,
      FlareMessageDeliveryStatus.sending,
    );
    // Delivery is not a visual state (spec/message-receipt-vectors.json):
    // one check until it is read.
    expect(
      const FlareMessageLifecycle(
        delivery: FlareMessageLifecycleDeliveryState.delivered,
      ).visualStatus,
      FlareMessageDeliveryStatus.sent,
    );
    expect(
      FlareMessageDeliveryStatus.values.map((s) => s.name),
      ['pending', 'sending', 'sent', 'read', 'failed'],
    );
  });
}
