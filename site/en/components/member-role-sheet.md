---
title: MemberRoleSheet
---

# MemberRoleSheet

Management menu for ONE group member: change role, mute, remove, transfer ownership. The host passes the member snapshot, its own role and the capabilities it can honour; the shared `memberRoleActions(member, viewerRole, capabilities)` contract decides what is shown — rank rules first, capability switches only narrowing further — so all four platforms render the same set, order and danger grouping. The component owns no positioning: hosts place it in a bottom sheet or popover.

<div class="flare-demo flare-demo--stack"><MemberRoleSheetDemo /></div>

<ComponentApi name="MemberRoleSheet" />

Rank rules: the owner is untouchable — no promote, demote, mute, remove or transfer against them, and the sheet says so instead of going blank. A plain member sees no management action at all. An admin cannot act on a peer admin and can never transfer ownership; it manages members only. The owner can manage members and admins and can transfer ownership. promote applies to a member, demote to an admin, and mute/unmute are mutually exclusive by `member.muted`. `mute` also needs host-supplied durations: with an empty `muteDurations` the row is not offered, because the kit ships no durations of its own.

The action enum is `promote | demote | mute | unmute | transferOwner | remove`, in that order. `transferOwner` and `remove` are destructive: they sit alone in a trailing danger group with the error token plus an icon, never colour alone. Tapping mute expands the host's durations in place and only a chosen duration dispatches `{ memberId, action: "mute", durationId }`; unmute dispatches directly. `busy` disables every row and every duration button.

**The second confirmation is not in this component.** Remove and transfer ownership must be routed through the host's DangerConfirm; the sheet only emits intent, never mutates the snapshot and never performs a network call. Hosts set `busy` synchronously before dispatching and update the member snapshot once the SDK confirms. `close` fires on Escape (collapsing the duration list first when it is open); the host dismisses its own overlay.

Entries: FlareMemberRoleSheet (Vue/Flutter), MemberRoleSheetView (SwiftUI), MemberRoleSheet (Compose). Native callbacks: onAction(memberId, action, durationId), onClose(); a native sheet with no onAction renders every row disabled. Rows are at least 48 logical units, the menu exposes the member name as its accessible name, each row is a `menuitem` (mute carries `aria-expanded`), and Tab / Enter / Escape work with a visible focus ring. See the [full integration guide](/components/member-role-sheet).
