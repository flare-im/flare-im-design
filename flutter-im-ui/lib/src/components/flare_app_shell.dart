import 'package:flutter/material.dart';

import '../models/directory_data.dart';

/// Adaptive application shell — bottom navigation on phones, a side rail on
/// tablet/desktop, wrapping the content [child]. Spec: Layout/AppShell
/// (`FlareAppShell`). Responsive via [LayoutBuilder] (rail at > 600 width).
class FlareAppShell extends StatelessWidget {
  const FlareAppShell({
    super.key,
    required this.items,
    required this.activeKey,
    required this.child,
    this.onNavigate,
  });

  final List<FlareNavItem> items;
  final String activeKey;
  final Widget child;
  final ValueChanged<String>? onNavigate;

  int get _index {
    final i = items.indexWhere((e) => e.key == activeKey);
    return i < 0 ? 0 : i;
  }

  Widget _icon(FlareNavItem it) => it.badge > 0
      ? Badge(label: Text(it.badge > 99 ? '99+' : '${it.badge}'), child: Icon(it.icon))
      : Icon(it.icon);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth > 600) {
          return Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => onNavigate?.call(items[i].key),
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final it in items)
                    NavigationRailDestination(icon: _icon(it), label: Text(it.label)),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          );
        }
        return Column(
          children: [
            Expanded(child: child),
            NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => onNavigate?.call(items[i].key),
              destinations: [
                for (final it in items)
                  NavigationDestination(icon: _icon(it), label: it.label),
              ],
            ),
          ],
        );
      },
    );
  }
}
