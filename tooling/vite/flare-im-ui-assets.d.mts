/**
 * Serves (dev) and copies (build) the kit's emoji and sticker resources under `<base><path>/`.
 * Returns a Vite plugin; typed loosely so hosts on any Vite major can use it.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export declare function flareImUiAssets(options?: { root?: string; path?: string }): any;
