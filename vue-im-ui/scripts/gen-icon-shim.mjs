// Generator for src/shared/icon-glyphs.ts — the ionicons→Lucide drop-in shim.
//
// The kit imports its icons by ionicons5 NAMES from ../shared/icon-glyphs, but
// each name is backed by a Lucide glyph (thin-line / Feishu style). This script
// owns that mapping and (re)writes the shim.
//
// Run:  node scripts/gen-icon-shim.mjs
//
// It also VALIDATES: (a) every ionicons name imported anywhere in src/ is present
// in MAP; (b) every mapped Lucide target actually exists in the installed
// lucide-vue-next. It exits non-zero on any gap so a missing icon can't slip in.
import { readFileSync, writeFileSync, readdirSync, statSync, existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const SRC = path.join(ROOT, "src");
const OUT = path.join(SRC, "shared", "icon-glyphs.ts");
const STROKE = 1.75;

// ionicons5 name -> [lucideName, filled?]. Keep alphabetical for easy diffing.
// When adding: verify the Lucide name against node_modules/lucide-vue-next/dist/
// *.d.ts (Lucide renames often — e.g. PlusCircle→CirclePlus).
const MAP = {
  AddCircleOutline: ["CirclePlus"], AddOutline: ["Plus"], AlertCircleOutline: ["CircleAlert"],
  AppsOutline: ["LayoutGrid"], ArchiveOutline: ["Archive"], ArrowBackOutline: ["ArrowLeft"],
  ArrowDownOutline: ["ArrowDown"], ArrowRedoOutline: ["Forward"], ArrowUndoOutline: ["Reply"],
  AtOutline: ["AtSign"], BanOutline: ["Ban"], BookmarkOutline: ["Bookmark"], CalendarOutline: ["Calendar"],
  CallOutline: ["Phone"], CameraOutline: ["Camera"], CameraReverseOutline: ["SwitchCamera"],
  ChatbubbleEllipsesOutline: ["MessageCircleMore"], ChatbubbleOutline: ["MessageCircle"],
  ChatbubblesOutline: ["MessagesSquare"], CheckboxOutline: ["SquareCheck"],
  CheckmarkCircle: ["CircleCheck", true], CheckmarkCircleOutline: ["CircleCheck"],
  CheckmarkDoneOutline: ["CheckCheck"], CheckmarkOutline: ["Check"], ChevronBackOutline: ["ChevronLeft"],
  ChevronDownOutline: ["ChevronDown"], ChevronForwardOutline: ["ChevronRight"], ChevronUpOutline: ["ChevronUp"],
  CloseCircle: ["CircleX", true], CloseCircleOutline: ["CircleX"], CloseOutline: ["X"],
  CloudDoneOutline: ["CloudCheck"], CloudDownloadOutline: ["CloudDownload"], CodeSlashOutline: ["Code"],
  CodeWorkingOutline: ["CodeXml"], ContractOutline: ["Shrink"], CopyOutline: ["Copy"], CreateOutline: ["Pencil"],
  DocumentOutline: ["File"], DocumentTextOutline: ["FileText"], DownloadOutline: ["Download"],
  EarthOutline: ["Earth"], EllipsisHorizontal: ["Ellipsis"], EllipsisHorizontalOutline: ["Ellipsis"],
  ExpandOutline: ["Expand"], EyeOffOutline: ["EyeOff"], EyeOutline: ["Eye"], FileTrayOutline: ["Inbox"],
  FlagOutline: ["Flag"], FlashOutline: ["Zap"], FlaskOutline: ["FlaskConical"], FolderOpenOutline: ["FolderOpen"],
  FolderOutline: ["Folder"], GiftOutline: ["Gift"], HappyOutline: ["Smile"], Heart: ["Heart", true],
  HeartDislikeOutline: ["HeartOff"], HeartOutline: ["Heart"], ImageOutline: ["Image"],
  InformationCircle: ["Info", true], InformationCircleOutline: ["Info"], LanguageOutline: ["Languages"],
  LibraryOutline: ["Library"], LinkOutline: ["Link"], ListOutline: ["List"], LocationOutline: ["MapPin"],
  LockClosedOutline: ["Lock"], LogInOutline: ["LogIn"], LogOutOutline: ["LogOut"], MailUnreadOutline: ["MailOpen"],
  MegaphoneOutline: ["Megaphone"], MicOffOutline: ["MicOff"], MicOutline: ["Mic"],
  MoonOutline: ["Moon"], PricetagOutline: ["Tag"], PhonePortraitOutline: ["MonitorSmartphone"],
  NotificationsOffOutline: ["BellOff"], NotificationsOutline: ["Bell"], PauseOutline: ["Pause"],
  PeopleOutline: ["Users"], PersonAddOutline: ["UserPlus"], PersonOutline: ["User"], PinOutline: ["Pin"],
  PlanetOutline: ["Compass"], PlayCircleOutline: ["CirclePlay"], PlayOutline: ["Play"], QrCodeOutline: ["QrCode"],
  ReaderOutline: ["Quote"], RefreshOutline: ["RefreshCw"], RemoveOutline: ["Minus"],
  ReorderThreeOutline: ["ListOrdered"], ReturnUpBackOutline: ["Reply"], SearchOutline: ["Search"],
  SendOutline: ["Send"], SettingsOutline: ["Settings"], ShareSocialOutline: ["Share2"], Star: ["Star", true],
  StarOutline: ["Star"], SyncOutline: ["RefreshCw"], TerminalOutline: ["Terminal"], TextOutline: ["Type"],
  ThumbsUpOutline: ["ThumbsUp"], TimeOutline: ["Clock"], TrashOutline: ["Trash2"], VideocamOffOutline: ["VideoOff"],
  VideocamOutline: ["Video"], VolumeHighOutline: ["Volume2"], VolumeMuteOutline: ["VolumeX"],
  WarningOutline: ["TriangleAlert"],
  // Extra ionicons used by consumer apps (e.g. flare-social-tauri-app's im-shared)
  // that redirect their @vicons imports here — kept so the shim covers them too.
  AlertCircle: ["CircleAlert", true], CropOutline: ["Crop"], DocumentAttachOutline: ["Paperclip"],
  Flame: ["Flame", true], FlameOutline: ["Flame"], MailOutline: ["Mail"], NavigateOutline: ["Navigation"],
  PeopleCircleOutline: ["UsersRound"], PlaySkipBackOutline: ["SkipBack"], PlaySkipForwardOutline: ["SkipForward"],
  ReorderFourOutline: ["List"], ReturnDownBackOutline: ["CornerDownLeft"], ShieldCheckmarkOutline: ["ShieldCheck"],
  SparklesOutline: ["Sparkles"], Time: ["Clock", true], WifiOutline: ["Wifi"],
  PodiumOutline: ["Vote"],
};

function walk(dir) {
  const out = [];
  for (const e of readdirSync(dir)) {
    const p = path.join(dir, e);
    if (statSync(p).isDirectory()) out.push(...walk(p));
    else if (/\.(vue|ts)$/.test(e)) out.push(p);
  }
  return out;
}

// (a) every ionicons name still imported from the shim in src must be in MAP.
const importRe = /from\s*["'][^"']*icon-glyphs["']/;
const nameRe = /import\s*\{([^}]*)\}\s*from\s*["'][^"']*icon-glyphs["']/g;
const used = new Set();
for (const f of walk(SRC)) {
  if (f === OUT) continue;
  const s = readFileSync(f, "utf8");
  if (!importRe.test(s)) continue;
  let m;
  while ((m = nameRe.exec(s))) {
    m[1].split(",").map((x) => x.trim().replace(/\s+as\s+.*/, "")).filter(Boolean).forEach((n) => used.add(n));
  }
}
const unmapped = [...used].filter((n) => !(n in MAP));
if (unmapped.length) {
  console.error("Icons imported from the shim but missing from MAP:", unmapped.join(", "));
  process.exit(1);
}

// (b) validate Lucide targets against the installed package's declarations.
const dts = path.join(ROOT, "node_modules/lucide-vue-next/dist/lucide-vue-next.suffixed.d.ts");
if (existsSync(dts)) {
  const decls = new Set([...readFileSync(dts, "utf8").matchAll(/declare const ([A-Za-z0-9]+)/g)].map((m) => m[1]));
  const bad = Object.entries(MAP).filter(([, [lu]]) => !decls.has(lu)).map(([ion, [lu]]) => `${ion}->${lu}`);
  if (bad.length) { console.error("Lucide target(s) not found in installed lucide-vue-next:", bad.join(", ")); process.exit(1); }
} else {
  console.warn("lucide-vue-next not installed — skipping Lucide-name validation.");
}

// 从 MAP 里取出实际用到的 Lucide 名，去重排序 —— 具名导入与 REGISTRY 都由它生成，
// 保证「新增图标只改 MAP」这一条仍然成立。
const lucideNames = [...new Set(Object.values(MAP).map(([lu]) => lu))].sort();
// 导入一律加 `Lu` 前缀别名：Lucide 里有 Heart/Star/Flame 这样的名字，而 shim 自己
// 也导出同名图标（ionicons5 的命名恰好撞上），不改名会变成同名声明合并 → 编译失败。
const lucideNamedImports = lucideNames.map((n) => `  ${n} as Lu${n},\n`).join("");
const lucideRegistry = lucideNames.map((n) => `  ${n}: Lu${n},\n`).join("");

const header = `// AUTO-GENERATED by scripts/gen-icon-shim.mjs — do not edit by hand.
// Drop-in shim: re-exports the ionicons5 names the kit uses, each backed by a
// Lucide glyph (thin-line / Feishu style). This is the single seam that swaps
// the kit's web icon set — all components import their icons from here instead
// of "@vicons/ionicons5", so call sites never change.
//
// Each export is a functional component sized to 1em so naive-ui <n-icon>'s
// font-size sizing keeps working, and inheriting currentColor. To change the
// mapping or add an icon, edit MAP in scripts/gen-icon-shim.mjs and re-run it.
import { h, type Component, type FunctionalComponent } from "vue";
import {
${lucideNamedImports}} from "lucide-vue-next";

// 具名导入而不是 \`import * as lucide\`：命名空间导入会让打包器无法 tree-shake，
// 整个 Lucide（近 900 KiB）都会进产物，而这里实际只用到一百来个图标。
const REGISTRY: Record<string, Component> = {
${lucideRegistry}};

const STROKE = ${STROKE};
function glyph(name: string, filled = false): FunctionalComponent {
  const Lucide = REGISTRY[name];
  const C: FunctionalComponent = (_props, { attrs }) =>
    h(Lucide, { size: "1em", "stroke-width": STROKE, ...(filled ? { fill: "currentColor" } : {}), ...attrs });
  (C as { displayName?: string }).displayName = name;
  return C;
}
`;
const lines = Object.entries(MAP).map(
  ([ion, [lu, filled]]) => `export const ${ion} = /*#__PURE__*/ glyph(${JSON.stringify(lu)}${filled ? ", true" : ""});`,
);
writeFileSync(OUT, header + "\n" + lines.join("\n") + "\n");
console.log(`Wrote ${path.relative(ROOT, OUT)} — ${lines.length} icons, ${used.size} used in src.`);
