public enum FlareMessageContentCapability: String, Sendable, Hashable {
    case select, copy, openLink, horizontalScroll, open, save, retry, zoom, swipe
    case play, pause, fullscreen, seek, reveal, vote, toggleTask, jumpToOriginal
    case openThread, openOnce
}

public enum FlareMessageContentFamily: String, Sendable {
    case text, richText, code, image, video, audio, file, location, card, link
    case poll, task, calendar, miniApp, topic, system, forward, reply, thread, treatment
}

public enum FlareMessageContentKind: String, CaseIterable, Sendable {
    case text, richText, markdown, code, image, multiImage, video, audio, file
    case location, contactCard, linkPreview, poll, task, calendarEvent, miniApp
    case topic, system, notice, forward, mergedForward, reply, threadRoot
    case ephemeral, readOnce, burnAfterRead

    public var wireType: String? {
        switch self {
        case .text: "text"
        case .richText, .markdown, .code: "rich_text"
        case .image: "image"
        case .multiImage: "image_group"
        case .video: "video"
        case .audio: "audio"
        case .file: "file"
        case .location: "location"
        case .contactCard: "card"
        case .linkPreview: "link_card"
        case .poll: "vote"
        case .task: "task"
        case .calendarEvent: "schedule"
        case .miniApp: "mini_program"
        case .topic: "custom"
        case .system: "system"
        case .notice: "notification"
        case .forward, .mergedForward: "forward"
        case .reply: "quote"
        case .threadRoot: "thread"
        case .ephemeral, .readOnce, .burnAfterRead: nil
        }
    }

    public var family: FlareMessageContentFamily {
        switch self {
        case .text: .text
        case .richText, .markdown: .richText
        case .code: .code
        case .image, .multiImage: .image
        case .video: .video
        case .audio: .audio
        case .file: .file
        case .location: .location
        case .contactCard: .card
        case .linkPreview: .link
        case .poll: .poll
        case .task: .task
        case .calendarEvent: .calendar
        case .miniApp: .miniApp
        case .topic: .topic
        case .system, .notice: .system
        case .forward, .mergedForward: .forward
        case .reply: .reply
        case .threadRoot: .thread
        case .ephemeral, .readOnce, .burnAfterRead: .treatment
        }
    }

    public var capabilities: Set<FlareMessageContentCapability> {
        switch self {
        case .text: [.select, .copy]
        case .richText, .markdown: [.select, .copy, .openLink]
        case .code: [.select, .copy, .horizontalScroll]
        case .image: [.open, .save, .retry, .zoom]
        case .multiImage: [.open, .save, .retry, .zoom, .swipe]
        case .video: [.play, .pause, .fullscreen, .save, .retry]
        case .audio: [.play, .pause, .seek, .retry]
        case .file: [.open, .save, .reveal, .retry]
        case .location, .contactCard, .calendarEvent, .miniApp, .topic, .notice, .forward, .mergedForward: [.open]
        case .linkPreview: [.open, .copy]
        case .poll: [.vote]
        case .task: [.toggleTask, .open]
        case .system, .ephemeral: []
        case .reply: [.jumpToOriginal]
        case .threadRoot: [.openThread]
        case .readOnce, .burnAfterRead: [.openOnce]
        }
    }
}

public struct FlareMessageContentContract: Sendable {
    public let kind: FlareMessageContentKind
    public var wireType: String? { kind.wireType }
    public var family: FlareMessageContentFamily { kind.family }
    public var capabilities: Set<FlareMessageContentCapability> { kind.capabilities }
    public init(kind: FlareMessageContentKind) { self.kind = kind }
}

public func resolveMessageContentContract(_ kind: FlareMessageContentKind) -> FlareMessageContentContract {
    FlareMessageContentContract(kind: kind)
}
