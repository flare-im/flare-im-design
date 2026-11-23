/// The recent-search list after [term] was used: trimmed, newest first, an
/// exact repeat moves to the front instead of appearing twice, and the oldest
/// fall off past [max]. A blank term changes nothing. The host stores the list
/// (per signed-in user); the rule is here so every client keeps the same one
/// (the Vue kit's `flareRememberSearch`).
List<String> flareRememberSearch(
  List<String> list,
  String term, {
  int max = 8,
}) {
  final value = term.trim();
  if (value.isEmpty) return List.of(list);
  return [
    value,
    for (final entry in list)
      if (entry != value) entry,
  ].take(max < 0 ? 0 : max).toList();
}
