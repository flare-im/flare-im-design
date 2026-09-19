// Serves and ships the kit's emoji and sticker resources (assets/emoji-sticker) for Vite hosts
// that consume the kit from this repository: the website, the reference apps in local mode.
//
// Dev: answers `<vite base><path>/…` with the file. Build: copies the folder to `<outDir>/<path>`.
// The kit resolves the same path through FlareUiProvider `assetBaseUrl`, so a host deployed
// under `/app/` passes `import.meta.env.BASE_URL + "flare-im-ui-assets"`.
import { cpSync, createReadStream, existsSync, statSync } from "node:fs";
import { dirname, join, normalize, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const DEFAULT_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "../../assets/emoji-sticker");

const MIME = { ".webp": "image/webp", ".json": "application/json; charset=utf-8", ".png": "image/png", ".gif": "image/gif" };

function mimeFor(file) {
  const ext = Object.keys(MIME).find((suffix) => file.endsWith(suffix));
  return ext ? MIME[ext] : "application/octet-stream";
}

/** @param {{ root?: string, path?: string }} [options] */
export function flareImUiAssets(options = {}) {
  const root = options.root ?? DEFAULT_ROOT;
  const segment = (options.path ?? "flare-im-ui-assets").replace(/^\/+|\/+$/g, "");
  let base = "/";
  let outDir = "dist";
  let ssr = false;
  return {
    name: "flare-im-ui-assets",
    configResolved(config) {
      base = config.base || "/";
      outDir = resolve(config.root, config.build.outDir);
      ssr = Boolean(config.build.ssr);
    },
    configureServer(server) {
      const prefixes = [...new Set([`${base.replace(/\/?$/, "/")}${segment}/`, `/${segment}/`])];
      server.middlewares.use((req, res, next) => {
        const url = (req.url ?? "").split("?")[0] ?? "";
        const prefix = prefixes.find((candidate) => url.startsWith(candidate));
        if (!prefix) return next();
        const file = normalize(join(root, decodeURIComponent(url.slice(prefix.length))));
        if (!file.startsWith(root + sep) || !existsSync(file) || !statSync(file).isFile()) return next();
        res.setHeader("Content-Type", mimeFor(file));
        createReadStream(file).pipe(res);
      });
    },
    writeBundle() {
      // A server-rendering pass (VitePress, SSR hosts) ships no static files.
      if (!ssr && existsSync(root)) cpSync(root, join(outDir, segment), { recursive: true });
    },
  };
}
