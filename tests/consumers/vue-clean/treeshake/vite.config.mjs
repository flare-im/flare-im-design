// Builds one tree-shaking entry (ENTRY=<file name without .ts>) and writes a ledger of
// every @flare-im/vue-ui module that contributed rendered code to the bundle.
// A module that is merely imported but has no side-effectful statements renders 0
// bytes and is not counted — the ledger measures what the consumer actually ships.
import vue from "@vitejs/plugin-vue";
import { writeFileSync } from "node:fs";
import { defineConfig } from "vite";

const entry = process.env.ENTRY;
const IM_DIRS = new Set(["call", "composer", "contacts", "conversation", "media", "message-preview", "messages", "moments", "profile", "scenes", "shell"]);

export default defineConfig({
  logLevel: "warn",
  plugins: [vue(), {
    name: "flare-module-ledger",
    generateBundle(_options, bundle) {
      const ledger = { entry, jsBytes: 0, cssBytes: 0, kitModules: {}, imModules: [], markdownItModules: 0 };
      for (const output of Object.values(bundle)) {
        if (output.type === "asset") {
          if (output.fileName.endsWith(".css")) ledger.cssBytes += Buffer.byteLength(output.source);
          continue;
        }
        ledger.jsBytes += Buffer.byteLength(output.code);
        for (const [id, info] of Object.entries(output.modules)) {
          if (info.renderedLength === 0) continue;
          const kit = id.match(/node_modules\/@flare-im\/vue-ui\/src\/([^?]+)/);
          if (kit) {
            ledger.kitModules[kit[1]] = (ledger.kitModules[kit[1]] ?? 0) + info.renderedLength;
            const dir = kit[1].match(/^components\/([^/]+)\//)?.[1];
            if (dir && IM_DIRS.has(dir) && !ledger.imModules.includes(kit[1])) ledger.imModules.push(kit[1]);
          }
          if (/node_modules\/markdown-it\//.test(id)) ledger.markdownItModules += 1;
        }
      }
      ledger.kitModuleCount = Object.keys(ledger.kitModules).length;
      ledger.kitRenderedBytes = Object.values(ledger.kitModules).reduce((sum, bytes) => sum + bytes, 0);
      writeFileSync(`treeshake/ledger-${entry}.json`, `${JSON.stringify(ledger, null, 2)}\n`);
    },
  }],
  build: { outDir: `treeshake/dist-${entry}`, emptyOutDir: true, rollupOptions: { input: `treeshake/${entry}.ts` } },
});
