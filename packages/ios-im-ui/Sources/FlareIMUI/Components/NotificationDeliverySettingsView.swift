import SwiftUI

/// The system notification permission, as a settings row says it.
public enum FlareNotificationStatus: String, CaseIterable, Sendable {
    case on, off, notTurnedOn
}

/// What the system lets the app do in the background, in the words of the platform's battery settings.
public enum FlareBackgroundDelivery: String, CaseIterable, Sendable {
    case unrestricted, optimized, restricted
}

/// One extra way to keep background delivery working, offered by the host (a phone maker's auto-start page).
/// `label` defaults to the strings table's `backgroundDeliveryAutoStart`.
public struct FlareNotificationGuideAction {
    public let label: String?
    public let onSelect: () -> Void
    public init(label: String? = nil, onSelect: @escaping () -> Void) {
        self.label = label; self.onSelect = onSelect
    }
}

/// The words of `status` in a settings row.
public func notificationStatusLabel(_ status: FlareNotificationStatus, strings: FlareStrings = FlareStrings()) -> String {
    switch status {
    case .on: return strings.notificationStatusOn
    case .off: return strings.notificationStatusOff
    case .notTurnedOn: return strings.notificationStatusNotTurnedOn
    }
}

/// The words of `background` in a settings row.
public func backgroundDeliveryLabel(_ background: FlareBackgroundDelivery, strings: FlareStrings = FlareStrings()) -> String {
    switch background {
    case .unrestricted: return strings.backgroundDeliveryUnrestricted
    case .optimized: return strings.backgroundDeliveryOptimized
    case .restricted: return strings.backgroundDeliveryRestricted
    }
}

/// Whether new messages reach the person when the app is not in front, as one settings section.
/// Spec: Profile/NotificationDeliverySettings (`NotificationDeliverySettingsView`).
///
/// "New message notifications" shows the system permission (`status`; nil until it has been read) and hands the
/// press to the host in `onStatusAction`: the host asks for the permission or opens the system settings, whichever
/// the platform allows (without the callback the row is information only). With `background` a second row shows
/// what the battery settings let the app do and opens a guide in a kit bottom sheet: why background running
/// matters, the battery settings (`onOpenBatterySettings`) and any auto-start pages the host knows of
/// (`vendorActions`). iOS has no such setting, so an iOS host leaves `background` out. The section draws through
/// ``SettingsListView``, so it looks like the settings around it, and takes a `footer`. It reads nothing from the
/// platform and opens nothing itself.
///
/// Without `sectionContent` it draws the group as a list of its own. A settings page that is already one
/// ``SettingsListView`` passes `sectionContent` and places the group among its own sections:
///
/// ```swift
/// NotificationDeliverySettingsView(status: status, onStatusAction: openFromSettings) { notifications, select in
///     SettingsListView(sections: [general, notifications, about], onSelect: { if !select($0) { open($0) } })
/// }
/// ```
public struct NotificationDeliverySettingsView<SectionContent: View>: View {
    private let status: FlareNotificationStatus?
    private let background: FlareBackgroundDelivery?
    private let vendorActions: [FlareNotificationGuideAction]
    private let title: String?
    private let footer: String?
    private let onStatusAction: (() -> Void)?
    private let onOpenBatterySettings: (() -> Void)?
    private let sectionContent: (FlareSettingsSection, @escaping (FlareSettingsItem) -> Bool) -> SectionContent
    @Environment(\.flareStrings) private var strings
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @State private var guideOpen = false

    static var statusRow: String { "notifications" }
    static var backgroundRow: String { "backgroundDelivery" }
    static var batteryRow: String { "batteryUsage" }
    private static var vendorPrefix: String { "vendor:" }

    /// The section form: the host draws the list in `sectionContent` and gets the group as one
    /// ``FlareSettingsSection`` with `select`, which runs a row of the group (the status action, or the background
    /// guide in the kit bottom sheet) and returns whether the row was one; the host handles the rows it returns false
    /// for. The group's rows are keyed `notifications` and `backgroundDelivery`, so the host's own rows keep other
    /// keys.
    public init(status: FlareNotificationStatus?, background: FlareBackgroundDelivery? = nil,
                vendorActions: [FlareNotificationGuideAction] = [], title: String? = nil, footer: String? = nil,
                onStatusAction: (() -> Void)? = nil, onOpenBatterySettings: (() -> Void)? = nil,
                @ViewBuilder sectionContent: @escaping (_ section: FlareSettingsSection,
                                                        _ select: @escaping (FlareSettingsItem) -> Bool) -> SectionContent) {
        self.status = status; self.background = background; self.vendorActions = vendorActions
        self.title = title; self.footer = footer
        self.onStatusAction = onStatusAction; self.onOpenBatterySettings = onOpenBatterySettings
        self.sectionContent = sectionContent
    }

    /// The section's rows: the permission, then the background row where the platform has one.
    var section: FlareSettingsSection {
        var items = [FlareSettingsItem(
            key: Self.statusRow, label: strings.notificationDeliveryNewMessages, icon: "notification",
            kind: onStatusAction == nil ? .value : .navigation,
            detail: status.map { notificationStatusLabel($0, strings: strings) }
        )]
        if let background {
            items.append(FlareSettingsItem(
                key: Self.backgroundRow, label: strings.backgroundDeliveryLabel, icon: "refresh", kind: .navigation,
                detail: backgroundDeliveryLabel(background, strings: strings)
            ))
        }
        return FlareSettingsSection(title: title ?? strings.notificationDeliveryTitle, items: items, footer: footer)
    }

    public var body: some View {
        sectionContent(section, select)
            .flareBottomSheet(
                isPresented: Binding(get: { guideOpen && background != nil }, set: { guideOpen = $0 }),
                title: strings.backgroundDeliveryLabel
            ) {
                guide
            }
    }

    /// Runs a row of the group and says whether `item` was one.
    func select(_ item: FlareSettingsItem) -> Bool {
        switch item.key {
        case Self.statusRow:
            onStatusAction?()
            return true
        case Self.backgroundRow where background != nil:
            guideOpen = true
            return true
        default:
            return false
        }
    }

    /// The guide behind the background row: why it matters, the battery settings, then the maker's auto-start pages.
    private var guide: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        var rows = [FlareSettingsItem(
            key: Self.batteryRow, label: strings.backgroundDeliveryBattery,
            kind: onOpenBatterySettings == nil ? .value : .navigation,
            detail: background.map { backgroundDeliveryLabel($0, strings: strings) }
        )]
        for (index, action) in vendorActions.enumerated() {
            rows.append(FlareSettingsItem(key: "\(Self.vendorPrefix)\(index)",
                                          label: action.label ?? strings.backgroundDeliveryAutoStart, kind: .navigation))
        }
        return ScrollView {
            VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
                Text(strings.backgroundDeliveryExplanation)
                    .font(.system(size: FlareSizes.fontSizeMd))
                    .foregroundColor(colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, FlareSizes.spacingLg)
                if !vendorActions.isEmpty {
                    Text(strings.backgroundDeliveryAutoStartHint)
                        .font(.system(size: FlareSizes.fontSizeMd))
                        .foregroundColor(colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, FlareSizes.spacingLg)
                }
                SettingsListView(sections: [FlareSettingsSection(items: rows)], onSelect: selectInGuide, scrollable: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, FlareSizes.spacingLg)
        }
    }

    private func selectInGuide(_ item: FlareSettingsItem) {
        if item.key == Self.batteryRow {
            onOpenBatterySettings?()
        } else if item.key.hasPrefix(Self.vendorPrefix),
                  let index = Int(item.key.dropFirst(Self.vendorPrefix.count)), vendorActions.indices.contains(index) {
            vendorActions[index].onSelect()
        }
    }
}

public extension NotificationDeliverySettingsView where SectionContent == SettingsListView {
    /// The group as a list of its own: one section that sizes to its content.
    init(status: FlareNotificationStatus?, background: FlareBackgroundDelivery? = nil,
         vendorActions: [FlareNotificationGuideAction] = [], title: String? = nil, footer: String? = nil,
         onStatusAction: (() -> Void)? = nil, onOpenBatterySettings: (() -> Void)? = nil) {
        self.init(status: status, background: background, vendorActions: vendorActions, title: title, footer: footer,
                  onStatusAction: onStatusAction, onOpenBatterySettings: onOpenBatterySettings) { section, select in
            SettingsListView(sections: [section], onSelect: { _ = select($0) }, scrollable: false)
        }
    }
}
