import 'package:flutter/material.dart';
import '../tokens/flare_strings.dart';
import 'flare_scene_panels.dart';
import 'dart:math' as math;
import 'flare_overlay.dart';
import '../models/directory_data.dart';
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
        final width = math.min(300.0, size.width - 24);
        final left = (anchor.center.dx - width / 2).clamp(
          12.0,
          math.max(12.0, size.width - width - 12),
        );
        return scopes(
          FlareTheme(
            colors: FlareColors.dark,
            child: Theme(
              data: ThemeData.dark(),
              child: Stack(
                children: [
                  Positioned(
                    left: left.toDouble(),
                    bottom: size.height - anchor.top + 8,
                    width: width,
                    child: Material(
                      color: FlareColors.dark.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: math.max(
                            48,
                            anchor.top - MediaQuery.paddingOf(context).top - 20,
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
      for (final group in groups)
        Padding(
          padding: const EdgeInsets.only(top: FlareSizes.spacingLg),
          child: _group(context, group),
        ),
    ],
  );
  Widget _group(BuildContext context, FlareCallDeviceGroup group) {
    final devices = group.uniqueDevices;
    final enabled =
        permission == FlareCapabilityState.available &&
        !group.busy &&
        devices.any((d) => !d.disabled) &&
        onSelect != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          group.label,
          style: TextStyle(
            color: FlareColors.of(context).textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: FlareSizes.spacingSm),
        for (final device in devices)
          Semantics(
            selected: device.id == (group.selectedId ?? 'default'),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              minVerticalPadding: 0,
              title: Text(device.label, style: const TextStyle(fontSize: 13)),
              trailing: device.id == (group.selectedId ?? 'default')
                  ? const Icon(Icons.check, size: 18)
                  : null,
              enabled: enabled && !device.disabled,
              onTap: enabled && !device.disabled
                  ? () => onSelect?.call(group.kind, device.id)
                  : null,
            ),
          ),
      ],
    );
  }
}
