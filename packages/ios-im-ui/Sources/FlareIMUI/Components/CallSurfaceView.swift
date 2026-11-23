import SwiftUI

// MARK: - CallSurface

/// The window that carries a call view (``CallView``, ``GroupCallView``). Spec: Call/CallSurface (`CallSurfaceView`),
/// docs/plugin-experience.md §3.1; the Vue and Flutter `FlareCallSurface`.
///
/// Compact width (iPhone, iPad Slide Over): true full screen — the stage runs under the status bar and the home
/// indicator, with no margin and no corners; the call view keeps its keys inside the safe area. Regular width (iPad,
/// Mac): a floating window of the mode's size (`componentCallWindowAudio*` / `componentCallWindowVideo*`), `radiusXl`,
/// `shadows.xl`; its top `touchTarget` band drags it, and an expand key grows it to the container less `spacingXl` a
/// side, 90% high. The call view inside draws that key at the end of its own top row, beside minimize and the encrypted
/// note (§3.1). Escape (Mac, and an iPad's hardware keyboard) leaves the expanded window; it never hangs up.
/// Inside the window the call view hears `flareCallInWindow`: the 80-point avatar and the 20/600 name.
/// `onMinimize` reaches the call view inside as its minimize key when the host passed it none of its own.
public struct CallSurfaceView<Content: View>: View {
    private let mode: FlareCallMode
    private let label: String?
    private let content: Content
    private let expandedProp: Bool
    private let onExpandedChange: ((Bool) -> Void)?
    private let onMinimize: (() -> Void)?
    @State private var expanded: Bool
    @State private var offset: CGSize = .zero
    @GestureState private var drag: CGSize = .zero
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.colorScheme) private var scheme
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    /// `label` is the window's VoiceOver name. `expanded` sets the size (a later value from the host wins);
    /// `onExpandedChange` hears the expand key and Escape (Vue `update:expanded`); `onMinimize` is the `minimize`
    /// event, raised by the call view's minimize key.
    public init(mode: FlareCallMode, expanded: Bool = false, label: String? = nil,
                onExpandedChange: ((Bool) -> Void)? = nil, onMinimize: (() -> Void)? = nil,
                @ViewBuilder content: () -> Content) {
        self.mode = mode; self.label = label; self.content = content()
        self.expandedProp = expanded; self.onExpandedChange = onExpandedChange; self.onMinimize = onMinimize
        _expanded = State(initialValue: expanded)
    }

    /// The window's size in a `container`: the mode's size, or expanded, both kept `spacingXl` inside each side.
    static func windowSize(mode: FlareCallMode, expanded: Bool, in container: CGSize) -> CGSize {
        let room = CGSize(width: max(0, container.width - FlareSizes.spacingXl * 2),
                          height: max(0, container.height - FlareSizes.spacingXl * 2))
        if expanded { return CGSize(width: room.width, height: min(room.height, container.height * 0.9)) }
        let size = mode == .audio
            ? CGSize(width: FlareSizes.componentCallWindowAudioWidth, height: FlareSizes.componentCallWindowAudioHeight)
            : CGSize(width: FlareSizes.componentCallWindowVideoWidth, height: FlareSizes.componentCallWindowVideoHeight)
        return CGSize(width: min(size.width, room.width), height: min(size.height, room.height))
    }

    /// A dragged window's offset from the centre, kept so the whole window stays `spacingXl` inside the container.
    static func clampedOffset(_ offset: CGSize, window: CGSize, in container: CGSize) -> CGSize {
        let maxX = max(0, (container.width - window.width) / 2 - FlareSizes.spacingXl)
        let maxY = max(0, (container.height - window.height) / 2 - FlareSizes.spacingXl)
        return CGSize(width: min(max(offset.width, -maxX), maxX), height: min(max(offset.height, -maxY), maxY))
    }

    private var compact: Bool {
        #if os(iOS)
        return sizeClass == .compact
        #else
        return false
        #endif
    }

    public var body: some View {
        if compact {
            content
                .environment(\.flareCallWindow, CallWindowChrome(onMinimize: onMinimize))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CallStageBackground().ignoresSafeArea())
                .accessibilityElement(children: .contain)
                .accessibilityLabel(label ?? "")
        } else {
            GeometryReader { geo in
                let size = Self.windowSize(mode: mode, expanded: expanded, in: geo.size)
                content.frame(maxWidth: .infinity, maxHeight: .infinity)
                    .environment(\.flareCallInWindow, true)
                    .environment(\.flareCallWindow, CallWindowChrome(expandKey: AnyView(expandKey), onMinimize: onMinimize))
                .frame(width: size.width, height: size.height)
                // The top band drags the window; a key or a preview there keeps its own touch (child gestures win).
                .gesture(
                    DragGesture()
                        .updating($drag) { value, state, _ in
                            if Self.drags(from: value.startLocation, expanded: expanded) { state = value.translation }
                        }
                        .onEnded { value in
                            guard Self.drags(from: value.startLocation, expanded: expanded) else { return }
                            offset = Self.clampedOffset(CGSize(width: offset.width + value.translation.width,
                                                               height: offset.height + value.translation.height),
                                                        window: size, in: geo.size)
                        }
                )
                .background(CallStageBackground())
                .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusXl))
                .flareShadow(FlareShadows.of(scheme).xl)
                .offset(expanded ? .zero : Self.clampedOffset(CGSize(width: offset.width + drag.width,
                                                                     height: offset.height + drag.height),
                                                              window: size, in: geo.size))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(label ?? "")
            }
            .onChange(of: expandedProp) { expanded = $0 }
        }
    }

    /// A drag moves the window when it starts in the top `touchTarget` band of a window that is not expanded.
    static func drags(from start: CGPoint, expanded: Bool) -> Bool {
        !expanded && start.y <= FlareSizes.touchTarget
    }

    private func setExpanded(_ value: Bool) {
        expanded = value
        onExpandedChange?(value)
    }

    /// The expand key: grows the window, or (expanded) shrinks it back, Escape too.
    private var expandKey: some View {
        CallTopKey(icon: expanded ? "collapse" : "expand", label: expanded ? strings.collapse : strings.expand) {
            setExpanded(!expanded)
        }
        .keyboardShortcut(expanded ? KeyboardShortcut(.escape, modifiers: []) : nil)
    }
}
