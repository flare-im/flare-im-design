import { inject, provide, shallowRef, type InjectionKey, type Ref } from "vue";
import type { FlareTone } from "../shared/contracts/tone";
import { flareErrorText } from "../shared/errors";

/** A destructive or irreversible step the user must confirm. */
export interface FlareConfirmOptions {
  title: string;
  description: string;
  /** What the step applies to, shown on its own line (a conversation, a contact). */
  target?: string;
  confirmText?: string;
  cancelText?: string;
  /**
   * Runs after the user confirms while the dialog shows busy. A failure keeps the
   * dialog open with the error, so the user can try again or cancel.
   */
  action?: () => unknown | Promise<unknown>;
}

/** Resolves true once confirmed (and `action`, if any, succeeded); false when cancelled. */
export type FlareConfirm = (options: FlareConfirmOptions) => Promise<boolean>;

export interface FlareToastOptions {
  message: string;
  tone?: FlareTone;
  actionLabel?: string;
  onAction?: () => void;
  /** Milliseconds on screen; 0 keeps it until its action runs. Defaults to 4000, 6000 for danger. */
  duration?: number;
}

/**
 * Shows a toast and returns a function that removes it early. A caught `Error` is a toast by itself:
 * it reads as danger and its text comes from `flareErrorText`, so a host never writes that conversion
 * at each catch (FR-067). Pass `{ message, ... }` to say anything else about it.
 */
export type FlareShowToast = (options: FlareToastOptions | string | Error) => () => void;

export interface FlareConfirmRequest {
  options: FlareConfirmOptions;
  busy: boolean;
  error: string;
}

export interface FlareToastEntry {
  id: number;
  message: string;
  tone: FlareTone;
  actionLabel?: string;
}

/** Presenter state rendered by FlareUiProvider; hosts use `useFlareConfirm` / `useFlareToast`. */
export interface FlareFeedback {
  confirmRequest: Readonly<Ref<FlareConfirmRequest | null>>;
  toasts: Readonly<Ref<readonly FlareToastEntry[]>>;
  confirm: FlareConfirm;
  toast: FlareShowToast;
  accept(): Promise<void>;
  cancel(): void;
  runToastAction(id: number): void;
  dismissToast(id: number): void;
  dispose(): void;
}

/** Toasts on screen at once; a new one pushes out the oldest. */
export const FLARE_TOAST_LIMIT = 3;

export function createFlareFeedback(): FlareFeedback {
  const confirmRequest = shallowRef<FlareConfirmRequest | null>(null);
  const toasts = shallowRef<readonly FlareToastEntry[]>([]);
  let settle: ((confirmed: boolean) => void) | null = null;
  const actions = new Map<number, () => void>();
  const timers = new Map<number, ReturnType<typeof setTimeout>>();
  let nextId = 0;

  function close(confirmed: boolean): void {
    const done = settle;
    settle = null;
    confirmRequest.value = null;
    done?.(confirmed);
  }

  const confirm: FlareConfirm = (options) => {
    // One dialog at a time: a newer request replaces an idle one, which counts as cancelled.
    if (confirmRequest.value?.busy) return Promise.resolve(false);
    if (confirmRequest.value) close(false);
    return new Promise<boolean>((resolve) => {
      settle = resolve;
      confirmRequest.value = { options, busy: false, error: "" };
    });
  };

  async function accept(): Promise<void> {
    const request = confirmRequest.value;
    if (!request || request.busy) return;
    if (!request.options.action) {
      close(true);
      return;
    }
    confirmRequest.value = { ...request, busy: true, error: "" };
    try {
      await request.options.action();
      close(true);
    } catch (error) {
      confirmRequest.value = { ...request, busy: false, error: flareErrorText(error) };
    }
  }

  function cancel(): void {
    if (!confirmRequest.value || confirmRequest.value.busy) return;
    close(false);
  }

  function dismissToast(id: number): void {
    clearTimeout(timers.get(id));
    timers.delete(id);
    actions.delete(id);
    toasts.value = toasts.value.filter((entry) => entry.id !== id);
  }

  const toast: FlareShowToast = (input) => {
    const options: FlareToastOptions = typeof input === "string"
      ? { message: input }
      : input instanceof Error
        ? { message: flareErrorText(input), tone: "danger" }
        : input;
    const id = ++nextId;
    const tone = options.tone ?? "info";
    const entries = [...toasts.value, { id, message: options.message, tone, actionLabel: options.actionLabel }];
    while (entries.length > FLARE_TOAST_LIMIT) {
      const oldest = entries.shift();
      if (oldest) {
        clearTimeout(timers.get(oldest.id));
        timers.delete(oldest.id);
        actions.delete(oldest.id);
      }
    }
    toasts.value = entries;
    if (options.onAction) actions.set(id, options.onAction);
    const duration = options.duration ?? (tone === "danger" ? 6000 : 4000);
    if (duration > 0) timers.set(id, setTimeout(() => dismissToast(id), duration));
    return () => dismissToast(id);
  };

  function runToastAction(id: number): void {
    const action = actions.get(id);
    dismissToast(id);
    action?.();
  }

  function dispose(): void {
    for (const timer of timers.values()) clearTimeout(timer);
    timers.clear();
    actions.clear();
    toasts.value = [];
    if (confirmRequest.value) close(false);
  }

  return { confirmRequest, toasts, confirm, toast, accept, cancel, runToastAction, dismissToast, dispose };
}

const FEEDBACK_KEY: InjectionKey<FlareFeedback> = Symbol("flare-feedback");

/** Installed by FlareUiProvider, which renders the dialog and the toast stack. */
export function provideFlareFeedback(): FlareFeedback {
  const feedback = createFlareFeedback();
  provide(FEEDBACK_KEY, feedback);
  return feedback;
}

function injectFeedback(caller: string): FlareFeedback {
  const feedback = inject(FEEDBACK_KEY, null);
  if (!feedback) throw new Error(`${caller}() needs a FlareUiProvider ancestor: the provider renders confirmations and toasts.`);
  return feedback;
}

/** Ask before a destructive step: `if (await confirm({ title, description, action })) …`. */
export function useFlareConfirm(): FlareConfirm {
  return injectFeedback("useFlareConfirm").confirm;
}

/** Transient feedback with a bounded queue and auto-dismiss. */
export function useFlareToast(): FlareShowToast {
  return injectFeedback("useFlareToast").toast;
}
