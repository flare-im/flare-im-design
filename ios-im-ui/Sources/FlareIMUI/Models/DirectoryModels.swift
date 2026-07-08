import Foundation

/// A directory contact.
public struct Contact: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let avatarURL: String?
    public let signature: String?
    public let presence: FlarePresence?
    /// Explicit A-Z index letter; derived from name when nil.
    public let indexKey: String?

    public init(id: String, name: String, avatarURL: String? = nil, signature: String? = nil,
                presence: FlarePresence? = nil, indexKey: String? = nil) {
        self.id = id; self.name = name; self.avatarURL = avatarURL; self.signature = signature
        self.presence = presence; self.indexKey = indexKey
    }
}

public struct FriendRequest: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let avatarURL: String?
    public let message: String?
    public init(id: String, name: String, avatarURL: String? = nil, message: String? = nil) {
        self.id = id; self.name = name; self.avatarURL = avatarURL; self.message = message
    }
}

public struct GroupSummary: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let avatarURL: String?
    public let memberCount: Int
    public init(id: String, name: String, avatarURL: String? = nil, memberCount: Int = 0) {
        self.id = id; self.name = name; self.avatarURL = avatarURL; self.memberCount = memberCount
    }
}

public struct UserProfile: Sendable {
    public let id: String
    public let name: String
    public let avatarURL: String?
    public let signature: String?
    public let flareId: String?
    public init(id: String, name: String, avatarURL: String? = nil, signature: String? = nil, flareId: String? = nil) {
        self.id = id; self.name = name; self.avatarURL = avatarURL; self.signature = signature; self.flareId = flareId
    }
}

public enum FlareSettingKind: Sendable { case navigation, toggle, value }

public struct FlareSettingsItem: Identifiable, Sendable {
    public var id: String { key }
    public let key: String
    public let label: String
    public let systemImage: String?
    public let kind: FlareSettingKind
    public var value: Bool
    public let detail: String?
    public init(key: String, label: String, systemImage: String? = nil,
                kind: FlareSettingKind = .navigation, value: Bool = false, detail: String? = nil) {
        self.key = key; self.label = label; self.systemImage = systemImage
        self.kind = kind; self.value = value; self.detail = detail
    }
}

public struct FlareSettingsSection: Identifiable {
    public let id = UUID()
    public let title: String?
    public let items: [FlareSettingsItem]
    public init(title: String? = nil, items: [FlareSettingsItem]) {
        self.title = title; self.items = items
    }
}

public struct FlareNavItem: Identifiable, Sendable {
    public var id: String { key }
    public let key: String
    public let label: String
    public let systemImage: String
    public let badge: Int
    public init(key: String, label: String, systemImage: String, badge: Int = 0) {
        self.key = key; self.label = label; self.systemImage = systemImage; self.badge = badge
    }
}
