<script setup>
import { computed, ref } from "vue";
import { useRoute } from "vitepress";
import spec from "../../../../spec/components.json";
import catalog from "../../../../spec/component-catalog.json";
import layers from "../../../../spec/component-layers.json";
import metadata from "../../../../spec/catalog-metadata.json";
import { curatedExamples } from "../../../scripts/examples.mjs";

const props = defineProps({ name: { type: String, required: true } });
const route = useRoute();
const en = computed(() => route.path.startsWith("/en"));
const loc = computed(() => (en.value ? "en" : "zh"));
const t = (zh, english) => (en.value ? english : zh);
const entry = computed(() => spec.components.find((component) => component.name === props.name));
const catalogEntry = computed(() => catalog.components.find((component) => component.name === props.name));
const docsSections = computed(() => catalogEntry.value?.docsSections ?? {});
const override = computed(() => metadata.overrides?.[props.name] ?? {});
const layer = computed(() => layers.components[props.name]);
const examples = computed(() => curatedExamples[props.name] ?? []);
const selectedPlatform = ref("vue");
const copied = ref(false);

const capabilityKeys = [
  "supportsConfiguration",
  "supportsCustomActions",
  "supportsCustomContent",
  "supportsSlots",
  "supportsCapabilities",
  "supportsDensity",
  "supportsResponsive",
];
const capabilities = computed(() => capabilityKeys
  .map((key) => ({ key, value: catalogEntry.value?.[key] ?? entry.value?.[key] ?? false }))
  .filter((item) => item.value));
const summary = computed(() => entry.value?.summary?.[loc.value] ?? entry.value?.summary?.en ?? "");
const dataSource = computed(() => entry.value?.dataSource?.[loc.value] ?? entry.value?.dataSource?.en ?? "");
const status = computed(() => override.value.status ?? metadata.defaultStatus);
const packageNames = computed(() => [...new Set(Object.values(entry.value?.platforms ?? {}).map((platform) => platform.package))]);
const slug = (name) => name.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
const componentBase = computed(() => (en.value ? "/en/components" : "/components"));
const platformRows = computed(() => [
  { label: "Vue", key: "vue", note: t("网站仅运行 Vue 公共组件，并继承文档站主题。", "The website runs only the public Vue component and inherits the documentation theme.") },
  { label: "Flutter", key: "flutter", note: t("这里只记录 Widget 与 Semantics，不在网页模拟原生截图。", "This page documents widgets and Semantics; it does not simulate native screenshots.") },
  { label: "Android Compose", key: "compose", note: t("这里只记录 Compose API 与语义，不在网页模拟原生截图。", "This page documents Compose APIs and semantics; it does not simulate native screenshots.") },
  { label: "SwiftUI", key: "ios", note: t("这里只记录 SwiftUI API、Dynamic Type 与语义，不在网页模拟原生截图。", "This page documents SwiftUI APIs, Dynamic Type, and semantics; it does not simulate native screenshots.") },
].map((row) => ({ ...row, value: catalogEntry.value?.platforms?.[row.key] })));
const availablePlatforms = computed(() => platformRows.value.filter((row) => row.value?.support === "supported"));
const platformStatusLabel = (support) => ({
  supported: t("支持", "Supported"),
  partial: t("部分支持", "Partial"),
  "not-applicable": "N/A",
}[support] ?? "N/A");
const related = computed(() => spec.components
  .filter((component) => component.category === entry.value?.category && component.name !== props.name)
  .slice(0, 6));
const navigationComponents = computed(() => catalog.components.filter((component) => component.status !== "internal"));
const navigationIndex = computed(() => navigationComponents.value.findIndex((component) => component.name === props.name));
const previousComponent = computed(() => navigationComponents.value[navigationIndex.value - 1] ?? null);
const nextComponent = computed(() => navigationComponents.value[navigationIndex.value + 1] ?? null);
const variants = computed(() => catalogEntry.value?.docExamples?.variants ?? []);
const documentedStates = computed(() => catalogEntry.value?.docExamples?.states ?? entry.value?.states ?? []);
const boundary = computed(() => layer.value === "general-ui"
  ? t("不要传入 Message、Conversation 或 SDK 对象。领域映射留在宿主或 IM UI 层。", "Do not pass Message, Conversation, or SDK objects. Keep domain mapping in the host or IM UI layer.")
  : t("不要在组件中实现发送、权限、持久化或同步规则。组件表达状态并发出意图。", "Do not implement sending, permission, persistence, or sync rules in the component. It presents state and emits intent."));
const responsive = computed(() => {
  if (catalogEntry.value?.previewMode === "workspace") {
    return t("宽屏保留任务上下文并使用多窗格；紧凑宽度依据容器收敛为单窗格、覆盖层或独立路由。预览使用真实容器宽度，不做 CSS 缩放。", "Wide containers retain task context with multiple panes; compact containers reduce to one pane, an overlay, or a route. The preview uses real container widths without CSS scaling.");
  }
  return t("内容宽度由容器决定；长文本换行，操作区保持触控目标，软键盘和安全区不能遮挡当前任务。", "The container owns content width; long text wraps, controls retain touch targets, and keyboards or safe areas never obscure the active task.");
});
const tokenNames = computed(() => {
  const names = ["--flare-color-bg-primary", "--flare-color-text-primary", "--flare-color-border-primary", "--flare-color-focus-ring", "--flare-size-layout-touch-target"];
  if (entry.value?.category === "Message") names.push("--flare-color-message-incoming-background", "--flare-color-message-outgoing-background", "--flare-color-message-status-read");
  if (["Layout", "Patterns", "Workspaces", "AppKit"].includes(entry.value?.category)) names.push("--flare-size-layout-primary-pane-default-width", "--flare-size-layout-detail-pane-default-width");
  return names;
});
const stateDescription = (state) => ({
  loading: t("保留布局骨架并宣布忙碌状态。", "Preserves layout while announcing busy state."),
  empty: t("解释空结果并保留下一步操作。", "Explains the empty result and retains a next action."),
  error: t("错误就地出现，并提供恢复路径。", "Shows the error in place with a recovery path."),
  disabled: t("保留上下文，阻止操作并说明原因。", "Retains context, blocks action, and exposes the reason."),
  offline: t("保留草稿与失败操作，等待宿主重试。", "Retains drafts and failed actions for host recovery."),
  uploading: t("展示进度，不锁死其余会话。", "Shows progress without freezing the conversation."),
}[state] ?? t("这是由宿主显式传入并可验证的视觉状态。", "This is an explicit, host-driven, testable visual state."));

function placeholder(type, platform) {
  const value = String(type);
  if (value.includes("[]")) return "[]";
  if (/boolean/.test(value)) return "false";
  if (/number/.test(value)) return "0";
  if (/string/.test(value)) return "\"\"";
  const literal = value.match(/'([^']+)'/);
  if (literal) return "\"" + literal[1] + "\"";
  return platform === "flutter" ? "const {}" : "{}";
}

const code = computed(() => {
  const curated = examples.value.find((example) => example[selectedPlatform.value]);
  if (curated) return curated[selectedPlatform.value];
  const symbol = catalogEntry.value?.platforms?.[selectedPlatform.value]?.symbol ?? props.name;
  const required = (entry.value?.props ?? []).filter((prop) => prop.required);
  if (selectedPlatform.value === "vue") {
    const declarations = required.map((prop) => "const " + prop.name.replace(/[^a-zA-Z0-9_$]/g, "_") + " = " + placeholder(prop.type, "vue") + ";").join("\n");
    const attrs = required.map((prop) => "  :" + prop.name + "=\"" + prop.name.replace(/[^a-zA-Z0-9_$]/g, "_") + "\"").join("\n");
    return "<script setup>\nimport { " + symbol + " } from \"@flare-im/vue-ui\";" + (declarations ? "\n\n" + declarations : "") + "\n<\/script>\n\n<template>\n  <" + symbol + (attrs ? "\n" + attrs + "\n" : " ") + "/>\n</template>";
  }
  if (selectedPlatform.value === "flutter") {
    const args = required.map((prop) => "  " + prop.name + ": " + placeholder(prop.type, "flutter") + ",").join("\n");
    return "import 'package:flare_im_ui/flare_im_ui.dart';\n\n" + symbol + "(\n" + args + "\n);";
  }
  if (selectedPlatform.value === "compose") {
    const args = required.map((prop) => "  " + prop.name + " = " + placeholder(prop.type, "compose") + ",").join("\n");
    return "import com.flare.im.ui." + symbol + "\n\n" + symbol + "(\n" + args + "\n)";
  }
  const args = required.map((prop) => prop.name + ": " + placeholder(prop.type, "ios")).join(", ");
  return "import FlareIMUI\n\n" + symbol + "(" + args + ")";
});
const language = computed(() => ({ vue: "vue", flutter: "dart", compose: "kotlin", ios: "swift" })[selectedPlatform.value]);

async function copyCode() {
  if (typeof navigator === "undefined" || !navigator.clipboard) return;
  await navigator.clipboard.writeText(code.value);
  copied.value = true;
  window.setTimeout(() => { copied.value = false; }, 1400);
}
</script>

<template>
  <article v-if="entry" class="reference">
    <p class="reference__lead">{{ summary }}</p>
    <dl class="reference__meta" aria-label="Component metadata">
      <div><dt>{{ t("状态", "Status") }}</dt><dd :data-status="status">{{ status }}</dd></div>
      <div><dt>{{ t("包", "Package") }}</dt><dd><code>{{ packageNames.join(" · ") }}</code></dd></div>
      <div><dt>{{ t("平台", "Platforms") }}</dt><dd class="reference__platform-summary"><span v-for="item in platformRows" :key="item.key" :data-support="item.value?.support ?? 'not-applicable'">{{ item.label }} {{ platformStatusLabel(item.value?.support) }}</span></dd></div>
      <div><dt>{{ t("始于", "Since") }}</dt><dd>{{ override.since ?? metadata.defaultSince }}</dd></div>
    </dl>

    <section><h2 id="preview">{{ t("预览", "Preview") }}</h2><ComponentPreview :name="name" /></section>

    <section>
      <h2 id="usage">{{ t("用法", "Usage") }}</h2>
      <div class="reference__code-tabs" role="tablist" :aria-label="t('平台代码', 'Platform code')">
        <button v-for="item in availablePlatforms" :key="item.key" type="button" role="tab" :aria-selected="selectedPlatform === item.key" @click="selectedPlatform = item.key">{{ item.label }}</button>
      </div>
      <div class="reference__code">
        <button type="button" class="reference__copy" @click="copyCode">{{ copied ? t("已复制", "Copied") : t("复制", "Copy") }}</button>
        <pre :data-language="language"><code>{{ code }}</code></pre>
      </div>
      <p class="reference__copy-status" aria-live="polite">{{ copied ? t("代码已复制到剪贴板。", "Code copied to the clipboard.") : "" }}</p>
    </section>

    <section>
      <h2 id="examples">{{ t("示例", "Examples") }}</h2>
      <ComposerCustomMenuDemo v-if="name === 'Composer'" />
      <div v-if="examples.length" class="reference__example-list">
        <div v-for="example in examples" :key="example.title?.en ?? example.title">
          <h3>{{ example.title?.[loc] ?? example.title?.en ?? example.title }}</h3>
          <p>{{ example.description?.[loc] ?? example.description?.en ?? example.description }}</p>
          <pre v-if="example[selectedPlatform]" :data-language="language"><code>{{ example[selectedPlatform] }}</code></pre>
        </div>
      </div>
      <p v-else>{{ t("上方示例直接运行公开 Vue 组件；复杂组合请参阅 Customization 与 Recipes。", "The example above runs the public Vue component directly; see Customization and Recipes for composed cases.") }}</p>
    </section>

    <section v-if="docsSections.configuration">
      <h2 id="configuration">{{ t("配置", "Configuration") }}</h2>
      <p><strong>{{ t("数据源", "Data source") }}:</strong> {{ dataSource }}</p>
      <p><strong>{{ t("边界", "Boundary") }}:</strong> {{ boundary }}</p>
      <p v-if="name === 'Composer'">{{ t("动作按 Defaults → Capabilities → Host Configuration 解析。默认仅包含图片、文件、语音、位置与联系人；宿主可以隐藏、禁用、重排、替换或追加动作。", "Actions resolve through Defaults → Capabilities → Host Configuration. Defaults contain only Image, File, Voice, Location, and Contact; hosts may hide, disable, reorder, replace, or append actions.") }}</p>
      <p v-if="name === 'ConversationHeader'">{{ t("动作按 Preset → Host Overrides / Additions → Capabilities / Visibility → Stable Order 解析。Plus 只承载 placement=add 的宿主意图；窄屏把超出主动作上限的项目移入 More。", "Actions resolve through Preset → Host Overrides / Additions → Capabilities / Visibility → Stable Order. Plus contains only host intents with placement=add; narrow containers move excess primary actions into More.") }}</p>
      <div class="reference__capabilities" aria-label="Capabilities">
        <code v-for="item in capabilities" :key="item.key">{{ item.key }}</code>
      </div>
      <h3 v-if="docsSections.slots">{{ t("Slots / Builders", "Slots / Builders") }}</h3>
      <p v-if="docsSections.slots">{{ t("扩展点只覆盖 Header、Footer、Leading、Trailing、Empty、Loading、Error 与内容渲染等稳定区域。", "Extension points cover stable regions such as Header, Footer, Leading, Trailing, Empty, Loading, Error, and content rendering.") }}</p>
      <h3 v-if="docsSections.customization">{{ t("高级覆盖", "Advanced overrides") }}</h3>
      <p v-if="docsSections.customization">{{ t("先使用库默认值，再按 capabilities、host configuration 和定向扩展点覆盖。简单模式无需构造巨型配置对象。", "Start with library defaults, then override through capabilities, host configuration, and targeted extension points. Simple mode does not require a large configuration object.") }}</p>
    </section>

    <section v-if="docsSections.variants">
      <h2 id="variants">{{ t("变体", "Variants") }}</h2>
      <div class="reference__variant-list"><div v-for="variant in variants" :key="variant.name"><strong>{{ variant.name }}</strong><span v-for="value in variant.values" :key="value"><code>{{ value }}</code></span></div></div>
    </section>

    <section v-if="docsSections.density">
      <h2 id="density">{{ t("密度", "Density") }}</h2>
      <div class="reference__density" role="list">
        <div v-for="item in ['comfortable', 'default', 'compact']" :key="item" role="listitem" :data-density="item"><span>{{ item }}</span><i aria-hidden="true"></i><i aria-hidden="true"></i><i aria-hidden="true"></i></div>
      </div>
      <p>{{ t("密度只改变信息间距，不缩小可读字号、焦点轮廓或触控目标。", "Density changes information spacing without reducing readable type, focus rings, or touch targets.") }}</p>
    </section>

    <section v-if="docsSections.states">
      <h2 id="states">{{ t("状态", "States") }}</h2>
      <div class="reference__state-grid" role="list">
        <div v-for="item in documentedStates" :key="item" role="listitem"><span class="reference__state-sample"><i aria-hidden="true"></i><strong>{{ item }}</strong></span><span>{{ stateDescription(item) }}</span></div>
      </div>
    </section>

    <section v-if="docsSections.interaction">
      <h2 id="interaction">{{ t("交互", "Interaction") }}</h2>
      <p>{{ t("宿主传入受控状态并处理意图事件；组件不发起网络请求，也不复制领域状态。错误和离线状态必须保留恢复路径。", "The host supplies controlled state and handles intent events. The component does not start network requests or duplicate domain state. Error and offline states retain a recovery path.") }}</p>
      <p v-if="entry.events?.length"><code v-for="event in entry.events" :key="event" class="reference__event">{{ event }}</code></p>
    </section>

    <section v-if="docsSections.responsive"><h2 id="responsive">{{ t("响应式", "Responsive") }}</h2><p>{{ responsive }}</p></section>

    <section>
      <h2 id="accessibility">{{ t("可访问性", "Accessibility") }}</h2>
      <dl class="reference__a11y">
        <div><dt>Role</dt><dd><code>{{ entry.accessibility?.role ?? "group" }}</code></dd></div>
        <div><dt>{{ t("焦点", "Focus") }}</dt><dd>{{ entry.accessibility?.focusable ?? t("后代元素", "descendants") }}</dd></div>
        <div><dt>{{ t("触控目标", "Touch target") }}</dt><dd>{{ entry.accessibility?.touchTarget?.minWidth ?? 48 }} × {{ entry.accessibility?.touchTarget?.minHeight ?? 48 }} logical px</dd></div>
        <div><dt>{{ t("屏幕阅读器", "Screen reader") }}</dt><dd>{{ entry.accessibility?.screenReaderSemantics }}</dd></div>
        <div><dt>{{ t("减少动态效果", "Reduced motion") }}</dt><dd>{{ entry.accessibility?.reducedMotionBehavior }}</dd></div>
      </dl>
      <h3 v-if="docsSections.keyboard">{{ t("键盘", "Keyboard") }}</h3>
      <ul v-if="docsSections.keyboard"><li v-for="item in entry.accessibility.keyboardBehavior" :key="item">{{ item }}</li></ul>
    </section>

    <section>
      <h2 id="api">API</h2>
      <h3 id="props">Props</h3>
      <div class="reference__table-wrap"><table><thead><tr><th>Name</th><th>Type</th><th>{{ t("必填", "Required") }}</th><th>{{ t("说明", "Description") }}</th></tr></thead><tbody>
        <tr v-for="prop in entry.props ?? []" :key="prop.name"><td><code>{{ prop.name }}</code></td><td><code>{{ prop.type }}</code></td><td>{{ prop.required ? t("是", "Yes") : t("否", "No") }}</td><td>{{ prop.description?.[loc] ?? prop.description?.en ?? "" }}</td></tr>
        <tr v-if="!entry.props?.length"><td colspan="4">{{ t("无公开 Props", "No public props") }}</td></tr>
      </tbody></table></div>
      <template v-if="entry.events?.length">
        <h3 id="events">Events</h3>
        <p class="reference__event-list"><code v-for="event in entry.events" :key="event">{{ event }}</code></p>
      </template>
    </section>

    <section>
      <h2 id="tokens">Tokens</h2>
      <p>{{ t("只通过 semantic 或 component token 扩展视觉。", "Extend visuals only through semantic or component tokens.") }}</p>
      <p class="reference__token-list"><code v-for="token in tokenNames" :key="token">{{ token }}</code></p>
      <p><a :href="en ? '/en/foundations/token-explorer' : '/foundations/token-explorer'">{{ t("打开 Token Explorer", "Open Token Explorer") }}</a></p>
    </section>

    <section>
      <h2 id="platform-differences">{{ t("平台差异", "Platform Differences") }}</h2>
      <div class="reference__table-wrap"><table><thead><tr><th>{{ t("平台", "Platform") }}</th><th>{{ t("公开符号", "Public symbol") }}</th><th>{{ t("实现说明", "Implementation note") }}</th></tr></thead><tbody>
        <tr v-for="item in platformRows" :key="item.key"><td>{{ item.label }}</td><td><code v-if="item.value?.symbol">{{ item.value.symbol }}</code><span v-else>{{ t("不适用", "Not applicable") }}</span></td><td>{{ item.note }}</td></tr>
      </tbody></table></div>
    </section>

    <section><h2 id="related">{{ t("相关组件", "Related") }}</h2><p class="reference__links"><a v-for="component in related" :key="component.name" :href="componentBase + '/' + slug(component.name)">{{ component.name }}</a></p></section>

    <section>
      <h2 id="source-of-truth">{{ t("事实来源", "Source of Truth") }}</h2>
      <p><code>{{ catalogEntry?.sourceOfTruth }}</code></p>
      <dl class="reference__sources"><div v-for="(path, platformKey) in catalogEntry?.sourcePaths" :key="platformKey"><dt>{{ platformKey }}</dt><dd><code>{{ path }}</code></dd></div></dl>
    </section>

    <section>
      <h2 id="validation">{{ t("验证", "Validation") }}</h2>
      <p>{{ t("发布门禁校验公开签名、文档覆盖、token 使用、可访问性契约和四端测试。网页预览只承担 Vue 行为验证；原生视觉由各平台测试工程负责。", "Release gates verify public signatures, documentation coverage, token usage, accessibility contracts, and all four platform test suites. The website validates Vue behavior only; native visuals remain in platform test projects.") }}</p>
    </section>

    <nav class="reference__pager" :aria-label="t('组件导航', 'Component navigation')">
      <a v-if="previousComponent" :href="componentBase + '/' + previousComponent.slug" rel="prev"><small>{{ t("上一个", "Previous") }}</small><strong>{{ previousComponent.name }}</strong></a>
      <span v-else></span>
      <a v-if="nextComponent" :href="componentBase + '/' + nextComponent.slug" rel="next"><small>{{ t("下一个", "Next") }}</small><strong>{{ nextComponent.name }}</strong></a>
    </nav>
  </article>
</template>

<style scoped>
.reference { margin-top: 10px; }
.reference section { margin-top: 34px; }
.reference__lead { margin-top: 14px; color: var(--vp-c-text-1); font-size: 17px; line-height: 1.65; }
.reference__meta { display: grid; grid-template-columns: 0.7fr minmax(220px, 1.8fr) 1.3fr 0.7fr; margin: 18px 0 28px; border-block: 1px solid var(--vp-c-divider); }
.reference__meta div { min-width: 0; padding: 11px 14px 11px 0; }
.reference__meta dt,
.reference__a11y dt,
.reference__sources dt { color: var(--vp-c-text-3); font-size: 11px; text-transform: uppercase; }
.reference__meta dd,
.reference__a11y dd,
.reference__sources dd { margin: 4px 0 0; overflow-wrap: anywhere; color: var(--vp-c-text-1); font-size: 13px; }
.reference__meta dd[data-status="stable"] { color: var(--flare-color-success-text, #15803d); font-weight: 650; }
.reference__platform-summary { display: flex; flex-wrap: wrap; gap: 4px 10px; }
.reference__platform-summary span { white-space: nowrap; }
.reference__platform-summary span[data-support="not-applicable"] { color: var(--vp-c-text-3); }
.reference__table-wrap { overflow-x: auto; }
.reference table { width: 100%; border-collapse: collapse; font-size: 13px; }
.reference th,
.reference td { padding: 9px 10px; border-bottom: 1px solid var(--vp-c-divider); text-align: start; vertical-align: top; }
.reference th { color: var(--vp-c-text-2); font-size: 11px; text-transform: uppercase; }
.reference__capabilities,
.reference__token-list,
.reference__links { display: flex; flex-wrap: wrap; gap: 8px 16px; }
.reference__capabilities code { padding: 3px 7px; border: 1px solid var(--vp-c-divider); border-radius: 4px; background: var(--vp-c-bg-soft); }
.reference__example-list > div { min-width: 0; padding: 14px 0; border-bottom: 1px solid var(--vp-c-divider); }
.reference__composer-example { margin-bottom: 20px; }
.reference__example-list h3 { margin: 0 0 5px; font-size: 15px; }
.reference__example-list p { margin: 0; }
.reference__example-list pre { box-sizing: border-box; width: 100%; max-width: 100%; overflow: auto; }
.reference__variant-list { border-top: 1px solid var(--vp-c-divider); }
.reference__variant-list > div { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; min-height: 48px; border-bottom: 1px solid var(--vp-c-divider); }
.reference__variant-list strong { min-width: 120px; font-size: 13px; }
.reference__variant-list code { font-size: 11px; }
.reference__density { display: grid; gap: 8px; }
.reference__density > div { display: flex; align-items: center; gap: 8px; border-bottom: 1px solid var(--vp-c-divider); }
.reference__density span { width: 92px; color: var(--vp-c-text-2); font-family: var(--vp-font-family-mono); font-size: 11px; }
.reference__density i { width: 48px; border-radius: 3px; background: var(--vp-c-bg-soft); }
.reference__density [data-density="comfortable"] { min-height: 56px; }
.reference__density [data-density="comfortable"] i { height: 36px; }
.reference__density [data-density="default"] { min-height: 48px; }
.reference__density [data-density="default"] i { height: 32px; }
.reference__density [data-density="compact"] { min-height: 40px; }
.reference__density [data-density="compact"] i { height: 26px; }
.reference__state-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); border-top: 1px solid var(--vp-c-divider); }
.reference__state-grid > div { display: grid; gap: 5px; min-height: 88px; padding: 13px 14px 13px 0; border-bottom: 1px solid var(--vp-c-divider); }
.reference__state-grid strong { font-family: var(--vp-font-family-mono); font-size: 12px; }
.reference__state-grid span { color: var(--vp-c-text-2); font-size: 12px; line-height: 1.5; }
.reference__state-sample { display: inline-flex; align-items: center; gap: 7px; color: var(--vp-c-text-1) !important; }
.reference__state-sample i { width: 7px; height: 7px; border-radius: 50%; background: var(--vp-c-brand-1); }
.reference__code-tabs { display: flex; overflow-x: auto; border-bottom: 1px solid var(--vp-c-divider); }
.reference__code-tabs button { min-height: 38px; padding: 7px 13px; border: 0; border-bottom: 2px solid transparent; color: var(--vp-c-text-2); background: transparent; font: inherit; font-size: 12px; cursor: pointer; }
.reference__code-tabs button[aria-selected="true"] { border-bottom-color: var(--vp-c-brand-1); color: var(--vp-c-brand-1); font-weight: 650; }
.reference__code { position: relative; }
.reference__code pre { max-height: 460px; margin: 0; padding: 18px; overflow: auto; border-radius: 0 0 6px 6px; background: var(--vp-code-block-bg); font-size: 12px; line-height: 1.6; }
.reference__copy { position: absolute; top: 9px; right: 9px; z-index: 1; min-height: 32px; padding: 5px 9px; border: 1px solid var(--vp-c-divider); border-radius: 4px; color: var(--vp-c-text-2); background: var(--vp-c-bg); font: inherit; font-size: 11px; cursor: pointer; }
.reference__copy-status { min-height: 18px; margin: 3px 0 0; color: var(--vp-c-text-3); font-size: 11px; }
.reference__event { display: inline-block; margin: 0 8px 8px 0; }
.reference__event-list { display: flex; flex-wrap: wrap; gap: 8px; }
.reference__a11y,
.reference__sources { display: grid; grid-template-columns: 1fr 1fr; margin: 0; border-top: 1px solid var(--vp-c-divider); }
.reference__a11y div,
.reference__sources div { min-width: 0; padding: 11px 14px 11px 0; border-bottom: 1px solid var(--vp-c-divider); }
.reference__pager { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-top: 44px; padding-top: 18px; border-top: 1px solid var(--vp-c-divider); }
.reference__pager a { display: grid; gap: 4px; min-width: 0; padding: 10px 0; color: var(--vp-c-text-1); text-decoration: none; }
.reference__pager a:last-child { text-align: end; }
.reference__pager small { color: var(--vp-c-text-3); font-size: 11px; text-transform: uppercase; }
.reference__pager strong { overflow-wrap: anywhere; font-size: 14px; }
.reference__pager a:hover strong { color: var(--vp-c-brand-1); }
button:focus-visible,
a:focus-visible { outline: 2px solid var(--vp-c-brand-1); outline-offset: 2px; }
@media (max-width: 760px) {
  .reference__meta,
  .reference__a11y,
  .reference__sources { grid-template-columns: 1fr; }
}
</style>
