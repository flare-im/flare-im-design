// Flare icon library — a curated set of semantic icon names shared across all
// four platforms. Each platform maps the SAME name to its native glyph source
// (Web → Lucide via ./icon-glyphs, iOS → SF Symbols, Flutter/Android → Material Icons).
// Consumers use `<FlareIcon name="search" />` instead of importing icons directly.
import type { Component } from "vue";
import {
  SearchOutline,
  SendOutline,
  EllipsisHorizontal,
  ArrowBackOutline,
  CloseOutline,
  CheckmarkOutline,
  AddOutline,
  RemoveOutline,
  CreateOutline,
  TrashOutline,
  HeartOutline,
  ChatbubbleOutline,
  ChatbubblesOutline,
  PlanetOutline,
  ShareSocialOutline,
  CameraOutline,
  ImageOutline,
  LocationOutline,
  MicOutline,
  CallOutline,
  VideocamOutline,
  SettingsOutline,
  PersonOutline,
  PeopleOutline,
  PersonAddOutline,
  StarOutline,
  DownloadOutline,
  LinkOutline,
  HappyOutline,
  DocumentOutline,
  FolderOutline,
  NotificationsOutline,
  NotificationsOffOutline,
  CopyOutline,
  ArrowRedoOutline,
  ArrowUndoOutline,
  RefreshOutline,
  ChevronDownOutline,
  ChevronForwardOutline,
  ArrowDownOutline,
  WarningOutline,
  InformationCircleOutline,
  CheckmarkCircleOutline,
  CalendarOutline,
  TimeOutline,
  EyeOutline,
  EyeOffOutline,
  LockClosedOutline,
  QrCodeOutline,
  BanOutline,
  PricetagOutline,
  MegaphoneOutline,
  MoonOutline,
  LanguageOutline,
  PhonePortraitOutline,
  LogOutOutline,
  PinOutline,
  UndoOutline,
  PinOffOutline,
  GitMergeOutline,
  ChecklistOutline,
  ReaderOutline,
  AddReactionOutline,
  AtOutline,
  CheckmarkDoneOutline,
  FlagOutline,
  TextOutline,
  DocumentAttachOutline,
  ChatbubbleDotOutline,
  ArchiveOutline,
  ArchiveRestoreOutline,
  EraserOutline,
  MicOffOutline,
  VideocamOffOutline,
  VolumeHighOutline,
  VolumeMuteOutline,
  CallEndOutline,
  CameraReverseOutline,
  ScreenShareOutline,
  PlayOutline,
  PauseOutline,
  ExpandOutline,
  ContractOutline,
  ZoomInOutline,
  ZoomOutOutline,
  RotateOutline,
  PeopleCircleOutline,
  ShieldCheckmarkOutline,
  PersonRemoveOutline,
  KeyOutline,
  ChatbubbleOffOutline,
  AlertOctagonOutline,
  ChevronUpOutline,
  ChevronBackOutline,
  KeyboardOutline,
  AppsOutline,
  AlertCircleOutline,
  BarChartOutline,
  GlobeOutline,
  BookmarkOutline,
  BugOutline,
  IdCardOutline,
  HashOutline,
  FileTrayOutline,
  ServerOutline,
  ExtensionPuzzleOutline,
  LocateOutline,
  WalletOutline,
} from "./icon-glyphs";
import { RedPacketOutline } from "./icon-custom";

/** The canonical Flare icon name set (single source; native maps the same keys). */
export const flareIcons = {
  search: SearchOutline,
  send: SendOutline,
  more: EllipsisHorizontal,
  back: ArrowBackOutline,
  close: CloseOutline,
  check: CheckmarkOutline,
  add: AddOutline,
  remove: RemoveOutline,
  edit: CreateOutline,
  delete: TrashOutline,
  heart: HeartOutline,
  comment: ChatbubbleOutline,
  chats: ChatbubblesOutline,
  moments: PlanetOutline,
  share: ShareSocialOutline,
  camera: CameraOutline,
  image: ImageOutline,
  location: LocationOutline,
  mic: MicOutline,
  phone: CallOutline,
  video: VideocamOutline,
  settings: SettingsOutline,
  person: PersonOutline,
  people: PeopleOutline,
  "person-add": PersonAddOutline,
  star: StarOutline,
  download: DownloadOutline,
  link: LinkOutline,
  emoji: HappyOutline,
  file: DocumentOutline,
  folder: FolderOutline,
  notification: NotificationsOutline,
  mute: NotificationsOffOutline,
  copy: CopyOutline,
  forward: ArrowRedoOutline,
  reply: ArrowUndoOutline,
  refresh: RefreshOutline,
  "chevron-down": ChevronDownOutline,
  "chevron-right": ChevronForwardOutline,
  "arrow-down": ArrowDownOutline,
  warning: WarningOutline,
  info: InformationCircleOutline,
  success: CheckmarkCircleOutline,
  error: AlertCircleOutline,
  calendar: CalendarOutline,
  clock: TimeOutline,
  eye: EyeOutline,
  "eye-off": EyeOffOutline,
  lock: LockClosedOutline,
  qr: QrCodeOutline,
  block: BanOutline,
  tag: PricetagOutline,
  announcement: MegaphoneOutline,
  theme: MoonOutline,
  language: GlobeOutline,
  devices: PhonePortraitOutline,
  logout: LogOutOutline,
  pin: PinOutline,
  poll: BarChartOutline,
  recall: UndoOutline,
  unpin: PinOffOutline,
  "merge-forward": GitMergeOutline,
  "multi-select": ChecklistOutline,
  quote: ReaderOutline,
  reaction: AddReactionOutline,
  translate: LanguageOutline,
  mention: AtOutline,
  read: CheckmarkDoneOutline,
  mark: FlagOutline,
  "rich-text": TextOutline,
  attachment: DocumentAttachOutline,
  "mark-unread": ChatbubbleDotOutline,
  archive: ArchiveOutline,
  unarchive: ArchiveRestoreOutline,
  "clear-history": EraserOutline,
  "mic-off": MicOffOutline,
  "camera-off": VideocamOffOutline,
  speaker: VolumeHighOutline,
  "speaker-off": VolumeMuteOutline,
  "end-call": CallEndOutline,
  "switch-camera": CameraReverseOutline,
  "screen-share": ScreenShareOutline,
  play: PlayOutline,
  pause: PauseOutline,
  expand: ExpandOutline,
  collapse: ContractOutline,
  "zoom-in": ZoomInOutline,
  "zoom-out": ZoomOutOutline,
  rotate: RotateOutline,
  group: PeopleCircleOutline,
  admin: ShieldCheckmarkOutline,
  "remove-member": PersonRemoveOutline,
  "transfer-owner": KeyOutline,
  silence: ChatbubbleOffOutline,
  report: AlertOctagonOutline,
  "chevron-up": ChevronUpOutline,
  "chevron-left": ChevronBackOutline,
  keyboard: KeyboardOutline,
  "mini-app": AppsOutline,
  // Round 9: concepts every kit drew under a name that meant something else.
  "pin-self": BookmarkOutline,
  diagnostics: BugOutline,
  card: IdCardOutline,
  id: HashOutline,
  "join-request": FileTrayOutline,
  storage: ServerOutline,
  // Kit-drawn glyphs (icon-custom.ts): concepts no icon library has.
  "red-packet": RedPacketOutline,
  // The generic plugin glyph: a plugin's "+" tile whose icon is not a registry name falls back to it.
  plugin: ExtensionPuzzleOutline,
  // The location picker's "use current location" key: a crosshair, not the map pin `location` draws.
  locate: LocateOutline,
  // The 我 page's wallet entry (the red packet plugin's account-entry).
  wallet: WalletOutline,
} satisfies Record<string, Component>;

export type FlareIconName = keyof typeof flareIcons;
export const flareIconNames = Object.keys(flareIcons) as FlareIconName[];

/** The glyph a name outside the registry draws: the neutral extension glyph, never a question mark or a blank. */
export const FLARE_ICON_FALLBACK: FlareIconName = "plugin";

const warnedIconNames = new Set<string>();

// Only the build mode, typed here so the kit does not lean on a host's Node typings.
declare const process: { env: { NODE_ENV?: string } };

/**
 * Whether this is a development build. Bundlers write the build mode over `process.env.NODE_ENV` in the source they
 * compile (Vite in dev and build, webpack, esbuild) and a test runner or SSR process has a real one; source loaded as
 * a plain script has neither, and is not a development build. `import.meta` is not used: it is a syntax error in a
 * script.
 */
function flareDevelopmentBuild(): boolean {
  try {
    return process.env.NODE_ENV !== "production";
  } catch {
    return false;
  }
}

/**
 * A registry name for an icon name that came in as data (a plugin, the SDK, host configuration): the name itself
 * when the registry has it, `plugin` for any other name (a development build warns once per name), null for none
 * (spec/me-menu-vectors.json iconFallback).
 */
export function flareIconNameOrFallback(name: string | null | undefined): FlareIconName | null {
  const trimmed = typeof name === "string" ? name.trim() : "";
  if (!trimmed) return null;
  if (Object.prototype.hasOwnProperty.call(flareIcons, trimmed)) return trimmed as FlareIconName;
  if (!warnedIconNames.has(trimmed) && flareDevelopmentBuild()) {
    warnedIconNames.add(trimmed);
    console.warn(`[flare-im] "${trimmed}" is not a Flare icon name; drawing the "${FLARE_ICON_FALLBACK}" glyph`);
  }
  return FLARE_ICON_FALLBACK;
}
