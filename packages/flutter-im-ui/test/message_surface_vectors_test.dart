import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The message surface, meta placement and receipt rules against the shared
/// spec/message-surface-vectors.json, message-meta-placement-vectors.json and
/// message-receipt-vectors.json (the Vue, SwiftUI and Compose kits read the
/// same files).
Map<String, dynamic> _read(String name) =>
    jsonDecode(File('../../spec/$name').readAsStringSync())
        as Map<String, dynamic>;

/// The English copy of the keys the shared strings source registered for this
/// round, from strings/en.json, until the generated preset carries them.
FlareStrings english() {
  final en =
      jsonDecode(File('../../strings/en.json').readAsStringSync())
          as Map<String, dynamic>;
  String of(String key) => (en[key] as Map<String, dynamic>)['en'] as String;
  return flareStringsEnglish.copyWith(
    messageReadSummaryUnread: of('messageReadSummaryUnread'),
    messageReadSummaryAllRead: of('messageReadSummaryAllRead'),
    messageSendFailedRetry: of('messageSendFailedRetry'),
  );
}

FlareMessageSurface surfaceOf(String name) =>
    FlareMessageSurface.values.byName(name);

FlareMessageDeliveryStatus statusOf(String name) =>
    FlareMessageDeliveryStatus.values.byName(name);

void main() {
  group('bubble palette', () {
    final palette =
        _read('message-surface-vectors.json')['palette']
            as Map<String, dynamic>;
    final tones = palette['tones'] as Map<String, dynamic>;

    Color? token(String? path, FlareColors colors) => switch (path) {
      null => null,
      'message.incoming.background' => colors.messageIncomingBackground,
      'message.incoming.foreground' => colors.messageIncomingForeground,
      'message.outgoing.background' => colors.messageOutgoingBackground,
      'message.outgoing.foreground' => colors.messageOutgoingForeground,
      'message.failed.background' => colors.messageFailedBackground,
      'message.failed.foreground' => colors.messageFailedForeground,
      'message.failed.border' => colors.messageFailedBorder,
      _ => throw StateError('unknown token $path'),
    };

    test('the tones are the kit\'s', () {
      expect(
        tones.keys.toSet(),
        FlareMessageBubbleTone.values.map((tone) => tone.name).toSet(),
      );
    });

    for (final raw in palette['cases'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      test('${c['id']} → ${c['tone']}', () {
        expect(
          flareMessageBubbleTone(
            self: c['self'] as bool,
            status: statusOf(c['status'] as String),
          ).name,
          c['tone'],
        );
      });
    }

    test('each tone paints the table\'s tokens', () {
      for (final colors in [
        FlareColors.resolve(Brightness.light),
        FlareColors.resolve(Brightness.dark),
      ]) {
        for (final tone in FlareMessageBubbleTone.values) {
          final expected = tones[tone.name] as Map<String, dynamic>;
          final got = flareMessageBubblePalette(tone, colors);
          expect(
            got.background,
            token(expected['background'] as String?, colors),
          );
          expect(
            got.foreground,
            token(expected['foreground'] as String?, colors),
          );
          expect(got.edge, token(expected['edge'] as String?, colors));
        }
      }
    });
  });

  group('message-surface-vectors', () {
    final table = _read('message-surface-vectors.json');

    test('the surfaces and the defaults table are the kit\'s', () {
      expect(FlareMessageSurface.values.map((s) => s.name), table['surfaces']);
      final defaults = table['defaults'] as Map<String, dynamic>;
      for (final entry in defaults.entries) {
        expect(
          flareMessageSurfaceDefaults[surfaceOf(entry.key)],
          (entry.value as List).toSet(),
          reason: entry.key,
        );
      }
    });

    test('the table still carries its cases', () {
      expect((table['cases'] as List).length, greaterThanOrEqualTo(40));
    });

    for (final v in (table['cases'] as List).cast<Map<String, dynamic>>()) {
      test('surface ${v['id']}', () {
        final input = v['input'] as Map<String, dynamic>;
        final registered = input['registered'] as String?;
        expect(
          flareMessageSurface(
            FlareMessageSurfaceInput(
              contentType: input['contentType'] as String,
              subtype: input['subtype'] as String?,
              loneEmoji: input['loneEmoji'] as bool? ?? false,
              hasQuote: input['hasQuote'] as bool? ?? false,
              hasCaption: input['hasCaption'] as bool? ?? false,
              recalled: input['recalled'] as bool? ?? false,
              deleted: input['deleted'] as bool? ?? false,
              registered: registered == null ? null : surfaceOf(registered),
            ),
          ),
          surfaceOf(v['surface'] as String),
        );
      });
    }

    test('kit content maps onto the spec vocabulary', () {
      expect(
        flareMessageContentKey(
          const FlareGenericContent(
            contentType: 'custom:flare.plugin.message.v1',
            label: 'x',
          ),
        ),
        (contentType: 'custom', subtype: 'flare.plugin.message.v1'),
      );
      expect(
        flareMessageContentKey(
          const FlareGenericContent(contentType: 'mini_program', label: 'x'),
        ).contentType,
        'miniProgram',
      );
      expect(
        flareMessageContentKey(
          const FlareLinkCardContent(url: 'https://a.b', title: 't'),
        ).contentType,
        'linkCard',
      );
      // A message keeps its kit content but draws on the spec's surface.
      final emoji = FlareMessageData(
        id: '1',
        senderId: 'a',
        senderName: 'A',
        content: const FlareTextContent('👍'),
      );
      expect(
        flareMessageSurface(flareMessageSurfaceInputOf(emoji)),
        FlareMessageSurface.bareMedia,
      );
      final deleted = FlareMessageData(
        id: '2',
        senderId: 'a',
        senderName: 'A',
        content: const FlareImageContent(url: 'https://a.b/c.png'),
        lifecycle: const FlareMessageLifecycle(
          mutation: FlareMessageMutationState.deleted,
        ),
      );
      expect(
        flareMessageSurface(flareMessageSurfaceInputOf(deleted)),
        FlareMessageSurface.centered,
      );
    });
  });

  group('message-meta-placement-vectors', () {
    final table = _read('message-meta-placement-vectors.json');

    test('the placements are the kit\'s', () {
      expect(
        FlareMessageMetaPlacement.values.map((p) => p.name),
        table['placements'],
      );
    });

    for (final v in (table['cases'] as List).cast<Map<String, dynamic>>()) {
      test('placement ${v['id']}', () {
        final got = flareMessageMetaPlacement(
          surface: surfaceOf(v['surface'] as String),
          contentType: v['contentType'] as String,
          self: v['self'] as bool,
          status: statusOf(v['status'] as String),
        );
        final expected = v['expect'] as Map<String, dynamic>;
        expect(got.placement.name, expected['placement']);
        expect(
          got.tone == FlareMessageMetaTone.onOutgoing
              ? 'onOutgoing'
              : 'default',
          expected['tone'],
        );
        expect(got.retry?.name, expected['retry']);
      });
    }
  });

  group('message-receipt-vectors', () {
    final table = _read('message-receipt-vectors.json');
    final en = english();

    test('five statuses, no delivered, and their glyphs', () {
      expect(
        FlareMessageDeliveryStatus.values.map((s) => s.name),
        table['statuses'],
      );
      final glyphs = table['glyphs'] as Map<String, dynamic>;
      for (final entry in glyphs.entries) {
        expect(flareMessageReceiptGlyph(statusOf(entry.key)).name, entry.value);
      }
    });

    for (final v in (table['cases'] as List).cast<Map<String, dynamic>>()) {
      test('receipt ${v['id']}', () {
        final summary = v['readSummary'] as Map<String, dynamic>?;
        final got = flareMessageReceiptPresentation(
          self: v['self'] as bool,
          status: statusOf(v['status'] as String),
          group: v['conversationKind'] == 'group',
          readSummary: summary == null
              ? null
              : FlareMessageReadSummary(
                  readCount: summary['readCount'] as int,
                  unreadCount: summary['unreadCount'] as int,
                  total: summary['total'] as int,
                ),
        );
        final expected = v['expect'] as Map<String, dynamic>;
        expect(got.glyph?.name, expected['glyph']);
        final want = expected['summary'] as Map<String, dynamic>?;
        if (want == null) {
          expect(got.summary, isNull);
        } else {
          expect(got.summary, isNotNull);
          expect(got.summary!.allRead, want['allRead']);
          expect(got.summary!.count, want['count']);
          expect(got.summary!.text(const FlareStrings()), want['zh']);
          expect(got.summary!.text(en), want['en']);
        }
      });
    }

    for (final v
        in (table['accessibility'] as List).cast<Map<String, dynamic>>()) {
      test('reading unit ${v['id']}', () {
        final locale = v['locale'] as String;
        final summary = v['readSummary'] as Map<String, dynamic>?;
        expect(
          flareMessageAccessibilityLabel(
            sender: v['sender'] as String,
            preview: v['preview'] as String,
            time: v['time'] as String,
            self: v['self'] as bool,
            status: statusOf(v['status'] as String),
            strings: locale.startsWith('zh') ? const FlareStrings() : en,
            locale: locale,
            group: v['conversationKind'] == 'group',
            readSummary: summary == null
                ? null
                : FlareMessageReadSummary(
                    readCount: summary['readCount'] as int,
                    unreadCount: summary['unreadCount'] as int,
                    total: summary['total'] as int,
                  ),
          ),
          v['expect'],
        );
      });
    }
  });
}
