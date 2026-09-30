/**
 * Geometry and number formatting behind the kit's dependency-free charts (FlareChartCard,
 * FlareMetricTile). Everything here is pure, so the edge cases a dashboard really meets — no points,
 * one point, every reading zero, negative readings, a missing reading in the middle — are unit-tested
 * without a DOM.
 *
 * Coordinates are in a 0..100 × 0..100 viewBox that the SVG stretches to its box
 * (`preserveAspectRatio="none"`): x grows to the inline end, y grows downwards, 0 is the top. Lines
 * and dots are drawn with `vector-effect: non-scaling-stroke`, so the stretch never makes a stroke
 * thicker on one axis than the other.
 */

/** One reading of a series. `value: null` is a label with no reading (collection failed, not zero). */
export interface FlareChartPoint {
  label: string;
  value: number | null;
}

/** The value range the plot shows: always contains 0, and `max > min`. */
export interface ChartDomain {
  min: number;
  max: number;
  /** No reading differs from zero (or there is none): only the zero line has a meaning. */
  flat: boolean;
}

export interface ChartBar {
  index: number;
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface ChartSlot {
  index: number;
  x: number;
  width: number;
  center: number;
}

export interface ChartVertex {
  index: number;
  x: number;
  y: number;
}

export interface ChartTick {
  value: number;
  y: number;
}

export const CHART_VIEWBOX = 100;
/** A bar never grows wider than this share of the plot, so one or two points do not read as a slab. */
const MAX_BAR_WIDTH = 12;
/** A bar takes this share of its slot; the rest is the gap between bars. */
const BAR_FILL = 0.64;

export function isReading(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value);
}

/** The readings of a series, in order, without the missing ones. */
export function chartReadings(points: readonly FlareChartPoint[]): number[] {
  return points.map((point) => point.value).filter(isReading);
}

/** The smallest of 1, 2, 2.5, 5 × 10ⁿ that is not below `value` — gridline values people can read. */
export function niceCeil(value: number): number {
  if (!(value > 0) || !Number.isFinite(value)) return 0;
  const magnitude = 10 ** Math.floor(Math.log10(value));
  // Rounded so floating-point noise (0.3 / 0.1 is 2.9999999999999996) never moves a value across a step.
  const fraction = Math.round((value / magnitude) * 1e9) / 1e9;
  const step = fraction <= 1 ? 1 : fraction <= 2 ? 2 : fraction <= 2.5 ? 2.5 : fraction <= 5 ? 5 : 10;
  return step * magnitude;
}

export function chartDomain(readings: readonly number[]): ChartDomain {
  let high = 0;
  let low = 0;
  for (const value of readings) {
    if (value > high) high = value;
    if (value < low) low = value;
  }
  const max = niceCeil(high);
  const min = low < 0 ? -niceCeil(-low) : 0;
  // Nothing but zeros: draw the zero line at the bottom and give the empty band above it a unit
  // height, so no coordinate divides by zero.
  if (max === min) return { min: 0, max: 1, flat: true };
  return { min, max, flat: false };
}

export function chartY(value: number, domain: ChartDomain): number {
  return (CHART_VIEWBOX * (domain.max - value)) / (domain.max - domain.min);
}

/** One equal slot per label, the whole width shared out; the hover target and the bar's lane. */
export function chartSlots(count: number): ChartSlot[] {
  if (count <= 0) return [];
  const width = CHART_VIEWBOX / count;
  return Array.from({ length: count }, (_, index) => ({
    index,
    x: index * width,
    width,
    center: index * width + width / 2,
  }));
}

/** A bar per reading, standing on (or hanging from) the zero line; a missing reading has none. */
export function chartBars(points: readonly FlareChartPoint[], domain: ChartDomain): ChartBar[] {
  const slots = chartSlots(points.length);
  const zero = chartY(0, domain);
  const bars: ChartBar[] = [];
  points.forEach((point, index) => {
    if (!isReading(point.value)) return;
    const slot = slots[index];
    const width = Math.min(slot.width * BAR_FILL, MAX_BAR_WIDTH);
    const top = chartY(point.value, domain);
    bars.push({
      index,
      x: slot.center - width / 2,
      y: Math.min(top, zero),
      width,
      height: Math.abs(zero - top),
    });
  });
  return bars;
}

/** The line's runs: a missing reading breaks the line instead of pulling it to zero. */
export function chartSegments(points: readonly FlareChartPoint[], domain: ChartDomain): ChartVertex[][] {
  const slots = chartSlots(points.length);
  const segments: ChartVertex[][] = [];
  let current: ChartVertex[] = [];
  points.forEach((point, index) => {
    if (!isReading(point.value)) {
      if (current.length) segments.push(current);
      current = [];
      return;
    }
    current.push({ index, x: slots[index].center, y: chartY(point.value, domain) });
  });
  if (current.length) segments.push(current);
  return segments;
}

/** A path coordinate, rounded to 1/1000 of the plot: short `d` strings, no floating-point noise. */
export const chartPathCoordinate = (value: number) => String(Math.round(value * 1000) / 1000);
const coordinate = chartPathCoordinate;

export function chartLinePath(segments: readonly ChartVertex[][]): string {
  return segments
    .filter((segment) => segment.length > 1)
    .map((segment) => segment.map((vertex, i) => `${i ? "L" : "M"}${coordinate(vertex.x)} ${coordinate(vertex.y)}`).join(" "))
    .join(" ");
}

/** The tint under the line, closed down to the zero line; a lone reading has no area. */
export function chartAreaPath(segments: readonly ChartVertex[][], domain: ChartDomain): string {
  const zero = coordinate(chartY(0, domain));
  return segments
    .filter((segment) => segment.length > 1)
    .map((segment) => {
      const first = segment[0];
      const last = segment[segment.length - 1];
      const run = segment.map((vertex, i) => `${i ? "L" : "M"}${coordinate(vertex.x)} ${coordinate(vertex.y)}`).join(" ");
      return `${run} L${coordinate(last.x)} ${zero} L${coordinate(first.x)} ${zero} Z`;
    })
    .join(" ");
}

/**
 * The dots a line chart draws: every reading that has no neighbour to draw a line to (else it would
 * not show at all — a single point is exactly this), and the latest reading.
 */
export function chartMarkers(segments: readonly ChartVertex[][]): ChartVertex[] {
  const markers = new Map<number, ChartVertex>();
  for (const segment of segments) if (segment.length === 1) markers.set(segment[0].index, segment[0]);
  const lastSegment = segments[segments.length - 1];
  const latest = lastSegment?.[lastSegment.length - 1];
  if (latest) markers.set(latest.index, latest);
  return [...markers.values()].sort((a, b) => a.index - b.index);
}

/** Gridline values, top to bottom. A flat series has only the zero line. */
export function chartTicks(domain: ChartDomain): ChartTick[] {
  const values = domain.flat
    ? [0]
    : domain.min < 0
      ? [domain.max, 0, domain.min]
      : [domain.max, domain.max / 2, 0];
  return values.map((value) => ({ value, y: chartY(value, domain) }));
}

// ── numbers ───────────────────────────────────────────────────────────────

function numberFormat(locale: string | undefined, options: Intl.NumberFormatOptions): Intl.NumberFormat {
  try {
    return new Intl.NumberFormat(locale, options);
  } catch {
    // A host-registered tag the runtime does not know still gets digits, in the runtime's default.
    return new Intl.NumberFormat(undefined, options);
  }
}

/** A unit that is one symbol (%, ‰, °) rather than a word. */
export function isSymbolUnit(unit: string): boolean {
  return /^[^\p{L}\p{N}\s]$/u.test(unit);
}

/** A value with its unit: a lone symbol such as % or ‰ sits on the number, a word takes a space. */
export function withUnit(text: string, unit?: string): string {
  if (!unit) return text;
  return isSymbolUnit(unit) ? `${text}${unit}` : `${text} ${unit}`;
}

export function formatChartNumber(value: number, locale?: string, options: { compact?: boolean; signed?: boolean } = {}): string {
  return numberFormat(locale, {
    maximumFractionDigits: options.compact ? 1 : 2,
    notation: options.compact ? "compact" : "standard",
    signDisplay: options.signed ? "exceptZero" : "auto",
  }).format(value);
}
