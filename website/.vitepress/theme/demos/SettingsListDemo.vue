<script setup>
import { FlareSettingsList } from "@flare-im/vue-ui/components";
import { flareMeMenuSections } from "@flare-im/vue-ui";
import DemoStage from "./DemoStage.vue";

const sections = [
  {
    title: "通用",
    items: [
      { key: "notify", label: "新消息通知", kind: "toggle", value: true },
      { key: "sound", label: "声音", kind: "toggle", value: false },
      { key: "lang", label: "语言", detail: "简体中文" },
    ],
  },
  {
    title: "隐私",
    items: [
      { key: "read", label: "已读回执", kind: "toggle", value: true },
      { key: "block", label: "黑名单", detail: "2 人" },
    ],
  },
];

// 「我」页：社交 SDK features.meMenu 的结果原样交给 Kit；内置项文案、图标回落、插件副标题与分组都由 Kit 决定。
const meMenu = {
  items: [
    { kind: "builtin", id: "moments", icon: "moments", order: 10, target: { route: "moments" } },
    { kind: "builtin", id: "reports", icon: "report", order: 20, target: { route: "reports" } },
    { kind: "plugin", id: "plugin:flare.redpacket.wallet-entry", title: "钱包", icon: "wallet", order: 100 },
    { kind: "plugin", id: "plugin:acme.points", title: "积分", icon: "coins-stack", order: 110 },
    { kind: "builtin", id: "settings", icon: "settings", order: 2147483647, target: { route: "settings" } },
  ],
  complete: true,
};
const meSections = flareMeMenuSections(meMenu, undefined, { "plugin:flare.redpacket.wallet-entry": "¥12.00" }, "zh-CN");
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareSettingsList :sections="sections" />
      <p class="caption">「我」页（flareMeMenuSections）</p>
      <FlareSettingsList :sections="meSections" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 380px; }
.caption { margin: 16px 0 8px; color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-sm); }
</style>
