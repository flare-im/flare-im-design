---
title: ConfigProvider
---

# ConfigProvider

<p><span class="flare-tag">Layout</span></p>

> Global config — unify default control size/density at the root and drive language (locale) + theme (light/dark) switching; descendants read and switch via useFlareConfig().

## Preview

<div class="flare-demo flare-demo--stack">
  <ConfigProviderDemo />
</div>

<ComponentApi name="ConfigProvider" />

## Platform implementations

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareConfigProvider</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><span style='color:var(--vp-c-text-3)'>—</span></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><span style='color:var(--vp-c-text-3)'>—</span></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><span style='color:var(--vp-c-text-3)'>—</span></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div><p style='font-size:12px;color:var(--vp-c-text-3);margin-top:8px'>全局配置是 Web/宿主层能力;原生端通过各自的主题/环境(FlareColors/FlareSizes)配置。</p>
