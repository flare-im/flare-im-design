#!/usr/bin/env node
// Builds fonts/FlareKitIcons.ttf: the kit's own glyphs — concepts Material Icons has no shape for, and
// shapes that have to match the other kits where Material draws something else — as a TrueType font so
// they are ordinary IconData: every call site that resolves a name through flareIconGlyph (the composer's
// "+" panel and toolbar, menus, buttons) draws them and tints them like any other icon.
//
// The geometry is the same as the Vue glyph (icon-custom.ts, or the Lucide icon itself; 24-unit box);
// here each stroke is outlined at the Material weight (2 units) because a font only fills. Contours of
// one glyph may overlap: all of them wind clockwise, so the non-zero fill paints their union. Zero
// dependencies: the tables are written by hand.
//
//   node scripts/build-icon-font.mjs           write the font
//   node scripts/build-icon-font.mjs --check   fail if the committed font is out of date
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const OUT = join(here, "..", "fonts", "FlareKitIcons.ttf");
const FAMILY = "FlareKitIcons";
const UPM = 1200;
const UNIT = UPM / 24;
const STROKE = 2;

// ── geometry (24-unit box, y down) ────────────────────────────────────────────────────────────
/** A contour: points [x, y, onCurve] in the 24-unit box. */
const arc = (cx, cy, r, from, to, steps) => {
  // Quadratic approximation of a circular arc, `steps` segments: on-curve ends, off-curve at the tangents' meet.
  const out = [];
  const span = (to - from) / steps;
  for (let i = 0; i < steps; i += 1) {
    const a0 = from + span * i;
    const a1 = a0 + span;
    const mid = (a0 + a1) / 2;
    const k = r / Math.cos(span / 2);
    if (i === 0) out.push([cx + r * Math.cos(a0), cy + r * Math.sin(a0), true]);
    out.push([cx + k * Math.cos(mid), cy + k * Math.sin(mid), false]);
    out.push([cx + r * Math.cos(a1), cy + r * Math.sin(a1), true]);
  }
  return out;
};

function roundedRect(x0, y0, x1, y1, r) {
  const q = Math.PI / 2;
  return [
    ...arc(x1 - r, y0 + r, r, -q, 0, 2),
    ...arc(x1 - r, y1 - r, r, 0, q, 2),
    ...arc(x0 + r, y1 - r, r, q, 2 * q, 2),
    ...arc(x0 + r, y0 + r, r, 2 * q, 3 * q, 2),
  ];
}

const circle = (cx, cy, r) => arc(cx, cy, r, 0, 2 * Math.PI, 8).slice(0, -1);

/** The band a stroke of half-width `h` paints along the segment p0 → p1, round caps included. */
function capsule([x0, y0], [x1, y1], h) {
  const a = Math.atan2(y1 - y0, x1 - x0);
  const q = Math.PI / 2;
  return [...arc(x1, y1, h, a - q, a + q, 4), ...arc(x0, y0, h, a + q, a + 3 * q, 4)];
}

/** The band a stroke of half-width `h` paints along a circular arc (y down, angles from +x). */
function strokedArc(cx, cy, r, from, to, h) {
  const outer = arc(cx, cy, r + h, from, to, 2);
  if (r - h <= 0) return [[cx, cy, true], ...outer];
  return [...outer, ...arc(cx, cy, r - h, to, from, 2)];
}

/** The band a stroke of half-width `h` paints along the quadratic curve p0 → c → p1 (butt ends). */
function strokedQuad(p0, c, p1, h, samples = 24) {
  const at = (t) => [
    (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t ** 2 * p1[0],
    (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t ** 2 * p1[1],
  ];
  const tangent = (t) => [
    2 * (1 - t) * (c[0] - p0[0]) + 2 * t * (p1[0] - c[0]),
    2 * (1 - t) * (c[1] - p0[1]) + 2 * t * (p1[1] - c[1]),
  ];
  const upper = [];
  const lower = [];
  for (let i = 0; i <= samples; i += 1) {
    const t = i / samples;
    const [x, y] = at(t);
    const [dx, dy] = tangent(t);
    const len = Math.hypot(dx, dy);
    const nx = -dy / len;
    const ny = dx / len;
    upper.push([x + nx * h, y + ny * h, true]);
    lower.push([x - nx * h, y - ny * h, true]);
  }
  return [...upper, ...lower.reverse()];
}

const h = STROKE / 2;
// The card's small envelope: body 15 × 19.5 at (4.5, 2.25), corners 2.7 (0.18 of the width); the flap's
// curve leaves the sides 0.7 of the flap down and dips to the flap (0.42 of the height) at the middle;
// a solid seal of radius 2.6 sits on that lowest point.
const body = { x0: 4.5, y0: 2.25, x1: 19.5, y1: 21.75, r: 2.7 };
const flap = body.y0 + (body.y1 - body.y0) * 0.42;
const side = body.y0 + (flap - body.y0) * 0.7;
const control = flap + (flap - side);
const RED_PACKET = [
  { points: roundedRect(body.x0 - h, body.y0 - h, body.x1 + h, body.y1 + h, body.r + h), hole: false },
  { points: roundedRect(body.x0 + h, body.y0 + h, body.x1 - h, body.y1 - h, body.r - h), hole: true },
  { points: strokedQuad([body.x0, side], [12, control], [body.x1, side], h), hole: false },
  { points: circle(12, flap, 2.6), hole: false },
];

// The rich-text key's "T", Lucide `Type` as the other kits draw it: a top bar from 4 to 20 whose ends
// turn down to 7 over corners of radius 1, a stem from 4 to 20 and a foot from 9 to 15, with Lucide's
// round caps and joins. Material's `title` is a different letterform.
const RICH_TEXT = [
  capsule([12, 4], [12, 20], h),
  capsule([9, 20], [15, 20], h),
  capsule([4, 7], [4, 5], h),
  strokedArc(5, 5, 1, Math.PI, 1.5 * Math.PI, h),
  capsule([5, 4], [19, 4], h),
  strokedArc(19, 5, 1, 1.5 * Math.PI, 2 * Math.PI, h),
  capsule([20, 5], [20, 7], h),
].map((points) => ({ points, hole: false }));

const GLYPHS = [
  { name: "redPacket", code: 0xe000, contours: RED_PACKET },
  { name: "richText", code: 0xe001, contours: RICH_TEXT },
];

// ── outline → font units ──────────────────────────────────────────────────────────────────────
const toFont = ([x, y, on]) => [Math.round(x * UNIT), Math.round((24 - y) * UNIT), on];

/** Signed area (y up): positive is counter-clockwise. */
function area(points) {
  let sum = 0;
  for (let i = 0; i < points.length; i += 1) {
    const [x0, y0] = points[i];
    const [x1, y1] = points[(i + 1) % points.length];
    sum += x0 * y1 - x1 * y0;
  }
  return sum / 2;
}

/** TrueType fills by non-zero winding: outlines clockwise, holes counter-clockwise. */
function orient(contour) {
  const points = contour.points.map(toFont);
  const clockwise = area(points) < 0;
  return contour.hole === clockwise ? points.reverse() : points;
}

// ── binary writers ────────────────────────────────────────────────────────────────────────────
class Writer {
  constructor() { this.bytes = []; }
  u8(v) { this.bytes.push(v & 0xff); return this; }
  u16(v) { return this.u8(v >> 8).u8(v); }
  i16(v) { return this.u16(v < 0 ? v + 0x10000 : v); }
  u32(v) { return this.u16((v >>> 16) & 0xffff).u16(v & 0xffff); }
  tag(s) { for (const ch of s) this.u8(ch.charCodeAt(0)); return this; }
  raw(arr) { for (const b of arr) this.u8(b); return this; }
  pad4() { while (this.bytes.length % 4) this.u8(0); return this; }
  get length() { return this.bytes.length; }
  buffer() { return Uint8Array.from(this.bytes); }
}

function checksum(bytes) {
  let sum = 0;
  for (let i = 0; i < bytes.length; i += 4) {
    const word = ((bytes[i] ?? 0) << 24) | ((bytes[i + 1] ?? 0) << 16) | ((bytes[i + 2] ?? 0) << 8) | (bytes[i + 3] ?? 0);
    sum = (sum + (word >>> 0)) >>> 0;
  }
  return sum;
}

// ── glyphs ────────────────────────────────────────────────────────────────────────────────────
const outlines = [null, ...GLYPHS.map((g) => g.contours.map(orient))];
const glyf = new Writer();
const loca = [];
const bounds = [];
let maxPoints = 0;
let maxContours = 0;
for (const contours of outlines) {
  loca.push(glyf.length);
  if (!contours) { bounds.push([0, 0, 0, 0]); continue; }
  const all = contours.flat();
  const xs = all.map((p) => p[0]);
  const ys = all.map((p) => p[1]);
  const box = [Math.min(...xs), Math.min(...ys), Math.max(...xs), Math.max(...ys)];
  bounds.push(box);
  maxPoints = Math.max(maxPoints, all.length);
  maxContours = Math.max(maxContours, contours.length);
  glyf.i16(contours.length).i16(box[0]).i16(box[1]).i16(box[2]).i16(box[3]);
  let end = -1;
  for (const c of contours) { end += c.length; glyf.u16(end); }
  glyf.u16(0); // no instructions
  for (const [, , on] of all) glyf.u8(on ? 1 : 0); // long coordinates, no repeats
  let px = 0;
  for (const [x] of all) { glyf.i16(x - px); px = x; }
  let py = 0;
  for (const [, y] of all) { glyf.i16(y - py); py = y; }
  glyf.pad4();
}
loca.push(glyf.length);
const numGlyphs = outlines.length;
const fontBox = bounds.slice(1).reduce((a, b) => [Math.min(a[0], b[0]), Math.min(a[1], b[1]), Math.max(a[2], b[2]), Math.max(a[3], b[3])]);

// ── tables ────────────────────────────────────────────────────────────────────────────────────
const head = new Writer()
  .u32(0x00010000).u32(0x00010000).u32(0) // version, revision, checkSumAdjustment (patched below)
  .u32(0x5f0f3cf5).u16(0x000b).u16(UPM)
  .u32(0).u32(0).u32(0).u32(0) // created / modified: zero keeps the build reproducible
  .i16(fontBox[0]).i16(fontBox[1]).i16(fontBox[2]).i16(fontBox[3])
  .u16(0).u16(8).i16(2).i16(1).i16(0);

const hhea = new Writer()
  .u32(0x00010000).i16(UPM).i16(0).i16(0).u16(UPM)
  .i16(0).i16(0).i16(fontBox[2])
  .i16(1).i16(0).i16(0).i16(0).i16(0).i16(0).i16(0).i16(0).u16(numGlyphs);

const maxp = new Writer()
  .u32(0x00010000).u16(numGlyphs).u16(maxPoints).u16(maxContours).u16(0).u16(0)
  .u16(2).u16(0).u16(0).u16(0).u16(0).u16(0).u16(0).u16(0).u16(0);

const hmtx = new Writer();
for (const box of bounds) hmtx.u16(UPM).i16(box[0]);

const codes = GLYPHS.map((g) => g.code);
const os2 = new Writer()
  .u16(4).i16(UPM / 2).u16(400).u16(5).u16(0) // version, xAvgCharWidth, weight, width, fsType (installable)
  .i16(UPM / 2).i16(UPM / 2).i16(0).i16(UPM / 4) // subscript size / offset
  .i16(UPM / 2).i16(UPM / 2).i16(0).i16(UPM / 2) // superscript size / offset
  .i16(UPM / 20).i16(UPM / 4).i16(0) // strikeout, family class
  .raw(new Array(10).fill(0)) // panose
  .u32(0).u32(0x10000000).u32(0).u32(0) // unicode ranges: bit 60 (range 2, bit 28), private use area
  .tag("FLRE").u16(0x0040) // vendor, fsSelection REGULAR
  .u16(Math.min(...codes)).u16(Math.max(...codes))
  .i16(UPM).i16(0).i16(0).u16(UPM).u16(0) // typo ascender / descender / gap, win ascent / descent
  .u32(1).u32(0) // code page ranges: Latin 1
  .i16(0).i16(UPM).u16(0).u16(0x20).u16(0);

// cmap: one format 4 subtable, a segment per glyph plus the 0xFFFF terminator.
const segments = [...GLYPHS.map((g, i) => ({ start: g.code, end: g.code, delta: (i + 1 - g.code + 0x10000) % 0x10000 })), { start: 0xffff, end: 0xffff, delta: 1 }];
const segX2 = segments.length * 2;
const searchRange = 2 * 2 ** Math.floor(Math.log2(segments.length));
const sub = new Writer().u16(4).u16(16 + segments.length * 8).u16(0).u16(segX2).u16(searchRange)
  .u16(Math.log2(searchRange / 2)).u16(segX2 - searchRange);
for (const s of segments) sub.u16(s.end);
sub.u16(0);
for (const s of segments) sub.u16(s.start);
for (const s of segments) sub.u16(s.delta);
for (const s of segments) sub.u16(0);
const cmap = new Writer().u16(0).u16(1).u16(3).u16(1).u32(12).raw(sub.bytes);

const NAMES = [[1, FAMILY], [2, "Regular"], [3, `${FAMILY}-Regular`], [4, FAMILY], [5, "Version 1.0"], [6, FAMILY]];
const utf16 = (s) => [...s].flatMap((ch) => [ch.charCodeAt(0) >> 8, ch.charCodeAt(0) & 0xff]);
const nameData = [];
const name = new Writer().u16(0).u16(NAMES.length).u16(6 + NAMES.length * 12);
for (const [id, text] of NAMES) {
  const bytes = utf16(text);
  name.u16(3).u16(1).u16(0x409).u16(id).u16(bytes.length).u16(nameData.length);
  nameData.push(...bytes);
}
name.raw(nameData);

const post = new Writer().u32(0x00030000).u32(0).i16(-UPM / 10).i16(UPM / 20).u32(0).u32(0).u32(0).u32(0).u32(0);

const locaTable = new Writer();
for (const offset of loca) locaTable.u32(offset);

// ── assemble ──────────────────────────────────────────────────────────────────────────────────
const tables = { "OS/2": os2, cmap, glyf, head, hhea, hmtx, loca: locaTable, maxp, name, post };
const tags = Object.keys(tables).sort();
const font = new Writer();
const pow = 2 ** Math.floor(Math.log2(tags.length));
font.u32(0x00010000).u16(tags.length).u16(pow * 16).u16(Math.log2(pow)).u16(tags.length * 16 - pow * 16);
let offset = 12 + tags.length * 16;
const records = [];
for (const tag of tags) {
  const bytes = tables[tag].bytes;
  records.push({ tag, sum: checksum(bytes), offset, length: bytes.length });
  offset += Math.ceil(bytes.length / 4) * 4;
}
for (const r of records) font.tag(r.tag).u32(r.sum).u32(r.offset).u32(r.length);
for (const tag of tags) font.raw(tables[tag].bytes).pad4();
const bytes = font.buffer();
const headAt = records.find((r) => r.tag === "head").offset;
const adjust = (0xb1b0afba - checksum(bytes)) >>> 0;
bytes[headAt + 8] = adjust >>> 24;
bytes[headAt + 9] = (adjust >>> 16) & 0xff;
bytes[headAt + 10] = (adjust >>> 8) & 0xff;
bytes[headAt + 11] = adjust & 0xff;

if (process.argv.includes("--check")) {
  let current = null;
  try { current = readFileSync(OUT); } catch { /* missing */ }
  if (!current || Buffer.compare(current, Buffer.from(bytes)) !== 0) {
    console.error("fonts/FlareKitIcons.ttf is out of date — run node scripts/build-icon-font.mjs");
    process.exit(1);
  }
  console.log(`FlareKitIcons.ttf current: ${GLYPHS.length} glyph(s)`);
} else {
  mkdirSync(dirname(OUT), { recursive: true });
  writeFileSync(OUT, bytes);
  console.log(`wrote fonts/FlareKitIcons.ttf: ${GLYPHS.map((g) => `${g.name} U+${g.code.toString(16).toUpperCase()}`).join(", ")} (${bytes.length} bytes)`);
}
