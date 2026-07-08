import SwiftUI

/// Full-screen video player chrome — poster, title, close, play surface. Spec:
/// Media/VideoPlayerModal (`VideoPlayerView`).
///
/// The package stays dependency-free, so real decoding is provided by the host
/// via `player` (e.g. an `AVKit.VideoPlayer` wrapped in `AnyView`); without it,
/// the poster + play affordance is shown and `onPlay` fires on tap.
public struct VideoPlayerView: View {
    private let show: Bool
    private let videoSrc: String
    private let poster: String?
    private let title: String?
    private let player: AnyView?
    private let onPlay: (() -> Void)?
    private let onClose: (() -> Void)?

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
                    player
                } else {
                    posterWithPlay
                }

                VStack {
                    HStack(spacing: FlareSizes.spacingMd) {
                        Button { onClose?() } label: {
                            Image(systemName: "xmark").font(.system(size: 20)).foregroundColor(.white)
                                .frame(width: 38, height: 38).background(Circle().fill(.white.opacity(0.25)))
                        }.buttonStyle(.plain)
                        if let title, !title.isEmpty {
                            Text(title).font(.system(size: FlareSizes.fontSize2xl, weight: .semibold))
                                .foregroundColor(.white).lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding()
                    Spacer()
                }
            }
        }
    }

    private var posterWithPlay: some View {
        ZStack {
            if let poster, let url = URL(string: poster), !poster.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: { Color.clear }
            }
            Button { onPlay?() } label: {
                Image(systemName: "play.circle.fill").font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.9))
            }.buttonStyle(.plain)
        }
    }
}
