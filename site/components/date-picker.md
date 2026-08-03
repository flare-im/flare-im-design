---
title: DatePicker
---

# DatePicker

<p><span class="flare-tag">表单</span></p>

> 日期选择器 —— 自适应:PC 为锚定 popover(月历),App/H5 为底部 Sheet;v-model 取 "YYYY-MM-DD",支持 min/max。

## 预览

同屏并列展示两种形态:左侧 PC 打开是月历下拉,右侧手机框里打开是底部 Sheet(裁在框内)。

<div class="flare-demo flare-demo--stack">
  <DatePickerDemo />
</div>

<ComponentApi name="DatePicker" />

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareDatePicker</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">@flare-im/vue-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareDatePicker</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>DatePickerView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>DatePicker</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>
