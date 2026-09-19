<script setup lang="ts">
import { computed, nextTick, ref, useId, watch } from "vue";
import type { FlareCommandPaletteCommand, FlareCommandPaletteGroup } from "../../shared/contracts/command-palette";

const props = withDefaults(defineProps<{
  open: boolean;
  query: string;
  groups: FlareCommandPaletteGroup[];
  label: string;
  placeholder: string;
  emptyText: string;
  busy?: boolean;
  selectedId?: string;
}>(), { busy: false, selectedId: undefined });

const emit = defineEmits<{
  queryChange: [value: string];
  invoke: [command: FlareCommandPaletteCommand];
  close: [];
  selectedIdChange: [id: string];
}>();

const inputRef = ref<HTMLInputElement | null>(null);
const listboxId = `flare-command-palette-${useId()}`;
let returnFocus: HTMLElement | null = null;
const normalizedQuery = computed(() => props.query.trim().toLocaleLowerCase());
const visibleGroups = computed(() => props.groups.map((group) => ({
  ...group,
  commands: group.commands.filter((command) => {
    if (!normalizedQuery.value) return true;
    return [command.label, command.description, ...(command.keywords ?? [])]
      .filter(Boolean)
      .some((value) => value!.toLocaleLowerCase().includes(normalizedQuery.value));
  }),
})).filter((group) => group.commands.length > 0));
const enabledCommands = computed(() => visibleGroups.value.flatMap((group) => group.commands).filter((command) => !command.disabled));
const activeId = computed(() => {
  if (props.selectedId && enabledCommands.value.some((command) => command.id === props.selectedId)) return props.selectedId;
  return enabledCommands.value[0]?.id;
});

watch(() => props.open, async (open, wasOpen) => {
  if (open) {
    returnFocus = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    await nextTick();
    inputRef.value?.focus();
  } else if (wasOpen) {
    returnFocus?.focus();
    returnFocus = null;
  }
});

function move(delta: number): void {
  const commands = enabledCommands.value;
  if (!commands.length) return;
  const current = Math.max(0, commands.findIndex((command) => command.id === activeId.value));
  const next = commands[(current + delta + commands.length) % commands.length];
  emit("selectedIdChange", next.id);
}

function invoke(command?: FlareCommandPaletteCommand): void {
  if (!command || command.disabled || props.busy) return;
  emit("invoke", command);
}

function onKeydown(event: KeyboardEvent): void {
  if (event.key === "ArrowDown" || event.key === "ArrowUp") {
    event.preventDefault();
    move(event.key === "ArrowDown" ? 1 : -1);
  } else if (event.key === "Home" || event.key === "End") {
    event.preventDefault();
    const command = event.key === "Home" ? enabledCommands.value[0] : enabledCommands.value.at(-1);
    if (command) emit("selectedIdChange", command.id);
  } else if (event.key === "Enter") {
    event.preventDefault();
    invoke(enabledCommands.value.find((command) => command.id === activeId.value));
  } else if (event.key === "Escape") {
    event.preventDefault();
    emit("close");
  }
}
</script>

<template>
  <Teleport to="body">
    <div v-if="open" class="flare-command-palette-backdrop" @mousedown.self="emit('close')">
      <section
        class="flare-command-palette"
        role="dialog"
        aria-modal="true"
        :aria-label="label"
        :aria-busy="busy"
        @keydown="onKeydown"
      >
        <input
          ref="inputRef"
          class="flare-command-palette__input"
          type="search"
          :value="query"
          :placeholder="placeholder"
          :aria-label="placeholder"
          :aria-controls="listboxId"
          @input="emit('queryChange', ($event.target as HTMLInputElement).value)"
        />
        <div :id="listboxId" class="flare-command-palette__results" role="listbox" :aria-label="label">
          <p v-if="!visibleGroups.length" class="flare-command-palette__empty" role="status">{{ emptyText }}</p>
          <section
            v-for="group in visibleGroups"
            :key="group.id"
            class="flare-command-palette__group"
            role="group"
            :aria-label="group.label"
          >
            <!-- The group carries the name; the visible heading would be an element a listbox may not
                 contain, and reading it twice helps nobody. -->
            <h3 aria-hidden="true">{{ group.label }}</h3>
            <button
              v-for="command in group.commands"
              :key="command.id"
              type="button"
              role="option"
              class="flare-command-palette__command"
              :class="{ 'flare-command-palette__command--active': command.id === activeId }"
              :aria-selected="command.id === activeId"
              :disabled="command.disabled || busy"
              @mouseenter="!command.disabled && emit('selectedIdChange', command.id)"
              @click="invoke(command)"
            >
              <span><strong>{{ command.label }}</strong><small v-if="command.description">{{ command.description }}</small></span>
              <kbd v-if="command.shortcut">{{ command.shortcut }}</kbd>
            </button>
          </section>
        </div>
      </section>
    </div>
  </Teleport>
</template>

<style scoped>
.flare-command-palette-backdrop {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  justify-content: center;
  align-items: flex-start;
  padding: 12vh var(--flare-size-spacing-md);
  background: rgb(0 0 0 / 32%);
}

.flare-command-palette {
  width: min(640px, 100%);
  max-height: min(70vh, 680px);
  overflow: hidden;
  color: var(--flare-color-text-primary);
  background: var(--flare-color-bg-elevated);
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-lg);
  box-shadow: var(--flare-shadow-lg);
}

.flare-command-palette__input {
  box-sizing: border-box;
  width: 100%;
  min-height: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  color: inherit;
  font: inherit;
  background: transparent;
  border: 0;
  border-bottom: 1px solid var(--flare-color-border-primary);
  outline: none;
}

.flare-command-palette__input:focus-visible {
  box-shadow: inset 0 0 0 2px var(--flare-color-focus-ring);
}

.flare-command-palette__results { max-height: 56vh; overflow: auto; padding: var(--flare-size-spacing-xs); }
.flare-command-palette__group h3 { margin: var(--flare-size-spacing-sm); color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-xs); }
.flare-command-palette__command { display: flex; width: 100%; min-height: var(--flare-size-layout-touch-target); align-items: center; justify-content: space-between; gap: var(--flare-size-spacing-md); padding: var(--flare-size-spacing-sm); color: inherit; text-align: left; background: transparent; border: 0; border-radius: var(--flare-size-radius-sm); }
.flare-command-palette__command:hover, .flare-command-palette__command--active { background: var(--flare-color-bg-hover); }
.flare-command-palette__command:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-command-palette__command span { min-width: 0; }
.flare-command-palette__command strong, .flare-command-palette__command small { display: block; overflow-wrap: anywhere; }
.flare-command-palette__command small, .flare-command-palette__empty { color: var(--flare-color-text-secondary); }
/* Secondary, not tertiary: on the active row's background the tertiary grey reads at 4.47 in dark. */
.flare-command-palette__command kbd { flex: none; color: var(--flare-color-text-secondary); font: inherit; font-size: var(--flare-size-font-size-xs); }
.flare-command-palette__empty { margin: 0; padding: var(--flare-size-spacing-xl) var(--flare-size-spacing-md); text-align: center; }

@media (prefers-reduced-motion: reduce) { .flare-command-palette, .flare-command-palette * { scroll-behavior: auto !important; } }
</style>
