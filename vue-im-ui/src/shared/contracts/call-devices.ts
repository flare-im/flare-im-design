export type CallDeviceKind = 'microphone' | 'speaker' | 'camera';
export interface CallDevice { id: string; label: string; disabled?: boolean }
export interface CallDeviceGroup { kind: CallDeviceKind; label: string; selectedId?: string; devices: CallDevice[]; busy?: boolean }
export function selectableCallDevices(group: CallDeviceGroup): CallDevice[] {
  const ids = new Set<string>();
  return group.devices.filter(device => {
    if (!device.id || ids.has(device.id)) return false;
    ids.add(device.id);return true;
  });
}
