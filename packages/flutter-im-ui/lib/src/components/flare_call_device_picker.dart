import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/flare_strings.dart';
import 'call_stage.dart';
import 'flare_icon.dart';
import 'flare_scene_panels.dart';
import 'dart:math' as math;
import 'flare_overlay.dart';
import '../tokens/flare_tokens.dart';

enum FlareCallDeviceKind { microphone, speaker, camera }

class FlareCallDevice {
  final String id, label;
  final bool disabled;
  const FlareCallDevice({
    required this.id,
    required this.label,
    this.disabled = false,
  });
}

class FlareCallDeviceGroup {
  final FlareCallDeviceKind kind;
  final String label;
  final String? selectedId;
  final List<FlareCallDevice> devices;
  final bool busy;
  const FlareCallDeviceGroup({
    required this.kind,
    required this.label,
    this.selectedId,
    required this.devices,
    this.busy = false,
  });
  List<FlareCallDevice> get uniqueDevices {
    final ids = <String>{};
    return devices.where((d) => d.id.isNotEmpty && ids.add(d.id)).toList();
  }
}

/// The call's device chooser (docs/plugin-experience.md §3.6): microphone,
/// speaker and camera groups of single-choice rows on the call popover
/// colour. A busy group's rows are disabled and its title spins.
class FlareCallDevicePicker extends StatelessWidget {
  final List<FlareCallDeviceGroup> groups;
  final FlareCapabilityState permission;
  final String permissionText;

  /// Empty-selection text; null takes it from [FlareStrings].
  final String? placeholder;
  final String? actionText;
  final void Function(FlareCallDeviceKind, String)? onSelect;
  final VoidCallback? onPermissionAction;
  const FlareCallDevicePicker({
    super.key,
    required this.groups,
    required this.permission,
    required this.permissionText,
    this.actionText,
    this.placeholder,
    this.onSelect,
    this.onPermissionAction,
  });

  /// Anchored above the actual button; outside click, Escape and back dismiss.
  static Future<void> showAnchored(
    BuildContext anchorContext, {
    required WidgetBuilder builder,
  }) {
    final box = anchorContext.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final scopes = flareOverlayScopes(anchorContext);
    return showDialog<void>(
      context: anchorContext,
      barrierColor: Colors.transparent,
      builder: (context) {
        final size = MediaQuery.sizeOf(context);
        const margin = FlareSizes.spacingMd;
        final width = math.min(
          FlareSizes.componentCallDevicePanelWidth,
          size.width - margin * 2,
        );
        final left = (anchor.center.dx - width / 2).clamp(
          margin,
          math.max(margin, size.width - width - margin),
        );
        return scopes(
          FlareTheme(
            colors: callStagePalette(anchorContext),
            child: Theme(
              data: ThemeData.dark(),
              child: Stack(
                children: [
                  Positioned(
                    left: left.toDouble(),
                    bottom: size.height - anchor.top + FlareSizes.spacingSm,
                    width: width,
                    child: Material(
                      color: FlareColors.of(anchorContext).callPopover,
                      borderRadius: BorderRadius.circular(
                        FlareSizes.radiusCard,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: math.max(
                            FlareSizes.touchTarget,
                            anchor.top -
                                MediaQuery.paddingOf(context).top -
                                FlareSizes.spacingXl,
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(FlareSizes.spacingMd),
                          child: Builder(builder: builder),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (permission != FlareCapabilityState.available)
        FlareCapabilityBoundary(
          state: permission,
          text: permissionText,
          actionText: actionText,
          onAction: onPermissionAction,
          child: Text(permissionText),
        ),
      for (final (i, group) in groups.indexed)
        Padding(
          padding: EdgeInsets.only(
            top: i == 0 && permission == FlareCapabilityState.available
                ? 0
                : FlareSizes.spacingLg,
          ),
          child: _group(context, group),
        ),
    ],
  );
  Widget _group(BuildContext context, FlareCallDeviceGroup group) {
    final devices = group.uniqueDevices;
    final selectedId = group.selectedId ?? 'default';
    final colors = FlareColors.of(context);
    final labelStyle = TextStyle(
      color: colors.callOnStageSecondary,
      fontSize: FlareSizes.fontSizeSm,
    );
    final enabled =
        permission == FlareCapabilityState.available &&
        !group.busy &&
        devices.any((d) => !d.disabled) &&
        onSelect != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(child: Text(group.label, style: labelStyle)),
            if (group.busy) ...[
              const SizedBox(width: FlareSizes.spacingXs),
              SizedBox.square(
                dimension: FlareSizes.fontSizeSm,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.callOnStageSecondary,
                ),
              ),
            ],
          ],
        ),
        if (!devices.any((d) => d.id == selectedId))
          Text(
            placeholder ?? FlareStrings.of(context).callDevicePickerPlaceholder,
            style: labelStyle,
          ),
        const SizedBox(height: FlareSizes.spacingSm),
        // Up and Down stay inside the group (they stop at its first and
        // last rows); Tab still moves on to the next group.
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          onKeyEvent: (node, event) {
            final key = event.logicalKey;
            if (event is KeyUpEvent ||
                (key != LogicalKeyboardKey.arrowUp &&
                    key != LogicalKeyboardKey.arrowDown)) {
              return KeyEventResult.ignored;
            }
            final rows = node.traversalDescendants.toList();
            if (rows.isEmpty) return KeyEventResult.ignored;
            final edge = key == LogicalKeyboardKey.arrowUp
                ? rows.first
                : rows.last;
            return edge.hasPrimaryFocus
                ? KeyEventResult.handled
                : KeyEventResult.ignored;
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final device in devices)
                Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: device.id == selectedId,
                  child: ListTile(
                    dense: true,
                    minTileHeight: FlareSizes.touchTargetMin,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: FlareSizes.spacingSm,
                    ),
                    minVerticalPadding: 0,
                    title: Text(
                      device.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.callOnStage,
                        fontSize: FlareSizes.fontSizeLg,
                      ),
                    ),
                    trailing: device.id == selectedId
                        ? FlareIcon(
                            'check',
                            size: FlareSizes.iconSizeSm,
                            color: colors.callOnStage,
                          )
                        : null,
                    enabled: enabled && !device.disabled,
                    onTap: enabled && !device.disabled
                        ? () => onSelect?.call(group.kind, device.id)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
