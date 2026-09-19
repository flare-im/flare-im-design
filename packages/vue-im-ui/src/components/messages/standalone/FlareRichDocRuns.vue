<script setup lang="ts">
import { inject } from "vue";
import { flareRichSpoilerCover, type FlareRichRun } from "../../../utils/richDoc";
import { safeExternalUrl } from "../../../shared/contracts/url-safety";
import { hasEmojiPackAssetKey, resolveEmojiPackAssetUrlByKey } from "../../composer/ComposerEmojiStickerPopover/composerEmojiAssets";
import { formatEmojiPackBracket } from "../../../utils/emojiPackI18n";
import FrozenStickerThumb from "../../composer/FrozenStickerThumb/index.vue";
import { FLARE_RICH_DOC_SPOILERS } from "./richDocContext";

/** The runs of one paragraph or heading: marks, code, links, mentions, emoji and covered spoilers. */
defineProps<{ runs: readonly FlareRichRun[]; self: boolean }>();
const spoilers = inject(FLARE_RICH_DOC_SPOILERS, null);

const has = (run: FlareRichRun, mark: string) => run.marks?.includes(mark as never) === true;
const covered = (run: FlareRichRun) => has(run, "spoiler") && spoilers?.revealed.value !== true;
const href = (run: FlareRichRun) => (run.link ? safeExternalUrl(run.link) : null);
const packEmoji = (run: FlareRichRun) => (run.emoji && hasEmojiPackAssetKey(run.emoji) ? run.emoji : null);
const markClasses = (run: FlareRichRun) => ({
  "is-bold": has(run, "bold"),
  "is-italic": has(run, "italic"),
  "is-underline": has(run, "underline"),
  "is-strike": has(run, "strike"),
});
</script>

<template>
  <template v-for="(run, index) in runs" :key="index">
    <span
      v-if="covered(run)"
      class="fm-rich__spoiler"
      role="button"
      tabindex="0"
      data-flare-spoiler
      :aria-label="spoilers?.label.value"
    >{{ flareRichSpoilerCover(run.text) }}</span>
    <component
      :is="href(run) ? 'a' : 'span'"
      v-else
      class="fm-rich__run"
      :class="[markClasses(run), { 'is-link': href(run), 'is-mention': run.mention !== undefined, 'is-self': self }]"
      :href="href(run) ?? undefined"
      :target="href(run) ? '_blank' : undefined"
      :rel="href(run) ? 'noopener noreferrer' : undefined"
    >
      <code v-if="run.code" class="fm-rich__code">{{ run.text }}</code>
      <FrozenStickerThumb
        v-else-if="packEmoji(run)"
        class="fm-rich__emoji"
        :load-src="() => resolveEmojiPackAssetUrlByKey(packEmoji(run)!).then((url) => url ?? '')"
        :alt="formatEmojiPackBracket(packEmoji(run)!)"
        :em-size="1.3"
        object-fit="contain"
      />
      <template v-else>{{ run.text }}</template>
    </component>
  </template>
</template>

<style scoped>
.fm-rich__run.is-bold { font-weight: 700; }
.fm-rich__run.is-italic { font-style: italic; }
.fm-rich__run.is-underline { text-decoration: underline; }
.fm-rich__run.is-strike { text-decoration: line-through; }
.fm-rich__run.is-underline.is-strike { text-decoration: underline line-through; }
.fm-rich__run.is-link {
  color: inherit;
  text-decoration: underline;
  text-underline-offset: 2px;
}
/* A mention reads as a name, as it does in a text body: accent colour and weight when incoming. */
.fm-rich__run.is-mention { color: var(--flare-color-primary-text); font-weight: 500; }
.fm-rich__run.is-mention.is-self { color: inherit; font-weight: 600; }
.fm-rich__code {
  padding: 0 var(--flare-size-spacing-2xs);
  border-radius: var(--flare-size-radius-xs);
  background: color-mix(in srgb, currentColor 10%, transparent);
  font-family: var(--flare-component-font-family-mono);
  font-size: 0.92em;
}
.fm-rich__emoji {
  display: inline-block;
  vertical-align: middle;
}
/* Covered: a ground in the text colour over blank space as wide as the words, which are not drawn at all. */
.fm-rich__spoiler {
  border-radius: var(--flare-size-radius-xs);
  background: currentColor;
  cursor: pointer;
  user-select: none;
}
.fm-rich__spoiler:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
</style>
