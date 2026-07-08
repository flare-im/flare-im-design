/// A selectable contact/directory entry for `FlareStartConversationSheet`.
/// The product supplies these from its own directory.
class FlareContactOption {
  const FlareContactOption({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.subtitle,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? subtitle;
}
