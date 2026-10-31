part of 'flare_strings_english.dart';

// The English copy of the FlareStrings fields that are functions of a count, a
// name or a kind — the part of flareStringsEnglish that strings/en.json cannot
// hold, because a template alone cannot pick a plural form, a month name or an
// omitted name. strings/build.mjs hands every `_<field>English` here to the
// generated preset. The wording is checked against strings/en-formats.json,
// the table the native kits share; a count takes the English `one` form at 1
// (spec/plural-vectors.json).

/// [one] at 1, else [other], with `{count}` filled in.
String _english(int count, String one, String other) =>
    (count == 1 ? one : other).replaceAll('{count}', '$count');

const List<String> _englishMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _imagePreviewPositionEnglish(int index, int count) =>
    '$index of $count';
String _readTabEnglish(int count) => 'Read ($count)';
String _unreadTabEnglish(int count) => 'Unread ($count)';
String _viewAllEnglish(int total) => 'View all $total';
String _typingOneEnglish(String name) => '$name is typing…';
String _typingManyEnglish(int count) =>
    _english(count, '{count} person typing…', '{count} people typing…');
String _newMessagesEnglish(int count) => count > 0
    ? _english(count, '{count} new message', '{count} new messages')
    : 'New messages';
String _joinedCountEnglish(int count, String status) =>
    '$count joined · $status';
String _selfSuffixEnglish(String name) => '$name (me)';
String _selectedCountEnglish(int count) => '$count selected';
String _translatedByEnglish(String provider) => 'Translated by $provider';
String _pollOptionHintEnglish(int index) => 'Option $index';
String _yearMonthEnglish(int year, int month) =>
    '${month >= 1 && month <= 12 ? _englishMonths[month - 1] : '$month'} $year';
String _ratingStarsEnglish(int count) =>
    _english(count, '{count} star', '{count} stars');
String _confirmCountEnglish(int count) => 'Confirm ($count)';
String _memberCountEnglish(int count) =>
    _english(count, '{count} member', '{count} members');
String _wordCharCountEnglish(int words, int chars) =>
    '${_english(words, '{count} word', '{count} words')} · '
    '${_english(chars, '{count} character', '{count} characters')}';
String _permissionTitleEnglish(String noun) => 'Allow $noun access';
String _permissionUndeterminedDescriptionEnglish(String feature, String verb) =>
    '$feature needs to $verb. Allow it to continue.';
String _permissionDeniedDescriptionEnglish(String feature, String verb) =>
    'Permission to $verb was denied, so $feature can\'t be used. '
    'Turn it on in system settings.';
String _permissionRestrictedDescriptionEnglish(String feature, String verb) =>
    'Permission to $verb is restricted by this device or your organization, '
    'so $feature isn\'t available.';
String _permissionUnavailableDescriptionEnglish(String feature, String verb) =>
    'This device can\'t $verb here, so $feature isn\'t available.';
String _messageRecalledGroupOtherEnglish(String name) =>
    '$name recalled a message';
String _quotedMessageEnglish(String name, String summary) =>
    name.isEmpty ? 'Quoted: $summary' : 'Quoted $name: $summary';
String _jumpedToMessageEnglish(String name, String summary) =>
    'Jumped to $name\'s message: $summary';
String _previewImageNamedEnglish(String label) => '[Image] $label';
String _previewFileNamedEnglish(String name) => '[File] $name';
String _previewLocationNamedEnglish(String label) => '[Location] $label';
String _previewCardNamedEnglish(String label) => '[Contact] $label';
String _previewForwardCountEnglish(int count) =>
    _english(count, '[Forward] {count} message', '[Forward] {count} messages');
String _previewImageGroupCountEnglish(int count) => '[Album] $count';
String _systemEventGroupProfileUpdatedNamedEnglish(String name) =>
    'Group renamed to $name';
String _displayNameMembersMoreEnglish(String names, int count) =>
    '$names${_english(count, ' and {count} other', ' and {count} others')}';
String _announcementReadBarReadCountEnglish(int read, int total) =>
    '$read/$total read';
String _groupDetailMemberCountEnglish(int count) =>
    _english(count, '{count} member', '{count} members');
String _groupDetailInviteConfirmEnglish(int count) => 'Invite ($count)';
String _groupDetailTransferConfirmEnglish(String name) =>
    'Transfer group ownership to "$name"? You\'ll become a regular member. '
    'This can\'t be undone.';
String _messageImageGroupLabelEnglish(int count) =>
    _english(count, '{count} image', '{count} images');
String _messageImageGroupItemEnglish(int index, int count) =>
    'Image $index of $count';
String _messageImageGroupItemMoreEnglish(int index, int count, int more) =>
    'Image $index of $count, $more more not shown';
String _conversationBatchToolbarSucceededSummaryEnglish(int count) =>
    '$count succeeded';
String _conversationBatchToolbarFailedSummaryEnglish(int count) =>
    '$count failed';
String _conversationBatchToolbarMaxSelectionEnglish(int max) =>
    _english(max, 'Select up to {count} item', 'Select up to {count} items');
String _storageUsageFileCountEnglish(int count) =>
    _english(count, '{count} file', '{count} files');
String _momentAudienceSheetSelectedEnglish(int count) =>
    _english(count, '{count} person selected', '{count} people selected');
String _conversationHeaderMemberCountEnglish(int count) =>
    _english(count, '{count} member', '{count} members');
String _connectionDisconnectedReasonEnglish(String reason) =>
    'Disconnected: $reason';
String _groupDetailMembersTitleEnglish(int count) => 'Members ($count)';
String _profilePanelEditProfileEnglish(String name) => '$name, edit profile';
String _momentReplyToCommentEnglish(String name, String text) =>
    'Reply to $name: $text';
