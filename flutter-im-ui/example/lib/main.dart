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

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flare_im_ui gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const _Gallery(),
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
  const _Gallery();

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(title: const Text('flare_im_ui · 组件 Gallery')),
      body: ListView(
        children: [
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
        ],
      ),
    );
  }
}
