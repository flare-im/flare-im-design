<script setup>
import { ref } from 'vue';
import FlareConnectionDetails from '@flare-im/vue-ui/components/general/FlareConnectionDetails.vue';
import DemoStage from './DemoStage.vue';

const states = ['connected', 'connecting', 'reconnecting', 'offline', 'sessionExpired', 'kicked', 'sdkUnready'];
const reasons = {
  connected: undefined,
  connecting: '正在建立连接，请稍候',
  reconnecting: '网络波动，正在自动重连（第 2 次）',
  offline: '设备已断开网络',
  sessionExpired: '登录凭证已过期，需要重新登录',
  kicked: '账号已在另一台设备登录，本设备已下线',
  sdkUnready: '客户端正在初始化，暂不可操作',
};
const state = ref('offline');
const busy = ref(false);
const withDiagnostics = ref(true);
const last = ref('尚未操作');
const diagnostics = 'transport=QUIC endpoint=quic://gateway.flare.example.com:60443\nclose=1006 reason=abnormal-closure\nretry=2/5 backoff=4s\nlast_seq=18234 pending_ack=3';

function run(name) {
  last.value = `${name} · busy 已同步置位`;
  busy.value = true;
  setTimeout(() => { busy.value = false; if (name === 'reconnect') state.value = 'connected'; if (name === 'reauth') state.value = 'connecting'; }, 1200);
}
</script>

<template>
  <DemoStage>
    <div class="cd-demo">
      <FlareConnectionDetails
        :state="state"
        transport="QUIC"
        endpoint="quic://gateway.flare.example.com:60443/v1/session/7f3c9a2e-very-long-path-segment"
        last-sync-at="今天 14:32"
        :reason="reasons[state]"
        :diagnostics="withDiagnostics ? diagnostics : undefined"
        :busy="busy"
        has-reconnect
        has-reauth
        @reconnect="run('reconnect')"
        @reauth="run('reauth')"
        @copy-diagnostics="last = 'copyDiagnostics · 宿主负责写入剪贴板'"
      />
      <div class="controls" role="group" aria-label="切换状态">
        <button v-for="s in states" :key="s" type="button" :aria-pressed="state === s" :class="{ active: state === s }" @click="state = s">{{ s }}</button>
      </div>
      <div class="controls">
        <button type="button" @click="busy = !busy">{{ busy ? '结束 busy' : '模拟 busy' }}</button>
        <button type="button" @click="withDiagnostics = !withDiagnostics">{{ withDiagnostics ? '清空诊断信息' : '提供诊断信息' }}</button>
      </div>
      <p role="status">{{ last }}。本地模拟，不发起任何网络请求。</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.cd-demo { width: 100%; max-width: 520px; min-width: 0; display: grid; gap: 16px; }
.controls { display: flex; flex-wrap: wrap; gap: 8px; }
.controls button { min-height: 48px; padding: 8px 12px; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; background: var(--flare-color-bg-primary); color: var(--flare-color-text-primary); }
.controls button.active { border-color: var(--flare-color-primary); color: var(--flare-color-primary); }
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
