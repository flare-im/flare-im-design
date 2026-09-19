import { computed, inject, provide, reactive, ref, type ComputedRef, type InjectionKey, type Ref } from "vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import { flareImageGalleryItems, flareImageGalleryStart, type FlareImageGalleryItem } from "../../utils/imageGallery";

/**
 * What a picture body drawn in the timeline knows about its picture: the address it resolved (empty while it
 * resolves) and how the picture is saved (null when the host offers no download for it).
 */
export interface TimelineImageEntry {
  fullUrl: string;
  alt: string;
  download: (() => void) | null;
  downloading: boolean;
}

/**
 * A timeline's image gallery: a picture tapped in a message list opens a full-screen preview that pages through
 * every picture of the conversation (`spec/image-gallery-vectors.json`), as they were when it opened. The picture
 * bodies tell the gallery what they resolved and how their picture is saved, so the preview neither asks the host's
 * resolver again for a picture already drawn nor offers a download its body would not. A body outside a list opens
 * its own single-picture preview.
 */
export interface TimelineImageGallery {
  /** The pictures the open gallery pages through; empty while it is closed. */
  readonly pictures: Readonly<Ref<readonly FlareImageGalleryItem[]>>;
  /** The position of the picture on screen, or null while the gallery is closed. */
  readonly position: Readonly<Ref<number | null>>;
  /** Opens the gallery at picture `index` of message `messageId`; false when that picture is not in it. */
  open(messageId: string, index: number): boolean;
  /** Shows the picture `step` places away, when there is one. */
  page(step: 1 | -1): void;
  close(): void;
  /** What a body drew for picture `index` of message `messageId`; undefined forgets it. */
  report(messageId: string, index: number, entry: TimelineImageEntry | undefined): void;
  /** What the body of `item` reported, if it is drawn. */
  entry(item: FlareImageGalleryItem): TimelineImageEntry | undefined;
}

const timelineImageGalleryKey: InjectionKey<TimelineImageGallery> = Symbol("flare-timeline-image-gallery");

/** The gallery of the list whose messages `messages` returns, given to the picture bodies below it. */
export function provideTimelineImageGallery(messages: () => readonly MessageLike[]): TimelineImageGallery {
  // Built from the messages only when a picture opens, and again only after they change.
  const items: ComputedRef<FlareImageGalleryItem[]> = computed(() => flareImageGalleryItems(messages()));
  const pictures = ref<readonly FlareImageGalleryItem[]>([]);
  const position = ref<number | null>(null);
  const entries = reactive(new Map<string, TimelineImageEntry>());
  const gallery: TimelineImageGallery = {
    pictures,
    position,
    open(messageId, index) {
      const start = flareImageGalleryStart(items.value, messageId, index);
      if (start == null) return false;
      pictures.value = items.value;
      position.value = start;
      return true;
    },
    page(step) {
      const at = position.value;
      if (at == null) return;
      const next = at + step;
      if (next >= 0 && next < pictures.value.length) position.value = next;
    },
    close() {
      position.value = null;
      pictures.value = [];
    },
    report(messageId, index, entry) {
      const id = `${messageId}#${index}`;
      if (entry) entries.set(id, entry);
      else entries.delete(id);
    },
    entry(item) {
      return entries.get(`${item.messageId}#${item.index}`);
    },
  };
  provide(timelineImageGalleryKey, gallery);
  return gallery;
}

/** The gallery of the message list a body is drawn in; null outside one. */
export function injectTimelineImageGallery(): TimelineImageGallery | null {
  return inject(timelineImageGalleryKey, null);
}
