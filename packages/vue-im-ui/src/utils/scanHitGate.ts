/** Camera-independent scan arbitration. All kits run spec/scan-gate-vectors.json. */
export interface FlareScanPoint { x: number; y: number }
export interface FlareScanCode { raw: string; corners?: FlareScanPoint[] }
export type FlareScanHit = { kind: "ignore" } | { kind: "lock"; code: FlareScanCode; ready: boolean } | { kind: "choose"; codes: FlareScanCode[] };

export class FlareScanHitGate {
  private phase: "idle" | "collecting" | "choosing" | "busy" = "idle";
  private startedAt = 0;
  private lastAt = -Infinity;
  private candidates = new Map<string, FlareScanCode>();
  private suppressed = new Map<string, number | null>();
  private selected?: string;

  observe(frame: { codes: FlareScanCode[]; tsMs: number }): FlareScanHit {
    if (!Number.isFinite(frame.tsMs) || frame.tsMs < this.lastAt) return { kind: "ignore" };
    this.lastAt = frame.tsMs;
    const visible = new Map(frame.codes.filter(code => code.raw.length > 0).map(code => [code.raw, code]));
    for (const [raw, absentAt] of this.suppressed) {
      if (absentAt !== null && frame.tsMs - absentAt >= 1500) this.suppressed.delete(raw);
      else if (visible.has(raw)) this.suppressed.set(raw, null);
      else if (absentAt === null) this.suppressed.set(raw, frame.tsMs);
      else if (frame.tsMs - absentAt >= 1500) this.suppressed.delete(raw);
    }
    if (this.phase === "busy" || this.phase === "choosing") return { kind: "ignore" };
    const available = [...visible.values()].filter(code => !this.suppressed.has(code.raw));
    if (this.phase === "idle") {
      if (!available.length) return { kind: "ignore" };
      this.startedAt = frame.tsMs;
      this.phase = "collecting";
      this.candidates.clear();
      for (const code of available) this.candidates.set(code.raw, code);
      return { kind: "lock", code: available[0]!, ready: false };
    }
    for (const code of available) this.candidates.set(code.raw, code);
    if (frame.tsMs - this.startedAt < 150) return { kind: "ignore" };
    const codes = [...this.candidates.values()];
    if (codes.length > 1) {
      this.phase = "choosing";
      return { kind: "choose", codes };
    }
    this.phase = "busy";
    this.selected = codes[0]!.raw;
    return { kind: "lock", code: codes[0]!, ready: true };
  }

  /** Only an explicit marker gesture may select from a multi-code frame. */
  select(raw: string): FlareScanHit {
    const code = this.candidates.get(raw);
    if (this.phase !== "choosing" || !code) return { kind: "ignore" };
    this.phase = "busy";
    this.selected = raw;
    return { kind: "lock", code, ready: true };
  }

  /** Resume capture; a dismissed code must leave view continuously for 1.5s. */
  dismiss(): void {
    for (const raw of this.selected ? [this.selected] : this.candidates.keys()) this.suppressed.set(raw, null);
    this.candidates.clear();
    this.selected = undefined;
    this.phase = "idle";
  }
}
