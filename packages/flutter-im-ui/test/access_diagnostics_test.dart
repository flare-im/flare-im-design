import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared diagnostics table (`spec/access-diagnostics-vectors.json`): what
/// the host read in, what the page shows out. The Vue, SwiftUI and Compose kits
/// run the same file.
void main() {
  final table =
      jsonDecode(
            File(
              '../../spec/access-diagnostics-vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  List<Map<String, dynamic>> rows(String key) =>
      (table[key] as List).cast<Map<String, dynamic>>();

  FlareAccessStatus? statusOf(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final ack = raw['connectAck'] as Map<String, dynamic>?;
    final recovering = raw['recovering'] as Map<String, dynamic>?;
    return FlareAccessStatus(
      loaded: raw['loaded'] as bool,
      serial: raw['serial'] as int?,
      source: raw['source'] as String?,
      stale: raw['stale'] as bool? ?? false,
      developmentMode: raw['developmentMode'] as bool? ?? false,
      regionId: raw['regionId'] as String?,
      accessPointId: raw['accessPointId'] as String?,
      protocol: raw['protocol'] as String?,
      connectAck: ack == null
          ? null
          : FlareAccessConnectAck(
              accessPointId: ack['accessPointId'] as String?,
              accessPointMismatch: ack['accessPointMismatch'] as bool? ?? false,
            ),
      recovering: recovering == null
          ? null
          : FlareAccessRecovering(
              rounds: recovering['rounds'] as int,
              nextRoundAtMs: recovering['nextRoundAtMs'] as int?,
            ),
    );
  }

  FlareAccessPoint pointOf(Map<String, dynamic> raw) => FlareAccessPoint(
    accessPointId: raw['accessPointId'] as String,
    regionId: raw['regionId'] as String?,
    host: raw['host'] as String?,
    status: raw['status'] as String,
    rttMs: (raw['rttMs'] as num?)?.toDouble(),
    breaker: raw['breaker'] as String,
    pinned: raw['pinned'] as bool,
    current: raw['current'] as bool,
  );

  Map<String, Object?> said(FlareAccessFeedback<Enum>? feedback) => {
    'text': feedback?.text.name,
    'tone': feedback?.tone.name,
  };

  test('the thresholds are the shared ones', () {
    final thresholds = table['thresholds'] as Map<String, dynamic>;
    expect(FlareAccessRttThresholds.goodBelowMs, thresholds['rttGoodBelowMs']);
    expect(FlareAccessRttThresholds.poorAboveMs, thresholds['rttPoorAboveMs']);
    expect(rows('cases').length, greaterThanOrEqualTo(14));
  });

  for (final vector in rows('cases')) {
    test(vector['name'] as String, () {
      final model = flareAccessDiagnostics(
        statusOf(vector['status'] as Map<String, dynamic>?),
        (vector['accessPoints'] as List)
            .cast<Map<String, dynamic>>()
            .map(pointOf)
            .toList(),
      );
      final want = vector['expect'] as Map<String, dynamic>;
      expect(model.state.name, want['state']);
      expect([
        for (final notice in model.notices)
          {
            'text': notice.text.name,
            'tone': notice.tone.name,
            'pulse': notice.pulse,
          },
      ], want['notices']);
      expect(model.manifest.name, want['manifest']);
      expect(model.rtt.shownMs, want['rttMs']);
      expect(model.rtt.grade?.name, want['rttGrade']);
      expect(model.reportedAccessPointId, want['reportedAccessPointId']);
      expect(model.recoveryRounds, want['recoveryRounds']);
      expect([
        for (final region in model.regions)
          {
            'regionId': region.regionId,
            'accessPoints': [
              for (final row in region.accessPoints) row.accessPointId,
            ],
          },
      ], want['regions']);
    });
  }

  for (final vector in rows('points')) {
    test('row: ${vector['name']}', () {
      final row = flareAccessPointRow(
        pointOf(vector['point'] as Map<String, dynamic>),
      );
      expect({
        'status': row.status.name,
        'statusTone': row.statusTone.name,
        'breaker': row.breaker?.name,
        'breakerTone': row.breakerTone?.name,
        'pin': row.pin?.name,
      }, vector['expect']);
    });
  }

  test('latency is graded on the whole milliseconds it shows', () {
    for (final row in rows('rtt')) {
      final rtt = flareAccessRtt((row['rttMs'] as num?)?.toDouble());
      expect(rtt.shownMs, row['shownMs'], reason: '${row['rttMs']}');
      expect(rtt.grade?.name, row['grade'], reason: '${row['rttMs']}');
    }
    expect(flareAccessRtt(double.nan).grade, isNull);
    expect(flareAccessRtt(double.infinity).grade, isNull);
  });

  test('the protocol is named', () {
    for (final row in rows('protocols')) {
      expect(
        flareAccessProtocolLabel(row['protocol'] as String?),
        row['label'],
      );
    }
  });

  test('the source reads apart', () {
    for (final row in rows('sources')) {
      final source = flareAccessSource(row['source'] as String?);
      expect(source.kind.name, row['kind'], reason: '${row['source']}');
      expect(source.detail, row['detail'], reason: '${row['source']}');
    }
  });

  test('a refresh is answered', () {
    for (final row in rows('refresh')) {
      expect(
        said(flareAccessRefreshFeedback(row['outcome'] as String?)),
        {'text': row['text'], 'tone': row['tone']},
        reason: '${row['outcome']}',
      );
    }
  });

  test('an import is answered', () {
    for (final row in rows('import')) {
      expect(
        said(
          flareAccessImportFeedback(
            row['outcome'] as String?,
            row['code'] as String?,
          ),
        ),
        {'text': row['text'], 'tone': row['tone']},
        reason: '${row['outcome']} ${row['code']}',
      );
    }
  });

  test('an export is answered', () {
    for (final row in rows('export')) {
      expect(
        said(flareAccessExportFeedback(row['outcome'] as String?)),
        {'text': row['text'], 'tone': row['tone']},
        reason: '${row['outcome']}',
      );
    }
  });

  group('FlareAccessDiagnostics', () {
    const healthy = FlareAccessStatus(
      loaded: true,
      accessPointId: 'ap-sg-1',
      regionId: 'sg',
      protocol: 'quic',
      serial: 42,
      source: 'https:https://cfg-b.other-cloud.net/flare/v1/abc/',
    );
    const lines = [
      FlareAccessPoint(
        accessPointId: 'ap-sg-1',
        regionId: 'sg',
        host: 'sg1.example.net',
        status: 'active',
        rttMs: 86,
        breaker: 'closed',
        current: true,
      ),
      FlareAccessPoint(
        accessPointId: 'ap-sg-2',
        regionId: 'sg',
        status: 'active',
        rttMs: 420,
        breaker: 'open',
      ),
      FlareAccessPoint(
        accessPointId: 'ap-de-1',
        regionId: 'de',
        status: 'draining',
        breaker: 'closed',
      ),
    ];

    Widget page(
      FlareAccessDiagnostics child, {
      FlareStrings? strings,
      ScrollController? controller,
    }) => MaterialApp(
      home: FlareStringsScope(
        strings: strings ?? const FlareStrings(),
        child: Scaffold(
          body: SingleChildScrollView(controller: controller, child: child),
        ),
      ),
    );

    Finder inRow(String id, Finder finder) => find.descendant(
      of: find.byKey(ValueKey('flare-access-point-$id')),
      matching: finder,
    );

    testWidgets('draws the current line and groups the list by region', (
      tester,
    ) async {
      await tester.pumpWidget(
        page(
          const FlareAccessDiagnostics(status: healthy, accessPoints: lines),
        ),
      );
      expect(find.text('线路正常'), findsOneWidget);
      expect(find.text('QUIC'), findsOneWidget);
      expect(find.text('86 ms · 良好'), findsNWidgets(2));
      expect(find.text('镜像 cfg-b.other-cloud.net'), findsOneWidget);
      expect(find.text('sg'), findsNWidgets(2));
      expect(find.text('de'), findsOneWidget);
      expect(inRow('ap-sg-2', find.text('已熔断')), findsOneWidget);
      expect(inRow('ap-de-1', find.text('即将下线')), findsOneWidget);
    });

    testWidgets('reads in English', (tester) async {
      await tester.pumpWidget(
        page(
          const FlareAccessDiagnostics(status: healthy, accessPoints: lines),
          strings: flareStringsEnglish,
        ),
      );
      expect(find.text('Connection is healthy'), findsOneWidget);
      expect(find.text('86 ms · Good'), findsNWidgets(2));
    });

    testWidgets('puts recovery first while recovering', (tester) async {
      await tester.pumpWidget(
        page(
          const FlareAccessDiagnostics(
            status: FlareAccessStatus(
              loaded: true,
              recovering: FlareAccessRecovering(
                rounds: 2,
                nextRoundAtMs: 91000,
              ),
            ),
          ),
        ),
      );
      expect(find.text('服务暂时不可用，正在自动恢复…'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('恢复工具')).dy,
        lessThan(tester.getTopLeft(find.text('当前线路')).dy),
      );
      expect(find.text('已尝试恢复轮数'), findsOneWidget);
    });

    testWidgets('flags a disagreement and shows what the server reports', (
      tester,
    ) async {
      await tester.pumpWidget(
        page(
          const FlareAccessDiagnostics(
            status: FlareAccessStatus(
              loaded: true,
              accessPointId: 'ap-a',
              connectAck: FlareAccessConnectAck(
                accessPointId: 'ap-b',
                accessPointMismatch: true,
              ),
            ),
          ),
        ),
      );
      expect(find.text('服务端报告的接入点与当前线路不一致，连接不受影响'), findsOneWidget);
      expect(find.text('ap-b'), findsOneWidget);
    });

    testWidgets('offers a pin only where it can hold and the host handles it', (
      tester,
    ) async {
      String? pinned;
      await tester.pumpWidget(
        page(
          FlareAccessDiagnostics(
            status: healthy,
            accessPoints: lines,
            onPin: (id) => pinned = id,
          ),
        ),
      );
      expect(inRow('ap-sg-2', find.text('固定')), findsNothing);
      expect(inRow('ap-de-1', find.text('固定')), findsNothing);
      await tester.tap(inRow('ap-sg-1', find.text('固定')));
      expect(pinned, 'ap-sg-1');

      await tester.pumpWidget(
        page(
          const FlareAccessDiagnostics(status: healthy, accessPoints: lines),
        ),
      );
      expect(inRow('ap-sg-1', find.text('固定')), findsNothing);
    });

    testWidgets('lets go of a pinned line', (tester) async {
      var unpinned = 0;
      await tester.pumpWidget(
        page(
          FlareAccessDiagnostics(
            status: healthy,
            accessPoints: const [
              FlareAccessPoint(
                accessPointId: 'ap-sg-1',
                status: 'active',
                breaker: 'closed',
                pinned: true,
                current: true,
              ),
            ],
            onUnpin: () => unpinned += 1,
          ),
        ),
      );
      expect(inRow('ap-sg-1', find.text('已固定')), findsOneWidget);
      await tester.tap(inRow('ap-sg-1', find.text('取消固定')));
      expect(unpinned, 1);
    });

    testWidgets('draws the recovery actions only while the host handles them', (
      tester,
    ) async {
      await tester.pumpWidget(
        page(
          const FlareAccessDiagnostics(status: healthy, accessPoints: lines),
        ),
      );
      expect(find.text('立即刷新'), findsNothing);
      expect(find.text('复制诊断'), findsNothing);
      expect(find.text('导入'), findsNothing);
    });

    testWidgets('reports the actions and draws their answers', (tester) async {
      var refreshes = 0;
      var exports = 0;
      await tester.pumpWidget(
        page(
          FlareAccessDiagnostics(
            status: healthy,
            accessPoints: lines,
            refreshOutcome: 'upToDate',
            exportOutcome: 'copied',
            onRefresh: () => refreshes += 1,
            onExportDiagnostics: () => exports += 1,
          ),
        ),
      );
      await tester.ensureVisible(find.text('立即刷新'));
      await tester.tap(find.text('立即刷新'));
      await tester.tap(find.text('复制诊断'));
      expect(refreshes, 1);
      expect(exports, 1);
      expect(find.text('线路已是最新'), findsOneWidget);
      expect(find.text('诊断信息已复制'), findsOneWidget);
    });

    testWidgets('brings the answer to a link into view', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      Widget build({String? outcome, String? code}) => page(
        FlareAccessDiagnostics(
          status: healthy,
          accessPoints: lines,
          importOutcome: outcome,
          importCode: code,
          onImportRecovery: (_) {},
        ),
        controller: scroll,
      );
      await tester.pumpWidget(build());
      expect(scroll.offset, 0);

      await tester.pumpWidget(build(outcome: 'rejected', code: 'badSignature'));
      await tester.pumpAndSettle();

      expect(scroll.offset, greaterThan(0));
      final answer = tester.getRect(find.byType(FlareStatusBanner).last);
      expect(answer.bottom, lessThanOrEqualTo(500));
      expect(answer.top, greaterThanOrEqualTo(0));
    });

    testWidgets('keeps the answer in view when the lines load above it', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 500));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Widget build(List<FlareAccessPoint> points) => page(
        FlareAccessDiagnostics(
          status: healthy,
          accessPoints: points,
          importOutcome: 'rejected',
          importCode: 'badSignature',
          onImportRecovery: (_) {},
        ),
      );
      await tester.pumpWidget(build(const []));
      await tester.pumpAndSettle();

      await tester.pumpWidget(build(lines));
      await tester.pumpAndSettle();

      final answer = tester.getRect(find.byType(FlareStatusBanner).last);
      expect(answer.bottom, lessThanOrEqualTo(500));
    });

    testWidgets('imports the trimmed link and clears it once adopted', (
      tester,
    ) async {
      final links = <String>[];
      Widget build({String? outcome, String? code}) => page(
        FlareAccessDiagnostics(
          status: healthy,
          accessPoints: lines,
          importOutcome: outcome,
          importCode: code,
          onImportRecovery: links.add,
        ),
      );
      await tester.pumpWidget(build());
      await tester.ensureVisible(find.text('导入'));
      await tester.tap(find.text('导入'));
      expect(links, isEmpty);

      await tester.enterText(
        find.byType(EditableText),
        '  flare-recover://v1?p=a&k=b&s=c \n',
      );
      await tester.pump();
      await tester.tap(find.text('导入'));
      expect(links, ['flare-recover://v1?p=a&k=b&s=c']);

      await tester.pumpWidget(build(outcome: 'rejected', code: 'rollback'));
      expect(find.text('这条链接比本机线路旧，不需要导入'), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isNotEmpty,
      );

      await tester.pumpWidget(build(outcome: 'adopted'));
      await tester.pump();
      expect(find.text('恢复链接已导入，正在切换线路'), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isEmpty,
      );
    });
  });
}
