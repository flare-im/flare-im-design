// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { enableAutoUnmount, mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { nextTick } from "vue";
import FlarePluginForm from "./FlarePluginForm.vue";
import FlarePluginView from "../messages/FlarePluginView.vue";
import {
  flarePluginNativeIntoKey,
  type FlarePluginActionTarget,
  type FlarePluginFileAction,
  type FlarePluginInput,
  type FlarePluginLocationAction,
  type FlarePluginViewModel,
} from "../../shared/contracts/plugin-ui";

enableAutoUnmount(afterEach);
const vectors = JSON.parse(
  readFileSync(resolve(__dirname, "../../../../../spec/plugin-native-into-vectors.json"), "utf8"),
) as { cases: { target: FlarePluginActionTarget | null; input: FlarePluginInput; key: "file" | "location" | null }[] };

const front: FlarePluginInput = {
  id: "front", kind: "document", label: "Front", required: true, side: "front",
  file: { accept: ["image/jpeg"], maxBytes: 1048576 },
} as FlarePluginInput;
const area: FlarePluginInput = { id: "area", kind: "location", label: "Area", precision: "coarse" };
const scan: FlarePluginActionTarget = { kind: "native", capability: "documentCapture", params: { side: "front" }, into: "front" };
const locate: FlarePluginActionTarget = { kind: "native", capability: "locationOnce", params: { precision: "coarse" }, into: "area" };

describe("a native action into a form input", () => {
  it("follows the shared vectors", () => {
    for (const c of vectors.cases) expect(flarePluginNativeIntoKey(c.target ?? undefined, c.input) ?? null).toBe(c.key);
  });

  it("runs through the input's own key, with the form's scope, before the input was touched", async () => {
    const files: FlarePluginFileAction[] = [];
    const places: FlarePluginLocationAction[] = [];
    const wrapper = mount(FlarePluginForm, {
      props: {
        inputs: [front, area],
        onFileAction: (a: FlarePluginFileAction) => files.push(a),
        onLocationAction: (a: FlarePluginLocationAction) => places.push(a),
      },
    });
    const form = wrapper.vm as unknown as { nativeInto(t: FlarePluginActionTarget): boolean };
    expect(form.nativeInto(scan)).toBe(true);
    expect(files.map((a) => [a.action, a.inputId])).toEqual([["choose", "front"]]);
    expect(files[0].scope).not.toBe("");
    // The host writes the engine's reference under that ticket: the input holds it.
    await wrapper.setProps({
      fileStates: { front: { scope: files[0].scope, generation: files[0].generation, phase: "uploaded", value: { fileId: "file:1" } } },
    });
    await nextTick();
    // A second capture replaces the held file.
    expect(form.nativeInto(scan)).toBe(true);
    expect(files.at(-1)?.action).toBe("replace");
    expect(form.nativeInto(locate)).toBe(true);
    expect(places.map((a) => [a.action, a.inputId])).toEqual([["locate", "area"]]);
    // Not an input of this form: the action goes out as itself.
    expect(form.nativeInto({ ...scan, into: "back" })).toBe(false);
  });

  it("is not taken when the host does not handle that key", () => {
    const wrapper = mount(FlarePluginForm, { props: { inputs: [front] } });
    const form = wrapper.vm as unknown as { nativeInto(t: FlarePluginActionTarget): boolean };
    expect(form.nativeInto(scan)).toBe(false);
  });

  it("a page's scan action fills the inline form's document input instead of going out", async () => {
    const view: FlarePluginViewModel = {
      available: true,
      title: "Identity",
      fields: [],
      inputs: [front],
      actions: [
        { id: "scan", label: "Scan", target: scan },
        { id: "submit", label: "Submit", form: ["front"], style: "primary", target: { kind: "operation", operation: "example.submit" } },
      ],
    };
    const sent: string[] = [];
    const files: FlarePluginFileAction[] = [];
    const wrapper = mount(FlarePluginView, {
      props: {
        view,
        inlineFormActionId: "submit",
        onAction: (id: string) => sent.push(id),
        onFileAction: (a: FlarePluginFileAction) => files.push(a),
      },
    });
    await wrapper.get('[data-action-id="scan"]').trigger("click");
    expect(sent).toEqual([]);
    expect(files.map((a) => [a.action, a.inputId])).toEqual([["choose", "front"]]);
  });
});
