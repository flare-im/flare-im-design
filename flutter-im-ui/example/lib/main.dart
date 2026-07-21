import 'package:flutter/material.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

// Gallery app — the Flutter equivalent of the web docs demos. Every entry renders
// the REAL flare_im_ui widget with mock data.
void main() => runApp(const GalleryApp());

FlareMessageData _msg(String id, String name, String text,
    {bool self = false, FlareMessageDeliveryStatus status = FlareMessageDeliveryStatus.read}) {
  return FlareMessageData(
    id: id,
    senderId: self ? 'me' : id,
    senderName: name,
    content: FlareTextContent(text),
    timeLabel: '14:30',
    status: status,
  );
}

class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  // Default to dark so the Aurora surfaces (violet-lit cards + glow headers)
  // are visible on first load; the AppBar action toggles light/dark.
  ThemeMode _mode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flare_im_ui gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      themeMode: _mode,
      home: _Gallery(
        isDark: _mode == ThemeMode.dark,
        onToggleTheme: () => setState(
            () => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.child);
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 8),
          child,
          const Divider(height: 28),
        ],
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.isDark, required this.onToggleTheme});
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final moment = FlareMoment(
      id: 'm1',
      author: const FlareMomentAuthor(id: 'u2', name: 'Ivy Chen'),
      text: '新版 Aurora 主题上线 ✨ 深色下用品牌紫做「暗处的光源」，卡片浮起来了。',
      images: const [FlareGridImage(alt: '设计稿一'), FlareGridImage(alt: '设计稿二')],
      location: '深圳·科技园',
      time: '刚刚',
      likes: const [FlareMomentLike(id: 'u1', name: 'Henry'), FlareMomentLike(id: 'u3', name: 'Kai')],
      comments: const [
        FlareMomentComment(id: 'c1', author: FlareMomentAuthor(id: 'u1', name: 'Henry'), text: '这个紫太顶了', time: '刚刚'),
      ],
      likedBySelf: true,
    );
    const profile = FlareUserProfile(
      id: 'u2', name: 'Ivy Chen', signature: '设计即沟通', flareId: 'ivy_chen',
    );
    const profileEntries = [
      FlareSettingsItem(key: 'moments', label: '我的圈子', icon: Icons.photo_library_outlined, kind: FlareSettingKind.navigation),
      FlareSettingsItem(key: 'favorites', label: '收藏', icon: Icons.star_outline, kind: FlareSettingKind.navigation),
      FlareSettingsItem(key: 'settings', label: '设置', icon: Icons.settings_outlined, kind: FlareSettingKind.navigation),
    ];

    final contacts = [
      FlareContact(id: 'u1', name: 'Henry Ford', signature: 'Keep it simple.', presence: FlarePresence.online),
      FlareContact(id: 'u2', name: 'Ivy Chen', signature: '设计即沟通', presence: FlarePresence.busy),
      FlareContact(id: 'u3', name: 'Kai', presence: FlarePresence.away),
    ];
    final conversations = [
      ConversationRowData(id: 'c1', title: 'Ivy Chen', preview: '好的，那明天上午同步一下 👍', timestampLabel: '14:32', unreadCount: 3, pinned: true),
      ConversationRowData(id: 'c2', title: '设计评审组', preview: 'Kai: 新稿已上传', timestampLabel: '13:05'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('flare_im_ui · 组件 Gallery'),
        actions: [
          IconButton(
            tooltip: isDark ? '切换浅色' : '切换深色',
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: onToggleTheme,
          ),
        ],
      ),
      body: ListView(
        children: [
          _Section('FlareScreen (aurora)', SizedBox(
            height: 200,
            child: FlareScreen(
              title: '我的',
              surface: FlareScreenSurface.aurora,
              scroll: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FlareProfileCard(
                  user: const FlareContact(
                      id: 'u2', name: 'Ivy Chen', signature: '设计即沟通', presence: FlarePresence.online),
                ),
              ),
            ),
          )),
          _Section('MomentsCoverHeader', FlareMomentsCoverHeader(
            userId: profile.id, name: profile.name, signature: profile.signature,
          )),
          _Section('MomentCard (elevated)', FlareMomentCard(moment: moment)),
          _Section('ProfilePanel (aurora header)', SizedBox(
            height: 320,
            child: FlareProfilePanel(user: profile, entries: profileEntries),
          )),
          _Section('Avatar', Row(children: const [
            FlareAvatar(userId: 'u1', displayName: 'Ivy Chen', presence: FlarePresence.online),
            SizedBox(width: 12),
            FlareAvatar(userId: 'u2', displayName: 'Henry Ford', presence: FlarePresence.busy),
          ])),
          _Section('TimeStamp', Row(children: const [
            FlareTimeStamp(label: '刚刚'), SizedBox(width: 8), FlareTimeStamp(label: '14:32'),
          ])),
          _Section('MessageStatus', Row(children: const [
            FlareMessageStatus(status: FlareMessageDeliveryStatus.pending), SizedBox(width: 16),
            FlareMessageStatus(status: FlareMessageDeliveryStatus.sent), SizedBox(width: 16),
            FlareMessageStatus(status: FlareMessageDeliveryStatus.read), SizedBox(width: 16),
            FlareMessageStatus(status: FlareMessageDeliveryStatus.failed),
          ])),
          const _Section('EmptyState', FlareEmptyState(title: '还没有会话', description: '发起一个聊天，或从通讯录里找人开始对话。', actionText: '发起聊天')),
          const _Section('SearchBar', FlareSearchBar(placeholder: '搜索联系人、群组、消息')),
          _Section('ConversationRow', FlareConversationRow(item: conversations.first)),
          _Section('ConversationList', SizedBox(height: 140, child: FlareConversationList(items: conversations))),
          _Section('ContactItem', FlareContactItem(item: contacts[1])),
          _Section('ContactList', SizedBox(height: 180, child: FlareContactList(items: contacts))),
          _Section('GroupList', SizedBox(height: 120, child: FlareGroupList(items: [
            FlareGroupSummary(id: 'g1', name: '设计评审组', memberCount: 12),
            FlareGroupSummary(id: 'g2', name: 'Flare 前端', memberCount: 34),
          ]))),
          const _Section('TextMessage', Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            FlareTextMessage(text: '收到，我下午过一遍给你反馈 👍', self: true),
            SizedBox(height: 8),
            FlareTextMessage(text: '新版设计稿已经上传啦，帮忙看下～'),
          ])),
          _Section('Message bodies', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FlareImageMessage(alt: '示例图片'),
            const SizedBox(height: 10),
            const FlareVideoMessage(duration: '01:24'),
            const SizedBox(height: 10),
            const FlareVoiceMessage(seconds: 12),
            const SizedBox(height: 10),
            const FlareFileMessage(name: '设计规范.pdf', size: '2.4 MB', ext: 'pdf'),
            const SizedBox(height: 10),
            const FlareLocationMessage(title: '深圳湾科技生态园', address: '科技南路 · 3 栋'),
            const SizedBox(height: 10),
            const FlareContactMessage(name: 'Ivy Chen', subtitle: '设计师'),
            const SizedBox(height: 10),
            const FlareLinkCardMessage(title: 'Flare IM Design', domain: 'flare.im', description: '一套契约，四端原生实现'),
            const SizedBox(height: 10),
            const FlareTaskMessage(title: '提交本周周报', meta: '周五 18:00'),
            const SizedBox(height: 10),
            Row(children: const [FlareStickerMessage(), SizedBox(width: 12), FlareEmojiMessage()]),
            const SizedBox(height: 10),
            const FlareSystemMessage(text: 'Ivy 加入了群聊'),
          ])),
          _Section('MessageBubble', Column(children: [
            FlareMessageBubble(message: _msg('2', 'Ivy Chen', '新版设计稿已经上传啦～'), currentUserId: 'me', conversationKind: FlareConversationKind.group),
            FlareMessageBubble(message: _msg('3', 'Me', '收到，下午看', self: true), currentUserId: 'me', conversationKind: FlareConversationKind.group),
          ])),
          _Section('MessageList', SizedBox(height: 220, child: FlareMessageList(
            messages: [
              _msg('1', 'Ivy Chen', '新版设计稿已经上传啦～'),
              _msg('2', 'Me', '收到，下午看', self: true),
              _msg('3', 'Ivy Chen', '辛苦～重点看会话列表'),
            ],
            currentUserId: 'me',
            conversationKind: FlareConversationKind.group,
          ))),
          const _FormShowcase(),
        ],
      ),
    );
  }
}

/// Stateful showcase for the interactive Form components (Select sheet, Textarea,
/// Stepper, Slider, Rating). Each renders the REAL flare_im_ui widget with local
/// state wired through value / onChanged.
class _FormShowcase extends StatefulWidget {
  const _FormShowcase();

  @override
  State<_FormShowcase> createState() => _FormShowcaseState();
}

class _FormShowcaseState extends State<_FormShowcase> {
  String _selectValue = '';
  String _timeValue = '';
  String _dateValue = '';
  String _textareaValue = '';
  num _stepperValue = 1;
  double _sliderValue = 40;
  int _ratingValue = 3;

  static const _selectOptions = [
    FlareSelectOption(value: 'online', label: '在线'),
    FlareSelectOption(value: 'busy', label: '忙碌'),
    FlareSelectOption(value: 'away', label: '离开'),
    FlareSelectOption(value: 'invisible', label: '隐身', disabled: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Section('Select (bottom sheet)', Align(
          alignment: Alignment.centerLeft,
          child: FlareSelect(
            options: _selectOptions,
            value: _selectValue,
            placeholder: '选择状态',
            title: '设置在线状态',
            onChanged: (v) => setState(() => _selectValue = v),
          ),
        )),
        _Section('TimePicker (bottom sheet)', Align(
          alignment: Alignment.centerLeft,
          child: FlareTimePicker(
            value: _timeValue,
            placeholder: '选择时间',
            title: '设置提醒时间',
            onChanged: (v) => setState(() => _timeValue = v),
          ),
        )),
        _Section('DatePicker (bottom sheet)', Align(
          alignment: Alignment.centerLeft,
          child: FlareDatePicker(
            value: _dateValue,
            placeholder: '选择日期',
            title: '设置日期',
            onChanged: (v) => setState(() => _dateValue = v),
          ),
        )),
        _Section('Textarea', FlareTextarea(
          value: _textareaValue,
          placeholder: '说点什么…（⌘/Ctrl+Enter 提交）',
          showCount: true,
          maxlength: 140,
          maxRows: 5,
          onChanged: (v) => setState(() => _textareaValue = v),
        )),
        _Section('Stepper', Align(
          alignment: Alignment.centerLeft,
          child: FlareStepper(
            value: _stepperValue,
            min: 0,
            max: 10,
            onChanged: (v) => setState(() => _stepperValue = v),
          ),
        )),
        _Section('Slider', FlareSlider(
          value: _sliderValue,
          showValue: true,
          onChanged: (v) => setState(() => _sliderValue = v),
        )),
        _Section('Rating', Align(
          alignment: Alignment.centerLeft,
          child: FlareRating(
            value: _ratingValue,
            clearable: true,
            onChanged: (v) => setState(() => _ratingValue = v),
          ),
        )),
      ],
    );
  }
}
