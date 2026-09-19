import { defineConfig } from "vitepress";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { flareImUiAssets } from "../../tooling/vite/flare-im-ui-assets.mjs";

const here = dirname(fileURLToPath(import.meta.url));

const spec = JSON.parse(
  readFileSync(join(here, "../../spec/components.json"), "utf8"),
);

const slug = (name: string) =>
  name.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();

const catLabel = (cat: string, loc: "zh" | "en") =>
  spec.categoryLabels?.[cat]?.[loc] ?? cat;

const byCat: Record<string, { name: string; category: string }[]> = {};
for (const c of spec.components) (byCat[c.category] ??= []).push(c);

const layers = JSON.parse(readFileSync(join(here, "../../spec/component-layers.json"), "utf8")).components;
const dataDisplayNames = new Set(["Avatar", "Icon", "Rating"]);
const mediaPreviewNames = new Set(["ImagePreviewModal", "VideoPlayerModal", "MarkdownPreview"]);
const groupNames = new Set([
  "GroupDetail", "GroupList", "GroupMemberGrid", "GroupPermissionMatrix", "MemberRoleSheet", "MemberPanel",
]);

const sidebarItems = (names: string[], prefix: string) => names.map((name) => ({ text: name, link: `${prefix}/components/${slug(name)}` }));
const namesWhere = (predicate: (component: any) => boolean) => spec.components.filter(predicate).map((component: any) => component.name);

/** Productized component sidebar. Categories are presentation IA; architecture remains spec-owned. */
const componentSidebar = (loc: "zh" | "en", prefix: string) => {
  const general = [
    ["General", namesWhere((c) => layers[c.name] === "general-ui" && c.category === "General" && !dataDisplayNames.has(c.name))],
    ["Layout", namesWhere((c) => layers[c.name] === "general-ui" && c.category === "Layout")],
    ["Navigation", namesWhere((c) => layers[c.name] === "general-ui" && c.category === "Navigation")],
    ["Form", namesWhere((c) => layers[c.name] === "general-ui" && c.category === "Form" && !dataDisplayNames.has(c.name))],
    ["Data Display", namesWhere((c) => dataDisplayNames.has(c.name))],
    ["Feedback", namesWhere((c) => layers[c.name] === "general-ui" && c.category === "Feedback")],
    ["Overlay", namesWhere((c) => layers[c.name] === "general-ui" && c.category === "Overlay")],
    ["Media", namesWhere((c) => mediaPreviewNames.has(c.name))],
  ];
  const im = [
    ["Conversation", namesWhere((c) => layers[c.name] === "im-ui" && c.category === "Conversation")],
    ["Message", namesWhere((c) => layers[c.name] === "im-ui" && c.category === "Message")],
    ["Composer", namesWhere((c) => layers[c.name] === "im-ui" && c.category === "Composer")],
    ["Media", namesWhere((c) => layers[c.name] === "im-ui" && c.category === "Media" && !mediaPreviewNames.has(c.name))],
    ["Contacts", namesWhere((c) => layers[c.name] === "im-ui" && c.category === "Contacts" && !groupNames.has(c.name))],
    ["Group", namesWhere((c) => groupNames.has(c.name))],
    ["Call", namesWhere((c) => layers[c.name] === "im-ui" && c.category === "Call")],
    ["Profile", namesWhere((c) => layers[c.name] === "im-ui" && c.category === "Profile")],
    ["Moments", namesWhere((c) => layers[c.name] === "im-ui" && c.category === "Moments")],
  ];
  const group = (text: string, sections: (string | string[])[][]) => ({
    text,
    collapsed: false,
    items: sections.map(([section, names]) => ({ text: section as string, collapsed: true, items: sidebarItems(names as string[], prefix) })),
  });
  return [
    { text: "Foundations", collapsed: true, items: [
      { text: loc === "zh" ? "设计基础" : "Overview", link: `${prefix}/foundations/` },
      { text: "Token Explorer", link: `${prefix}/foundations/token-explorer` },
      { text: "Accessibility", link: `${prefix}/guide/accessibility` },
    ] },
    group(loc === "zh" ? "通用组件" : "General Components", general),
    group(loc === "zh" ? "IM 组件" : "IM Components", im),
    { text: "Patterns", collapsed: true, items: sidebarItems(namesWhere((c) => layers[c.name] === "patterns"), prefix) },
    { text: "App Kit", collapsed: true, items: sidebarItems(namesWhere((c) => ["workspaces", "appkit"].includes(layers[c.name])), prefix) },
    { text: loc === "zh" ? "平台" : "Platforms", collapsed: true, items: [
      { text: "Vue", link: `${prefix}/platforms/vue` },
      { text: "Flutter", link: `${prefix}/platforms/flutter` },
      { text: "Android Compose", link: `${prefix}/platforms/compose` },
      { text: "SwiftUI", link: `${prefix}/platforms/swiftui` },
    ] },
  ];
};

const routeItems = (prefix: string, items: [string, string][]) =>
  items.map(([text, path]) => ({ text, link: `${prefix}${path}` }));

const zhSections = {
  guide: routeItems("", [
    ["介绍", "/guide/introduction"], ["快速开始", "/guide/getting-started"],
    ["安装", "/guide/install"], ["主题", "/guide/theming"], ["暗色模式", "/guide/dark-mode"],
    ["响应式", "/guide/responsive"], ["可访问性", "/guide/accessibility"], ["组件契约", "/guide/spec"],
  ]),
  foundations: routeItems("", [
    ["总览", "/foundations/"], ["Colors", "/foundations/colors"], ["Typography", "/foundations/typography"],
    ["Spacing", "/foundations/spacing"], ["Radius", "/foundations/radius"], ["Elevation", "/foundations/elevation"],
    ["Icons", "/foundations/icons"], ["Motion", "/foundations/motion"], ["Breakpoints", "/foundations/breakpoints"],
    ["Density", "/foundations/density"], ["Token Explorer", "/foundations/token-explorer"],
  ]),
  patterns: routeItems("", [
    ["总览", "/patterns/"], ["AppShell", "/patterns/app-shell"], ["Adaptive Layout", "/patterns/adaptive-layout"],
    ["DesktopAppShell", "/patterns/desktop-app-shell"], ["Conversation Workspace", "/patterns/conversation-workspace"],
    ["Chat Workspace", "/patterns/chat-workspace"], ["Thread Workspace", "/patterns/thread-workspace"],
    ["Search Workspace", "/patterns/search-workspace"], ["Settings Workspace", "/patterns/settings-workspace"],
  ]),
  platforms: routeItems("", [
    ["总览", "/platforms/"], ["Vue", "/platforms/vue"], ["Flutter", "/platforms/flutter"],
    ["Android Compose", "/platforms/compose"], ["SwiftUI", "/platforms/swiftui"],
    ["Desktop Guide", "/platforms/desktop"], ["Mobile Guide", "/platforms/mobile"],
  ]),
  resources: routeItems("", [
    ["总览", "/resources/"], ["Compatibility", "/resources/compatibility"], ["Migration", "/resources/migration"],
    ["Changelog", "/resources/changelog"], ["Contributing", "/resources/contributing"], ["Release", "/resources/release"],
  ]),
  customization: routeItems("", [
    ["总览", "/customization/"], ["Themes", "/customization/themes"],
    ["Capabilities", "/customization/capabilities"], ["Actions", "/customization/actions"],
    ["Slots / Builders", "/customization/slots-builders"], ["Custom Message", "/customization/custom-message"],
    ["Custom Navigation", "/customization/custom-navigation"], ["Custom Composer", "/customization/custom-composer"],
    ["Custom Empty/Error", "/customization/custom-empty-error"], ["AppKit Overrides", "/customization/app-kit-overrides"],
  ]),
};

const enSections = {
  guide: routeItems("/en", [
    ["Introduction", "/guide/introduction"], ["Getting started", "/guide/getting-started"],
    ["Installation", "/guide/install"], ["Theming", "/guide/theming"], ["Dark mode", "/guide/dark-mode"],
    ["Responsive", "/guide/responsive"], ["Accessibility", "/guide/accessibility"], ["Component contract", "/guide/spec"],
  ]),
  foundations: routeItems("/en", [
    ["Overview", "/foundations/"], ["Colors", "/foundations/colors"], ["Typography", "/foundations/typography"],
    ["Spacing", "/foundations/spacing"], ["Radius", "/foundations/radius"], ["Elevation", "/foundations/elevation"],
    ["Icons", "/foundations/icons"], ["Motion", "/foundations/motion"], ["Breakpoints", "/foundations/breakpoints"],
    ["Density", "/foundations/density"], ["Token Explorer", "/foundations/token-explorer"],
  ]),
  patterns: routeItems("/en", [
    ["Overview", "/patterns/"], ["AppShell", "/patterns/app-shell"], ["Adaptive Layout", "/patterns/adaptive-layout"],
    ["DesktopAppShell", "/patterns/desktop-app-shell"], ["Conversation Workspace", "/patterns/conversation-workspace"],
    ["Chat Workspace", "/patterns/chat-workspace"], ["Thread Workspace", "/patterns/thread-workspace"],
    ["Search Workspace", "/patterns/search-workspace"], ["Settings Workspace", "/patterns/settings-workspace"],
  ]),
  platforms: routeItems("/en", [
    ["Overview", "/platforms/"], ["Vue", "/platforms/vue"], ["Flutter", "/platforms/flutter"],
    ["Android Compose", "/platforms/compose"], ["SwiftUI", "/platforms/swiftui"],
    ["Desktop Guide", "/platforms/desktop"], ["Mobile Guide", "/platforms/mobile"],
  ]),
  resources: routeItems("/en", [
    ["Overview", "/resources/"], ["Compatibility", "/resources/compatibility"], ["Migration", "/resources/migration"],
    ["Changelog", "/resources/changelog"], ["Contributing", "/resources/contributing"], ["Release", "/resources/release"],
  ]),
  customization: routeItems("/en", [
    ["Overview", "/customization/"], ["Themes", "/customization/themes"],
    ["Capabilities", "/customization/capabilities"], ["Actions", "/customization/actions"],
    ["Slots / Builders", "/customization/slots-builders"], ["Custom Message", "/customization/custom-message"],
    ["Custom Navigation", "/customization/custom-navigation"], ["Custom Composer", "/customization/custom-composer"],
    ["Custom Empty/Error", "/customization/custom-empty-error"], ["AppKit Overrides", "/customization/app-kit-overrides"],
  ]),
};

export default defineConfig({
  title: "Flare UI",
  cleanUrls: true,
  appearance: true,
  srcExclude: ["test-results/**", "playwright-report/**"],
  vite: {
    // Emoji and sticker files under /flare-im-ui-assets/ for the kit's composer panel and message views.
    plugins: [flareImUiAssets()],
    resolve: {
      dedupe: ["vue", "vue-router", "naive-ui", "@vicons/ionicons5"],
    },
    // The kit ships .vue source → SSR must transform (not externalize) it, plus naive-ui and
    // its CommonJS deps (vueuc/css-render/... — the standard naive-ui + VitePress SSR set).
    ssr: {
      noExternal: [
        "@flare-im/vue-ui",
        "naive-ui",
        "@vicons/ionicons5",
        "vueuc",
        "css-render",
        "@css-render/vue3-ssr",
        "date-fns",
        "@juggle/resize-observer",
        "seemly",
        "treemate",
        "vooks",
        "evtd",
      ],
    },
    server: { fs: { allow: [join(here, "../..")] } },
  },
  // /downloads/* are static package archives in public/, not pages
  ignoreDeadLinks: [/^\/downloads\//],
  themeConfig: {
    search: {
      provider: "local",
      options: {
        detailedView: true,
        miniSearch: {
          searchOptions: {
            combineWith: "AND",
            fuzzy: 0.15,
            prefix: true,
          },
        },
      },
    },
    socialLinks: [
      { icon: "github", link: "https://github.com/flare-im/flare-im-design" },
    ],
  },

  locales: {
    root: {
      label: "简体中文",
      lang: "zh-CN",
      description:
        "跨端 IM UI 组件库 — 一套契约，四端原生实现（Vue · Flutter · iOS · Android）。",
      themeConfig: {
        nav: [
          { text: "指南", link: "/guide/introduction" },
          { text: "组件", link: "/general/" },
          { text: "IM 组件", link: "/im/" },
          { text: "Patterns", link: "/patterns/" },
          { text: "App Kit", link: "/app-kit/" },
          { text: "平台", link: "/platforms/" },
          { text: "资源", items: [
            { text: "Foundations", link: "/foundations/" },
            { text: "Customization", link: "/customization/" },
            { text: "Recipes", link: "/recipes/" },
            { text: "Examples", link: "/examples" },
            { text: "Resources", link: "/resources/" },
          ] },
        ],
        sidebar: {
          "/guide/": [
            {
              text: "指南",
              items: [
                ...zhSections.guide,
              ],
            },
            { text: "Foundations", collapsed: true, items: zhSections.foundations },
            { text: "Customization", collapsed: true, items: zhSections.customization },
          ],
          "/foundations/": [{ text: "Foundations", items: zhSections.foundations }],
          "/general/": [{ text: "General UI", items: [{ text: "总览", link: "/general/" }, { text: "全部组件", link: "/components/" }] }, ...componentSidebar("zh", "")],
          "/im/": [{ text: "IM UI", items: [{ text: "总览", link: "/im/" }, { text: "消息生命周期", link: "/im/message-lifecycle" }, { text: "消息状态", link: "/im/message-status" }, { text: "消息内容", link: "/im/message-content" }] }, ...componentSidebar("zh", "")],
          "/patterns/": [{ text: "Patterns", items: zhSections.patterns }],
          "/app-kit/": [{ text: "App Kit", items: [{ text: "Build an IM App", link: "/app-kit/" }, { text: "IM Capabilities", link: "/capabilities/" }, { text: "Recipes", link: "/recipes/" }] }],
          "/capabilities/": [{ text: "IM Capabilities", items: [{ text: "能力矩阵", link: "/capabilities/" }, { text: "Build an IM App", link: "/app-kit/" }] }],
          "/platforms/": [{ text: "平台", items: zhSections.platforms }],
          "/recipes/": [{ text: "Recipes", items: [
            { text: "总览", link: "/recipes/" },
            { text: "Customize Composer", link: "/recipes/customize-composer" },
            { text: "Custom Message", link: "/recipes/custom-message" },
            { text: "Custom Navigation", link: "/recipes/custom-navigation" },
            { text: "Minimal IM", link: "/recipes/minimal-im" },
            { text: "Full IM", link: "/recipes/full-im" },
          ] }],
          "/accessibility/": [{ text: "Accessibility", items: [{ text: "可访问性", link: "/accessibility/" }] }],
          "/resources/": [{ text: "Resources", items: zhSections.resources }],
          "/customization/": [{ text: "Customization", items: zhSections.customization }],
          "/examples": [{ text: "Examples", items: [{ text: "组件与 SDK 示例", link: "/examples" }] }],
          "/components/": [
            {
              text: "总览",
              items: [
                { text: "全部组件", link: "/components/" },
                { text: "数据类型", link: "/reference/data-types" },
              ],
            },
            ...componentSidebar("zh", ""),
          ],
          "/reference/": [
            { text: "参考", items: [{ text: "数据类型", link: "/reference/data-types" }] },
          ],
        },
        outline: { level: [2, 3], label: "本页目录" },
        docFooter: { prev: "上一页", next: "下一页" },
        footer: {
          message: "一套契约 · 四端原生实现",
          copyright: "Flare UI — Apache-2.0",
        },
      },
    },

    en: {
      label: "English",
      lang: "en-US",
      link: "/en/",
      description:
        "Cross-platform IM UI kit — one contract, four native implementations (Vue · Flutter · iOS · Android).",
      themeConfig: {
        nav: [
          { text: "Guide", link: "/en/guide/introduction" },
          { text: "Components", link: "/en/general/" },
          { text: "IM Components", link: "/en/im/" },
          { text: "Patterns", link: "/en/patterns/" },
          { text: "App Kit", link: "/en/app-kit/" },
          { text: "Platforms", link: "/en/platforms/" },
          { text: "Resources", items: [
            { text: "Foundations", link: "/en/foundations/" },
            { text: "Customization", link: "/en/customization/" },
            { text: "Recipes", link: "/en/recipes/" },
            { text: "Examples", link: "/en/examples" },
            { text: "Resources", link: "/en/resources/" },
          ] },
        ],
        sidebar: {
          "/en/guide/": [
            {
              text: "Guide",
              items: [
                ...enSections.guide,
              ],
            },
            { text: "Foundations", collapsed: true, items: enSections.foundations },
            { text: "Customization", collapsed: true, items: enSections.customization },
          ],
          "/en/foundations/": [{ text: "Foundations", items: enSections.foundations }],
          "/en/general/": [{ text: "General UI", items: [{ text: "Overview", link: "/en/general/" }, { text: "All components", link: "/en/components/" }] }, ...componentSidebar("en", "/en")],
          "/en/im/": [{ text: "IM UI", items: [{ text: "Overview", link: "/en/im/" }, { text: "Message lifecycle", link: "/en/im/message-lifecycle" }, { text: "Message status", link: "/en/im/message-status" }, { text: "Message content", link: "/en/im/message-content" }] }, ...componentSidebar("en", "/en")],
          "/en/patterns/": [{ text: "Patterns", items: enSections.patterns }],
          "/en/app-kit/": [{ text: "App Kit", items: [{ text: "Build an IM App", link: "/en/app-kit/" }, { text: "IM Capabilities", link: "/en/capabilities/" }, { text: "Recipes", link: "/en/recipes/" }] }],
          "/en/capabilities/": [{ text: "IM Capabilities", items: [{ text: "Capability matrix", link: "/en/capabilities/" }, { text: "Build an IM App", link: "/en/app-kit/" }] }],
          "/en/platforms/": [{ text: "Platforms", items: enSections.platforms }],
          "/en/recipes/": [{ text: "Recipes", items: [
            { text: "Overview", link: "/en/recipes/" },
            { text: "Customize Composer", link: "/en/recipes/customize-composer" },
            { text: "Custom Message", link: "/en/recipes/custom-message" },
            { text: "Custom Navigation", link: "/en/recipes/custom-navigation" },
            { text: "Minimal IM", link: "/en/recipes/minimal-im" },
            { text: "Full IM", link: "/en/recipes/full-im" },
          ] }],
          "/en/accessibility/": [{ text: "Accessibility", items: [{ text: "Accessibility", link: "/en/accessibility/" }] }],
          "/en/resources/": [{ text: "Resources", items: enSections.resources }],
          "/en/customization/": [{ text: "Customization", items: enSections.customization }],
          "/en/examples": [{ text: "Examples", items: [{ text: "Component and SDK examples", link: "/en/examples" }] }],
          "/en/components/": [
            {
              text: "Overview",
              items: [
                { text: "All components", link: "/en/components/" },
                { text: "Data Types", link: "/en/reference/data-types" },
              ],
            },
            ...componentSidebar("en", "/en"),
          ],
          "/en/reference/": [
            { text: "Reference", items: [{ text: "Data Types", link: "/en/reference/data-types" }] },
          ],
        },
        outline: { level: [2, 3], label: "On this page" },
        footer: {
          message: "One contract · four native implementations",
          copyright: "Flare UI — Apache-2.0",
        },
      },
    },
  },
});
