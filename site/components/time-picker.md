---
title: TimePicker
---

# TimePicker

<p><span class="flare-tag">表单</span></p>

> 时间选择器 —— 自适应:PC 为锚定 popover(时/分列),App/H5 为底部 Sheet;v-model 取 "HH:mm"。

## 预览

下面同屏并列展示两种形态:左侧 PC 打开是下拉面板,右侧手机框里打开是底部 Sheet(Sheet 被裁在手机框内)。

<div class="flare-demo flare-demo--stack">
  <TimePickerDemo />
</div>

<ComponentApi name="TimePicker" />

## 各端实现

<div class="flare-platform-grid">
  <div class="flare-platform-card"><h4>Vue</h4><div><code>FlareTimePicker</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare-core-vue-im-ui</div></div>
  <div class="flare-platform-card"><h4>Flutter</h4><div><code>FlareTimePicker</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">flare_im_ui</div></div>
  <div class="flare-platform-card"><h4>iOS</h4><div><code>TimePickerView</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">FlareIMUI</div></div>
  <div class="flare-platform-card"><h4>Android · Compose</h4><div><code>TimePicker</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">com.flare.im:im-ui-compose</div></div>
</div>
