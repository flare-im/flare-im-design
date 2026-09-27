import SwiftUI

/// Full-screen video player chrome — poster, title, close, download, play surface. Spec:
/// Media/VideoPlayerModal (`VideoPlayerView`).
///
/// `player` is the playback surface (the kit's timeline default passes its AVKit player; a host may
/// pass its own); the close key and title sit above it, clear of the player's own controls. Without
/// a player, the poster + play affordance is shown and `onPlay` fires on tap. VoiceOver's escape
/// gesture closes it like the close key.
///
/// The download key sits at the top right, as in ``ImagePreviewView``, and appears only with
/// `onDownload`; while `downloading` it shows the progress (`progressPct`, 0–100) in its place, and once
/// the video is `saved` it is a folder that calls `onReveal` (without `onReveal` it stays the download key).
public struct VideoPlayerView: View {
    private let show: Bool
    private let videoSrc: String
    private let poster: String?
    private let title: String?
    private let player: AnyView?
    private let onPlay: (() -> Void)?
    private let onClose: (() -> Void)?
    private let onDownload: (() -> Void)?
    private let downloading: Bool
    private let progressPct: Int
    private let saved: Bool
    private let onReveal: (() -> Void)?
    @Environment(\.flareStrings) private var strings

    public init(
        show: Bool,
        videoSrc: String,
        poster: String? = nil,
        title: String? = nil,
        player: AnyView? = nil,
        onPlay: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        onDownload: (() -> Void)? = nil,
        downloading: Bool = false,
        progressPct: Int = 0,
        saved: Bool = false,
        onReveal: (() -> Void)? = nil
    ) {
        self.show = show
        self.videoSrc = videoSrc
        self.poster = poster
        self.title = title
        self.player = player
        self.onPlay = onPlay
        self.onClose = onClose
        self.onDownload = onDownload
        self.downloading = downloading
        self.progressPct = progressPct
        self.saved = saved
        self.onReveal = onReveal
    }

    public var body: some View {
        if !show {
            EmptyView()
        } else {
            ZStack {
                Color.black.ignoresSafeArea()

                if let player {
                    VStack(spacing: 0) {
                        chrome
                        player.frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    posterWithPlay
                    VStack {
                        chrome
                        Spacer()
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityAction(.escape) { onClose?() }
        }
    }

    /// The close key, the title, and the download key (its progress, or the saved video's folder) at the trailing end.
    private var chrome: some View {
        HStack(spacing: FlareSizes.spacingMd) {
            chromeKey("close", label: strings.close) { onClose?() }
            if let title, !title.isEmpty {
                Text(title).font(.system(size: FlareSizes.fontSize2xl, weight: .semibold))
                    .foregroundColor(.white).lineLimit(1)
            }
            Spacer()
            switch FlareMediaKey.resolve(canDownload: onDownload != nil, downloading: downloading, saved: saved,
                                         canReveal: onReveal != nil) {
            case .folder?:
                chromeKey("folder", label: strings.showInFolder) { onReveal?() }
            case .progress?:
                FlareMediaDownloadRing(progressPct: progressPct)
                    .frame(width: FlareSizes.touchTarget, height: FlareSizes.touchTarget)
            case .download?:
                chromeKey("download", label: strings.download) { onDownload?() }
            case nil:
                EmptyView()
            }
        }
        .padding()
    }

    /// A chrome key over the video: the kit icon `icon` on a touch-target disc, named `label`.
    private func chromeKey(_ icon: String, label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: flareIconSymbol(icon)).font(.system(size: 20)).foregroundColor(.white)
                .frame(width: FlareSizes.touchTarget, height: FlareSizes.touchTarget).background(Circle().fill(.white.opacity(0.25)))
        }.buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var posterWithPlay: some View {
        ZStack {
            if let poster, let url = URL(string: poster), !poster.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: { Color.clear }
            }
            // The kit's play glyph on the same chrome disc as the close key, at poster scale.
            Button { onPlay?() } label: {
                Image(systemName: flareIconSymbol("play")).font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 64, height: 64).background(Circle().fill(.white.opacity(0.25)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(strings.play)
        }
    }
}
