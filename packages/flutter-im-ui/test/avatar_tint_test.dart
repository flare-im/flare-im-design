import 'package:flare_im_ui/src/components/flare_avatar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Expected slots from running the Vue kit's `avatarTint` (the same pairs the
  // Android and iOS kits test), so one name is one colour on every kit.
  test('the tint slot is the Vue hash', () {
    expect(flareAvatarTintIndex('Lab Bob'), 4);
    expect(flareAvatarTintIndex('Plugin Lab Group'), 3);
    expect(flareAvatarTintIndex('群签到验收 g2 m7df423d1d5'), 2);
    expect(flareAvatarTintIndex('😀a'), 2);
    expect(flareAvatarTintIndex('  '), 3);
  });
}
