export const applicationPreviewComponents = [
  "AppLayout",
  "AdaptiveNavigation",
  "MobileAppShell",
  "DesktopAppShell",
  "ConversationListContainer",
  "FriendListContainer",
  "WorkspaceFrame",
  "IMAppKit",
];

export const directoryPreviewComponents = [
  "MomentsVisibilityRuleList",
  "ContactMatchList",
  "AnnouncementReadBar",
  "MomentAudienceSheet",
];

export const scenePreviewComponents = [
  "CapabilityBoundary",
  "DangerConfirm",
  "MemberPanel",
  "DeviceSessions",
  "NotificationPreferences",
  "MediaCenter",
];

export const previewAliases = {
  Composer: "ComposerDemo",
  PinnedMessageBar: "PinnedBarDemo",
};

export function previewDemoName(name) {
  if (applicationPreviewComponents.includes(name)) return "ApplicationCompositionDemo";
  if (directoryPreviewComponents.includes(name)) return "DirectoryMomentDemo";
  if (scenePreviewComponents.includes(name)) return "ScenePanelsDemo";
  return previewAliases[name] ?? `${name}Demo`;
}

export function previewDemoProps(name) {
  if (applicationPreviewComponents.includes(name)) return { component: name };
  if (directoryPreviewComponents.includes(name)) return { component: name };
  if (scenePreviewComponents.includes(name)) return { mode: name };
  return {};
}
