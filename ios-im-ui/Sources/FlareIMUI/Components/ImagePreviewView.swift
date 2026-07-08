import SwiftUI

/// Full-screen image viewer — zoom/pan, download with progress. Spec:
/// Media/ImagePreviewModal (`ImagePreviewView`). Renders nothing when `show`
/// is false, so it can sit in a `ZStack`.
public struct ImagePreviewView: View {
    private let show: Bool
    private let imageSrc: String
    private let loading: Bool
    private let alt: String?
    private let downloading: Bool
    private let progressPct: Int
    private let zoomMin: CGFloat
    private let zoomMax: CGFloat
    private let onClose: (() -> Void)?
    private let onDownload: (() -> Void)?

    @State private var scale: CGFloat = 1

    public init(
        show: Bool,
        imageSrc: String,
        loading: Bool = false,
        alt: String? = nil,
        downloading: Bool = false,
        progressPct: Int = 0,
        zoomMin: CGFloat = 1,
        zoomMax: CGFloat = 4,
        onClose: (() -> Void)? = nil,
        onDownload: (() -> Void)? = nil
    ) {
        self.show = show
        self.imageSrc = imageSrc
        self.loading = loading
        self.alt = alt
        self.downloading = downloading
        self.progressPct = progressPct
        self.zoomMin = zoomMin
        self.zoomMax = zoomMax
        self.onClose = onClose
        self.onDownload = onDownload
    }

    public var body: some View {
        if !show {
            EmptyView()
        } else {
            ZStack {
                Color.black.ignoresSafeArea()

                if loading {
                    ProgressView().tint(.white)
                } else if let url = URL(string: imageSrc) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                            .scaleEffect(scale)
                            .gesture(MagnificationGesture().onChanged { v in
                                scale = min(max(zoomMin, v), zoomMax)
                            }.onEnded { _ in
                                if scale < zoomMin { scale = zoomMin }
                            })
                    } placeholder: {
                        ProgressView().tint(.white)
                    }
                    .onTapGesture { onClose?() }
                } else {
                    Image(systemName: "photo").font(.system(size: 64)).foregroundColor(.white.opacity(0.5))
                }

                VStack {
                    HStack {
                        circleButton("xmark", onClose)
                        Spacer()
                        if onDownload != nil {
                            if downloading { progressRing } else { circleButton("arrow.down.to.line", onDownload) }
                        }
                    }
                    .padding()
                    Spacer()
                }
            }
        }
    }

    private func circleButton(_ icon: String, _ action: (() -> Void)?) -> some View {
        Button { action?() } label: {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(.white)
                .frame(width: 38, height: 38).background(Circle().fill(.white.opacity(0.25)))
        }.buttonStyle(.plain)
    }

    private var progressRing: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.3), lineWidth: 2)
            Circle().trim(from: 0, to: CGFloat(progressPct) / 100)
                .stroke(.white, lineWidth: 2).rotationEffect(.degrees(-90))
            Text("\(progressPct)").font(.system(size: 10)).foregroundColor(.white)
        }.frame(width: 38, height: 38)
    }
}
