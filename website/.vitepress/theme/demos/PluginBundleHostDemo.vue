<script setup>
import { onBeforeUnmount, onMounted, ref } from "vue";
import { FlarePluginBundleHost } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// A plugin web bundle in the kit's sandboxed frame. In an app the files come from the sandbox domain and the engine
// answers the bridge; here a tiny page is made in the browser and a local bridge answers it: the greeting, one query,
// and a toast the kit draws.
const PAGE = `<!doctype html><meta charset="utf-8"><style>
body{margin:0;padding:16px;font:14px/1.5 system-ui,sans-serif;color:#1f2329}
li{padding:6px 0;border-bottom:1px solid #e5e6eb;list-style:none}ul{margin:0 0 12px;padding:0}
button{padding:6px 14px;border-radius:6px;border:0;background:#3370ff;color:#fff;font:inherit}
<\/style><ul id="list"><li>…</li></ul><button id="publish">发布公告</button><script>
let seq=0;const pending=new Map();
function call(method,params){const id="d"+(++seq);parent.postMessage({bridge:1,id,type:"request",method,params:params||{}},"*");
return new Promise((resolve,reject)=>pending.set(id,{resolve,reject}));}
addEventListener("message",(e)=>{if(e.source!==parent)return;const m=e.data;const p=pending.get(m&&m.id);if(!p)return;
pending.delete(m.id);m.error?p.reject(m.error):p.resolve(m.result);});
(async()=>{await call("host.hello");const data=await call("plugin.query",{operation:"example.notice.list",input:{}});
const list=document.getElementById("list");list.textContent="";for(const item of data.items){const li=document.createElement("li");
li.textContent=item.title;list.appendChild(li);}})();
document.getElementById("publish").onclick=()=>call("ui.toast",{message:"已发布",kind:"success"});
<\/script>`;

const files = ref("");
const log = ref("");
const bridge = {
  async request(envelope) {
    const answer = (result) => ({ bridge: 1, id: envelope.id, type: "response", result });
    log.value = envelope.method;
    switch (envelope.method) {
      case "host.hello":
        return answer({
          bridge: 1, pluginId: "example.notice", version: "1.0.0", contributionId: "example.notice.board",
          route: "/", locale: "zh-CN", theme: { mode: "light", tokens: {} }, presentation: "page",
          permissions: ["plugin.query"], capabilities: [],
        });
      case "plugin.query":
        return answer({ items: [{ title: "周五下午全员会议" }, { title: "新版考勤制度上线" }] });
      case "ui.toast":
        return { host: { id: envelope.id, method: "ui.toast", params: envelope.params } };
      default:
        return { bridge: 1, id: envelope.id, type: "response", error: { code: "method_not_found", messageKey: "plugin.bridge.methodNotFound", retryable: false } };
    }
  },
};

onMounted(() => {
  files.value = URL.createObjectURL(new Blob([PAGE], { type: "text/html" }));
});
onBeforeUnmount(() => {
  if (files.value) URL.revokeObjectURL(files.value);
});
</script>
<template>
  <DemoStage>
    <div class="frame">
      <FlarePluginBundleHost v-if="files" :files="files" :bridge="bridge" title="公告" presentation="detail" />
    </div>
    <p v-if="log" class="log">{{ log }}</p>
  </DemoStage>
</template>
<style scoped>
.frame { height: 240px; border: 1px solid var(--flare-color-border-primary); border-radius: var(--flare-size-radius-md); overflow: hidden; }
.log { margin: 12px 0 0; color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }
</style>
