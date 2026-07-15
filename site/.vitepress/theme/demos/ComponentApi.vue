<script setup>
import { computed } from "vue";
import { useRoute } from "vitepress";
import spec from "../../../../spec/components.json";

const props = defineProps({ name: { type: String, required: true } });
const route = useRoute();
const en = computed(() => route.path.startsWith("/en"));
const loc = computed(() => (en.value ? "en" : "zh"));
const t = (zh, enText) => (en.value ? enText : zh);

const entry = computed(() => spec.components.find((c) => c.name === props.name));
const apiProps = computed(() => entry.value?.props ?? []);
const states = computed(() => entry.value?.states ?? []);
const events = computed(() => entry.value?.events ?? []);
const desc = (p) => (typeof p.description === "string" ? p.description : p.description?.[loc.value] ?? p.description?.zh ?? "");
</script>

<template>
  <div v-if="apiProps.length || states.length || events.length" class="capi">
    <template v-if="apiProps.length">
      <h2 id="props" class="capi__h">Props</h2>
      <div class="capi__scroll">
        <table class="capi__table">
          <thead>
            <tr>
              <th>{{ t("名称", "Name") }}</th>
              <th>{{ t("类型", "Type") }}</th>
              <th>{{ t("必填", "Required") }}</th>
              <th>{{ t("默认", "Default") }}</th>
              <th>{{ t("说明", "Description") }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="p in apiProps" :key="p.name">
              <td><code>{{ p.name }}</code></td>
              <td><code class="capi__type">{{ p.type }}</code></td>
              <td class="capi__req">{{ p.required ? "✔" : "—" }}</td>
              <td>{{ p.default != null && p.default !== "" ? "" : "—" }}<code v-if="p.default != null && p.default !== ''">{{ p.default }}</code></td>
              <td>{{ desc(p) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>

    <template v-if="states.length">
      <h2 id="states" class="capi__h">States</h2>
      <p class="capi__tags"><span v-for="s in states" :key="s" class="capi__tag">{{ s }}</span></p>
    </template>

    <template v-if="events.length">
      <h2 id="events" class="capi__h">Events</h2>
      <p class="capi__tags"><span v-for="ev in events" :key="ev" class="capi__tag capi__tag--ev">{{ ev }}</span></p>
    </template>
  </div>
</template>

<style scoped>
.capi { margin-top: 8px; }
.capi__h {
  font-size: 18px;
  font-weight: 600;
  margin: 28px 0 12px;
  padding-top: 20px;
  border-top: 1px solid var(--vp-c-divider);
}
.capi__scroll { overflow-x: auto; }
.capi__table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13.5px;
  display: table;
}
.capi__table th,
.capi__table td {
  text-align: left;
  padding: 8px 12px;
  border: 1px solid var(--vp-c-divider);
  vertical-align: top;
}
.capi__table th {
  background: var(--vp-c-bg-soft);
  font-weight: 600;
  white-space: nowrap;
}
.capi__table code { font-size: 12.5px; }
.capi__type { color: var(--vp-c-brand-1); }
.capi__req { text-align: center; white-space: nowrap; }
.capi__tags { display: flex; flex-wrap: wrap; gap: 6px; }
.capi__tag {
  font-size: 12.5px;
  font-family: var(--vp-font-family-mono);
  padding: 2px 10px;
  border-radius: 6px;
  color: var(--vp-c-text-2);
  background: var(--vp-c-bg-soft);
  border: 1px solid var(--vp-c-divider);
}
.capi__tag--ev { color: var(--vp-c-brand-1); border-color: var(--vp-c-brand-soft); background: var(--vp-c-brand-soft); }
</style>
