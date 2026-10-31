import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The FlareStrings fields that are functions (of a count, a name, a kind)
/// against strings/en-formats.json, which the Compose and SwiftUI kits read
/// too: every case listing flutter answers its English with
/// flareStringsEnglish and its Chinese with the defaults, and every function
/// field FlareStrings declares has a case whose two languages differ — so a
/// new counted field cannot ship with Chinese only.
final Map<String, dynamic> _table =
    jsonDecode(File('../../strings/en-formats.json').readAsStringSync())
        as Map<String, dynamic>;

typedef _Call = String Function(FlareStrings strings, List<Object?> args);

int _i(Object? value) => value! as int;
String _s(Object? value) => value! as String;

/// How each function field is called with a case's arguments.
final Map<String, _Call> _calls = {
  'imagePreviewPosition': (s, a) => s.imagePreviewPosition(_i(a[0]), _i(a[1])),
  'readTab': (s, a) => s.readTab(_i(a[0])),
  'unreadTab': (s, a) => s.unreadTab(_i(a[0])),
  'viewAll': (s, a) => s.viewAll(_i(a[0])),
  'typingOne': (s, a) => s.typingOne(_s(a[0])),
  'typingMany': (s, a) => s.typingMany(_i(a[0])),
  'newMessages': (s, a) => s.newMessages(_i(a[0])),
  'joinedCount': (s, a) => s.joinedCount(_i(a[0]), _s(a[1])),
  'selfSuffix': (s, a) => s.selfSuffix(_s(a[0])),
  'selectedCount': (s, a) => s.selectedCount(_i(a[0])),
  'packetFromSender': (s, a) => s.packetFromSender(_s(a[0])),
  'displayNameUser': (s, a) => s.displayNameUser(_s(a[0])),
  'displayNameMembersMore': (s, a) =>
      s.displayNameMembersMore(_s(a[0]), _i(a[1])),
  'translatedBy': (s, a) => s.translatedBy(_s(a[0])),
  'pollOptionHint': (s, a) => s.pollOptionHint(_i(a[0])),
  'yearMonth': (s, a) => s.yearMonth(_i(a[0]), _i(a[1])),
  'ratingStars': (s, a) => s.ratingStars(_i(a[0])),
  'confirmCount': (s, a) => s.confirmCount(_i(a[0])),
  'memberCount': (s, a) => s.memberCount(_i(a[0])),
  'wordCharCount': (s, a) => s.wordCharCount(_i(a[0]), _i(a[1])),
  'permissionTitle': (s, a) => s.permissionTitle(_s(a[0])),
  'permissionUndeterminedDescription': (s, a) =>
      s.permissionUndeterminedDescription(_s(a[0]), _s(a[1])),
  'permissionDeniedDescription': (s, a) =>
      s.permissionDeniedDescription(_s(a[0]), _s(a[1])),
  'permissionRestrictedDescription': (s, a) =>
      s.permissionRestrictedDescription(_s(a[0]), _s(a[1])),
  'permissionUnavailableDescription': (s, a) =>
      s.permissionUnavailableDescription(_s(a[0]), _s(a[1])),
  'messageRecalledGroupOther': (s, a) =>
      s.messageRecalledGroupOther(_s(a[0])),
  'quotedMessage': (s, a) => s.quotedMessage(_s(a[0]), _s(a[1])),
  'jumpedToMessage': (s, a) => s.jumpedToMessage(_s(a[0]), _s(a[1])),
  'previewImageNamed': (s, a) => s.previewImageNamed(_s(a[0])),
  'previewFileNamed': (s, a) => s.previewFileNamed(_s(a[0])),
  'previewLocationNamed': (s, a) => s.previewLocationNamed(_s(a[0])),
  'previewCardNamed': (s, a) => s.previewCardNamed(_s(a[0])),
  'previewForwardCount': (s, a) => s.previewForwardCount(_i(a[0])),
  'previewImageGroupCount': (s, a) => s.previewImageGroupCount(_i(a[0])),
  'systemEventGroupProfileUpdatedNamed': (s, a) =>
      s.systemEventGroupProfileUpdatedNamed(_s(a[0])),
  'announcementReadBarReadCount': (s, a) =>
      s.announcementReadBarReadCount(_i(a[0]), _i(a[1])),
  'groupDetailMemberCount': (s, a) => s.groupDetailMemberCount(_i(a[0])),
  'groupDetailInviteConfirm': (s, a) => s.groupDetailInviteConfirm(_i(a[0])),
  'groupDetailTransferConfirm': (s, a) =>
      s.groupDetailTransferConfirm(_s(a[0])),
  'messageImageGroupLabel': (s, a) => s.messageImageGroupLabel(_i(a[0])),
  'messageImageGroupItem': (s, a) =>
      s.messageImageGroupItem(_i(a[0]), _i(a[1])),
  'messageImageGroupItemMore': (s, a) =>
      s.messageImageGroupItemMore(_i(a[0]), _i(a[1]), _i(a[2])),
  'conversationBatchToolbarSucceededSummary': (s, a) =>
      s.conversationBatchToolbarSucceededSummary(_i(a[0])),
  'conversationBatchToolbarFailedSummary': (s, a) =>
      s.conversationBatchToolbarFailedSummary(_i(a[0])),
  'conversationBatchToolbarMaxSelection': (s, a) =>
      s.conversationBatchToolbarMaxSelection(_i(a[0])),
  'storageUsageFileCount': (s, a) => s.storageUsageFileCount(_i(a[0])),
  'momentAudienceSheetSelected': (s, a) =>
      s.momentAudienceSheetSelected(_i(a[0])),
  'conversationHeaderMemberCount': (s, a) =>
      s.conversationHeaderMemberCount(_i(a[0])),
  'connectionDisconnectedReason': (s, a) =>
      s.connectionDisconnectedReason(_s(a[0])),
  'groupDetailMembersTitle': (s, a) => s.groupDetailMembersTitle(_i(a[0])),
  'profilePanelEditProfile': (s, a) => s.profilePanelEditProfile(_s(a[0])),
  'momentReplyToComment': (s, a) =>
      s.momentReplyToComment(_s(a[0]), _s(a[1])),
};

void main() {
  final cases = [
    for (final c in (_table['cases'] as List).cast<Map<String, dynamic>>())
      if ((c['kits'] as List).contains('flutter')) c,
  ];

  /// The function fields FlareStrings declares, read from its source.
  final declared = RegExp(
    r'^  final String Function\([^)]*\)\s*(\w+);',
    multiLine: true,
  ).allMatches(
    File('lib/src/tokens/flare_strings.dart').readAsStringSync(),
  ).map((m) => m.group(1)!).toSet();

  test('every function field has a case, in English and Chinese', () {
    expect(declared, isNotEmpty);
    expect(_calls.keys.toSet(), declared, reason: 'the call table');
    final covered = {
      for (final c in cases)
        if (c['en'] != c['zh']) c['field'] as String,
    };
    expect(declared.difference(covered), isEmpty);
  });

  for (final c in cases) {
    final field = c['field'] as String;
    final args = (c['args'] as List).cast<Object?>();
    test('$field(${args.join(', ')})', () {
      final call = _calls[field];
      expect(call, isNotNull, reason: 'a case for a field FlareStrings lacks');
      expect(call!(flareStringsEnglish, args), c['en']);
      expect(call(const FlareStrings(), args), c['zh']);
    });
  }
}
