import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';

/// Complete adaptive reference client assembled from the public package API.
/// The in-memory state stands in for a host adapter; no internal library source
/// or transport SDK is imported.
class ReferenceIMApp extends StatefulWidget {
  const ReferenceIMApp({super.key, this.gallery});

  final Widget? gallery;

  @override
  State<ReferenceIMApp> createState() => _ReferenceIMAppState();
}

class _ReferenceIMAppState extends State<ReferenceIMApp> {
  static const _navigation = [
    FlareNavigationGroup(
      id: 'main',
      items: [
        FlareNavigationItem(
          id: 'chats',
          label: 'Chats',
          icon: 'chats',
          badge: FlareNavigationBadge(
            kind: FlareNavigationBadgeKind.count,
            count: 2,
            label: '2 unread chats',
          ),
        ),
        FlareNavigationItem(id: 'contacts', label: 'Contacts', icon: 'people'),
        FlareNavigationItem(id: 'search', label: 'Search', icon: 'search'),
        FlareNavigationItem(
          id: 'settings',
          label: 'Settings',
          icon: 'settings',
        ),
      ],
    ),
  ];

  static const _configuration = FlareIMAppConfiguration(
    features: FlareFeatureSet({
      'conversations',
      'contacts',
      'groups',
      'search',
      'media',
      'savedMessages',
      'settings',
    }),
    capabilities: FlareCapabilitySet({
      'reply',
      'reaction',
      'forward',
      'thread',
      'media',
      'messageActions',
    }),
    navigation: _navigation,
  );

  static const _conversations = [
    ConversationRowData(
      id: 'c1',
      title: 'Henry Ford',
      preview: 'Taking a look now',
      timestampLabel: '14:30',
      presence: FlarePresence.online,
    ),
    ConversationRowData(
      id: 'c2',
      title: 'Design Team',
      preview: 'Ivy: shipped the new build',
      timestampLabel: '14:08',
      unreadCount: 2,
      tags: [ConversationRowTag('Group', tone: FlareTagTone.info)],
    ),
    ConversationRowData(
      id: 'c3',
      title: 'Kai Wang',
      preview: 'Let us sync tomorrow',
      timestampLabel: 'Tue',
    ),
  ];

  static const _contacts = [
    FlareContact(
      id: 'u1',
      name: 'Henry Ford',
      signature: 'Keep it simple.',
      presence: FlarePresence.online,
    ),
    FlareContact(
      id: 'u2',
      name: 'Ivy Chen',
      signature: 'Design is communication.',
      presence: FlarePresence.busy,
    ),
    FlareContact(
      id: 'u3',
      name: 'Kai Wang',
      signature: 'Building reliable systems.',
      presence: FlarePresence.offline,
    ),
  ];

  final _messages = <String>[
    'Did the new build go out?',
    'Yes, the release notes are ready.',
    'Great. I am taking a look now.',
  ];
  String _activeNavigationId = 'chats';
  String _activeConversationId = 'c1';
  String _activeContactId = 'u1';
  bool _conversationOpen = false;
  // What the chats frame reports: one pane (a phone, or a window too narrow for
  // the list beside a usable chat) puts the chat in the list's place.
  bool _chatsSinglePane = false;
  bool _contactsSinglePane = false;

  // A destination keeps its state while another is active, so switching back
  // finds the conversation where it was.
  void _navigate(String id) => setState(() => _activeNavigationId = id);

  Widget _conversationList(bool mobile) => FlareConversationListContainer(
    state: const FlareViewState<List<Object?>>(
      status: FlareViewStatus.ready,
      data: [],
    ),
    label: 'Conversations',
    header: Padding(
      padding: const EdgeInsets.all(FlareSizes.spacingLg),
      child: Text(
        mobile ? 'Chats' : 'Flare',
        style: const TextStyle(
          fontSize: FlareSizes.fontSize3xl,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    child: FlareConversationList(
      items: _conversations,
      activeId: _activeConversationId,
      onSelect: (item) => setState(() {
        _activeConversationId = item.id;
        _conversationOpen = true;
      }),
    ),
  );

  Widget _chat(bool mobile) => Column(
    children: [
      FlareConversationHeader(
        identity: FlareConversationIdentity(
          id: _activeConversationId,
          title: _conversations
              .firstWhere((item) => item.id == _activeConversationId)
              .title,
        ),
        capabilities: const FlareConversationHeaderCapabilities(
          availableActionIds: {'search', 'details'},
        ),
        showBack: mobile,
        onBack: mobile ? () => setState(() => _conversationOpen = false) : null,
        onAction: (action) {
          if (action.id == 'search') _navigate('search');
        },
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(FlareSizes.spacingXl),
          itemCount: _messages.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: FlareSizes.spacingMd),
          itemBuilder: (context, index) => FlareMessageBubble(
            message: FlareMessageData(
              id: '$index',
              senderId: index.isOdd ? 'me' : _activeConversationId,
              senderName: index.isOdd ? 'Me' : _activeConversationId,
              content: FlareTextContent(_messages[index]),
            ),
            currentUserId: 'me',
          ),
        ),
      ),
      FlareComposer(
        conversationKey: _activeConversationId,
        placeholder: 'Type a message',
        onSend: (text) {
          setState(() => _messages.add(text));
          return true;
        },
        onAttach: () {},
        onEmoji: () {},
      ),
    ],
  );

  Widget _contactsList() => FlareFriendListContainer(
    state: const FlareViewState<List<Object?>>(
      status: FlareViewStatus.ready,
      data: [],
    ),
    label: 'Contacts',
    header: const Padding(
      padding: EdgeInsets.all(FlareSizes.spacingLg),
      child: Text(
        'Contacts',
        style: TextStyle(
          fontSize: FlareSizes.fontSize3xl,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    child: FlareContactList(
      items: _contacts,
      onSelect: (contact) => setState(() => _activeContactId = contact.id),
    ),
  );

  Widget _destination(BuildContext context, String id) {
    switch (id) {
      case 'chats':
        return FlareAppLayout(
          label: 'Chats',
          activePane: _conversationOpen
              ? FlareWorkspacePane.content
              : FlareWorkspacePane.primary,
          onLayoutChange: (layout) => _report(
            layout,
            _chatsSinglePane,
            (single) => _chatsSinglePane = single,
          ),
          primary: _conversationList(_chatsSinglePane),
          content: _chat(_chatsSinglePane),
        );
      case 'contacts':
        final contact = _contacts.firstWhere(
          (item) => item.id == _activeContactId,
        );
        return FlareAppLayout(
          label: 'Contacts',
          activePane: FlareWorkspacePane.primary,
          hasDetail: !_contactsSinglePane,
          onLayoutChange: (layout) => _report(
            layout,
            _contactsSinglePane,
            (single) => _contactsSinglePane = single,
          ),
          primary: _contactsList(),
          content: FlareEmptyState(
            title: contact.name,
            description: contact.signature,
            icon: 'person',
          ),
          detail: const FlareEmptyState(
            title: 'Contact details',
            description: 'Profile, presence, shared media, and actions.',
            icon: 'info',
          ),
        );
      case 'search':
        return const FlareEmptyState(
          title: 'Search across Flare',
          description: 'Find conversations, messages, contacts, and groups.',
          icon: 'search',
        );
      default:
        return FlareEmptyState(
          title: 'Settings',
          description: 'Notifications, appearance, privacy, and devices.',
          icon: 'settings',
          actionText: widget.gallery == null ? null : 'Open component gallery',
          onAction: widget.gallery == null
              ? null
              : () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => widget.gallery!)),
        );
    }
  }

  void _report(
    FlareWorkspacePresentation layout,
    bool current,
    void Function(bool single) apply,
  ) {
    final single = layout.paneMode == FlareWorkspacePaneMode.singlePane;
    if (single != current) setState(() => apply(single));
  }

  @override
  Widget build(BuildContext context) => FlareIMAppKit(
    configuration: _configuration,
    activeNavigationId: _activeNavigationId,
    onNavigate: _navigate,
    destinationBuilder: _destination,
    label: 'Reference IM application',
  );
}
