export interface FlareCommandPaletteCommand {
  id: string;
  label: string;
  description?: string;
  keywords?: string[];
  shortcut?: string;
  disabled?: boolean;
}

export interface FlareCommandPaletteGroup {
  id: string;
  label: string;
  commands: FlareCommandPaletteCommand[];
}
