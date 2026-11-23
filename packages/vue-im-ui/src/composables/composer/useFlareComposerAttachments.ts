import { computed, onScopeDispose, ref, shallowRef } from "vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

type AttachmentKind = "image" | "video" | "file";
type Attachment = { id: string; file: File; kind: AttachmentKind; previewUrl?: string };

function attachmentKind(file: File): AttachmentKind {
  if (file.type.startsWith("image/")) return "image";
  if (file.type.startsWith("video/")) return "video";
  return "file";
}

/** Bind a composer's file picks to FlareComposerMediaPreview. The host owns message creation and upload. */
export function useFlareComposerAttachments(options: {
  maxImages: number;
  /** True once the timeline owns the attachment, including when its row is available to retry. */
  send: (request: { files: readonly File[]; kind: AttachmentKind | "imageGroup"; description: string }) => Promise<boolean>;
}) {
  const { t } = useFlareI18n();
  const attachments = shallowRef<Attachment[]>([]);
  const open = ref(false);
  const sending = ref(false);
  const failed = ref(false);
  const selectionNotice = ref<"images" | "file" | null>(null);
  const description = ref("");
  const selectionKey = ref(0);
  let generation = 0;

  const kind = computed<AttachmentKind | "imageGroup">(() =>
    attachments.value.length > 1 ? "imageGroup" : attachments.value[0]?.kind ?? "file");
  const previewProps = computed(() => ({
    key: selectionKey.value,
    show: open.value,
    kind: kind.value,
    items: attachments.value.map(({ id, file, kind, previewUrl }) => ({
      id, kind, previewUrl, name: file.name, mimeType: file.type, size: file.size,
    })),
    loading: sending.value,
    notice: selectionNotice.value === "images" ? t("composer.attachmentLimit", { count: options.maxImages })
      : selectionNotice.value === "file" ? t("composer.attachmentSingleFile") : "",
    error: failed.value ? t("composer.attachmentSendFailed") : "",
    initialDescription: description.value,
    showDescription: kind.value !== "file",
  }));

  function reset(): void {
    generation++;
    for (const item of attachments.value) if (item.previewUrl) URL.revokeObjectURL(item.previewUrl);
    attachments.value = [];
    open.value = false;
    sending.value = false;
    failed.value = false;
    selectionNotice.value = null;
    description.value = "";
  }

  function select(files: readonly File[]): void {
    if (!files.length) return;
    reset();
    selectionKey.value = generation;
    const allImages = files.every((file) => attachmentKind(file) === "image");
    const selected = files.slice(0, allImages ? options.maxImages : 1);
    if (selected.length < files.length) selectionNotice.value = allImages ? "images" : "file";
    attachments.value = selected.map((file, index) => {
      const kind = attachmentKind(file);
      return { id: `attachment-${generation}-${index}`, file, kind,
        previewUrl: kind === "file" ? undefined : URL.createObjectURL(file) };
    });
    open.value = true;
  }

  function remove(id: string): void {
    if (sending.value) return;
    const item = attachments.value.find((item) => item.id === id);
    if (!item) return;
    if (item.previewUrl) URL.revokeObjectURL(item.previewUrl);
    attachments.value = attachments.value.filter((entry) => entry.id !== id);
    if (!attachments.value.length) reset();
  }

  async function submit(text: string): Promise<void> {
    if (!open.value || sending.value || !attachments.value.length) return;
    const ticket = generation;
    const request = { files: attachments.value.map((item) => item.file), kind: kind.value, description: text };
    description.value = text;
    sending.value = true;
    failed.value = false;
    // Upload progress can appear in the timeline as soon as the host has created the message.
    open.value = false;
    let accepted = false;
    try {
      accepted = await options.send(request);
    } catch {
      // Keep the files and caption available when the host could not prepare the message.
    }
    if (ticket !== generation) return;
    if (accepted) reset();
    else {
      sending.value = false;
      failed.value = true;
      open.value = true;
    }
  }

  onScopeDispose(reset);
  return { select, reset, previewProps, previewEvents: { cancel: reset, remove, submit } };
}
