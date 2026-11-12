/** Explicit N/A is separate from a missing or incomplete required implementation. */
export function platformContractIssues(component, platforms) {
  const errors = [], missing = [];
  const notApplicable = component.notApplicablePlatforms ?? {};
  for (const [platform, reason] of Object.entries(notApplicable)) {
    if (!platforms.includes(platform)) errors.push(`unknown not-applicable platform ${platform}`);
    if (component.platforms?.[platform] !== undefined) errors.push(`platform ${platform} cannot be both implemented and not applicable`);
    if (typeof reason !== "string" || reason.trim().length < 40) errors.push(`platform ${platform} requires a specific not-applicable reason`);
  }
  for (const platform of platforms) {
    const binding = component.platforms?.[platform];
    if (binding === undefined) {
      if (!(platform in notApplicable)) missing.push(platform);
    } else if (!binding?.package || !binding?.symbol) {
      errors.push(`platform ${platform} 声明了却缺 package/symbol（契约不完整）`);
    }
  }
  return { errors, missing };
}
