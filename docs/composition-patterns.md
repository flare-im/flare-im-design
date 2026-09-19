# Composition Patterns

The canonical definitions are generated in `spec/composition-patterns.json`. A pattern names regions and behavior; it is not another component package.

| Pattern | Required regions | Typical adaptation |
|---|---|---|
| DesktopWorkbench | navigation, primary pane, content pane | Three panes on wide desktop; supporting content becomes overlay or route |
| ConversationWorkspace | conversation list, conversation content | Master-detail on desktop; list/detail navigation on mobile |
| ChatWorkspace | header, message list, composer | Fixed composer with virtualized timeline |
| ThreadWorkspace | thread header, thread list, thread composer | Side panel on desktop; sheet or route on mobile |
| SearchWorkspace | query, filters, results | Dense desktop panel; full-screen mobile search |
| MediaWorkspace | media navigation, media content | Inspector on desktop; native viewer route on mobile |
| ContactWorkspace | contact list, contact detail | Split view or navigation stack |
| GroupWorkspace | group header, member/content area | Inline tools or sheet-based actions |
| CallWorkspace | call stage, controls | Window-aware controls and compact mobile dock |
| SettingsWorkspace | settings navigation, settings content | Sidebar categories or pushed screens |
| NotificationWorkspace | notification list, detail/action region | Split view or one-screen feed |

Every pattern must expose loading, ready, empty, error, offline, and permission-denied composition points where relevant. Optional status, overlay, and command-host regions remain host supplied.

Responsive collapse preserves the primary task, moves supporting regions into a drawer/sheet/route, and never keeps an invisible duplicate focus target. Platform adaptations should use native navigation and sheet conventions rather than pixel-matching the web shell.
