import { describe, expect, it, vi } from "vitest";
import { useFileDrop } from "./useFileDrop";

function drag(types: string[], files: File[] = []) {
  return { dataTransfer: { types, files, dropEffect: "none" }, preventDefault: vi.fn() } as unknown as DragEvent;
}

describe("useFileDrop", () => {
  it("tracks nested drag depth and hands accepted files to the host", () => {
    const onFiles = vi.fn();
    let accepts = true;
    const drop = useFileDrop({ enabled: () => true, accepts: () => accepts, onFiles });
    const file = new File(["x"], "a.png", { type: "image/png" });
    drop.onDragEnter(drag(["Files"]));
    drop.onDragEnter(drag(["Files"]));
    expect(drop.active.value).toBe(true);
    drop.onDragLeave();
    expect(drop.active.value).toBe(true);
    drop.onDrop(drag(["Files"], [file]));
    expect(onFiles).toHaveBeenCalledWith([file]);
    expect(drop.active.value).toBe(false);
    accepts = false;
    drop.onDragEnter(drag(["Files"]));
    expect(drop.active.value).toBe(false);
    drop.onDrop(drag(["Files"], [file]));
    expect(onFiles).toHaveBeenCalledTimes(1);
  });

  it("ignores non-file drags and disabled targets", () => {
    const onFiles = vi.fn();
    const drop = useFileDrop({ enabled: () => false, accepts: () => true, onFiles });
    const event = drag(["Files"], [new File(["x"], "a.txt")]);
    drop.onDragEnter(event);
    drop.onDrop(event);
    expect(event.preventDefault).not.toHaveBeenCalled();
    expect(onFiles).not.toHaveBeenCalled();
    const enabled = useFileDrop({ enabled: () => true, accepts: () => true, onFiles });
    enabled.onDragEnter(drag(["text/plain"]));
    expect(enabled.depth.value).toBe(0);
  });
});
