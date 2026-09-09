/** Presentation states supplied by the SDK adapter; the UI never starts a transfer. */
export type TransferState = 'queued' | 'transferring' | 'paused' | 'failed' | 'completed' | 'cancelled';
export type TransferAction = 'pause' | 'resume' | 'cancel' | 'retry' | 'open';
export const transferActions: Record<TransferState, readonly TransferAction[]> = {
  queued: ['cancel'], transferring: ['pause', 'cancel'], paused: ['resume', 'cancel'],
  failed: ['retry'], completed: ['open'], cancelled: ['retry'],
};
export function transferProgress(state: TransferState, progress?: number | null): number | null {
  if (state === 'completed') return 1;
  return progress != null && Number.isFinite(progress) ? Math.max(0, Math.min(1, progress)) : null;
}

/** Each task is scoped to the host session; IDs must be unique and stable. */
export interface TransferQueueItem {
  id: string;
  name: string;
  state: TransferState;
  statusText: string;
  progress?: number | null;
  actionLabels?: Partial<Record<TransferAction, string>>;
  busy?: boolean;
}
/** Retry failed tasks only: cancelled tasks require an explicit individual retry. */
export function retryableTransferIds(items: readonly TransferQueueItem[]): string[] {
  return items.filter(item => item.state === 'failed' && !item.busy && !!item.actionLabels?.retry?.trim()).map(item => item.id);
}
