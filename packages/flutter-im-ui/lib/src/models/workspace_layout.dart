import 'package:flutter/foundation.dart' show immutable;

import '../tokens/flare_tokens.dart';

// The layout vocabulary every layout in the kit speaks, and the one pane rule
// they all ask (FR-110): pure values and functions, so a general component can
// use them without depending on the application frames.

enum FlareApplicationResponsiveMode { mobile, tablet, desktop, wideDesktop }

FlareApplicationResponsiveMode flareApplicationResponsiveModeForWidth(
  double width, {
  double textScale = 1,
}) {
  final effective =
      width.clamp(0, double.infinity) / textScale.clamp(1, double.infinity);
  if (effective < 600) return FlareApplicationResponsiveMode.mobile;
  if (effective < FlareSizes.appShellCompactMinWidth)
    return FlareApplicationResponsiveMode.tablet;
  if (effective < FlareSizes.appShellExpandedMinWidth)
    return FlareApplicationResponsiveMode.desktop;
  return FlareApplicationResponsiveMode.wideDesktop;
}

/// How many panes a layout shows side by side; mirrors the Vue contract names.
enum FlareWorkspacePaneMode { singlePane, dualPane, triplePane }

/// How the detail region is presented; `route` means the host navigates to it.
enum FlareWorkspaceDetailPresentation { hidden, inline, overlay, route }

@immutable
class FlareWorkspacePresentation {
  const FlareWorkspacePresentation(this.paneMode, this.detail);
  final FlareWorkspacePaneMode paneMode;
  final FlareWorkspaceDetailPresentation detail;

  // A value, so a host can compare what it was told with what it had, and so
  // the layout reports a change only when there is one.
  @override
  bool operator ==(Object other) =>
      other is FlareWorkspacePresentation &&
      other.paneMode == paneMode &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(paneMode, detail);

  @override
  String toString() =>
      'FlareWorkspacePresentation(${paneMode.name}, ${detail.name})';
}

/// Width that [paneMode] needs side by side — the one pane rule of every layout in the kit
/// (FR-110, `spec/application-layout-vectors.json` `panes`). Two panes: navigation + list + a usable
/// chat ([FlareSizes.chatMinWidth] times the text scale, never less than the minimum); three: that plus
/// the detail. Navigation, list and detail are drawn at fixed widths, so only the chat grows with the
/// text. A 72 rail + 320 list + 360 chat = 752. One pane needs nothing.
double flarePaneModeMinWidth(
  FlareWorkspacePaneMode paneMode, {
  double navigationWidth = 0,
  double primaryWidth = FlareSizes.primaryPaneDefaultWidth,
  double detailWidth = FlareSizes.detailPaneDefaultWidth,
  double textScale = 1,
}) {
  if (paneMode == FlareWorkspacePaneMode.singlePane) return 0;
  final scale = textScale.isFinite
      ? textScale.clamp(1.0, double.infinity)
      : 1.0;
  final two =
      navigationWidth.clamp(0.0, double.infinity) +
      primaryWidth.clamp(0.0, double.infinity) +
      FlareSizes.chatMinWidth * scale;
  return paneMode == FlareWorkspacePaneMode.dualPane
      ? two
      : two + detailWidth.clamp(0.0, double.infinity);
}

/// The most panes that fit side by side in [width] (a third only when there is a detail to show).
FlareWorkspacePaneMode flarePaneModeForWidth(
  double width, {
  bool hasDetail = false,
  double textScale = 1,
  double navigationWidth = 0,
  double primaryWidth = FlareSizes.primaryPaneDefaultWidth,
  double detailWidth = FlareSizes.detailPaneDefaultWidth,
}) {
  double needs(FlareWorkspacePaneMode mode) => flarePaneModeMinWidth(
    mode,
    navigationWidth: navigationWidth,
    primaryWidth: primaryWidth,
    detailWidth: detailWidth,
    textScale: textScale,
  );
  if (!(width >= needs(FlareWorkspacePaneMode.dualPane))) {
    return FlareWorkspacePaneMode.singlePane;
  }
  return hasDetail && width >= needs(FlareWorkspacePaneMode.triplePane)
      ? FlareWorkspacePaneMode.triplePane
      : FlareWorkspacePaneMode.dualPane;
}
