import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/components/action_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The semantic icon registry: one fixed vocabulary, the same names in the same
// order on Vue / Flutter / SwiftUI / Compose, each name drawn by one glyph.
void main() {
  test('the registry holds 105 unique names, each with a glyph, in order', () {
    expect(flareIconNames, hasLength(105));
    expect(flareIconNames.toSet(), hasLength(105));
    expect(flareIconMap.keys.toList(), flareIconNames);
    // The shared prefix of the contract order: chats and moments follow comment.
    expect(flareIconNames.sublist(0, 15), [
      'search',
      'send',
      'more',
      'back',
      'close',
      'check',
      'add',
      'remove',
      'edit',
      'delete',
      'heart',
      'comment',
      'chats',
      'moments',
      'share',
    ]);
  });

  test('removed names are gone', () {
    for (final name in ['heart-filled', 'bookmark']) {
      expect(flareIconNames, isNot(contains(name)));
      expect(flareIconMap.containsKey(name), isFalse);
    }
  });

  test('remapped names draw their new glyph', () {
    // An x-circle reads as cancel; error is the exclamation circle.
    expect(flareIconMap['error'], Icons.error_outline);
    // The outlined paper plane the composer's send key draws.
    expect(flareIconMap['send'], Icons.send_outlined);
  });

  test('the 40 added names, in contract order, and their glyphs', () {
    const added = <String, IconData>{
      'recall': Icons.undo_outlined,
      'unpin': Icons.push_pin,
      'merge-forward': Icons.merge_outlined,
      'multi-select': Icons.checklist_outlined,
      'quote': Icons.format_quote_outlined,
      'reaction': Icons.add_reaction_outlined,
      'translate': Icons.translate_outlined,
      'mention': Icons.alternate_email_outlined,
      'read': Icons.done_all_outlined,
      'mark': Icons.flag_outlined,
      'rich-text': Icons.title,
      'attachment': Icons.attach_file_outlined,
      'mark-unread': Icons.mark_chat_unread_outlined,
      'archive': Icons.archive_outlined,
      'unarchive': Icons.unarchive_outlined,
      'clear-history': Icons.delete_sweep_outlined,
      'mic-off': Icons.mic_off_outlined,
      'camera-off': Icons.videocam_off_outlined,
      'speaker': Icons.volume_up_outlined,
      'speaker-off': Icons.volume_off_outlined,
      'end-call': Icons.call_end_outlined,
      'switch-camera': Icons.cameraswitch_outlined,
      'screen-share': Icons.screen_share_outlined,
      'play': Icons.play_arrow_outlined,
      'pause': Icons.pause_outlined,
      'expand': Icons.open_in_full_outlined,
      'collapse': Icons.close_fullscreen_outlined,
      'zoom-in': Icons.zoom_in_outlined,
      'zoom-out': Icons.zoom_out_outlined,
      'rotate': Icons.rotate_right_outlined,
      'group': Icons.groups_outlined,
      'admin': Icons.admin_panel_settings_outlined,
      'remove-member': Icons.person_remove_outlined,
      'transfer-owner': Icons.key_outlined,
      'silence': Icons.comments_disabled_outlined,
      'report': Icons.report_outlined,
      'chevron-up': Icons.expand_less_outlined,
      'chevron-left': Icons.chevron_left_outlined,
      'keyboard': Icons.keyboard_outlined,
      'mini-app': Icons.apps_outlined,
    };
    expect(added, hasLength(40));
    expect(flareIconNames.sublist(59, 99), added.keys.toList());
    added.forEach(
      (name, glyph) => expect(flareIconMap[name], glyph, reason: name),
    );
  });

  test('concepts drawn under another name got their own, and their glyphs', () {
    const added = <String, IconData>{
      'pin-self': Icons.bookmark_border,
      'diagnostics': Icons.bug_report_outlined,
      'card': Icons.contact_page_outlined,
      'id': Icons.tag,
      'join-request': Icons.move_to_inbox_outlined,
      'storage': Icons.storage_outlined,
    };
    expect(flareIconNames.sublist(99), added.keys.toList());
    added.forEach(
      (name, glyph) => expect(flareIconMap[name], glyph, reason: name),
    );
  });

  test('names that used to share a glyph now draw different ones', () {
    IconData glyph(String name) => flareIconMap[name]!;
    expect(glyph('unpin'), isNot(glyph('pin')));
    expect(glyph('recall'), isNot(glyph('reply')));
    expect(glyph('remove-member'), isNot(glyph('logout')));
    expect(glyph('transfer-owner'), isNot(glyph('star')));
    expect(glyph('silence'), isNot(glyph('mute')));
    expect(glyph('silence'), isNot(glyph('notification')));
    // Each concept below was drawn under the second name, which means something else.
    expect(glyph('pin-self'), isNot(glyph('pin')));
    expect(glyph('card'), isNot(glyph('person')));
    expect(glyph('id'), isNot(glyph('info')));
    expect(glyph('id'), isNot(glyph('tag')));
    expect(glyph('join-request'), isNot(glyph('person-add')));
    expect(glyph('join-request'), isNot(glyph('notification')));
    expect(glyph('storage'), isNot(glyph('folder')));
    expect(glyph('diagnostics'), isNot(glyph('info')));
    expect(glyph('error'), isNot(Icons.cancel_outlined));
  });

  test('header action ids resolve to the glyph of the name they stand for', () {
    expect(flareActionIcon('audioCall'), flareActionIcon('phone'));
    expect(flareActionIcon('videoCall'), flareActionIcon('video'));
    expect(flareActionIcon('addMember'), flareActionIcon('person-add'));
    expect(flareActionIcon('details'), flareActionIcon('info'));
    for (final id in ['audioCall', 'videoCall', 'addMember', 'details']) {
      expect(flareActionIcon(id), isNotNull, reason: id);
    }
    expect(flareActionIcon('no-such-action'), isNull);
  });

  test(
    'a registry lookup draws the name, an unknown name the visible fallback',
    () {
      for (final name in flareIconNames) {
        expect(flareIconGlyph(name), flareIconMap[name], reason: name);
      }
      expect(flareIconGlyph('no-such-icon'), Icons.help_outline);
    },
  );

  testWidgets('FlareIcon draws the registry glyph for a new name', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FlareIcon('end-call'))),
    );
    expect(find.byIcon(Icons.call_end_outlined), findsOneWidget);
  });
}
