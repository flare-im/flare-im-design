export type MediaProxyRewriteConfig = {
  storageProxyPrefix?: string;
  storageProxyTargets?: string[];
};

let runtimeConfig: MediaProxyRewriteConfig = {};

/** Host app injects dev/prod media rewrite rules (e.g. Vite same-origin proxy). */
export function configureMediaProxy(config: MediaProxyRewriteConfig): void {
  runtimeConfig = { ...config };
}

export function sdkMediaProxyFields(): MediaProxyRewriteConfig {
  return runtimeConfig;
}
