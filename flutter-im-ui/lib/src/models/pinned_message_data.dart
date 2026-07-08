/// One pinned message shown in `FlarePinnedMessageBar`. The host summarises the
/// pinned message into [summary] (plain text) from the timeline view.
class FlarePinnedMessage {
  const FlarePinnedMessage({
    required this.id,
    required this.summary,
    this.senderName,
  });

  final String id;
  final String summary;
  final String? senderName;
}
