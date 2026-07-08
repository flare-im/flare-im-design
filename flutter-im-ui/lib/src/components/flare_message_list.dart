import 'package:flutter/material.dart';

import '../models/message_content.dart';
import '../models/message_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_message_bubble.dart';

/// The virtualised message thread — grouping, load-older, multi-select, media
/// state. Spec: Message/MessageList (`FlareMessageList`).
///
/// Pure/presentational and windowed via [ListView.builder] (O(visible)). Order
/// is oldest→newest (top→bottom); the host feeds [messages] from the timeline
/// view and drives pagination through [onLoadOlder].
class FlareMessageList extends StatelessWidget {
  const FlareMessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    this.conversationKind = FlareConversationKind.single,
    this.multiSelectMode = false,
    this.selectedIds = const {},
    this.loadingOlder = false,
    this.loading = false,
    this.mediaDownloadStates = const {},
    this.controller,
    this.onLoadOlder,
    this.onMessageLongPress,
    this.onAvatarTap,
    this.onMediaAction,
    this.onResend,
    this.onToggleSelect,
    this.emptyPlaceholder,
  });

  final List<FlareMessageData> messages;
  final String currentUserId;
  final FlareConversationKind conversationKind;
  final bool multiSelectMode;
  final Set<String> selectedIds;
  final bool loadingOlder;
  final bool loading;

  /// Per-message-id media download state.
  final Map<String, FlareMediaDownloadState> mediaDownloadStates;

  final ScrollController? controller;
  final VoidCallback? onLoadOlder;
  final void Function(FlareMessageData message)? onMessageLongPress;
  final void Function(FlareMessageData message)? onAvatarTap;
  final void Function(FlareMessageData message, FlareMessageContent content)?
      onMediaAction;
  final void Function(FlareMessageData message)? onResend;
  final void Function(FlareMessageData message)? onToggleSelect;
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    // Faint chat canvas so the white received bubbles read as cards.
    final canvas = FlareColors.of(Theme.of(context).brightness).bgSecondary;
    if (messages.isEmpty) {
      return ColoredBox(
        color: canvas,
        child: Center(
          child: loading
              ? const CircularProgressIndicator()
              : (emptyPlaceholder ?? const _Empty()),
        ),
      );
    }

    // header (load-older) occupies index 0
    final itemCount = messages.length + 1;

    return ColoredBox(
      color: canvas,
      child: NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (onLoadOlder != null &&
            n.metrics.pixels <= n.metrics.minScrollExtent + 160) {
          onLoadOlder!();
        }
        return false;
      },
      child: ListView.builder(
        controller: controller,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) return _header();
          final i = index - 1;
          final msg = messages[i];
          final prev = i > 0 ? messages[i - 1] : null;
          final next = i < messages.length - 1 ? messages[i + 1] : null;
          final groupStart = prev == null ||
              prev.senderId != msg.senderId ||
              prev.isSystem ||
              msg.isSystem;
          final groupEnd = next == null ||
              next.senderId != msg.senderId ||
              next.isSystem ||
              msg.isSystem;

          return FlareMessageBubble(
            message: msg,
            currentUserId: currentUserId,
            conversationKind: conversationKind,
            groupStart: groupStart,
            groupEnd: groupEnd,
            multiSelectMode: multiSelectMode,
            selected: selectedIds.contains(msg.id),
            mediaState: mediaDownloadStates[msg.id],
            onLongPress: onMessageLongPress,
            onAvatarTap: onAvatarTap,
            onMediaAction: onMediaAction,
            onResend: onResend,
            onToggleSelect: onToggleSelect,
          );
        },
      ),
      ),
    );
  }

  Widget _header() {
    if (!loadingOlder) return const SizedBox(height: FlareSizes.spacingSm);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: FlareSizes.spacingMd),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Text('No messages yet',
        style:
            TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeLg));
  }
}
