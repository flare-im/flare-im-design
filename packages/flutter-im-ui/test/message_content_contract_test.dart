import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('message content projection covers RC kinds', () {
    expect(FlareMessageContentKind.values, hasLength(26));
    expect(
      resolveMessageContentContract(
        FlareMessageContentKind.multiImage,
      ).wireType,
      'image_group',
    );
    expect(
      resolveMessageContentContract(FlareMessageContentKind.readOnce).wireType,
      isNull,
    );
    expect(
      resolveMessageContentContract(FlareMessageContentKind.code).capabilities,
      contains(FlareMessageContentCapability.horizontalScroll),
    );
  });
}
