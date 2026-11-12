<script setup>
import { computed, ref } from "vue";
import { FlareNotificationAlertSettings, FlareSettingsList } from "@flare-im/vue-ui/components";
import { defaultNotificationAlertPreferences } from "@flare-im/vue-ui/contracts";
import DemoStage from "./DemoStage.vue";

// The host holds the value, writes what `change` reports and saves it; the component keeps no copy.
const value = ref({
  ...defaultNotificationAlertPreferences,
  quietHours: { ...defaultNotificationAlertPreferences.quietHours, enabled: true, weekdays: 0b0011111 },
});
const saving = ref(false), oneList = ref(false), last = ref("尚未修改");
// The page's own rows around the group in the one-list form.
const general = { title: "通用", items: [{ key: "sound", label: "提示音", kind: "toggle", value: true }] };
const about = { items: [{ key: "about", label: "关于", icon: "info" }] };
function change(next) {
  value.value = next;
  last.value = "宿主写回新值并保存";
}
function own(item) { last.value = `设置页自己处理「${item.label}」`; }
const written = computed(() => JSON.stringify(value.value));
</script>
<template><DemoStage><div class="alert-demo">
  <FlareNotificationAlertSettings :value="value" :disabled="saving" @change="change">
    <template v-if="oneList" #sections="{ sections, select, toggle }">
      <FlareSettingsList
        :sections="[general, ...sections, about]"
        @select="(item) => select(item) || own(item)"
        @toggle="(item, on) => toggle(item, on) || own(item)"
      />
    </template>
  </FlareNotificationAlertSettings>
  <div class="controls">
    <label><input v-model="saving" type="checkbox" /> 保存中（disabled）</label>
    <label><input v-model="oneList" type="checkbox" /> 同一列表（sections 插槽）</label>
  </div>
  <p role="status">{{ last }}。</p>
  <code>{{ written }}</code>
</div></DemoStage></template>
<style scoped>
.alert-demo { width: 100%; min-width: 0; display: grid; gap: 16px; }
.controls { display: flex; flex-wrap: wrap; gap: 12px; align-items: center; }
.controls label { display: inline-flex; align-items: center; gap: 6px; font-size: 13px; }
p { font-size: 13px; overflow-wrap: anywhere; }
code { font-size: 12px; overflow-wrap: anywhere; }
</style>
