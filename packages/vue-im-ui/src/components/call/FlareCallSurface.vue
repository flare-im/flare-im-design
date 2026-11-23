<script setup lang="ts">
// The call's window (docs/plugin-experience.md §3.1): audio component.callWindowAudio*, video callWindowVideo*,
// expanded = the viewport less 2 × spacing.xl and 90vh high. On a phone it is the whole screen, the stage running under
// the status bar and the home indicator. Escape and the scrim never minimize or hang up a call. On PC the window moves
// by its top 48 (layout.controlHeightLg), kept inside the viewport; not while expanded or full screen. Escape (and the
// scrim) only leave the expanded state: update:expanded(false). The window casts shadows.xl.
// The call view inside draws the window's keys in its top bar: expand / collapse on PC and tablets, and minimize, which
// emits here as well as on the view (a host listens on either).
import { computed, getCurrentInstance, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import FlareModal from '../general/FlareModal.vue';
import { useCallPhone } from './useCallPhone';
import { provideCallWindow } from './useCallWindow';
const props = defineProps<{ mode: 'audio' | 'video'; label?: string }>();
/** Host-controlled with v-model:expanded; without a listener the window keeps the expand key's choice itself. */
const expanded = defineModel<boolean>('expanded', { default: false });
const emit = defineEmits<{ minimize: [] }>();
const instance = getCurrentInstance();
const fullscreen = useCallPhone();
const width = computed(() => expanded.value ? 'calc(100vw - var(--flare-size-spacing-xl) * 2)' : props.mode === 'video' ? 'var(--flare-size-component-call-window-video-width)' : 'var(--flare-size-component-call-window-audio-width)');
const height = computed(() => expanded.value ? '90vh' : `min(90vh, ${props.mode === 'video' ? 'var(--flare-size-component-call-window-video-height)' : 'var(--flare-size-component-call-window-audio-height)'})`);

const surface = ref<HTMLElement | null>(null);
const draggable = computed(() => !fullscreen.value && !expanded.value);
provideCallWindow({
  windowed: () => !fullscreen.value,
  expanded,
  minimize: () => emit('minimize'),
  listensMinimize: () => Boolean(instance?.vnode.props?.onMinimize),
});
const dialog = () => surface.value?.closest<HTMLElement>('[role="dialog"]') ?? null;
let offset = { x: 0, y: 0 };
let press: { x: number; y: number; id: number; ox: number; oy: number; lo: { x: number; y: number }; hi: { x: number; y: number } } | null = null;
function place(x: number, y: number): void {
  offset = { x, y };
  const box = dialog();
  if (box) box.style.translate = x || y ? `${x}px ${y}px` : '';
}
/** The drag area's height: the layout.controlHeightLg token as the surface resolves it. */
function handleHeight(): number {
  return parseFloat(getComputedStyle(surface.value!).getPropertyValue('--flare-size-layout-control-height-lg')) || 48;
}
function down(event: PointerEvent): void {
  const box = dialog();
  if (!draggable.value || !box || event.button !== 0) return;
  if (event.clientY - surface.value!.getBoundingClientRect().top > handleHeight()) return;
  if ((event.target as Element | null)?.closest('button, a, input, select, textarea, [role="button"], [role="switch"]')) return;
  const rect = box.getBoundingClientRect();
  // Where the window may go: its untranslated edges against the viewport's.
  const left = rect.left - offset.x, top = rect.top - offset.y, right = rect.right - offset.x, bottom = rect.bottom - offset.y;
  press = { x: event.clientX, y: event.clientY, id: event.pointerId, ox: offset.x, oy: offset.y,
    lo: { x: -left, y: -top }, hi: { x: window.innerWidth - right, y: window.innerHeight - bottom } };
  window.addEventListener('pointermove', move);
  window.addEventListener('pointerup', up);
  window.addEventListener('pointercancel', up);
}
const clamp = (value: number, lo: number, hi: number) => lo > hi ? 0 : Math.min(hi, Math.max(lo, value));
function move(event: PointerEvent): void {
  if (!press || event.pointerId !== press.id) return;
  place(clamp(press.ox + event.clientX - press.x, press.lo.x, press.hi.x), clamp(press.oy + event.clientY - press.y, press.lo.y, press.hi.y));
}
function up(event: PointerEvent): void {
  if (press && event.pointerId === press.id) stop();
}
function stop(): void {
  press = null;
  window.removeEventListener('pointermove', move);
  window.removeEventListener('pointerup', up);
  window.removeEventListener('pointercancel', up);
}
// Expanding, going full screen or resizing the window puts the window back in the middle.
const recentre = () => place(0, 0);
watch(draggable, recentre);
// FlareModal draws shadows.lg on its dialog (teleported, out of reach of scoped styles); a window takes xl.
watch([fullscreen, surface], () => { const box = dialog(); if (box) box.style.boxShadow = fullscreen.value ? '' : 'var(--flare-shadow-xl)'; }, { flush: 'post', immediate: true });
onMounted(() => window.addEventListener('resize', recentre));
onBeforeUnmount(() => {
  stop();
  window.removeEventListener('resize', recentre);
});
</script>
<template>
  <FlareModal :open="true" edge-to-edge :label="label" :title-hidden="true" :show-close="false" :dismissible="expanded" :fullscreen="fullscreen" :width="width" :max-height="height" :fill="true" :scrollable="false" @close="expanded = false">
    <div ref="surface" class="flare-call-surface" :data-expanded="expanded" :data-mode="mode" :data-fullscreen="fullscreen" @pointerdown="down"><slot name="default" /></div>
  </FlareModal>
</template>
<style scoped>
.flare-call-surface { width: 100%; height: 100%; min-height: 0; overflow: hidden; }
</style>
