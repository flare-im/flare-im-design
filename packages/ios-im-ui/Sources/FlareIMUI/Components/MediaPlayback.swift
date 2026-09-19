import AVFoundation
import AVKit
import SwiftUI

// The kit's default media behaviour for a timeline whose host passes no media handler: an image opens
// the kit preview full screen, a video opens the kit player full screen and plays, and a voice message
// plays inside its bubble, one at a time. Leaving the app (files, links, locations) stays with the host.

/// What the kit viewer shows full screen.
struct FlareMediaPresentation: Identifiable, Equatable {
    enum Kind: Equatable {
        /// The full-size image (else the thumbnail) and its description.
        case image(url: String, alt: String?)
        /// A gallery of images (address and description each), starting at `index`.
        case gallery(images: [FlareGalleryImage], index: Int)
        /// The video and its poster.
        case video(url: String, poster: String?)
    }

    let id = UUID()
    let kind: Kind
    /// The host's download handler for this media; the viewer offers a download control only with one.
    let onDownload: (() -> Void)?

    init(_ kind: Kind, onDownload: (() -> Void)? = nil) {
        self.kind = kind; self.onDownload = onDownload
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id && lhs.kind == rhs.kind }
}

/// One image of a presented gallery.
struct FlareGalleryImage: Equatable {
    let url: String
    let alt: String?
    /// The host's download handler for this image; the viewer offers a download control only with one.
    let onDownload: (() -> Void)?

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.url == rhs.url && lhs.alt == rhs.alt }
}

/// The media the kit viewer presents, if any.
@MainActor
final class FlareMediaViewerState: ObservableObject {
    @Published var presentation: FlareMediaPresentation?
}

/// Where a voice message is in its playback.
enum FlareVoicePhase: Equatable { case idle, playing, paused, failed }

/// The audio player behind ``FlareVoicePlayback``; ``FlareAVVoiceEngine`` plays for real, tests drive a fake.
@MainActor
protocol FlareVoiceEngine: AnyObject {
    /// Elapsed seconds while playing.
    var onProgress: ((TimeInterval) -> Void)? { get set }
    /// Playback reached the end.
    var onFinish: (() -> Void)? { get set }
    /// The media could not be loaded or played.
    var onFailure: (() -> Void)? { get set }
    func play(_ url: URL)
    func pause()
    func resume()
    func stop()
}

/// Voice playback for a timeline: one voice message at a time, in this playback and across every other
/// one in the app (starting a voice stops the one playing before it).
@MainActor
final class FlareVoicePlayback: ObservableObject {
    /// The voice message being played, paused or failed; nil when idle.
    @Published private(set) var activeId: String?
    @Published private(set) var phase: FlareVoicePhase = .idle
    /// Seconds played of the active message.
    @Published private(set) var elapsed: TimeInterval = 0

    private let engine: FlareVoiceEngine
    /// The playback that played last, so starting a voice elsewhere stops it.
    private static weak var current: FlareVoicePlayback?

    init(engine: FlareVoiceEngine? = nil) {
        self.engine = engine ?? FlareAVVoiceEngine()
        self.engine.onProgress = { [weak self] seconds in
            guard let self, self.phase == .playing else { return }
            self.elapsed = seconds
        }
        self.engine.onFinish = { [weak self] in self?.reset() }
        self.engine.onFailure = { [weak self] in
            guard let self, self.activeId != nil else { return }
            self.phase = .failed
        }
    }

    /// A tap on the voice message `id`: plays it from `url`; pauses or resumes it while it is the active
    /// one; plays it again after a failure.
    func toggle(id: String, url: String) {
        guard id == activeId else { return start(id: id, url: url) }
        switch phase {
        case .playing:
            engine.pause()
            phase = .paused
        case .paused:
            engine.resume()
            phase = .playing
        case .failed, .idle:
            start(id: id, url: url)
        }
    }

    /// Stops the active message, if any; the list calls it when it goes away.
    func stop() {
        guard activeId != nil else { return }
        engine.stop()
        reset()
    }

    private func start(id: String, url raw: String) {
        if let other = Self.current, other !== self { other.stop() }
        Self.current = self
        engine.stop()
        activeId = id
        elapsed = 0
        guard let url = Self.playableURL(raw) else {
            phase = .failed
            return
        }
        phase = .playing
        engine.play(url)
    }

    private func reset() {
        activeId = nil
        phase = .idle
        elapsed = 0
    }

    /// A URL the platform player can load: http(s), a file URL or an absolute file path. Anything else
    /// (empty, another scheme) cannot play and shows the failed state instead.
    nonisolated static func playableURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("/") { return URL(fileURLWithPath: trimmed) }
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(),
              ["http", "https", "file"].contains(scheme) else { return nil }
        return url
    }
}

/// The audio session for kit playback: playback category while something plays (so the ring/silent
/// switch does not mute a voice message the user asked to hear), released for other apps afterwards.
enum FlareMediaAudioSession {
    static func activate() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    static func deactivate() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
}

/// AVFoundation voice playback: streams the URL with `AVPlayer`, reports progress four times a second,
/// the end, and a load or playback failure.
@MainActor
final class FlareAVVoiceEngine: FlareVoiceEngine {
    var onProgress: ((TimeInterval) -> Void)?
    var onFinish: (() -> Void)?
    var onFailure: (() -> Void)?
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var status: NSKeyValueObservation?
    private var observers: [NSObjectProtocol] = []
    /// Bumped by every play and stop, so a late callback for an earlier item does nothing.
    private var generation = 0

    func play(_ url: URL) {
        stop()
        FlareMediaAudioSession.activate()
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        let current = generation
        status = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            let failed = item.status == .failed
            Task { @MainActor in if failed, self?.generation == current { self?.fail() } }
        }
        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
                Task { @MainActor in if self?.generation == current { self?.finish() } }
            },
            center.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main) { [weak self] _ in
                Task { @MainActor in if self?.generation == current { self?.fail() } }
            },
        ]
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 4), queue: .main) { [weak self] time in
            let seconds = time.seconds
            Task { @MainActor in if seconds.isFinite, self?.generation == current { self?.onProgress?(seconds) } }
        }
        self.player = player
        player.play()
    }

    func pause() { player?.pause() }

    func resume() { player?.play() }

    func stop() {
        generation += 1
        guard let player else { return }
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        timeObserver = nil
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
        status = nil
        player.pause()
        self.player = nil
        FlareMediaAudioSession.deactivate()
    }

    private func finish() {
        stop()
        onFinish?()
    }

    private func fail() {
        stop()
        onFailure?()
    }
}

/// Video playback for the kit player: loads and plays the URL, and reports a load failure so the player
/// shows a failed state with retry instead of a blank screen.
@MainActor
final class FlareVideoPlayback: ObservableObject {
    enum Phase: Equatable { case idle, loading, ready, failed }

    @Published private(set) var phase: Phase = .idle
    private(set) lazy var player = AVPlayer()
    private var url: URL?
    private var status: NSKeyValueObservation?
    private var observers: [NSObjectProtocol] = []
    /// Bumped by every load, so a late callback for an earlier item does nothing.
    private var generation = 0

    /// Loads `raw` and starts playing; an unplayable URL fails at once.
    func load(_ raw: String) {
        guard let url = FlareVoicePlayback.playableURL(raw) else {
            fail()
            return
        }
        self.url = url
        start(url)
    }

    /// Loads the last URL again after a failure.
    func retry() {
        guard let url else { return fail() }
        start(url)
    }

    /// Stops playing and releases the item; the player calls it when it closes.
    func stop() {
        release(to: .idle)
    }

    /// Shows the failed state: the item could not load or play.
    func fail() {
        release(to: .failed)
    }

    private func release(to next: Phase) {
        let active = phase == .loading || phase == .ready
        detach()
        phase = next
        if active { FlareMediaAudioSession.deactivate() }
    }

    private func start(_ url: URL) {
        detach()
        let item = AVPlayerItem(url: url)
        let current = generation
        status = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            let value = item.status
            Task { @MainActor in if self?.generation == current { self?.statusChanged(value) } }
        }
        observers = [
            NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main) { [weak self] _ in
                Task { @MainActor in if self?.generation == current { self?.fail() } }
            },
        ]
        phase = .loading
        FlareMediaAudioSession.activate()
        player.replaceCurrentItem(with: item)
        player.play()
    }

    private func statusChanged(_ value: AVPlayerItem.Status) {
        switch value {
        case .readyToPlay where phase == .loading: phase = .ready
        case .failed: fail()
        default: break
        }
    }

    private func detach() {
        generation += 1
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
        status = nil
        if phase != .idle || url != nil {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
    }
}

/// The media defaults of one timeline: the viewer's presentation and the voice playback. A list owns
/// one; a message body outside a list owns its own.
@MainActor
final class FlareMediaSession: ObservableObject {
    let viewer: FlareMediaViewerState
    let voice: FlareVoicePlayback

    init(voice: FlareVoicePlayback? = nil) {
        viewer = FlareMediaViewerState()
        self.voice = voice ?? FlareVoicePlayback()
    }

    /// Opens the kit preview on the image: its full-size URL, else the thumbnail.
    func present(_ image: FlareImageContent, onDownload: (() -> Void)?) {
        let url = image.url.isEmpty ? (image.thumbnailURL ?? "") : image.url
        viewer.presentation = FlareMediaPresentation(.image(url: url, alt: image.alt), onDownload: onDownload)
    }

    /// Opens the picture at `index` of message `messageId`: inside a timeline (`gallery`) as the conversation's gallery
    /// starting at that picture, each picture downloadable with the timeline's handler; else — or when the picture is
    /// not in the gallery — `image` alone, downloadable with `onDownload`.
    func open(_ image: FlareImageContent, messageId: String?, index: Int, gallery: FlareImageGallerySource?,
              onDownload: (() -> Void)?) {
        let items = gallery.map { flareImageGalleryItems($0.messages) } ?? []
        guard let gallery, let messageId, let start = flareImageGalleryStart(items, messageId: messageId, index: index) else {
            present(image, onDownload: onDownload)
            return
        }
        var owners: [String: FlareMessageData] = [:]
        if gallery.download != nil {
            for message in gallery.messages where owners[message.id] == nil { owners[message.id] = message }
        }
        let images = items.map { item in
            FlareGalleryImage(url: item.source, alt: item.image.alt, onDownload: gallery.download.flatMap { download in
                owners[item.messageId].map { owner in { download(owner, item.image) } }
            })
        }
        viewer.presentation = FlareMediaPresentation(.gallery(images: images, index: start))
    }

    /// Opens the kit player on the video; a voice message playing stops first.
    func present(_ video: FlareVideoContent) {
        voice.stop()
        viewer.presentation = FlareMediaPresentation(.video(url: video.url, poster: video.poster))
    }

    func dismiss() {
        viewer.presentation = nil
    }
}

/// The kit viewer for one presentation: ``ImagePreviewView`` or ``VideoPlayerView`` with the kit's
/// AVKit player.
struct FlareMediaViewer: View {
    let presentation: FlareMediaPresentation
    let onClose: () -> Void
    @StateObject private var video = FlareVideoPlayback()

    var body: some View {
        switch presentation.kind {
        case let .image(url, alt):
            ImagePreviewView(show: true, imageSrc: url, alt: alt, onClose: onClose, onDownload: presentation.onDownload)
        case let .gallery(images, index):
            FlareImageGalleryViewer(images: images, startIndex: index, onClose: onClose)
        case let .video(url, poster):
            FlareVideoViewer(url: url, poster: poster, playback: video, onClose: onClose)
        }
    }
}

/// A conversation's image gallery: ``ImagePreviewView`` of one image at a time, paging to its neighbours with the side
/// keys or a sideways swipe and saying where it is. Each image opens fresh at normal size.
struct FlareImageGalleryViewer: View {
    let images: [FlareGalleryImage]
    let onClose: () -> Void
    @State private var index: Int

    init(images: [FlareGalleryImage], startIndex: Int, onClose: @escaping () -> Void) {
        self.images = images
        self.onClose = onClose
        _index = State(initialValue: min(max(startIndex, 0), max(images.count - 1, 0)))
    }

    var body: some View {
        if images.indices.contains(index) {
            ImagePreviewView(show: true, imageSrc: images[index].url, alt: images[index].alt, onClose: onClose,
                             onDownload: images[index].onDownload, galleryIndex: index, galleryCount: images.count,
                             onPrevious: index > 0 ? { index -= 1 } : nil,
                             onNext: index < images.count - 1 ? { index += 1 } : nil)
                .id(index)
        }
    }
}

/// ``VideoPlayerView`` over the kit's player surface; plays on appear and stops when it goes away.
struct FlareVideoViewer: View {
    let url: String
    let poster: String?
    @ObservedObject var playback: FlareVideoPlayback
    let onClose: () -> Void

    var body: some View {
        VideoPlayerView(show: true, videoSrc: url, poster: poster,
                        player: AnyView(FlareVideoSurface(playback: playback, onClose: onClose)),
                        onClose: onClose)
            .onAppear { playback.load(url) }
            .onDisappear { playback.stop() }
    }
}

/// The player surface: AVKit's player with its named system controls while loading or playing, and the
/// failed state — what happened, 重试 and 关闭 — when the video cannot load.
struct FlareVideoSurface: View {
    @ObservedObject var playback: FlareVideoPlayback
    let onClose: () -> Void
    @Environment(\.flareStrings) private var strings

    var body: some View {
        if playback.phase == .failed {
            VStack(spacing: FlareSizes.spacingLg) {
                Image(systemName: flareIconSymbol("error"))
                    .font(.system(size: FlareSizes.iconSizeXl))
                    .foregroundColor(.white.opacity(0.8))
                    .accessibilityHidden(true)
                Text(strings.videoLoadFailed)
                    .font(.system(size: FlareSizes.fontSizeLg))
                    .foregroundColor(.white)
                HStack(spacing: FlareSizes.spacingMd) {
                    failedAction(strings.retry) { playback.retry() }
                    failedAction(strings.close, onClose)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ZStack {
                VideoPlayer(player: playback.player)
                if playback.phase == .loading {
                    ProgressView().tint(.white)
                }
            }
        }
    }

    private func failedAction(_ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, FlareSizes.spacingLg)
                .flareTouchTarget()
                .background(Capsule().fill(Color.white.opacity(0.18)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

extension View {
    /// Presents the session's viewer — full screen on iOS, a sheet on the macOS test host, which has no
    /// full-screen cover — and stops its voice playback when this view goes away or the app goes to
    /// the background.
    func flareMediaDefaults(_ session: FlareMediaSession) -> some View {
        modifier(FlareMediaDefaultsPresenter(session: session, viewer: session.viewer))
    }
}

private struct FlareMediaDefaultsPresenter: ViewModifier {
    let session: FlareMediaSession
    @ObservedObject var viewer: FlareMediaViewerState
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        let item = Binding(get: { viewer.presentation }, set: { viewer.presentation = $0 })
        presented(content, item: item)
            .onDisappear { session.voice.stop() }
            .onChange(of: scenePhase) { phase in
                if phase == .background { session.voice.stop() }
            }
    }

    @ViewBuilder
    private func presented(_ content: Content, item: Binding<FlareMediaPresentation?>) -> some View {
        #if os(iOS)
        content.fullScreenCover(item: item) { presentation in
            FlareMediaViewer(presentation: presentation, onClose: { session.dismiss() })
        }
        #else
        content.sheet(item: item) { presentation in
            FlareMediaViewer(presentation: presentation, onClose: { session.dismiss() })
        }
        #endif
    }
}

/// A message body outside a list owns its media defaults.
struct FlareOwnedMediaSession<Content: View>: View {
    @StateObject private var session = FlareMediaSession()
    let content: (FlareMediaSession) -> Content

    var body: some View {
        content(session).flareMediaDefaults(session)
    }
}
