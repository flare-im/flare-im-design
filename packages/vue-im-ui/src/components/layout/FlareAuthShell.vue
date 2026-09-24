<script setup lang="ts">
import FlareScreen from "./FlareScreen.vue";
import FlareBrandLogo from "../general/FlareBrandLogo.vue";

withDefaults(
  defineProps<{
    product: string;
    title: string;
    subtitle: string;
    tagline?: string;
    headline?: string;
    description?: string;
    backLabel?: string;
  }>(),
  {
    tagline: undefined,
    headline: undefined,
    description: undefined,
    backLabel: undefined,
  },
);

const emit = defineEmits<{ (event: "back"): void }>();
</script>

<template>
  <FlareScreen class="flare-auth-shell" surface="brand" :scroll="false">
    <div class="flare-auth-shell__stage">
      <aside class="flare-auth-shell__brand" aria-hidden="true">
        <div class="flare-auth-shell__lockup">
          <FlareBrandLogo :size="72" />
          <div>
            <p class="flare-auth-shell__product">{{ product }}</p>
            <p v-if="tagline" class="flare-auth-shell__tagline">{{ tagline }}</p>
          </div>
        </div>
        <div class="flare-auth-shell__story">
          <p v-if="headline" class="flare-auth-shell__headline">{{ headline }}</p>
          <p v-if="description" class="flare-auth-shell__description">{{ description }}</p>
        </div>
      </aside>

      <main class="flare-auth-shell__form-region">
        <section class="flare-auth-shell__panel" :aria-labelledby="'flare-auth-title'">
          <div class="flare-auth-shell__mobile-brand">
            <FlareBrandLogo :size="52" />
            <div>
              <p class="flare-auth-shell__product">{{ product }}</p>
              <p v-if="tagline" class="flare-auth-shell__tagline">{{ tagline }}</p>
            </div>
          </div>

          <button
            v-if="backLabel"
            type="button"
            class="flare-auth-shell__back"
            :aria-label="backLabel"
            @click="emit('back')"
          >
            <span aria-hidden="true">←</span>
            <span>{{ backLabel }}</span>
          </button>

          <header class="flare-auth-shell__heading">
            <h1 id="flare-auth-title" class="flare-auth-shell__title">{{ title }}</h1>
            <p class="flare-auth-shell__subtitle">{{ subtitle }}</p>
          </header>

          <div class="flare-auth-shell__content">
            <slot />
          </div>
        </section>
      </main>
    </div>
  </FlareScreen>
</template>

<style scoped>
.flare-auth-shell {
  height: 100%;
  min-height: 100%;
}
.flare-auth-shell__stage {
  box-sizing: border-box;
  display: grid;
  grid-template-columns: minmax(360px, 0.86fr) minmax(480px, 1.14fr);
  width: 100%;
  min-height: 100%;
  overflow: hidden;
  background: var(--flare-color-bg-primary);
}
.flare-auth-shell__brand {
  display: grid;
  grid-template-rows: auto minmax(0, 1fr);
  gap: var(--flare-size-spacing-2xl);
  min-width: 0;
  padding: clamp(48px, 6vw, 88px);
  border-right: 1px solid var(--flare-color-border-primary);
  background:
    radial-gradient(100% 76% at 8% 0%, color-mix(in srgb, var(--flare-color-info) 20%, transparent), transparent 68%),
    linear-gradient(150deg, color-mix(in srgb, var(--flare-color-primary) 14%, var(--flare-color-bg-primary)), var(--flare-color-bg-secondary));
}
.flare-auth-shell__lockup,
.flare-auth-shell__mobile-brand {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-lg);
}
.flare-auth-shell__story {
  align-self: center;
  max-width: 420px;
  padding-bottom: clamp(24px, 8vh, 96px);
}
.flare-auth-shell__product,
.flare-auth-shell__tagline,
.flare-auth-shell__headline,
.flare-auth-shell__description,
.flare-auth-shell__subtitle { margin: 0; }
.flare-auth-shell__product {
  color: var(--flare-color-text-primary);
  font-size: var(--flare-size-font-size-2xl);
  font-weight: 700;
}
.flare-auth-shell__tagline {
  margin-top: var(--flare-size-spacing-xs);
  color: var(--flare-color-primary-text);
  font-size: var(--flare-size-font-size-sm);
  font-weight: 600;
  letter-spacing: 0.06em;
}
.flare-auth-shell__headline {
  color: var(--flare-color-text-primary);
  font-size: var(--flare-size-font-size-5xl);
  font-weight: 700;
  line-height: 1.2;
}
.flare-auth-shell__description {
  margin-top: var(--flare-size-spacing-lg);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-lg);
  line-height: 1.7;
}
.flare-auth-shell__form-region {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 0;
  padding: clamp(40px, 7vh, 80px) clamp(40px, 7vw, 96px);
  overflow-y: auto;
  background: var(--flare-color-bg-primary);
}
.flare-auth-shell__panel {
  width: min(100%, 500px);
  margin-block: auto;
}
.flare-auth-shell__mobile-brand { display: none; margin-bottom: var(--flare-size-spacing-2xl); }
.flare-auth-shell__back {
  display: inline-flex;
  align-items: center;
  min-height: var(--flare-size-layout-touch-target-min);
  margin: 0 0 var(--flare-size-spacing-md);
  padding: 0 var(--flare-size-spacing-sm);
  gap: var(--flare-size-spacing-sm);
  border: 0;
  border-radius: var(--flare-size-radius-md);
  background: transparent;
  color: var(--flare-color-text-link);
  cursor: pointer;
  font: inherit;
  font-weight: 600;
}
.flare-auth-shell__back:hover { background: var(--flare-color-bg-hover); }
.flare-auth-shell__back:focus-visible { outline: 3px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-auth-shell__heading { margin-bottom: var(--flare-size-spacing-2xl); }
.flare-auth-shell__title {
  margin: 0;
  color: var(--flare-color-text-primary);
  font-size: var(--flare-size-font-size-5xl);
  line-height: 1.2;
}
.flare-auth-shell__subtitle {
  margin-top: var(--flare-size-spacing-sm);
  color: var(--flare-color-text-secondary);
  line-height: 1.6;
}
.flare-auth-shell__content { min-width: 0; }

@media (max-width: 899px) {
  .flare-auth-shell__stage {
    display: block;
    width: 100%;
    min-height: 100%;
    margin: 0;
    border: 0;
    border-radius: 0;
    box-shadow: none;
  }
  .flare-auth-shell__brand { display: none; }
  .flare-auth-shell__form-region {
    box-sizing: border-box;
    min-height: 100%;
    padding: max(32px, env(safe-area-inset-top)) max(24px, env(safe-area-inset-right)) max(32px, env(safe-area-inset-bottom)) max(24px, env(safe-area-inset-left));
  }
  .flare-auth-shell__mobile-brand { display: flex; }
}

@media (min-width: 900px) and (max-width: 1099px) {
  .flare-auth-shell__brand { padding-inline: 40px; }
  .flare-auth-shell__form-region { padding-inline: 40px; }
}
</style>
