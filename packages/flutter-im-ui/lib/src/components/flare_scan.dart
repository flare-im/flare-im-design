import 'package:flutter/material.dart';
import '../models/scan_hit_gate.dart';
import '../models/scan_view_rules.dart';
import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import '../tokens/flare_strings.dart';
import 'flare_avatar.dart';
import 'flare_button.dart';
import 'flare_input.dart';
import 'flare_permission_prompt.dart';
import 'flare_bottom_sheet.dart';

class FlareScanMarker {
  const FlareScanMarker({required this.id, required this.corners, this.label});
  final String id;
  final List<FlareScanPoint> corners;
  final String? label;
}
class FlareScanCapabilities {
  const FlareScanCapabilities({this.live = true, this.album = true, this.paste = true, this.myCode = true, this.torch = false});
  final bool live, album, paste, myCode, torch;
}
class FlareScanHeader {
  const FlareScanHeader({required this.title, this.subtitle, this.avatarUrl});
  final String title;
  final String? subtitle, avatarUrl;
}
class FlareScanFact {
  const FlareScanFact(this.label, this.value);
  final String label, value;
}
class FlareScanInput {
  const FlareScanInput({required this.id, this.kind = 'text', required this.label, required this.maxLen});
  final String id, kind, label;
  final int maxLen;
}
class FlareScanAction {
  const FlareScanAction({required this.id, required this.label, this.primary = false, this.inputs = const []});
  final String id, label;
  final bool primary;
  final List<FlareScanInput> inputs;
}
/// Capture and permission effects stay in the host. The preview is already transformed to this box.
class FlareScanViewfinder extends StatelessWidget {
  const FlareScanViewfinder({super.key, required this.state, required this.capabilities, required this.preview,
    this.markers = const [], this.hint, this.torch = false, required this.onClose, this.onToggleTorch,
    this.onPickImage, this.onPaste, this.onOpenMyCode, this.onSelectMarker, this.onRetry, this.onRequestPermission, this.onOpenSettings});
  final String state;
  final FlareScanCapabilities capabilities;
  final Widget preview;
  final List<FlareScanMarker> markers;
  final String? hint;
  final bool torch;
  final VoidCallback onClose;
  final VoidCallback? onToggleTorch, onPickImage, onPaste, onOpenMyCode, onRetry, onRequestPermission, onOpenSettings;
  final ValueChanged<String>? onSelectMarker;
  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final s = FlareStrings.of(context);
    final status = hint ?? switch (state) {
      'preparing' => s.scanPreparing, 'live' => s.scanLive, 'lowLight' => s.scanLowLight,
      'locked' => s.scanLocked, 'choosing' => s.scanChoosing, 'paused' => s.scanPaused,
      'imageDecoding' => s.scanImageDecoding, 'imageError' => s.scanImageError, 'noCodeInImage' => s.scanNoCodeInImage,
      'noCamera' => s.scanNoCamera, 'insecureContext' => s.scanInsecureContext,
      'cameraBusy' => s.scanCameraBusy, _ => s.scanCameraError,
    };
    final permission = switch (state) { 'permissionUndetermined' => FlarePermissionState.undetermined,
      'denied' => FlarePermissionState.denied, 'restricted' => FlarePermissionState.restricted, _ => null };
    return ColoredBox(color: colors.bgPrimary, child: Column(children: [
      SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.all(FlareSizes.spacingMd), child: Row(children: [
        FlareButton(label: s.close, variant: FlareButtonVariant.quiet, onPressed: onClose),
        Expanded(child: Text(s.scanTitle, textAlign: TextAlign.center, style: TextStyle(color: colors.textPrimary))),
        if (capabilities.torch) FlareButton(label: torch ? s.scanTorchOff : s.scanTorchOn, variant: FlareButtonVariant.quiet, onPressed: onToggleTorch),
      ]))),
      Expanded(child: LayoutBuilder(builder: (context, size) => Stack(fit: StackFit.expand, children: [
        preview,
        for (var index = 0; index < markers.length; index++) _marker(markers[index], index, size, s, colors),
        if (permission != null) Center(child: Padding(padding: const EdgeInsets.all(FlareSizes.spacingLg), child: FlarePermissionPrompt(kind: FlarePermissionKind.camera, state: permission, onRequest: onRequestPermission, onOpenSettings: onOpenSettings))),
        Align(alignment: Alignment.bottomCenter, child: Semantics(liveRegion: true, child: Container(color: colors.bgPrimary, padding: const EdgeInsets.all(FlareSizes.spacingMd), child: Text(status, textAlign: TextAlign.center, style: TextStyle(color: colors.textPrimary))))),
      ]))),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(FlareSizes.spacingMd), child: Wrap(spacing: FlareSizes.spacingSm, runSpacing: FlareSizes.spacingSm, alignment: WrapAlignment.center, children: [
        if (capabilities.album) FlareButton(label: s.scanAlbum, variant: FlareButtonVariant.secondary, onPressed: onPickImage),
        if (capabilities.paste) FlareButton(label: s.scanPaste, variant: FlareButtonVariant.secondary, onPressed: onPaste),
        if (capabilities.myCode) FlareButton(label: s.myQrCode, variant: FlareButtonVariant.secondary, onPressed: onOpenMyCode),
        if (['paused', 'cameraError', 'imageError', 'noCodeInImage', 'noCamera'].contains(state)) FlareButton(label: s.retry, onPressed: onRetry),
      ]))),
    ]));
  }
  Widget _marker(FlareScanMarker marker, int index, BoxConstraints size, FlareStrings s, FlareColors colors) {
    final bounds = flareScanMarkerBounds(marker.corners);
    return Positioned(left: size.maxWidth * bounds.left, top: size.maxHeight * bounds.top, width: (size.maxWidth * bounds.width).clamp(48.0, double.infinity).toDouble(), height: (size.maxHeight * bounds.height).clamp(48.0, double.infinity).toDouble(), child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: colors.primary, width: 2)), child: FlareButton(label: marker.label ?? '${s.scanChooseCode} ${index + 1}', disabled: state != 'choosing', onPressed: () => onSelectMarker?.call(marker.id))));
  }
}

/// Adaptive sheet content. Use [show] to apply the kit's focus, safe-area and modal behavior.
class FlareScanResultSheet extends StatefulWidget {
  const FlareScanResultSheet({super.key, required this.phase, required this.header, this.facts = const [], this.notice,
    this.actions = const [], this.busy = false, required this.onAction, this.onRetry, this.onDismiss});
  final String phase;
  final FlareScanHeader header;
  final List<FlareScanFact> facts;
  final String? notice;
  final List<FlareScanAction> actions;
  final bool busy;
  final void Function(String id, Map<String, String> values) onAction;
  final VoidCallback? onRetry, onDismiss;
  static Future<T?> show<T>(BuildContext context, {required WidgetBuilder builder, ValueNotifier<bool>? busy}) => FlareBottomSheet.show<T>(context, titleBuilder: (context) => FlareStrings.of(context).scanResult, busy: busy, builder: builder);
  @override
  State<FlareScanResultSheet> createState() => _FlareScanResultSheetState();
}
class _FlareScanResultSheetState extends State<FlareScanResultSheet> {
  final values = <String, String>{};
  @override
  void didUpdateWidget(covariant FlareScanResultSheet oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.header.title != widget.header.title) values.clear(); }
  @override
  Widget build(BuildContext context) {
    final s = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    return SingleChildScrollView(padding: const EdgeInsets.all(FlareSizes.spacingLg), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [FlareAvatar(userId: widget.header.title, displayName: widget.header.title, avatarUrl: widget.header.avatarUrl, size: 48), const SizedBox(width: FlareSizes.spacingMd), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.header.title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)), if (widget.header.subtitle != null) Text(widget.header.subtitle!, style: TextStyle(color: colors.textSecondary))]))]),
      for (final fact in widget.facts) Padding(padding: const EdgeInsets.only(top: FlareSizes.spacingMd), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(fact.label, style: TextStyle(color: colors.textTertiary)), SelectableText(fact.value, style: TextStyle(color: colors.textPrimary))])),
      if (widget.notice?.isNotEmpty == true) Padding(padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingMd), child: Semantics(liveRegion: true, child: Text(widget.notice!, style: TextStyle(color: colors.textSecondary)))),
      if (['loading', 'slow', 'acting'].contains(widget.phase)) Semantics(liveRegion: true, child: Text(s.scanPreparing)),
      for (final action in widget.actions) ...[
        for (final input in action.inputs.where((input) => input.kind == 'text')) Padding(padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(input.label), FlareInput(key: ValueKey('${action.id}/${input.id}'), semanticLabel: input.label, maxLength: input.maxLen, disabled: widget.busy, onChanged: (text) => values['${action.id}/${input.id}'] = text)])),
        if (!action.inputs.every((input) => input.kind == 'text' && input.maxLen > 0)) Text(s.scanUpgradeRequired),
        Padding(padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm), child: FlareButton(label: action.label, block: true, loading: widget.busy, disabled: widget.phase != 'ready' || !action.inputs.every((input) => input.kind == 'text' && input.maxLen > 0), variant: action.primary ? FlareButtonVariant.primary : FlareButtonVariant.secondary, onPressed: () => widget.onAction(action.id, {for (final input in action.inputs) input.id: values['${action.id}/${input.id}'] ?? ''}))),
      ],
      if (['failed', 'offlineWaiting', 'unknown'].contains(widget.phase)) FlareButton(label: s.retry, disabled: widget.busy, onPressed: widget.onRetry),
      if (widget.onDismiss != null) FlareButton(label: s.close, variant: FlareButtonVariant.quiet, disabled: widget.busy, onPressed: widget.onDismiss),
    ]));
  }
}

class FlareScanSurfaceHints {
  const FlareScanSurfaceHints({required this.secure, required this.maxBrightness});
  final bool secure, maxBrightness;
}
