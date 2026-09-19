import 'package:flutter/widgets.dart';

import '../models/workspace_layout.dart';

/// Hands [onLayoutChange] the presentation a layout settled on, after the frame
/// (a host callback during layout would rebuild mid-build). Reports once on the
/// first resolution, then only when the presentation actually changes.
///
/// Internal: shared by the application frames and `FlareResponsiveLayout`, so the
/// two layout families report panes the same way.
class FlareWorkspacePresentationReport extends StatefulWidget {
  const FlareWorkspacePresentationReport({
    super.key,
    required this.presentation,
    required this.onLayoutChange,
    required this.child,
  });

  final FlareWorkspacePresentation presentation;
  final ValueChanged<FlareWorkspacePresentation>? onLayoutChange;
  final Widget child;

  @override
  State<FlareWorkspacePresentationReport> createState() =>
      _FlareWorkspacePresentationReportState();
}

class _FlareWorkspacePresentationReportState
    extends State<FlareWorkspacePresentationReport> {
  FlareWorkspacePresentation? _reported;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(FlareWorkspacePresentationReport oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  void _schedule() {
    final report = widget.onLayoutChange;
    if (report == null || widget.presentation == _reported) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final presentation = widget.presentation;
      if (presentation == _reported) return;
      _reported = presentation;
      widget.onLayoutChange?.call(presentation);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
