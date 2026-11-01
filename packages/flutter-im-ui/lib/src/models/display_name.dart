import 'package:flutter/foundation.dart';

import '../tokens/flare_strings.dart';
import 'message_data.dart' show FlareReplyTarget;

/// Where a named value came from (`source` on the wire). For tests and
/// diagnostics only: every source reads the same.
enum FlareDisplayNameSource {
  alias,
  memberNickname,
  profile,
  snapshot,
  remark,
  name;

  /// The source a wire value names; null for one the kit does not know.
  static FlareDisplayNameSource? fromWire(Object? value) {
    for (final source in values) {
      if (source.name == value) return source;
    }
    return null;
  }
}

/// What an unnamed value is (`entity` on the wire), after the conversation
/// type, or a person.
enum FlareDisplayNameEntity {
  person,
  group,
  system,
  ai,
  customer,
  channel,
  broadcast,
  temp;

  /// The entity a wire value names; null for one the kit does not know.
  static FlareDisplayNameEntity? fromWire(Object? value) {
    for (final entity in values) {
      if (entity.name == value) return entity;
    }
    return null;
  }
}

/// A name as the core SDK projects it — a conversation's `title` and
/// `lastSender`, a message's `sender`, a participant's or a contact's `name` —
/// camelCase JSON on the wire. The SDKs carry no copy: a name that is not known
/// stays structured and every kit writes it with the same table
/// (spec/display-name-vectors.json) through [flareDisplayNameText]. Widgets
/// keep string parameters; a host turns the projected value into text where it
/// hands it to one.
@immutable
sealed class FlareDisplayName {
  const FlareDisplayName();

  static const FlareDisplayName _unknownUser = FlareUnnamedDisplayName(
    FlareDisplayNameEntity.person,
  );

  /// Reads a decoded wire value, never failing: an unknown `entity` reads as
  /// [FlareDisplayNameEntity.person]; an unknown `kind`, a form missing its
  /// text, or a value that is not a map as an unnamed person without an id
  /// tail (`displayNameUnknownUser`). A core newer than the kit therefore
  /// still draws something sensible.
  static FlareDisplayName fromJson(Object? json) {
    if (json is! Map) return _unknownUser;
    switch (json['kind']) {
      case 'named':
        final text = json['text'];
        if (text is! String) return _unknownUser;
        return FlareNamedDisplayName(
          text,
          source: FlareDisplayNameSource.fromWire(json['source']),
        );
      case 'members':
        final names = json['names'];
        final total = json['total'];
        return FlareMembersDisplayName(
          names is List ? names.whereType<String>().toList() : const [],
          total: total is num ? total.toInt() : 0,
        );
      case 'unnamed':
        final idTail = json['idTail'];
        return FlareUnnamedDisplayName(
          FlareDisplayNameEntity.fromWire(json['entity']) ??
              FlareDisplayNameEntity.person,
          idTail: idTail is String ? idTail : '',
        );
    }
    return _unknownUser;
  }

  /// The wire value (camelCase JSON).
  Map<String, Object?> toJson();
}

/// A real name, drawn as it is.
final class FlareNamedDisplayName extends FlareDisplayName {
  const FlareNamedDisplayName(this.text, {this.source});

  final String text;
  final FlareDisplayNameSource? source;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'named',
    'text': text,
    if (source != null) 'source': source!.name,
  };

  @override
  bool operator ==(Object other) =>
      other is FlareNamedDisplayName &&
      other.text == text &&
      other.source == source;

  @override
  int get hashCode => Object.hash(text, source);
}

/// A group without a name, by up to three of its named members (never the
/// reader); [total] counts the reader.
final class FlareMembersDisplayName extends FlareDisplayName {
  const FlareMembersDisplayName(this.names, {required this.total});

  final List<String> names;
  final int total;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'members',
    'names': names,
    'total': total,
  };

  @override
  bool operator ==(Object other) =>
      other is FlareMembersDisplayName &&
      listEquals(other.names, names) &&
      other.total == total;

  @override
  int get hashCode => Object.hash(Object.hashAll(names), total);
}

/// Nothing to call it by: what it is, and for a person the tail of their id
/// ([flareIdTail]).
final class FlareUnnamedDisplayName extends FlareDisplayName {
  const FlareUnnamedDisplayName(this.entity, {this.idTail = ''});

  final FlareDisplayNameEntity entity;
  final String idTail;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'unnamed',
    'entity': entity.name,
    'idTail': idTail,
  };

  @override
  bool operator ==(Object other) =>
      other is FlareUnnamedDisplayName &&
      other.entity == entity &&
      other.idTail == idTail;

  @override
  int get hashCode => Object.hash(entity, idTail);
}

/// The tail of an id the kits show for a person without a name: the id
/// trimmed of surrounding white space, then its last 4 Unicode scalars (runes,
/// not UTF-16 units, so an emoji is one), or the whole id when it has 4 or
/// fewer; a blank id gives ''. The core SDK makes `idTail` with the same rule
/// (spec/display-name-vectors.json `idTail`).
String flareIdTail(String id) {
  final trimmed = id.trim();
  final runes = trimmed.runes.toList();
  if (runes.length <= 4) return trimmed;
  return String.fromCharCodes(runes.sublist(runes.length - 4));
}

/// The text of a projected name (spec/display-name-vectors.json, the same on
/// all four kits). [FlareNamedDisplayName] reads as it is;
/// [FlareMembersDisplayName] joins the non-blank names with
/// `displayNameSeparator` and, when the group has more people than it names
/// besides the reader, adds `displayNameMembersMore(names, total, others)` —
/// Chinese counts the group (total, the reader included), English the others
/// (total - names - 1) — and with no name left reads as an unnamed group;
/// [FlareUnnamedDisplayName] reads by entity — a person with an id tail
/// `displayNameUser`, without one `displayNameUnknownUser`, any other entity
/// its own word.
/// The sender a quote shows (spec/display-name-vectors.json `quoteSender`, the
/// same on all four kits), never blank and never an id: the target's
/// [FlareReplyTarget.sender] written by [flareDisplayNameText] when the quote
/// carries one; else [FlareReplyTarget.senderName], trimmed, when it is not
/// blank; else the unnamed person of [FlareReplyTarget.senderId] —
/// `displayNameUser` with the tail of the id ([flareIdTail]),
/// `displayNameUnknownUser` without one. A projected sender that writes as
/// blank text falls through the same way. The bubble's quote and the
/// composer's reply strip both read it.
String flareQuoteSenderText(FlareReplyTarget target, FlareStrings strings) {
  final sender = target.sender;
  if (sender != null) {
    final projected = flareDisplayNameText(sender, strings).trim();
    if (projected.isNotEmpty) return projected;
  }
  final name = target.senderName.trim();
  if (name.isNotEmpty) return name;
  return flareDisplayNameText(
    FlareUnnamedDisplayName(
      FlareDisplayNameEntity.person,
      idTail: flareIdTail(target.senderId ?? ''),
    ),
    strings,
  );
}

String flareDisplayNameText(FlareDisplayName name, FlareStrings strings) {
  switch (name) {
    case FlareNamedDisplayName(:final text):
      return text;
    case FlareMembersDisplayName(:final names, :final total):
      final shown = names.where((each) => each.trim().isNotEmpty).toList();
      if (shown.isEmpty) return strings.displayNameGroup;
      final joined = shown.join(strings.displayNameSeparator);
      final others = total - shown.length - 1;
      return others > 0
          ? strings.displayNameMembersMore(joined, total, others)
          : joined;
    case FlareUnnamedDisplayName(:final entity, :final idTail):
      return switch (entity) {
        FlareDisplayNameEntity.person =>
          idTail.isEmpty
              ? strings.displayNameUnknownUser
              : strings.displayNameUser(idTail),
        FlareDisplayNameEntity.group => strings.displayNameGroup,
        FlareDisplayNameEntity.system => strings.displayNameSystem,
        FlareDisplayNameEntity.ai => strings.displayNameAi,
        FlareDisplayNameEntity.customer => strings.displayNameCustomer,
        FlareDisplayNameEntity.channel => strings.displayNameChannel,
        FlareDisplayNameEntity.broadcast => strings.displayNameBroadcast,
        FlareDisplayNameEntity.temp => strings.displayNameTemp,
      };
  }
}
