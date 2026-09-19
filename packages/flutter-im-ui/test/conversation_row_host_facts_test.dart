import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// `hostFacts` is the only way a host adds the two things it knows and the core does not: the draft this
/// device is holding, and who is typing. Without it an app could not set `typing` at all on Dart or Swift,
/// which is how the `typing` branch of `previewKind` stayed unreachable on four kits for several rounds.
void main() {
  const row = ConversationRowData(
    id: 'c1',
    title: 'Ann',
    preview: 'see you at nine',
    timestampLabel: '09:00',
    unreadCount: 3,
    mentioned: true,
    tags: [ConversationRowTag('群聊')],
  );

  test('typing changes the row and nothing else', () {
    final next = row.hostFacts(typing: true);
    expect(next.typing, isTrue);
    expect(next.previewKind, 'typing');
    expect(next.id, row.id);
    expect(next.preview, row.preview);
    expect(next.unreadCount, row.unreadCount);
    expect(next.mentioned, row.mentioned);
    expect(next.tags, row.tags);
    expect(next.timestampLabel, row.timestampLabel);
  });

  test('a draft outranks typing, as the shared rule says', () {
    expect(row.hostFacts(typing: true, draftPreview: 'half a thought').previewKind, 'draft');
  });

  test('passing nothing keeps what the row had', () {
    final next = row.hostFacts();
    expect(next.typing, row.typing);
    expect(next.draftPreview, row.draftPreview);
    expect(next.previewKind, row.previewKind);
  });
}
