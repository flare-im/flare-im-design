import SwiftUI

/// Full-screen video player chrome — poster, title, close, play surface. Spec:
/// Media/VideoPlayerModal (`VideoPlayerView`).
///
/// `player` is the playback surface (the kit's timeline default passes its AVKit player; a host may
/// pass its own); the close key and title sit above it, clear of the player's own controls. Without
/// a player, the poster + play affordance is shown and `onPlay` fires on tap. VoiceOver's escape
/// gesture closes it like the close key.
public struct VideoPlayerView: View {
    private let show: Bool
    private let videoSrc: String
    private let poster: String?
    private let title: String?
    private let player: AnyView?
    private let onPlay: (() -> Void)?
    private let onClose: (() -> Void)?
    @Environment(\.flareStrings) private var strings

    public init(
        show: Bool,
        videoSrc: String,
        poster: String? = nil,
        title: String? = nil,
        player: AnyView? = nil,
        onPlay: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.show = show
        self.videoSrc = videoSrc
        self.poster = poster
        self.title = title
        self.player = player
        self.onPlay = onPlay
        self.onClose = onClose
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

    /// The close key and the title.
    private var chrome: some View {
        HStack(spacing: FlareSizes.spacingMd) {
            Button { onClose?() } label: {
                Image(systemName: flareIconSymbol("close")).font(.system(size: 20)).foregroundColor(.white)
                    .frame(width: FlareSizes.touchTarget, height: FlareSizes.touchTarget).background(Circle().fill(.white.opacity(0.25)))
            }.buttonStyle(.plain)
            .accessibilityLabel(strings.close)
            if let title, !title.isEmpty {
                Text(title).font(.system(size: FlareSizes.fontSize2xl, weight: .semibold))
                    .foregroundColor(.white).lineLimit(1)
            }
            Spacer()
        }
        .padding()
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
