import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// spec/count-badge-vectors.json, the table the four kits run: what a
/// navigation item's count badge and a filter tab's badge read
/// ([flareCountBadgeText]), and when a filter tab draws one
/// ([flareCountBadgeDrawn]).
final Map<String, dynamic> _vectors =
    jsonDecode(File('../../spec/count-badge-vectors.json').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> get _cases =>
    (_vectors['cases'] as List).cast<Map<String, dynamic>>();

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  test('the shared table keeps its cases', () {
    expect(_cases.length, greaterThanOrEqualTo(14));
    expect(_vectors['cap'], 99);
    expect(_vectors['overflow'], '99+');
  });

  group('text and drawn', () {
    for (final row in _cases) {
      test('${row['id']}', () {
        final count = row['count'] as int?;
        final more = row['more'] as bool? ?? false;
        expect(flareCountBadgeText(count, more: more), row['text']);
        expect(flareCountBadgeDrawn(count, more: more), row['drawn']);
        if (!row.containsKey('more')) {
          // A host that passes no `more` gets the default.
          expect(flareCountBadgeText(count), row['text']);
          expect(flareCountBadgeDrawn(count), row['drawn']);
        }
      });
    }
  });

  group('a filter tab draws the shared badge', () {
    for (final row in _cases) {
      testWidgets('${row['id']}', (tester) async {
        await tester.pumpWidget(
          _host(
            FlareFilterTabs(
              options: [
                FlareFilterTabOption(
                  value: 'requests',
                  label: '申请',
                  badge: row['count'] as int?,
                  badgeMore: row['more'] as bool? ?? false,
                ),
              ],
              selected: 'requests',
              onSelect: (_) {},
            ),
          ),
        );
        expect(
          find.text(row['text'] as String),
          row['drawn'] as bool ? findsOneWidget : findsNothing,
        );
      });
    }
  });

  group("a navigation item's count badge reads the shared text", () {
    for (final presentation in [
      FlareNavigationPresentation.bottom,
      FlareNavigationPresentation.rail,
    ]) {
      for (final row in _cases) {
        testWidgets('${presentation.name} ${row['id']}', (tester) async {
          await tester.pumpWidget(
            _host(
              SizedBox(
                width: 400,
                height: 600,
                child: FlareAdaptiveNavigation(
                  groups: [
                    FlareNavigationGroup(
                      id: 'primary',
                      items: [
                        FlareNavigationItem(
                          id: 'contacts',
                          label: '通讯录',
                          icon: 'people',
                          badge: FlareNavigationBadge(
                            kind: FlareNavigationBadgeKind.count,
                            count: row['count'] as int?,
                            more: row['more'] as bool? ?? false,
                          ),
                        ),
                        const FlareNavigationItem(
                          id: 'me',
                          label: '我',
                          icon: 'person',
                        ),
                      ],
                    ),
                  ],
                  activeId: 'contacts',
                  responsiveMode: FlareApplicationResponsiveMode.mobile,
                  presentation: presentation,
                ),
              ),
            ),
          );
          expect(find.text(row['text'] as String), findsOneWidget);
        });
      }
    }
  });

  test('a navigation badge and a filter tab take more without a host change', () {
    // The new fields have defaults: a host that writes neither still builds.
    expect(
      const FlareNavigationBadge(kind: FlareNavigationBadgeKind.count).more,
      isFalse,
    );
    expect(
      const FlareFilterTabOption(value: 'a', label: 'A', badge: 3).badgeMore,
      isFalse,
    );
  });
}
