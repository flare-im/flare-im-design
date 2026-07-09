import { defineConfig } from "vitepress";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

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

/** component sidebar for a locale; `prefix` is "" (zh root) or "/en" */
const componentSidebar = (loc: "zh" | "en", prefix: string) =>
  Object.entries(byCat).map(([cat, list]) => ({
    text: catLabel(cat, loc),
    collapsed: false,
    items: list.map((c) => ({
      text: c.name,
      link: `${prefix}/components/${slug(c.name)}`,
    })),
  }));

const first = slug(spec.components[0].name);

export default defineConfig({
  title: "Flare IM Design",
  cleanUrls: true,
  appearance: true,
  // /downloads/* are static package archives in public/, not pages
  ignoreDeadLinks: [/^\/downloads\//],
  themeConfig: {
    logo: "/logo.svg",
    search: { provider: "local" },
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
          { text: "指南", link: "/guide/getting-started" },
          { text: "安装", link: "/guide/install" },
          { text: "设计 Tokens", link: "/guide/tokens" },
          { text: "主题定制", link: "/guide/theming" },
          { text: "组件", link: `/components/${first}` },
          { text: "数据类型", link: "/reference/data-types" },
          {
            text: `v${spec.version}`,
            items: [
              { text: "组件契约 (spec)", link: "/guide/spec" },
              { text: "GitHub", link: "https://github.com/flare-im/flare-im-design" },
            ],
          },
        ],
        sidebar: {
          "/guide/": [
            {
              text: "指南",
              items: [
                { text: "快速开始", link: "/guide/getting-started" },
                { text: "接你自己的后端", link: "/guide/standalone" },
                { text: "安装与引用", link: "/guide/install" },
                { text: "设计 Tokens", link: "/guide/tokens" },
                { text: "主题定制", link: "/guide/theming" },
                { text: "组件契约", link: "/guide/spec" },
              ],
            },
          ],
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
          copyright: "Flare IM Design — MIT Licensed",
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
          { text: "Guide", link: "/en/guide/getting-started" },
          { text: "Install", link: "/en/guide/install" },
          { text: "Tokens", link: "/en/guide/tokens" },
          { text: "Theming", link: "/en/guide/theming" },
          { text: "Components", link: `/en/components/${first}` },
          { text: "Data Types", link: "/en/reference/data-types" },
          {
            text: `v${spec.version}`,
            items: [
              { text: "Component spec", link: "/en/guide/spec" },
              { text: "GitHub", link: "https://github.com/flare-im/flare-im-design" },
            ],
          },
        ],
        sidebar: {
          "/en/guide/": [
            {
              text: "Guide",
              items: [
                { text: "Getting started", link: "/en/guide/getting-started" },
                { text: "Bring your own backend", link: "/en/guide/standalone" },
                { text: "Install & reference", link: "/en/guide/install" },
                { text: "Design tokens", link: "/en/guide/tokens" },
                { text: "Theming", link: "/en/guide/theming" },
                { text: "Component spec", link: "/en/guide/spec" },
              ],
            },
          ],
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
          copyright: "Flare IM Design — MIT Licensed",
        },
      },
    },
  },
});
