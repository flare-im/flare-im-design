import SwiftUI

/// What ``LocationPickerView`` is showing, as the contract names its states. More than one holds at a time: denied
/// with no results, located with the map unavailable.
public enum FlareLocationPickerStatus: String, Sendable, CaseIterable {
    case locating
    case located
    case denied
    case searching
    case noResults
    case mapUnavailable
    /// The host is sending the chosen place (`sending`): the send key spins and takes no second tap.
    case sending
}

/// Why the picker stopped waiting for a position.
enum FlareLocationPickerError: Error {
    case timedOut
}

/// The picker's state, without a view: the position, the lists, the search, the selection and the map. Every host
/// answer goes through one of its transitions, so an answer that arrives late (a search the user has typed past, a
/// map for a place no longer selected) is dropped here rather than shown.
struct FlareLocationPickerModel: Equatable {
    enum Locate: Equatable { case locating, located, denied }

    /// The first row, the user's position: the place passed in until a fix arrives, then the fix with what reverse
    /// geocoding says about it. Its id is ``FlareLocationPlace/currentId``.
    private(set) var current: FlareLocationPlace?
    private(set) var locate: Locate = .locating
    /// The places around `current`, the list for an empty query; nil until they have been asked for.
    private(set) var nearby: [FlareLocationPlace]?
    private(set) var query = ""
    /// The places for `query`; nil while the search runs.
    private(set) var results: [FlareLocationPlace]?
    private(set) var selected: FlareLocationPlace?
    /// The point the map shows and the image for it; `mapUnavailable` once the host had no image for it.
    private(set) var previewing: FlareLocationCoordinate?
    private(set) var snapshotUrl: String?
    private(set) var mapUnavailable = false

    init(initial: FlareLocationPlace? = nil) {
        if let initial {
            current = Self.asCurrent(initial)
            selected = current
        }
    }

    private static func asCurrent(_ place: FlareLocationPlace) -> FlareLocationPlace {
        FlareLocationPlace(id: FlareLocationPlace.currentId, title: place.title, address: place.address,
                           latitude: place.latitude, longitude: place.longitude)
    }

    private var searchQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isSearching: Bool { !searchQuery.isEmpty }

    // MARK: Position

    mutating func locateStarted() { locate = .locating }

    /// A fix: the first row moves to it (its name comes with ``geocoded(_:for:)``). It is selected when nothing is,
    /// or when the user asked for it with the locate key (`select`).
    mutating func located(_ point: FlareLocationCoordinate, select: Bool = false) {
        locate = .located
        let moved = current?.coordinate != point
        let place = FlareLocationPlace(id: FlareLocationPlace.currentId,
                                       title: moved ? "" : current?.title ?? "",
                                       address: moved ? "" : current?.address ?? "",
                                       latitude: point.latitude, longitude: point.longitude)
        current = place
        if moved { nearby = nil }
        if select || selected == nil || selected?.id == FlareLocationPlace.currentId { selected = place }
    }

    /// No fix — no permission, a failure or the timeout. The place passed in, if any, stays the first row.
    mutating func locateFailed() { locate = .denied }

    /// What reverse geocoding says about `point`; dropped when the first row has moved on.
    mutating func geocoded(_ address: FlareLocationAddress, for point: FlareLocationCoordinate) {
        guard let current, current.coordinate == point else { return }
        let named = FlareLocationPlace(id: current.id, title: address.title, address: address.address,
                                       latitude: current.latitude, longitude: current.longitude)
        self.current = named
        if selected?.id == FlareLocationPlace.currentId { selected = named }
    }

    // MARK: Lists

    /// The places around `point`; dropped when the first row has moved on. A place that repeats the first row's id is
    /// left out.
    mutating func nearbyLoaded(_ places: [FlareLocationPlace], for point: FlareLocationCoordinate?) {
        guard current?.coordinate == point else { return }
        nearby = places.filter { $0.id != FlareLocationPlace.currentId }
    }

    /// The user typed: a blank query goes back to the nearby list, any other starts its search.
    mutating func queryChanged(_ text: String) {
        query = text
        results = isSearching ? nil : []
    }

    /// The places for `text`; dropped unless it is still the query. A failed search has no results.
    mutating func searchFinished(_ text: String, _ places: [FlareLocationPlace]) {
        guard text == searchQuery else { return }
        results = places
    }

    mutating func select(_ place: FlareLocationPlace) { selected = place }

    // MARK: Map

    /// The point the map should show: the selected place, else the first row.
    var mapCenter: FlareLocationCoordinate? { selected?.coordinate ?? current?.coordinate }

    mutating func previewStarted(_ point: FlareLocationCoordinate) {
        guard previewing != point else { return }
        previewing = point
        snapshotUrl = nil
    }

    /// The host's map image for `point`, or nil when it has none; dropped when the map has moved on.
    mutating func previewLoaded(_ url: String?, for point: FlareLocationCoordinate) {
        guard previewing == point else { return }
        let image = url?.trimmingCharacters(in: .whitespacesAndNewlines)
        snapshotUrl = image?.isEmpty == false ? image : nil
        mapUnavailable = snapshotUrl == nil
    }

    // MARK: What the view draws

    /// The list: the first row and the nearby places, or the search's places.
    var rows: [FlareLocationPlace] {
        if isSearching { return results ?? [] }
        return (current.map { [$0] } ?? []) + (nearby ?? [])
    }

    /// Whether the list is still waiting for its first answer: no position and nothing nearby yet.
    var waitingForRows: Bool { !isSearching && current == nil && locate == .locating }

    var statuses: Set<FlareLocationPickerStatus> {
        var out: Set<FlareLocationPickerStatus> = []
        switch locate {
        case .locating: out.insert(.locating)
        case .located: out.insert(.located)
        case .denied: out.insert(.denied)
        }
        if isSearching && results == nil { out.insert(.searching) }
        if isSearching, let results, results.isEmpty { out.insert(.noResults) }
        if mapUnavailable { out.insert(.mapUnavailable) }
        return out
    }

    /// ``statuses`` with the host's send in flight.
    func statuses(sending: Bool) -> Set<FlareLocationPickerStatus> {
        sending ? statuses.union([.sending]) : statuses
    }

    /// The selected place as it is sent: the first row without a name is called `fallbackTitle`.
    func sendable(fallbackTitle: String) -> FlareLocationPlace? {
        guard let selected else { return nil }
        let title = selected.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard title.isEmpty else { return selected }
        return FlareLocationPlace(id: selected.id, title: fallbackTitle, address: selected.address,
                                  latitude: selected.latitude, longitude: selected.longitude,
                                  distanceM: selected.distanceM)
    }
}

/// Resumes once: the first of a host call and its timeout.
private final class FlareOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false
    func claim() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if done { return false }
        done = true
        return true
    }
}

/// `work`, or ``FlareLocationPickerError/timedOut`` after `timeoutMs` — whichever comes first. The host's call need not
/// honour cancellation: the picker stops waiting for it either way.
func flareFirst<T: Sendable>(timeoutMs: Int, _ work: @escaping @Sendable () async throws -> T) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        let once = FlareOnce()
        let worker = Task {
            do {
                let value = try await work()
                if once.claim() { continuation.resume(returning: value) }
            } catch {
                if once.claim() { continuation.resume(throwing: error) }
            }
        }
        Task {
            try? await Task.sleep(nanoseconds: UInt64(max(timeoutMs, 0)) * 1_000_000)
            if once.claim() {
                worker.cancel()
                continuation.resume(throwing: FlareLocationPickerError.timedOut)
            }
        }
    }
}

/// Location picker — the content of the kit bottom sheet a location is chosen in. Spec: Message/LocationPicker
/// (`LocationPickerView`).
///
/// A map of the selected place with a centre pin and a key that locates the user again; a search field; the list,
/// whose first row is the user's position (``FlareLocationPlace/currentId``, named by reverse geocoding, else
/// `locationCurrent`) followed by the places nearby, or the search's places; and the send key.
///
/// The host does the locating, geocoding, searching and map images through the functions it passes; the kit owns
/// the states (``FlareLocationPickerStatus``):
/// - `initialLocation` (the last place the user sent from) is the first row and the map from the first frame, so the
///   sheet never opens empty; without it the list starts as a skeleton.
/// - `requestCurrentLocation` throwing, or not answering within `locateTimeoutMs`, is `denied`: the picker says the
///   user can search for a place, and keeps `initialLocation` if there is one. Without the function the picker
///   starts denied.
/// - `ensurePermission` is the host's permission step, awaited before every locate (the first and the locate key)
///   while the picker shows locating: the system prompt's wait is not counted, `locateTimeoutMs` starts once it
///   answers true; false (or a throw) is `denied` at once, without calling `requestCurrentLocation`.
/// - `searchNearby(latitude, longitude, query)` is asked with an empty query for the list around the position and
///   with the user's words (after a short pause in typing) for a search; the coordinate is nil while the picker does
///   not know one.
/// - `previewUrl` returning nil or throwing is `mapUnavailable`: the map area shows the coordinate and the address.
///   Its width and height are device pixels: the map's size in points times the display scale clamped to 1...2,
///   rounded (``FlareLocationFormat/previewPixels(width:height:scale:)``).
/// - `onSend` receives the selected place; `onCancel` the cancel key. While `sending` the send key spins and is
///   disabled, so a second tap sends nothing; the host clears it when the send settles.
/// - It draws its own header (Cancel and the title) and declares it (``SwiftUI/View/flareSheetOwnHeader(_:)``):
///   present it with `flareBottomSheet(…, fill: true)` and the sheet keeps its title as the accessible name only.
/// - `provider` is the tenant's map service: with osm the map preview carries OpenStreetMap's credit
///   (`locationOsmAttribution`) once the picture shows; never while the map is unavailable, and never for amap.
public struct LocationPickerView: View {
    private let initialLocation: FlareLocationPlace?
    private let zoom: Int
    private let locateTimeoutMs: Int
    private let requestCurrentLocation: (@Sendable () async throws -> FlareLocationCoordinate)?
    private let ensurePermission: (@Sendable () async throws -> Bool)?
    private let reverseGeocode: (@Sendable (Double, Double) async throws -> FlareLocationAddress)?
    private let searchNearby: (@Sendable (Double?, Double?, String) async throws -> [FlareLocationPlace])?
    private let previewUrl: (@Sendable (Double, Double, Int, Int, Int) async throws -> String?)?
    private let onSend: ((FlareLocationPlace) -> Void)?
    private let onCancel: (() -> Void)?
    /// The tenant's map service; osm puts OpenStreetMap's credit on the map preview.
    private let provider: FlareLocationProvider
    /// The host is sending the chosen place.
    private let sending: Bool
    @State private var model: FlareLocationPickerModel
    /// Bumped by the locate key: each value runs one locate.
    @State private var locateRun = 0
    @State private var mapWidth: CGFloat = 0
    @Environment(\.displayScale) private var displayScale
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// The map's height; its width is the sheet's.
    static let mapHeight: CGFloat = 168
    /// How long typing pauses before the search runs.
    static let searchDelayMs = 300

    public init(initialLocation: FlareLocationPlace? = nil, zoom: Int = 16, locateTimeoutMs: Int = 5000,
                requestCurrentLocation: (@Sendable () async throws -> FlareLocationCoordinate)? = nil,
                ensurePermission: (@Sendable () async throws -> Bool)? = nil,
                reverseGeocode: (@Sendable (Double, Double) async throws -> FlareLocationAddress)? = nil,
                searchNearby: (@Sendable (Double?, Double?, String) async throws -> [FlareLocationPlace])? = nil,
                previewUrl: (@Sendable (Double, Double, Int, Int, Int) async throws -> String?)? = nil,
                provider: FlareLocationProvider = .osm, sending: Bool = false,
                onSend: ((FlareLocationPlace) -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.init(initialLocation: initialLocation, zoom: zoom, locateTimeoutMs: locateTimeoutMs,
                  requestCurrentLocation: requestCurrentLocation, reverseGeocode: reverseGeocode,
                  searchNearby: searchNearby, previewUrl: previewUrl, onSend: onSend, onCancel: onCancel,
                  model: FlareLocationPickerModel(initial: initialLocation), provider: provider,
                  ensurePermission: ensurePermission, sending: sending)
    }

    /// The picker drawn from `model` — how the tests reach a state without running the host's functions.
    init(initialLocation: FlareLocationPlace?, zoom: Int, locateTimeoutMs: Int,
         requestCurrentLocation: (@Sendable () async throws -> FlareLocationCoordinate)?,
         reverseGeocode: (@Sendable (Double, Double) async throws -> FlareLocationAddress)?,
         searchNearby: (@Sendable (Double?, Double?, String) async throws -> [FlareLocationPlace])?,
         previewUrl: (@Sendable (Double, Double, Int, Int, Int) async throws -> String?)?,
         onSend: ((FlareLocationPlace) -> Void)?, onCancel: (() -> Void)?, model: FlareLocationPickerModel,
         provider: FlareLocationProvider = .osm, ensurePermission: (@Sendable () async throws -> Bool)? = nil,
         sending: Bool = false) {
        self.initialLocation = initialLocation; self.zoom = zoom; self.locateTimeoutMs = locateTimeoutMs
        self.provider = provider; self.sending = sending; self.ensurePermission = ensurePermission
        self.requestCurrentLocation = requestCurrentLocation; self.reverseGeocode = reverseGeocode
        self.searchNearby = searchNearby; self.previewUrl = previewUrl
        self.onSend = onSend; self.onCancel = onCancel
        self._model = State(initialValue: model)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(spacing: 0) {
            header(colors)
            map(colors)
                .padding(.horizontal, FlareSizes.spacingLg)
            if model.statuses.contains(.denied) {
                Text(strings.locationDenied)
                    .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, FlareSizes.spacingLg).padding(.top, FlareSizes.spacingSm)
            }
            SearchBarView(text: Binding(get: { model.query }, set: { model.queryChanged($0) }),
                          placeholder: strings.locationSearchPlaceholder,
                          loading: model.statuses.contains(.searching))
                .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
            list(colors)
            Divider().overlay(colors.borderPrimary)
            // Loading disables the key without dimming it, as on every kit busy key.
            ButtonView(label: strings.locationSend, size: .lg, loading: sending, disabled: model.selected == nil,
                       block: true) {
                guard !sending, let place = model.sendable(fallbackTitle: strings.locationCurrent) else { return }
                onSend?(place)
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingMd)
        }
        .frame(maxWidth: .infinity)
        .background(colors.bgPrimary)
        .flareSheetOwnHeader()
        .task(id: locateRun) { await locate(select: locateRun > 0) }
        .task(id: model.current?.coordinate) { await loadNearby() }
        .task(id: model.query) { await search() }
        .task(id: previewRequest) { await loadPreview(previewRequest) }
    }

    /// The map's request: its centre at its size in device pixels.
    private var previewRequest: PreviewRequest {
        let pixels = FlareLocationFormat.previewPixels(width: Double(mapWidth), height: Double(Self.mapHeight),
                                                       scale: Double(displayScale))
        return PreviewRequest(center: model.mapCenter, width: pixels.width, height: pixels.height)
    }

    // MARK: Parts

    private func header(_ colors: FlareColors) -> some View {
        ZStack {
            Text(strings.locationTitle)
                .font(.system(size: FlareSizes.fontSize2xl, weight: .semibold)).foregroundColor(colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            HStack {
                ButtonView(label: strings.cancel, variant: .text, size: .sm) { onCancel?() }
                Spacer()
            }
        }
        .padding(.horizontal, FlareSizes.spacingSm).padding(.vertical, FlareSizes.spacingSm)
    }

    private func map(_ colors: FlareColors) -> some View {
        ZStack {
            if model.mapUnavailable {
                FlareMapPlaceholder(pin: false)
                VStack(spacing: FlareSizes.spacingXs) {
                    Text(strings.locationMapUnavailable)
                        .font(.system(size: FlareSizes.fontSizeSm, weight: .medium)).foregroundColor(colors.textSecondary)
                    if let center = model.mapCenter,
                       let label = FlareLocationFormat.label(latitude: center.latitude, longitude: center.longitude) {
                        Text(label).font(.system(size: FlareSizes.fontSizeLg, weight: .semibold).monospacedDigit())
                            .foregroundColor(colors.textPrimary)
                    }
                    if let address = model.selected?.address, !address.isEmpty {
                        Text(address).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                            .lineLimit(2).multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, FlareSizes.spacingLg)
                .accessibilityElement(children: .combine)
            } else {
                FlareMapSnapshot(url: model.snapshotUrl, attribution: FlareMapSnapshot.attribution(provider, strings),
                                 pin: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
                    .accessibilityHidden(true)
                // The point the map shows: the pin's tip at the centre.
                FlareIconImage(name: "location", size: FlareSizes.iconSizeXl, weight: .semibold)
                    .foregroundColor(colors.primaryText)
                    .offset(y: -FlareSizes.iconSizeXl / 2)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity).frame(height: Self.mapHeight)
        .background(GeometryReader { geo in
            Color.clear.preference(key: FlareMapWidthKey.self, value: geo.size.width)
        })
        .onPreferenceChange(FlareMapWidthKey.self) { mapWidth = $0 }
        .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusCard, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            IconButtonView(icon: "locate", accessibilityLabel: strings.locationLocateMe, variant: .tinted,
                           active: model.statuses.contains(.locating), background: colors.bgPrimary) {
                locateRun += 1
            }
            .padding(FlareSizes.spacingSm)
        }
    }

    @ViewBuilder private func list(_ colors: FlareColors) -> some View {
        let rows = model.rows
        ScrollView {
            LazyVStack(spacing: 0) {
                if model.waitingForRows {
                    locatingRow(colors)
                    SkeletonView(variant: .text, rows: 3).padding(.horizontal, FlareSizes.spacingLg)
                } else if model.statuses.contains(.noResults) {
                    EmptyStateView(title: strings.locationNoResults, icon: "location")
                } else if model.statuses.contains(.searching) {
                    ProgressView().tint(colors.primaryText).frame(maxWidth: .infinity).padding(FlareSizes.spacingLg)
                } else {
                    ForEach(rows) { place in row(colors, place) }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func locatingRow(_ colors: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingSm) {
            ProgressView().controlSize(.small).tint(colors.primaryText)
            Text(strings.locationLocating).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, FlareSizes.spacingLg).frame(minHeight: FlareSizes.touchTarget)
        .accessibilityElement(children: .combine)
    }

    private func row(_ colors: FlareColors, _ place: FlareLocationPlace) -> some View {
        let isCurrent = place.id == FlareLocationPlace.currentId
        let selected = model.selected?.id == place.id
        let title = place.title.isEmpty ? strings.locationCurrent : place.title
        let detail = [place.address, isCurrent && model.statuses.contains(.locating) ? strings.locationLocating : nil,
                      FlareLocationFormat.distance(place.distanceM)]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
        return Button { model.select(place) } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
                    Text(title).font(.system(size: FlareSizes.fontSizeLg, weight: isCurrent ? .semibold : .regular))
                        .foregroundColor(colors.textPrimary).lineLimit(1)
                    if !detail.isEmpty {
                        Text(detail).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if selected {
                    FlareIconImage(name: "check", size: FlareSizes.iconSizeMd, weight: .semibold)
                        .foregroundColor(colors.primaryText)
                }
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
            .frame(minHeight: FlareSizes.touchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Host calls

    /// One locate: the host's permission step first — its wait (the system prompt) is not timed — then the
    /// position within `timeoutMs`. Nil is denied: no permission (false or a throw, and `requestCurrentLocation` is
    /// not called), a failure, the timeout or an invalid fix.
    static func position(ensurePermission: (@Sendable () async throws -> Bool)?,
                         requestCurrentLocation: @escaping @Sendable () async throws -> FlareLocationCoordinate,
                         timeoutMs: Int) async -> FlareLocationCoordinate? {
        if let ensurePermission {
            guard (try? await ensurePermission()) == true else { return nil }
        }
        guard let point = try? await flareFirst(timeoutMs: timeoutMs, requestCurrentLocation),
              FlareLocationFormat.isValid(latitude: point.latitude, longitude: point.longitude) else { return nil }
        return point
    }

    private func locate(select: Bool) async {
        guard let requestCurrentLocation else { model.locateFailed(); return }
        model.locateStarted()
        guard let point = await Self.position(ensurePermission: ensurePermission,
                                              requestCurrentLocation: requestCurrentLocation,
                                              timeoutMs: locateTimeoutMs) else {
            model.locateFailed(); return
        }
        model.located(point, select: select)
        if select { model.queryChanged("") }
        guard let reverseGeocode else { return }
        if let address = try? await reverseGeocode(point.latitude, point.longitude) {
            model.geocoded(address, for: point)
        }
    }

    private func loadNearby() async {
        guard let searchNearby, let point = model.current?.coordinate else { return }
        let places = (try? await searchNearby(point.latitude, point.longitude, "")) ?? []
        model.nearbyLoaded(places, for: point)
    }

    private func search() async {
        let text = model.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        try? await Task.sleep(nanoseconds: UInt64(Self.searchDelayMs) * 1_000_000)
        guard !Task.isCancelled else { return }
        let point = model.current?.coordinate
        let places = (try? await searchNearby?(point?.latitude, point?.longitude, text)) ?? []
        model.searchFinished(text, places)
    }

    private func loadPreview(_ request: PreviewRequest) async {
        guard let point = request.center, request.width > 0 else { return }
        model.previewStarted(point)
        guard let previewUrl else { model.previewLoaded(nil, for: point); return }
        let url = try? await previewUrl(point.latitude, point.longitude, zoom, request.width, request.height)
        model.previewLoaded(url ?? nil, for: point)
    }
}

/// What the map asks the host for: a point at a size in device pixels. A new value runs a new request.
private struct PreviewRequest: Equatable {
    let center: FlareLocationCoordinate?
    let width: Int
    let height: Int
}

private struct FlareMapWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
