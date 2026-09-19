import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('core General components remain visually stable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          child: Scaffold(
            body: Stack(
              children: [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FlareButton(label: 'Send'),
                      SizedBox(height: 16),
                      SizedBox(
                        width: 320,
                        child: FlareInput(
                          placeholder: 'Message',
                          clearable: true,
                        ),
                      ),
                    ],
                  ),
                ),
                FlareCommandPalette(
                  open: true,
                  query: '',
                  label: 'Commands',
                  placeholder: 'Find a command',
                  emptyText: 'No commands',
                  groups: const [
                    FlareCommandPaletteGroup(
                      id: 'message',
                      label: 'Message',
                      commands: [
                        FlareCommandPaletteCommand(
                          id: 'reply',
                          label: 'Reply',
                          description: 'Reply to the selected message',
                          shortcut: 'R',
                        ),
                        FlareCommandPaletteCommand(
                          id: 'copy',
                          label: 'Copy',
                          shortcut: 'Ctrl+C',
                        ),
                      ],
                    ),
                  ],
                  onQueryChange: (_) {},
                  onInvoke: (_) {},
                  onClose: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('baselines/core_components.png'),
    );
  });

  testWidgets(
    'MessageStatus geometry and semantic colors remain visually stable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(840, 420));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            child: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: _MessageStatusGallery(
                      brightness: Brightness.light,
                      title: 'Light · standalone',
                    ),
                  ),
                  Expanded(
                    child: _MessageStatusGallery(
                      brightness: Brightness.dark,
                      title: 'Dark · standalone + outgoing bubble',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('baselines/message_status.png'),
      );
    },
  );
}

class _MessageStatusGallery extends StatelessWidget {
  const _MessageStatusGallery({required this.brightness, required this.title});

  final Brightness brightness;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(brightness: brightness);
    final colors = FlareColors.of(brightness);
    const states = FlareMessageDeliveryStatus.values;
    return Theme(
      data: theme,
      child: ColoredBox(
        color: colors.bgPrimary,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final state in states)
                    Column(
                      children: [
                        FlareMessageStatus(status: state),
                        const SizedBox(height: 8),
                        Text(
                          state.name,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.messageOutgoingBackground,
                      borderRadius: BorderRadius.circular(
                        FlareSizes.radiusBubble,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      child: FlareMessageMeta(
                        timestamp: '14:32',
                        edited: true,
                        status: FlareMessageDeliveryStatus.read,
                        tint: colors.messageStatusOnOutgoing,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
