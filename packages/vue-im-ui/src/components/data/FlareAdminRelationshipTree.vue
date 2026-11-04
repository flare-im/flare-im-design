<script lang="ts">
export interface FlareAdminRelationshipNode {
  key: string;
  label: string;
  children?: FlareAdminRelationshipNode[];
  current?: boolean;
  hasDetails?: boolean;
}
</script>

<script setup lang="ts">
import { NPopover } from "naive-ui";
import { computed, ref } from "vue";

const props = defineProps<{
  roots: FlareAdminRelationshipNode[];
  label: string;
}>();

const active = ref("");
const columnGap = 126;
const rowGap = 108;
const top = 32;

const layout = computed(() => {
  const nodes: { node: FlareAdminRelationshipNode; x: number; y: number }[] = [];
  const edges: string[] = [];
  let nextColumn = 0;
  let maxY = top;

  function visit(node: FlareAdminRelationshipNode, depth: number) {
    const children = node.children ?? [];
    const y = top + depth * rowGap;
    const point = { node, x: 0, y };
    nodes.push(point);
    maxY = Math.max(maxY, y);
    const branches = children.map((child) => visit(child, depth + 1));
    point.x = branches.length
      ? (branches[0]!.x + branches[branches.length - 1]!.x) / 2
      : columnGap * (nextColumn++ + 0.5);
    for (const child of branches) {
      const bend = (y + child.y) / 2;
      edges.push(`M ${point.x} ${y + 5} C ${point.x} ${bend}, ${child.x} ${bend}, ${child.x} ${child.y - 5}`);
    }
    return point;
  }

  props.roots.forEach((root) => visit(root, 0));
  return { nodes, edges, width: nextColumn * columnGap, height: maxY + 60 };
});
</script>

<template>
  <div class="flare-relationship-tree" role="region" :aria-label="label" tabindex="0">
    <div class="flare-relationship-tree__canvas" :style="{ width: layout.width + 'px', height: layout.height + 'px' }">
      <svg class="flare-relationship-tree__edges" :width="layout.width" :height="layout.height" aria-hidden="true">
        <path v-for="edge in layout.edges" :key="edge" :d="edge" />
      </svg>
      <div
        v-for="{ node, x, y } in layout.nodes"
        :key="node.key"
        class="flare-relationship-tree__point"
        :class="{ 'flare-relationship-tree__point--current': node.current }"
        :style="{ left: x + 'px', top: y + 'px' }"
      >
        <NPopover v-if="node.hasDetails && $slots.details" trigger="manual" :show="active === node.key" placement="top">
          <template #trigger>
            <button
              type="button"
              class="flare-relationship-tree__node"
              :aria-label="node.label"
              @mouseenter="active = node.key"
              @mouseleave="active = ''"
              @focus="active = node.key"
              @blur="active = ''"
              @click="active = node.key"
              @keydown.esc="
                (event) => {
                  if (active !== node.key) return;
                  event.stopPropagation();
                  active = '';
                }
              "
            >
              <span class="flare-relationship-tree__dot" aria-hidden="true" />
              <span class="flare-relationship-tree__label">{{ node.label }}</span>
            </button>
          </template>
          <slot name="details" :node="node" />
        </NPopover>
        <span v-else class="flare-relationship-tree__node" :title="node.label">
          <span class="flare-relationship-tree__dot" aria-hidden="true" />
          <span class="flare-relationship-tree__label">{{ node.label }}</span>
        </span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.flare-relationship-tree {
  max-width: 100%;
  overflow: auto;
}
.flare-relationship-tree__canvas {
  position: relative;
  margin-inline: auto;
}
.flare-relationship-tree__edges {
  position: absolute;
  inset: 0;
  fill: none;
  stroke: var(--flare-color-border-strong, #c4cbd5);
  stroke-width: 1.25;
  pointer-events: none;
}
.flare-relationship-tree__point {
  position: absolute;
  transform: translate(-50%, -5px);
  width: 118px;
}
.flare-relationship-tree__node {
  display: flex;
  width: 100%;
  flex-direction: column;
  align-items: center;
  gap: 5px;
  border: 0;
  border-radius: 4px;
  padding: 0 4px 4px;
  background: transparent;
  color: inherit;
  font: inherit;
}
button.flare-relationship-tree__node {
  cursor: pointer;
}
.flare-relationship-tree__dot {
  width: 10px;
  height: 10px;
  box-sizing: border-box;
  border: 2px solid var(--flare-color-primary, #547ee2);
  border-radius: 50%;
  background: var(--flare-color-bg-primary, #fff);
}
.flare-relationship-tree__label {
  overflow: hidden;
  max-width: 100%;
  text-overflow: ellipsis;
  white-space: nowrap;
  padding: 1px 3px;
  background: var(--flare-color-bg-primary, #fff);
  font-size: 12px;
}
.flare-relationship-tree__point--current .flare-relationship-tree__dot {
  background: var(--flare-color-primary, #547ee2);
}
.flare-relationship-tree__point--current .flare-relationship-tree__label {
  font-weight: 700;
}
</style>
