import 'package:flutter/material.dart';
import 'flare_scene_panels.dart';

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
  final String permissionText, placeholder;
  final String? actionText;
  final void Function(FlareCallDeviceKind, String)? onSelect;
  final VoidCallback? onPermissionAction;
  const FlareCallDevicePicker({
    super.key,
    required this.groups,
    required this.permission,
    required this.permissionText,
    this.actionText,
    this.placeholder = 'Choose device',
    this.onSelect,
    this.onPermissionAction,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FlareCapabilityBoundary(
        state: permission,
        text: permissionText,
        actionText: actionText,
        onAction: onPermissionAction,
        child: Text(permissionText),
      ),
      for (final group in groups)
        Padding(padding: const EdgeInsets.only(top: 12), child: _group(group)),
    ],
  );
  Widget _group(FlareCallDeviceGroup group) {
    final devices = group.uniqueDevices;
    final enabled =
        permission == FlareCapabilityState.available &&
        !group.busy &&
        devices.any((d) => !d.disabled) &&
        onSelect != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(group.label),
        Semantics(
          label: group.label,
          child: DropdownButton<String>(
            isExpanded: true,
            itemHeight: null,
            value: devices.any((d) => d.id == group.selectedId)
                ? group.selectedId
                : null,
            hint: Text(placeholder),
            items: [
              for (final device in devices)
                DropdownMenuItem(
                  value: device.id,
                  enabled: !device.disabled,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(device.label),
                    ),
                  ),
                ),
            ],
            onChanged: enabled
                ? (id) {
                    if (id != null &&
                        devices.any((d) => d.id == id && !d.disabled))
                      onSelect?.call(group.kind, id);
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
