<script setup lang="ts">
import { ref, useId, watch } from "vue";
import FlareScreen from "./FlareScreen.vue";
import FlareBrandLogo from "../general/FlareBrandLogo.vue";

// Shared presentation only: authentication and the form remain owned by the host.
const props = defineProps<{
  product: string;
  title: string;
  appearance?: "split";
  subtitle?: string;
  tagline?: string;
  headline?: string;
  description?: string;
  eyebrow?: string;
  footer?: string;
  backLabel?: string;
}>();
const emit = defineEmits<{ (event: "back"): void }>();
const headingId = `flare-auth-heading-${useId()}`;
const heading = ref<HTMLHeadingElement>();

watch(() => props.title, () => {
  if (props.appearance === "split") heading.value?.focus();
}, { flush: "post" });
</script>

<template>
  <FlareScreen class="flare-auth-shell" :class="{ 'flare-auth-shell--split': appearance === 'split' }" surface="surface" :scroll="false">
    <div class="flare-auth-shell__stage">
      <div class="flare-auth-shell__frame">
        <aside class="flare-auth-shell__brand" :aria-label="product">
          <FlareBrandLogo v-if="appearance !== 'split'" :size="440" variant="mark" class="flare-auth-shell__mark" aria-hidden="true" />
          <div class="flare-auth-shell__lockup">
            <FlareBrandLogo :size="36" variant="plate" aria-hidden="true" />
            <div>
              <p class="flare-auth-shell__product">{{ product }}</p>
              <p v-if="tagline" class="flare-auth-shell__tagline">{{ tagline }}</p>
            </div>
          </div>
          <div v-if="appearance === 'split'" class="flare-auth-shell__motif" aria-hidden="true">
            <div class="flare-auth-shell__bubble flare-auth-shell__bubble--rear"><span class="flare-auth-shell__dots" /></div>
            <div class="flare-auth-shell__bubble flare-auth-shell__bubble--front">
              <FlareBrandLogo :size="88" variant="mark" />
            </div>
          </div>
          <div v-if="headline || description" class="flare-auth-shell__story">
            <p v-if="headline" class="flare-auth-shell__headline">{{ headline }}</p>
            <p v-if="description" class="flare-auth-shell__description">{{ description }}</p>
          </div>
        </aside>
        <main class="flare-auth-shell__form-region">
          <div v-if="$slots.utility" class="flare-auth-shell__utility"><slot name="utility" /></div>
          <section class="flare-auth-shell__panel" :aria-labelledby="headingId">
            <div class="flare-auth-shell__mobile-brand">
              <FlareBrandLogo :size="40" aria-hidden="true" />
              <div>
                <p class="flare-auth-shell__product">{{ product }}</p>
                <p v-if="tagline" class="flare-auth-shell__tagline">{{ tagline }}</p>
              </div>
            </div>
            <button v-if="backLabel" type="button" class="flare-auth-shell__back" :aria-label="backLabel" @click="emit('back')">
              <span aria-hidden="true">←</span><span>{{ backLabel }}</span>
            </button>
            <header class="flare-auth-shell__heading">
              <p v-if="eyebrow" class="flare-auth-shell__eyebrow">{{ eyebrow }}</p>
              <h1 :id="headingId" ref="heading" :tabindex="appearance === 'split' ? -1 : undefined" class="flare-auth-shell__title">{{ title }}</h1>
              <p v-if="subtitle" class="flare-auth-shell__subtitle">{{ subtitle }}</p>
            </header>
            <div class="flare-auth-shell__content"><slot /></div>
            <footer v-if="footer || $slots.footer" class="flare-auth-shell__footer"><slot name="footer">{{ footer }}</slot></footer>
          </section>
        </main>
      </div>
    </div>
  </FlareScreen>
</template>

<style scoped>
.flare-auth-shell {
  height: 100%;
  min-height: 0;
  --flare-auth-brand-surface: var(--flare-color-text-primary);
  --flare-auth-brand-ink: var(--flare-color-bg-primary);
}
:global([data-flare-theme="dark"] .flare-auth-shell) {
  --flare-auth-brand-surface: var(--flare-color-bg-secondary);
  --flare-auth-brand-ink: var(--flare-color-text-primary);
}
.flare-auth-shell__stage {
  display: grid;
  place-items: center;
  width: 100%;
  height: 100%;
  box-sizing: border-box;
  padding: clamp(24px, 4vw, 64px);
  overflow: auto;
  background: var(--flare-color-bg-secondary);
}
.flare-auth-shell__frame {
  display: grid;
  grid-template-columns: minmax(0, 5fr) minmax(0, 6fr);
  width: min(100%, 1120px);
  min-height: min(640px, 100%);
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-2xl);
  background: var(--flare-color-bg-primary);
}
.flare-auth-shell__brand {
  position: relative;
  isolation: isolate;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  min-width: 0;
  overflow: hidden;
  padding: clamp(32px, 4vw, 56px);
  border-start-start-radius: inherit;
  border-end-start-radius: inherit;
  background: var(--flare-auth-brand-surface);
  color: var(--flare-auth-brand-ink);
}
.flare-auth-shell__mark {
  position: absolute;
  z-index: -1;
  inset-inline-end: -96px;
  inset-block-start: 0;
  transform: rotate(-9deg);
  color: color-mix(in srgb, var(--flare-auth-brand-ink) 7%, transparent);
  pointer-events: none;
}
.flare-auth-shell__lockup, .flare-auth-shell__mobile-brand { display: flex; align-items: center; gap: var(--flare-size-spacing-md); }
.flare-auth-shell__product, .flare-auth-shell__tagline, .flare-auth-shell__headline,
.flare-auth-shell__description, .flare-auth-shell__subtitle, .flare-auth-shell__eyebrow { margin: 0; }
.flare-auth-shell__product { color: inherit; font-size: var(--flare-size-font-size-4xl); font-weight: var(--flare-size-font-weight-semibold); line-height: 1.25; }
.flare-auth-shell__tagline { margin-top: var(--flare-size-spacing-xs); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); line-height: 1.6; }
.flare-auth-shell__brand .flare-auth-shell__tagline,
.flare-auth-shell__description { color: color-mix(in srgb, var(--flare-auth-brand-ink) 74%, transparent); }
.flare-auth-shell__story { width: 100%; max-width: var(--flare-size-layout-auth-form-max-width); padding-top: calc(var(--flare-size-spacing-2xl) * 2); }
.flare-auth-shell__story::before { content: ""; display: block; width: var(--flare-size-icon-size-xl); height: 2px; margin-bottom: var(--flare-size-spacing-xl); background: var(--flare-color-primary); }
.flare-auth-shell__headline { font-size: clamp(var(--flare-size-font-size-auth-headline), 3.2vw, 48px); font-weight: var(--flare-size-font-weight-semibold); line-height: 1.16; letter-spacing: -.025em; white-space: pre-line; overflow-wrap: anywhere; }
.flare-auth-shell__description { margin-top: var(--flare-size-spacing-lg); font-size: var(--flare-size-font-size-xl); line-height: 1.65; overflow-wrap: anywhere; }
.flare-auth-shell__form-region { display: flex; flex-direction: column; align-items: center; min-width: 0; padding: clamp(32px, 5vw, 72px); }
.flare-auth-shell__panel { width: 100%; max-width: var(--flare-size-layout-auth-form-max-width); margin-block: auto; }
.flare-auth-shell__utility { display: flex; flex-shrink: 0; align-self: flex-end; padding-bottom: var(--flare-size-spacing-lg); }
.flare-auth-shell__mobile-brand { display: none; margin-bottom: var(--flare-size-spacing-2xl); }
.flare-auth-shell__back { display: inline-flex; align-items: center; min-height: var(--flare-size-layout-touch-target-min); margin: 0 0 var(--flare-size-spacing-md); padding: 0; gap: var(--flare-size-spacing-sm); border: 0; border-radius: var(--flare-size-radius-md); background: transparent; color: var(--flare-color-text-link); cursor: pointer; font: inherit; font-weight: 600; }
.flare-auth-shell__back:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 4px; }
.flare-auth-shell__heading { margin-bottom: var(--flare-size-spacing-2xl); }
.flare-auth-shell__eyebrow { margin-bottom: var(--flare-size-spacing-sm); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); font-weight: var(--flare-size-font-weight-semibold); line-height: 1.5; }
.flare-auth-shell__title { margin: 0; color: var(--flare-color-text-primary); font-size: var(--flare-size-font-size-auth-headline); font-weight: var(--flare-size-font-weight-semibold); line-height: 1.2; letter-spacing: -.02em; overflow-wrap: anywhere; }
.flare-auth-shell__subtitle { margin-top: var(--flare-size-spacing-sm); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-lg); line-height: 1.7; overflow-wrap: anywhere; }
.flare-auth-shell__content { min-width: 0; }
.flare-auth-shell__footer { margin-top: var(--flare-size-spacing-2xl); padding-top: var(--flare-size-spacing-lg); border-top: 1px solid var(--flare-color-border-secondary); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); line-height: 1.7; overflow-wrap: anywhere; }
.flare-auth-shell--split .flare-auth-shell__stage { align-items: safe center; }
.flare-auth-shell--split {
  --flare-auth-brand-surface: color-mix(in srgb, var(--flare-color-primary-active) 42%, var(--flare-color-text-primary));
}
:global([data-flare-theme="dark"] .flare-auth-shell--split) {
  --flare-auth-brand-surface: color-mix(in srgb, var(--flare-color-primary-active) 34%, var(--flare-color-bg-secondary));
}
.flare-auth-shell--split .flare-auth-shell__title:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: var(--flare-size-spacing-xs);
  border-radius: var(--flare-size-radius-md);
}
.flare-auth-shell--split .flare-auth-shell__footer { padding-top: var(--flare-size-spacing-sm); }

@media (prefers-reduced-motion: no-preference) {
  .flare-auth-shell--split .flare-auth-shell__panel { animation: flare-auth-enter var(--flare-transition-normal); }
  @keyframes flare-auth-enter {
    from { transform: translateY(var(--flare-size-spacing-xs)); }
    to { transform: translateY(0); }
  }
}

@media (min-width: 900px) {
  .flare-auth-shell--split .flare-auth-shell__stage {
    padding: var(--flare-size-spacing-2xl);
  }
  .flare-auth-shell--split .flare-auth-shell__frame {
    width: min(100%, 1160px);
    min-height: min(100%, 720px);
    border: 1px solid var(--flare-color-border-primary);
  }
  .flare-auth-shell--split .flare-auth-shell__brand {
    display: grid;
    grid-template-rows: auto minmax(200px, 1fr) auto;
    justify-content: stretch;
    gap: var(--flare-size-spacing-2xl);
    padding: clamp(32px, 4vw, 64px);
    border-start-start-radius: inherit;
    border-end-start-radius: inherit;
  }
  .flare-auth-shell--split .flare-auth-shell__story { padding-top: 0; }
  .flare-auth-shell--split .flare-auth-shell__story::before { display: none; }
  .flare-auth-shell__motif {
    position: relative;
    align-self: center;
    justify-self: center;
    width: min(100%, var(--flare-size-layout-auth-artwork-width));
    aspect-ratio: 8 / 5;
  }
  .flare-auth-shell__bubble {
    position: absolute;
    display: grid;
    place-items: center;
    width: 63%;
    height: 62%;
    border: 1px solid var(--flare-auth-bubble-line);
    border-radius: var(--flare-size-radius-2xl);
    background: var(--flare-auth-bubble-surface);
  }
  .flare-auth-shell__bubble::after {
    position: absolute;
    inset-block-end: -9px;
    width: 16px;
    height: 16px;
    transform: rotate(45deg);
    border-inline-end: 1px solid var(--flare-auth-bubble-line);
    border-block-end: 1px solid var(--flare-auth-bubble-line);
    background: var(--flare-auth-bubble-surface);
    content: "";
  }
  .flare-auth-shell__bubble--rear {
    inset: 0 auto auto 0;
    --flare-auth-bubble-line: color-mix(in srgb, var(--flare-auth-brand-ink) 23%, transparent);
    --flare-auth-bubble-surface: color-mix(in srgb, var(--flare-auth-brand-ink) 7%, var(--flare-auth-brand-surface));
  }
  .flare-auth-shell__bubble--rear::after { inset-inline-start: 25%; }
  .flare-auth-shell__bubble--front {
    inset: auto 0 10px auto;
    --flare-auth-bubble-line: color-mix(in srgb, var(--flare-auth-brand-ink) 36%, transparent);
    --flare-auth-bubble-surface: color-mix(in srgb, var(--flare-color-primary) 50%, var(--flare-auth-brand-surface));
  }
  .flare-auth-shell__bubble--front::after { inset-inline-end: 25%; }
  .flare-auth-shell__dots {
    width: 8px;
    height: 8px;
    margin-inline-end: var(--flare-size-spacing-2xl);
    border-radius: 50%;
    background: currentColor;
    box-shadow: -16px 0 currentColor, 16px 0 currentColor;
    opacity: .64;
  }
}

@media (max-width: 899px) {
  .flare-auth-shell__frame { display: block; width: min(100%, 540px); min-height: 0; }
  .flare-auth-shell__brand { display: none; }
  .flare-auth-shell__form-region { padding: calc(var(--flare-size-spacing-2xl) * 2); }
  .flare-auth-shell__mobile-brand { display: flex; padding-bottom: var(--flare-size-spacing-lg); border-bottom: 1px solid var(--flare-color-border-secondary); }
  .flare-auth-shell--split .flare-auth-shell__mobile-brand { padding-bottom: 0; border-bottom: 0; }
}
@media (max-width: 599px) {
  .flare-auth-shell__stage {
    place-items: start center;
    padding: max(32px, env(safe-area-inset-top)) max(24px, env(safe-area-inset-right)) max(24px, env(safe-area-inset-bottom)) max(24px, env(safe-area-inset-left));
    background: var(--flare-color-bg-primary);
  }
  .flare-auth-shell__frame { border: 0; }
  .flare-auth-shell__form-region { padding: 0; }
  .flare-auth-shell__title { font-size: var(--flare-size-font-size-auth-title); }
  .flare-auth-shell--split .flare-auth-shell__stage { align-items: start; }
}
@media (max-width: 359px) {
  .flare-auth-shell__stage { padding-inline: max(var(--flare-size-spacing-lg), env(safe-area-inset-left), env(safe-area-inset-right)); }
}
</style>
