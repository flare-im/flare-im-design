export type AppMediaPathPickerRequest = {
  accept: string;
  multiple: boolean;
  kind: string;
};

export type AppMediaPathPicker = (request: AppMediaPathPickerRequest) => Promise<readonly string[]>;

let mediaPathPicker: AppMediaPathPicker | undefined;

export function configureAppMediaPathPicker(picker?: AppMediaPathPicker): void {
  mediaPathPicker = picker;
}

export function hasAppMediaPathPicker(): boolean {
  return Boolean(mediaPathPicker);
}

export async function pickAppMediaSourcePaths(request: AppMediaPathPickerRequest): Promise<string[]> {
  if (!mediaPathPicker) return [];
  return (await mediaPathPicker(request)).map((path) => path.trim()).filter(Boolean);
}
