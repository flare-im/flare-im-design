<script setup>
import { computed, ref } from 'vue';
import { FlareNotificationDeliverySettings, FlareSettingsList } from "@flare-im/vue-ui/components";
import DemoStage from './DemoStage.vue';
const statuses = ['on', 'off', 'notTurnedOn'];
const backgrounds = ['unrestricted', 'optimized', 'restricted'];
const status = ref('notTurnedOn'), platform = ref('android'), background = ref('restricted'), vendor = ref(true), footer = ref(true), oneList = ref(false), last = ref('尚未操作');
// No label: the guide names the maker's page with the kit's own "自启动管理".
const vendorActions = computed(() => (vendor.value ? [{ onSelect: () => { last.value = '宿主打开厂商的自启动管理页'; } }] : []));
// The page's own sections around the notification group in the one-list form.
const general = { title: '通用', items: [{ key: 'language', label: '语言', icon: 'language', detail: '简体中文' }] };
const about = { items: [{ key: 'about', label: '关于', icon: 'info' }] };
function statusAction() {
  if (status.value === 'notTurnedOn') { status.value = 'on'; last.value = '宿主申请通知权限，模拟：已允许'; }
  else last.value = '宿主打开本应用的系统通知设置';
}
function openBatterySettings() { background.value = 'unrestricted'; last.value = '宿主打开电池使用设置，模拟：改为不受限制'; }
function openPage(item) { last.value = `设置页自己处理「${item.label}」`; }
</script>
<template><DemoStage><div class="delivery-demo">
  <FlareNotificationDeliverySettings
    :status="status"
    :background="platform === 'android' ? background : null"
    :vendor-actions="vendorActions"
    :footer="footer ? '关闭后仍可在会话里看到新消息，只是不再提醒。' : undefined"
    @status-action="statusAction"
    @open-battery-settings="openBatterySettings"
  >
    <template v-if="oneList" #section="{ section, select }">
      <FlareSettingsList :sections="[general, section, about]" @select="(item) => select(item) || openPage(item)" />
    </template>
  </FlareNotificationDeliverySettings>
  <div class="controls">
    <label>通知 <select v-model="status"><option v-for="s in statuses" :key="s" :value="s">{{ s }}</option></select></label>
    <label>平台 <select v-model="platform"><option value="android">android</option><option value="ios">ios</option></select></label>
    <label>后台 <select v-model="background" :disabled="platform !== 'android'"><option v-for="b in backgrounds" :key="b" :value="b">{{ b }}</option></select></label>
    <label><input v-model="vendor" type="checkbox" /> 厂商自启动</label>
    <label><input v-model="footer" type="checkbox" /> footer</label>
    <label><input v-model="oneList" type="checkbox" /> 同一列表（section 插槽）</label>
  </div>
  <p role="status">{{ last }}。本地模拟，不读取也不修改任何系统设置。</p>
</div></DemoStage></template>
<style scoped>
.delivery-demo { width: 100%; min-width: 0; display: grid; gap: 16px; }
.controls { display: flex; flex-wrap: wrap; gap: 12px; align-items: center; }
.controls label { display: inline-flex; align-items: center; gap: 6px; font-size: 13px; }
.controls select { min-height: 36px; padding: 4px 8px; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; }
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
