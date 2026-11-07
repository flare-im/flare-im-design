import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  flareProgressBarValue,
  flareUpdateFailure,
  flareUpdatePrompt,
  flareUpdateVersionShown,
  flareVersionChannelText,
  flareVersionPanel,
  type FlareUpdatePromptInput,
} from "./updatePrompt";

/**
 * The shared update table (`spec/update-prompt-vectors.json`): what the host read in, what the prompt, the bar and the
 * version panel show out. The Flutter, SwiftUI and Compose kits run the same file.
 */
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../spec/update-prompt-vectors.json"), "utf8")) as {
  failures: { errorCode: string | null; message: string }[];
  versions: { version: string | null; shown: boolean }[];
  progressBar: { value: number | null; indeterminate: boolean; shown: number | null; percent: number | null }[];
  versionPanel: { updateState: string | null; row: string; action: string | null; detail: string | null }[];
  channels: { channel: string | null; text: string | null }[];
  cases: { name: string; input: FlareUpdatePromptInput; expect: Record<string, unknown> }[];
};

describe("update prompt rules", () => {
  it.each(table.cases)("$name", ({ input, expect: expected }) => {
    expect(flareUpdatePrompt(input)).toEqual(expected);
  });

  it.each(table.failures)("reads $errorCode as $message", ({ errorCode, message }) => {
    expect(flareUpdateFailure(errorCode)).toBe(message);
  });

  it.each(table.versions)("draws the version line for \"$version\": $shown", ({ version, shown }) => {
    expect(flareUpdateVersionShown(version)).toBe(shown);
  });

  it("reads a size it cannot show as unknown", () => {
    const metered = { form: "modal", errorCode: "update.meteredConfirmationRequired" } as const;
    expect(flareUpdatePrompt({ ...metered, sizeBytes: -1 }).message).toBe("meteredUnknown");
    expect(flareUpdatePrompt({ ...metered, sizeBytes: Number.NaN }).message).toBe("meteredUnknown");
    expect(flareUpdatePrompt({ ...metered, sizeBytes: 0 }).message).toBe("metered");
  });
});

describe("progress bar rules", () => {
  it.each(table.progressBar)("reads $value (indeterminate $indeterminate)", ({ value, indeterminate, shown, percent }) => {
    expect(flareProgressBarValue(value, indeterminate)).toEqual({ value: shown, percent });
  });

  it("reads a value that is not finite as indeterminate", () => {
    expect(flareProgressBarValue(Number.NaN)).toEqual({ value: null, percent: null });
    expect(flareProgressBarValue(Number.POSITIVE_INFINITY)).toEqual({ value: null, percent: null });
  });
});

describe("version panel rules", () => {
  it.each(table.versionPanel)("reads $updateState", ({ updateState, row, action, detail }) => {
    expect(flareVersionPanel(updateState)).toEqual({ row, action, detail });
  });

  it.each(table.channels)("reads the channel $channel", ({ channel, text }) => {
    expect(flareVersionChannelText(channel)).toBe(text);
  });
});
