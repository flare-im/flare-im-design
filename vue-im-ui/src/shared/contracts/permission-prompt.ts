/**
 * PermissionPrompt contract — pure logic shared by all four platforms.
 * The component never requests permissions or inspects the platform; the host
 * supplies `kind` + `state` and owns `request` / `openSettings` / `dismiss`.
 */
import type { FlareIconName } from '../icons';

export type PermissionKind = 'microphone' | 'camera' | 'notifications' | 'storage' | 'photos' | 'contacts' | 'location';
export type PermissionState = 'undetermined' | 'denied' | 'restricted' | 'unavailable';

export const permissionKinds: readonly PermissionKind[] = ['microphone', 'camera', 'notifications', 'storage', 'photos', 'contacts', 'location'];
export const permissionStates: readonly PermissionState[] = ['undetermined', 'denied', 'restricted', 'unavailable'];

/** Kit icon per kind; the same semantic names resolve on iOS / Flutter / Compose. */
export const permissionIcon: Record<PermissionKind, FlareIconName> = {
  microphone: 'mic', camera: 'camera', notifications: 'notification', storage: 'folder',
  photos: 'image', contacts: 'people', location: 'location',
};
/** State glyph so status never relies on colour alone. */
export const permissionStateIcon: Record<PermissionState, FlareIconName> = {
  undetermined: 'info', denied: 'block', restricted: 'lock', unavailable: 'warning',
};

export interface PermissionActionOptions { hasRequest: boolean; hasOpenSettings: boolean; hasDismiss: boolean; busy?: boolean }
export interface PermissionActions {
  /** Visible only while undetermined and the host supplied a handler. */
  request: boolean;
  /** Visible only while denied and the host supplied a handler. */
  openSettings: boolean;
  /** Visible whenever the host supplied a handler (any state). */
  dismiss: boolean;
  /** false while busy: visible actions stay rendered but disabled. */
  enabled: boolean;
}

export function permissionActions(state: PermissionState, opts: PermissionActionOptions): PermissionActions {
  return {
    request: state === 'undetermined' && opts.hasRequest,
    openSettings: state === 'denied' && opts.hasOpenSettings,
    dismiss: opts.hasDismiss,
    enabled: !opts.busy,
  };
}

export interface PermissionCopy { title: string; description: string; primaryLabel: string }

const kindNoun: Record<PermissionKind, string> = {
  microphone: '麦克风', camera: '摄像头', notifications: '通知', storage: '存储空间', photos: '相册', contacts: '通讯录', location: '位置信息',
};
const kindVerb: Record<PermissionKind, string> = {
  microphone: '使用麦克风', camera: '使用摄像头', notifications: '发送通知', storage: '访问存储空间', photos: '访问相册', contacts: '访问通讯录', location: '获取位置信息',
};

/** Default copy; `featureLabel` (e.g. "发送语音消息") is embedded in the description. */
export function defaultPermissionCopy(kind: PermissionKind, state: PermissionState, featureLabel?: string): PermissionCopy {
  const feature = featureLabel?.trim() || '此功能';
  const verb = kindVerb[kind];
  const title = `需要${kindNoun[kind]}权限`;
  switch (state) {
    case 'undetermined':
      return { title, description: `${feature}需要${verb}，请允许后继续。`, primaryLabel: '允许' };
    case 'denied':
      return { title, description: `${verb}的权限已被拒绝，${feature}无法使用。请前往系统设置开启。`, primaryLabel: '前往设置' };
    case 'restricted':
      return { title, description: `${verb}的权限受设备或组织策略限制，${feature}暂不可用。`, primaryLabel: '' };
    case 'unavailable':
      return { title, description: `当前设备或运行环境不支持${verb}，${feature}暂不可用。`, primaryLabel: '' };
  }
}

export function defaultPermissionStateLabel(state: PermissionState): string {
  switch (state) {
    case 'undetermined': return '未授权';
    case 'denied': return '已拒绝';
    case 'restricted': return '受限制';
    case 'unavailable': return '不可用';
  }
}
