<script setup lang="ts">
import { useId } from "vue";
import FlareScreen from "./FlareScreen.vue";
import FlareBrandLogo from "../general/FlareBrandLogo.vue";

// Shared presentation only: authentication and the form remain owned by the host.
defineProps<{
  product: string;
  title: string;
  subtitle: string;
  tagline?: string;
  headline?: string;
  description?: string;
  eyebrow?: string;
  footer?: string;
  backLabel?: string;
}>();
const emit = defineEmits<{ (event: "back"): void }>();
const headingId = `flare-auth-heading-${useId()}`;
</script>

<template>
  <FlareScreen class="flare-auth-shell" surface="surface" :scroll="false">
    <div class="flare-auth-shell__stage">
      <aside class="flare-auth-shell__brand" :aria-label="product">
        <div class="flare-auth-shell__lockup">
          <FlareBrandLogo :size="44" aria-hidden="true" />
          <div>
            <p class="flare-auth-shell__product">{{ product }}</p>
            <p v-if="tagline" class="flare-auth-shell__tagline">{{ tagline }}</p>
          </div>
        </div>
        <div class="flare-auth-shell__story">
          <p v-if="headline" class="flare-auth-shell__headline">{{ headline }}</p>
          <p v-if="description" class="flare-auth-shell__description">{{ description }}</p>
          <svg class="flare-auth-shell__art" viewBox="0 0 320 200" aria-hidden="true" focusable="false">
            <path class="auth-art__rear" d="M48 24H200A20 20 0 0 1 220 44V120A20 20 0 0 1 200 140H80L58 158V140H48A20 20 0 0 1 28 120V44A20 20 0 0 1 48 24Z" />
            <path class="auth-art__front" d="M138 82H274A18 18 0 0 1 292 100V160A18 18 0 0 1 274 178H258V194L238 178H138A18 18 0 0 1 120 160V100A18 18 0 0 1 138 82Z" />
            <g class="auth-art__dots"><circle cx="166" cy="130" r="4" /><circle cx="198" cy="130" r="4" /><circle cx="230" cy="130" r="4" /></g>
          </svg>
        </div>
        <div class="flare-auth-shell__brand-rule" aria-hidden="true"><span /></div>
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
          <div class="flare-auth-shell__task-surface">
          <button v-if="backLabel" type="button" class="flare-auth-shell__back" :aria-label="backLabel" @click="emit('back')">
            <span aria-hidden="true">←</span><span>{{ backLabel }}</span>
          </button>
          <header class="flare-auth-shell__heading">
            <p v-if="eyebrow" class="flare-auth-shell__eyebrow">{{ eyebrow }}</p>
            <h1 :id="headingId" class="flare-auth-shell__title">{{ title }}</h1>
            <p class="flare-auth-shell__subtitle">{{ subtitle }}</p>
          </header>
          <div class="flare-auth-shell__content"><slot /></div>
          <footer v-if="footer || $slots.footer" class="flare-auth-shell__footer"><slot name="footer">{{ footer }}</slot></footer>
          </div>
        </section>
      </main>
    </div>
  </FlareScreen>
</template>

<style scoped>
.flare-auth-shell { height: 100%; min-height: 0; }
.flare-auth-shell__stage {
  display: grid;
  grid-template-columns: minmax(0, .44fr) minmax(0, .56fr);
  width: 100%; height: 100%; min-height: 0;
  background: var(--flare-color-bg-primary);
}
.flare-auth-shell__brand {
  display: flex; flex-direction: column; min-width: 0; min-height: 0;
  padding: clamp(40px, 4.5vw, 72px);
  border-inline-end: 1px solid var(--flare-color-border-secondary);
  background: var(--flare-color-bg-selected);
  overflow-y: auto;
}
.flare-auth-shell__lockup, .flare-auth-shell__mobile-brand { display: flex; align-items: center; gap: var(--flare-size-spacing-md); }
.flare-auth-shell__product, .flare-auth-shell__tagline, .flare-auth-shell__headline,
.flare-auth-shell__description, .flare-auth-shell__subtitle, .flare-auth-shell__eyebrow { margin: 0; }
.flare-auth-shell__product { color: var(--flare-color-text-primary); font-size: var(--flare-size-font-size-5xl); font-weight: 700; letter-spacing: -.025em; line-height: 1.25; }
.flare-auth-shell__tagline { margin-top: var(--flare-size-spacing-2xs, 4px); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); letter-spacing: .04em; line-height: 1.6; }
.flare-auth-shell__story { width: 100%; max-width: var(--flare-size-layout-auth-form-max-width); margin-block: auto; padding-block: var(--flare-size-spacing-2xl); }
.flare-auth-shell__headline { color: var(--flare-color-text-primary); font-size: var(--flare-size-font-size-auth-headline); font-weight: 650; line-height: 1.3; letter-spacing: -.035em; white-space: pre-line; overflow-wrap: anywhere; }
.flare-auth-shell__description { max-width: 360px; margin-top: var(--flare-size-spacing-lg); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-2xl); line-height: 1.8; }
.flare-auth-shell__art { display: block; width: min(100%, var(--flare-size-layout-auth-artwork-width)); height: auto; margin-top: var(--flare-size-spacing-2xl); overflow: visible; }
.auth-art__rear { fill: color-mix(in srgb, var(--flare-color-primary) 12%, var(--flare-color-bg-primary)); stroke: var(--flare-color-primary-text); stroke-opacity: .24; stroke-width: 1.5; }
.auth-art__front { fill: var(--flare-color-bg-primary); stroke: var(--flare-color-primary-text); stroke-opacity: .55; stroke-width: 1.5; }
.auth-art__dots { fill: var(--flare-color-primary-text); opacity: .7; }
.flare-auth-shell__brand-rule { width: 100%; height: 1px; flex-shrink: 0; background: var(--flare-color-border-primary); }
.flare-auth-shell__brand-rule span { display: block; width: 32px; height: 1px; background: var(--flare-color-primary); }
.flare-auth-shell__form-region { display: flex; flex-direction: column; align-items: center; min-width: 0; min-height: 0; padding: var(--flare-size-spacing-2xl) clamp(32px, 6vw, 96px); overflow-y: auto; overscroll-behavior: contain; background: linear-gradient(150deg, color-mix(in srgb, var(--flare-color-primary) 10%, var(--flare-color-bg-secondary)), var(--flare-color-bg-secondary) 55%); }
.flare-auth-shell__panel { width: 100%; max-width: var(--flare-size-layout-auth-form-max-width); margin-block: auto; padding-block: var(--flare-size-spacing-2xl); flex-shrink: 0; }
.flare-auth-shell__task-surface { box-sizing: border-box; min-width: 0; padding: var(--flare-size-spacing-2xl); border: 1px solid var(--flare-color-border-primary); border-radius: var(--flare-size-radius-2xl); background: var(--flare-color-bg-primary); box-shadow: var(--flare-shadow-sm); }
.flare-auth-shell__utility { display: flex; flex-shrink: 0; align-self: flex-end; padding-bottom: var(--flare-size-spacing-lg); }
.flare-auth-shell__mobile-brand { display: none; margin-bottom: var(--flare-size-spacing-2xl); }
.flare-auth-shell__back { display: inline-flex; align-items: center; min-height: var(--flare-size-layout-touch-target-min); margin: 0 0 var(--flare-size-spacing-md); padding: 0; gap: var(--flare-size-spacing-sm); border: 0; border-radius: var(--flare-size-radius-md); background: transparent; color: var(--flare-color-text-link); cursor: pointer; font: inherit; font-weight: 600; }
.flare-auth-shell__back:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 4px; }
.flare-auth-shell__heading { margin-bottom: var(--flare-size-spacing-xl); }
.flare-auth-shell__eyebrow { margin-bottom: var(--flare-size-spacing-md); color: var(--flare-color-primary-text); font-size: var(--flare-size-font-size-sm); font-weight: 600; letter-spacing: .1em; line-height: 1.5; }
.flare-auth-shell__title { margin: 0; color: var(--flare-color-text-primary); font-size: var(--flare-size-font-size-auth-title); font-weight: 650; line-height: 1.3; letter-spacing: -.025em; overflow-wrap: anywhere; }
.flare-auth-shell__subtitle { margin-top: var(--flare-size-spacing-sm); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-lg); line-height: 1.7; overflow-wrap: anywhere; }
.flare-auth-shell__content { min-width: 0; }
.flare-auth-shell__footer { margin-top: var(--flare-size-spacing-2xl); padding-top: var(--flare-size-spacing-lg); border-top: 1px solid var(--flare-color-border-secondary); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); line-height: 1.7; overflow-wrap: anywhere; }
@media (max-width: 899px) {
  .flare-auth-shell__stage { display: flex; flex-direction: column; }
  .flare-auth-shell__brand { display: none; }
  .flare-auth-shell__form-region { flex: 1; padding: max(24px, env(safe-area-inset-top)) max(24px, env(safe-area-inset-right)) max(24px, env(safe-area-inset-bottom)) max(24px, env(safe-area-inset-left)); }
  .flare-auth-shell__panel { margin: 0; padding-block: var(--flare-size-spacing-lg); }
  .flare-auth-shell__task-surface { padding: var(--flare-size-spacing-xl); }
  .flare-auth-shell__mobile-brand { display: flex; }
  .flare-auth-shell__mobile-brand .flare-auth-shell__product { font-size: var(--flare-size-font-size-4xl); }
}
@media (max-width: 359px) {
  .flare-auth-shell__form-region { padding-inline: var(--flare-size-spacing-lg); }
}
</style>
