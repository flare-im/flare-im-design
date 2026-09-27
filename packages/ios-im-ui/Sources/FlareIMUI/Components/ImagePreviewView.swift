import SwiftUI

/// Full-screen image viewer — zoom/pan, download with progress. Spec:
/// Media/ImagePreviewModal (`ImagePreviewView`). Renders nothing when `show`
/// is false, so it can sit in a `ZStack`.
///
/// Closing: the close key (关闭预览), a tap on the image, a downward swipe while the image is not
/// zoomed, or VoiceOver's escape gesture. An image that cannot load shows that it failed instead of
/// a spinner that never ends. The download key appears only with `onDownload`; while `downloading` it
/// shows the progress (`progressPct`) in its place, and once the image is `saved` it is a folder that
/// calls `onReveal` (a saved image without `onReveal` keeps the download key).
///
/// In a gallery the preview says where it is (`galleryIndex` of `galleryCount`) and pages with `onPrevious` and
/// `onNext`: their keys at the sides, or a sideways swipe while the image is not zoomed. A key with no action (the
/// first or the last image) is disabled.
///
/// `imageSrc` may be a file on this device (a `file:` URL or an absolute path) only with `allowLocalFile`: the
/// picture's local copy, which the host resolved through the SDK media cache (``FlareImageContent/localPath``).
public struct ImagePreviewView: View {
    private let show: Bool
    private let imageSrc: String
    private let allowLocalFile: Bool
    private let loading: Bool
    private let alt: String?
    private let downloading: Bool
    private let progressPct: Int
    private let zoomMin: CGFloat
    private let zoomMax: CGFloat
    private let onClose: (() -> Void)?
    private let onDownload: (() -> Void)?
    private let saved: Bool
    private let onReveal: (() -> Void)?
    private let galleryIndex: Int?
    private let galleryCount: Int?
    private let onPrevious: (() -> Void)?
    private let onNext: (() -> Void)?

    @State private var scale: CGFloat = 1
    @State private var dragOffset: CGFloat = 0
    @Environment(\.flareStrings) private var strings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        onDownload: (() -> Void)? = nil,
        saved: Bool = false,
        onReveal: (() -> Void)? = nil,
        galleryIndex: Int? = nil,
        galleryCount: Int? = nil,
        onPrevious: (() -> Void)? = nil,
        onNext: (() -> Void)? = nil,
        allowLocalFile: Bool = false
    ) {
        self.show = show
        self.imageSrc = imageSrc
        self.allowLocalFile = allowLocalFile
        self.loading = loading
        self.alt = alt
        self.downloading = downloading
        self.progressPct = progressPct
        self.zoomMin = zoomMin
        self.zoomMax = zoomMax
        self.onClose = onClose
        self.onDownload = onDownload
        self.saved = saved
        self.onReveal = onReveal
        self.galleryIndex = galleryIndex
        self.galleryCount = galleryCount
        self.onPrevious = onPrevious
        self.onNext = onNext
    }

    /// Whether the preview pages a gallery.
    var pages: Bool { galleryIndex != nil && (galleryCount ?? 0) > 1 }

    /// Where a sideways drag that moved `translation` pages: the next image for a swipe to the left, the previous one
    /// for a swipe to the right, nothing for a drag that is not sideways or not far enough.
    enum Page: Equatable { case previous, next }
    static func page(horizontal: CGFloat, vertical: CGFloat) -> Page? {
        guard abs(horizontal) > abs(vertical), abs(horizontal) >= dismissDistance / 2 else { return nil }
        return horizontal < 0 ? .next : .previous
    }

    /// A downward swipe closes the preview once it has travelled this far (or is flung past twice that).
    static let dismissDistance: CGFloat = 120

    /// Whether a downward drag that moved `translation` and would carry on to `predicted` closes.
    static func closesOnDrag(translation: CGFloat, predicted: CGFloat) -> Bool {
        translation >= dismissDistance || predicted >= dismissDistance * 2
    }

    public var body: some View {
        if !show {
            EmptyView()
        } else {
            ZStack {
                Color.black.ignoresSafeArea()

                // The image follows a downward swipe; past the distance it closes.
                imageContent.offset(y: dragOffset)

                if pages, let galleryIndex, let galleryCount {
                    HStack {
                        circleButton("chevron-left", label: strings.imagePreviewPrevious, onPrevious)
                        Spacer()
                        circleButton("chevron-right", label: strings.imagePreviewNext, onNext)
                    }
                    .padding(.horizontal)
                    VStack {
                        Text(verbatim: "\(galleryIndex + 1) / \(galleryCount)")
                            .font(.system(size: FlareSizes.fontSizeLg))
                            .foregroundColor(.white)
                            .accessibilityLabel(strings.imagePreviewPosition(galleryIndex + 1, galleryCount))
                            .padding(.top, FlareSizes.spacingLg + FlareSizes.spacingXs)
                        Spacer()
                    }
                }

                VStack {
                    HStack {
                        circleButton("close", label: strings.imagePreviewClose, onClose)
                        Spacer()
                        switch FlareMediaKey.resolve(canDownload: onDownload != nil, downloading: downloading,
                                                     saved: saved, canReveal: onReveal != nil) {
                        case .folder?: circleButton("folder", label: strings.showInFolder, onReveal)
                        case .progress?: progressRing
                        case .download?: circleButton("download", label: strings.download, onDownload)
                        case nil: EmptyView()
                        }
                    }
                    .padding()
                    Spacer()
                }
            }
            .simultaneousGesture(dismissDrag)
            .accessibilityElement(children: .contain)
            .accessibilityAction(.escape) { onClose?() }
        }
    }

    @ViewBuilder
    private var imageContent: some View {
        if loading {
            ProgressView().tint(.white)
        } else if let url = flarePictureURL(imageSrc, local: allowLocalFile) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                        .scaleEffect(scale)
                        .gesture(MagnificationGesture().onChanged { v in
                            scale = min(max(zoomMin, v), zoomMax)
                        }.onEnded { _ in
                            if scale < zoomMin { scale = zoomMin }
                        })
                        .accessibilityLabel(alt?.isEmpty == false ? alt! : strings.messageImage)
                case .failure:
                    failed
                default:
                    ProgressView().tint(.white)
                }
            }
            .onTapGesture { onClose?() }
        } else {
            failed
        }
    }

    /// The image could not load: its glyph and what happened; the close key still closes.
    private var failed: some View {
        VStack(spacing: FlareSizes.spacingMd) {
            Image(systemName: flareIconSymbol("image")).font(.system(size: 64)).foregroundColor(.white.opacity(0.5))
                .accessibilityHidden(true)
            Text(strings.imageLoadFailed).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(.white.opacity(0.8))
        }
    }

    /// Swipe down to close, while the image is at its resting zoom.
    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: FlareSizes.spacingLg)
            .onChanged { value in
                guard onClose != nil, scale <= zoomMin, abs(value.translation.width) <= abs(value.translation.height) else { return }
                dragOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                if pages, scale <= zoomMin,
                   let page = Self.page(horizontal: value.translation.width, vertical: value.translation.height) {
                    dragOffset = 0
                    (page == .next ? onNext : onPrevious)?()
                    return
                }
                guard onClose != nil, dragOffset > 0 else { return }
                if Self.closesOnDrag(translation: value.translation.height, predicted: value.predictedEndTranslation.height) {
                    onClose?()
                }
                if reduceMotion { dragOffset = 0 } else { withAnimation(FlareMotion.normalAnimation) { dragOffset = 0 } }
            }
    }

    /// A chrome key over the image: the kit icon `icon` on a 38pt disc, named `label`, with a 44pt target.
    private func circleButton(_ icon: String, label: String, _ action: (() -> Void)?) -> some View {
        Button { action?() } label: {
            Image(systemName: flareIconSymbol(icon)).font(.system(size: 20)).foregroundColor(.white)
                .frame(width: 38, height: 38).background(Circle().fill(.white.opacity(0.25)))
                .flareTouchTarget()
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .opacity(action == nil ? 0.4 : 1)
        .flareCompactLayout(width: 38, height: 38)
        .accessibilityLabel(label)
    }

    private var progressRing: some View {
        FlareMediaDownloadRing(progressPct: progressPct).frame(width: 38, height: 38)
    }
}

/// The key at the top right of the image preview and the video player: the folder once the media is saved and the host
/// can show it, the progress while it is being saved, else the download; none without a download handler.
enum FlareMediaKey: Equatable {
    case download, progress, folder

    static func resolve(canDownload: Bool, downloading: Bool, saved: Bool, canReveal: Bool) -> FlareMediaKey? {
        guard canDownload else { return nil }
        if saved && canReveal { return .folder }
        return downloading ? .progress : .download
    }
}

/// A download under way over the dark media chrome, in place of the download key: a ring filling with `progressPct`
/// (0–100) and the number inside it, read as the download key's name with the percent. The image preview and the
/// video player share it.
struct FlareMediaDownloadRing: View {
    let progressPct: Int
    @Environment(\.flareStrings) private var strings

    var body: some View {
        let pct = min(max(progressPct, 0), 100)
        ZStack {
            Circle().stroke(.white.opacity(0.3), lineWidth: 2)
            Circle().trim(from: 0, to: CGFloat(pct) / 100)
                .stroke(.white, lineWidth: 2).rotationEffect(.degrees(-90))
            Text("\(pct)").font(.system(size: FlareSizes.fontSize2xs)).foregroundColor(.white)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(strings.download)
        .accessibilityValue("\(pct)%")
    }
}
