import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The location family: the shared link, label and distance rules (`spec/location-vectors.json`), the message card
/// with and without a map, where its tap goes, and the picker's states as its model moves through them. Copy is read
/// from the strings table, never repeated here.
final class LocationComponentsTests: XCTestCase {
    private let s = FlareStrings()

    // MARK: Shared vectors

    private struct Vectors: Decodable {
        struct Input: Decodable {
            let latitude: Double
            let longitude: Double
            let title: String?
            let provider: String?
        }
        struct Link: Decodable {
            let id: String
            let input: Input
            let web: String?
            let apple: String?
            let geo: String?
        }
        struct Point: Decodable { let latitude: Double; let longitude: Double }
        struct Label: Decodable { let id: String; let input: Point; let output: String? }
        struct Distance: Decodable { let id: String; let input: Double?; let output: String? }
        let osmZoom: Int
        let links: [Link]
        let label: [Label]
        let distance: [Distance]
    }

    private func vectors() throws -> Vectors {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try JSONDecoder().decode(
            Vectors.self, from: Data(contentsOf: root.appendingPathComponent("spec/location-vectors.json")))
    }

    func testLinksFollowTheSharedTable() throws {
        let table = try vectors()
        XCTAssertEqual(FlareLocationFormat.osmZoom, table.osmZoom)
        XCTAssertGreaterThanOrEqual(table.links.count, 10, "the shared table lost cases")
        for row in table.links {
            let i = row.input
            let provider = i.provider.flatMap(FlareLocationProvider.init(rawValue:)) ?? .osm
            XCTAssertEqual(FlareLocationFormat.webLink(latitude: i.latitude, longitude: i.longitude, title: i.title,
                                                       provider: provider), row.web, "\(row.id) web")
            XCTAssertEqual(FlareLocationFormat.appleLink(latitude: i.latitude, longitude: i.longitude, title: i.title),
                           row.apple, "\(row.id) apple")
            XCTAssertEqual(FlareLocationFormat.geoLink(latitude: i.latitude, longitude: i.longitude, title: i.title),
                           row.geo, "\(row.id) geo")
            // The card opens the apple column when the host takes no tap.
            XCTAssertEqual(LocationMessageView.defaultLink(latitude: i.latitude, longitude: i.longitude,
                                                           title: i.title ?? "")?.absoluteString,
                           row.apple, "\(row.id) card")
        }
    }

    func testLabelsAndDistancesFollowTheSharedTable() throws {
        let table = try vectors()
        for row in table.label {
            XCTAssertEqual(FlareLocationFormat.label(latitude: row.input.latitude, longitude: row.input.longitude),
                           row.output, row.id)
        }
        for row in table.distance {
            XCTAssertEqual(FlareLocationFormat.distance(row.input), row.output, row.id)
        }
        XCTAssertNil(FlareLocationFormat.distance(.nan))
        XCTAssertNil(FlareLocationFormat.distance(.infinity))
        XCTAssertNil(FlareLocationFormat.label(latitude: .nan, longitude: 0))
    }

    /// The rows whose inputs JSON types loosely (`providerFrom` takes any value), read without a fixed shape.
    private func looseVectors(_ key: String) throws -> [[String: Any]] {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let data = try Data(contentsOf: root.appendingPathComponent("spec/location-vectors.json"))
        let table = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try XCTUnwrap(table[key] as? [[String: Any]], "spec/location-vectors.json has no \(key)")
    }

    func testProviderValuesFollowTheSharedTable() throws {
        let rows = try looseVectors("providerFrom")
        XCTAssertGreaterThanOrEqual(rows.count, 8)
        for row in rows {
            let input = row["input"].flatMap { $0 is NSNull ? nil : $0 }
            XCTAssertEqual(flareLocationProviderFrom(input).rawValue, row["output"] as? String, "\(row["id"] ?? "")")
        }
    }

    func testWebMapUrlsFollowTheSharedTable() throws {
        let rows = try looseVectors("webMapUrl")
        XCTAssertGreaterThanOrEqual(rows.count, 10)
        for row in rows {
            let input = try XCTUnwrap(row["input"] as? [String: Any])
            let content = FlareLocationContent(name: input["title"] as? String ?? "",
                                               latitude: (input["latitude"] as? NSNumber)?.doubleValue,
                                               longitude: (input["longitude"] as? NSNumber)?.doubleValue,
                                               provider: flareLocationProviderFrom(input["provider"]))
            let provider = (row["provider"] as? String).map { flareLocationProviderFrom($0) }
            XCTAssertEqual(flareLocationWebMapUrl(content, provider: provider), row["output"] as? String,
                           "\(row["id"] ?? "")")
        }
    }

    // MARK: Message card

    @MainActor
    func testACardWithoutAMapDrawsTheGroundAndPin() throws {
        let card = try LocationMessageView(title: "西湖", address: "杭州").inspect()
        XCTAssertNoThrow(try card.find(FlareMapPlaceholder.self), "no snapshot: the map ground, never a blank")
        XCTAssertThrowsError(try card.find(ViewType.AsyncImage.self))
        let mapped = try LocationMessageView(title: "西湖", snapshotUrl: "https://geo.example.com/s.png").inspect()
        XCTAssertNoThrow(try mapped.find(ViewType.AsyncImage.self), "a snapshot loads over the ground")
    }

    func testTheLineUnderTheTitleIsTheAddressElseTheCoordinate() {
        XCTAssertEqual(LocationMessageView.detail(address: " 杭州 ", latitude: 30.2741, longitude: 120.1551), "杭州")
        XCTAssertEqual(LocationMessageView.detail(address: "", latitude: 30.2741, longitude: 120.1551),
                       "30.27410, 120.15510")
        XCTAssertEqual(LocationMessageView.detail(address: "", latitude: nil, longitude: nil), "")
    }

    @MainActor
    func testTheCardOpensTheHostElseAppleMapsElseNothing() throws {
        var opened = 0
        let hosted = LocationMessageView(title: "西湖", latitude: 30.2741, longitude: 120.1551, onOpen: { opened += 1 })
        try hosted.inspect().find(ViewType.Button.self).tap()
        XCTAssertEqual(opened, 1)
        let button = try LocationMessageView(title: "西湖", latitude: 30.2741, longitude: 120.1551).inspect()
            .find(ViewType.Button.self)
        XCTAssertEqual(try button.accessibilityHint().string(), s.locationOpenInMaps, "the kit default opens Maps")
        XCTAssertThrowsError(try LocationMessageView(title: "西湖").inspect().find(ViewType.Button.self),
                             "no coordinate and no host: nothing to open")
        XCTAssertThrowsError(try LocationMessageView(title: "x", latitude: 91, longitude: 0).inspect()
            .find(ViewType.Button.self), "an invalid coordinate opens nothing")
    }

    @MainActor
    func testTheTimelineRoutesLocationTapsToTheMostSpecificHandler() throws {
        let content = FlareLocationContent(name: "西湖", address: "杭州", latitude: 30.2741, longitude: 120.1551,
                                           snapshotUrl: "https://geo.example.com/s.png", provider: .amap)
        var located: [FlareLocationContent] = []
        var media = 0
        try MessageContentView(content: content, onMediaAction: { _ in media += 1 },
                               onLocationOpen: { located.append($0) })
            .inspect().find(ViewType.Button.self).tap()
        XCTAssertEqual(located.map(\.provider), [.amap])
        XCTAssertEqual(located.first?.latitude, 30.2741)
        XCTAssertEqual(media, 0, "onLocationOpen comes before the media handler")
        try MessageContentView(content: content, onMediaAction: { _ in media += 1 }).inspect().find(ViewType.Button.self).tap()
        XCTAssertEqual(media, 1)
        XCTAssertNoThrow(try MessageContentView(content: content).inspect().find(ViewType.Button.self),
                         "without a host the card still opens Maps")
        XCTAssertNoThrow(try MessageContentView(content: content).inspect().find(ViewType.AsyncImage.self),
                         "the content's snapshot reaches the card")
    }

    // MARK: Contact card

    @MainActor
    func testAContactCardHandsItsPersonToTheHost() throws {
        var opened: [String] = []
        try ContactMessageView(name: "Ivy", userId: "u-ivy", onOpen: { opened.append($0) }).inspect()
            .find(ViewType.Button.self).tap()
        XCTAssertEqual(opened, ["u-ivy"])
        XCTAssertThrowsError(try ContactMessageView(name: "Ivy", userId: "u-ivy").inspect().find(ViewType.Button.self),
                             "no handler, no tap")
    }

    @MainActor
    func testTheTimelineRoutesCardTapsToCardOpenThenTheMediaHandler() throws {
        let card = FlareCardContent(title: "Ivy", subtitle: "Designer", userId: "u-ivy")
        var people: [String] = []
        var media = 0
        try MessageContentView(content: card, onMediaAction: { _ in media += 1 }, onCardOpen: { people.append($0) })
            .inspect().find(ViewType.Button.self).tap()
        XCTAssertEqual(people, ["u-ivy"])
        XCTAssertEqual(media, 0)
        let anonymous = FlareCardContent(title: "Someone")
        XCTAssertThrowsError(try MessageContentView(content: anonymous, onCardOpen: { people.append($0) })
            .inspect().find(ViewType.Button.self), "a card that names no one is not a profile link")
        try MessageContentView(content: anonymous, onMediaAction: { _ in media += 1 }, onCardOpen: { people.append($0) })
            .inspect().find(ViewType.Button.self).tap()
        XCTAssertEqual(media, 1, "the media handler still takes it")
        XCTAssertThrowsError(try MessageContentView(content: card).inspect().find(ViewType.Button.self))
    }

    // MARK: Picker model

    private let here = FlareLocationCoordinate(latitude: 30.2741, longitude: 120.1551)
    private let last = FlareLocationPlace(id: "poi-9", title: "上次的咖啡馆", address: "延安路", latitude: 30.25, longitude: 120.16)
    private func poi(_ id: String, _ meters: Double? = nil) -> FlareLocationPlace {
        FlareLocationPlace(id: id, title: "POI \(id)", address: "Road \(id)", latitude: 30.27, longitude: 120.15,
                           distanceM: meters)
    }

    func testThePickerOpensOnTheLastPlaceOrASkeleton() {
        let warm = FlareLocationPickerModel(initial: last)
        XCTAssertEqual(warm.rows.map(\.id), [FlareLocationPlace.currentId])
        XCTAssertEqual(warm.rows.first?.title, "上次的咖啡馆")
        XCTAssertEqual(warm.selected?.id, FlareLocationPlace.currentId)
        XCTAssertEqual(warm.mapCenter, last.coordinate)
        XCTAssertEqual(warm.statuses, [.locating])
        XCTAssertFalse(warm.waitingForRows)

        let cold = FlareLocationPickerModel()
        XCTAssertTrue(cold.rows.isEmpty)
        XCTAssertTrue(cold.waitingForRows)
        XCTAssertNil(cold.mapCenter)
        XCTAssertNil(cold.sendable(fallbackTitle: s.locationCurrent), "nothing to send yet")
    }

    func testAFixMovesTheFirstRowAndGeocodingNamesIt() {
        var model = FlareLocationPickerModel(initial: last)
        model.located(here)
        XCTAssertEqual(model.statuses, [.located])
        XCTAssertEqual(model.current?.coordinate, here)
        XCTAssertEqual(model.current?.title, "", "the old name does not follow a new point")
        XCTAssertEqual(model.sendable(fallbackTitle: s.locationCurrent)?.title, s.locationCurrent)
        model.geocoded(FlareLocationAddress(title: "Elsewhere"), for: last.coordinate)
        XCTAssertEqual(model.current?.title, "", "geocoding for a point the row has left is dropped")
        model.geocoded(FlareLocationAddress(title: "西湖", address: "杭州"), for: here)
        XCTAssertEqual(model.rows.first?.title, "西湖")
        XCTAssertEqual(model.sendable(fallbackTitle: s.locationCurrent),
                       FlareLocationPlace(id: FlareLocationPlace.currentId, title: "西湖", address: "杭州",
                                          latitude: here.latitude, longitude: here.longitude))
    }

    func testNoFixIsDeniedAndKeepsTheLastPlace() {
        var model = FlareLocationPickerModel(initial: last)
        model.locateFailed()
        XCTAssertEqual(model.statuses, [.denied])
        XCTAssertEqual(model.rows.first?.title, "上次的咖啡馆")
        var cold = FlareLocationPickerModel()
        cold.locateFailed()
        XCTAssertFalse(cold.waitingForRows, "denied: the user searches instead of waiting")
        XCTAssertTrue(cold.rows.isEmpty)
    }

    func testNearbyPlacesFollowTheFirstRow() {
        var model = FlareLocationPickerModel()
        model.located(here)
        model.nearbyLoaded([poi("a")], for: last.coordinate)
        XCTAssertEqual(model.rows.map(\.id), [FlareLocationPlace.currentId], "places around another point are dropped")
        model.nearbyLoaded([poi("a", 12.4), poi(FlareLocationPlace.currentId), poi("b", 1240)], for: here)
        XCTAssertEqual(model.rows.map(\.id), [FlareLocationPlace.currentId, "a", "b"],
                       "the first row is the user's position, never a place that borrows its id")
        XCTAssertEqual(model.rows.compactMap { FlareLocationFormat.distance($0.distanceM) }, ["12m", "1.2km"])
    }

    func testASearchRunsShowsNoResultsAndGivesWayToANewerOne() {
        var model = FlareLocationPickerModel()
        model.located(here)
        model.nearbyLoaded([poi("a")], for: here)
        model.queryChanged("cof")
        XCTAssertEqual(model.statuses, [.located, .searching])
        model.queryChanged("coffee")
        model.searchFinished("cof", [poi("old")])
        XCTAssertTrue(model.statuses.contains(.searching), "an answer to an older query is dropped")
        model.searchFinished("coffee", [])
        XCTAssertEqual(model.statuses, [.located, .noResults])
        XCTAssertTrue(model.rows.isEmpty)
        model.queryChanged("coffee shop")
        model.searchFinished("coffee shop", [poi("c")])
        XCTAssertEqual(model.rows.map(\.id), ["c"], "a search lists its places, without the first row")
        model.queryChanged("  ")
        XCTAssertEqual(model.rows.map(\.id), [FlareLocationPlace.currentId, "a"], "a blank query is the nearby list")
        XCTAssertEqual(model.statuses, [.located])
    }

    func testSelectingAPlaceMovesTheMapAndAMissingImageIsMapUnavailable() {
        var model = FlareLocationPickerModel()
        model.located(here)
        model.previewStarted(here)
        model.previewLoaded("https://geo.example.com/a.png", for: here)
        XCTAssertEqual(model.snapshotUrl, "https://geo.example.com/a.png")
        let place = FlareLocationPlace(id: "b", title: "B", latitude: 30.3, longitude: 120.2)
        model.select(place)
        XCTAssertEqual(model.mapCenter, place.coordinate)
        model.previewStarted(place.coordinate)
        XCTAssertNil(model.snapshotUrl, "the old point's image does not stand in for the new one")
        model.previewLoaded("https://geo.example.com/late.png", for: here)
        XCTAssertNil(model.snapshotUrl, "an image for a point the map has left is dropped")
        model.previewLoaded(nil, for: place.coordinate)
        XCTAssertTrue(model.statuses.contains(.mapUnavailable))
        model.previewLoaded(" ", for: place.coordinate)
        XCTAssertTrue(model.mapUnavailable, "a blank address is no image")
        // A fix keeps the place the user chose; the locate key chooses the position again.
        model.located(FlareLocationCoordinate(latitude: 30.28, longitude: 120.16))
        XCTAssertEqual(model.selected?.id, "b")
        model.located(here, select: true)
        XCTAssertEqual(model.selected?.id, FlareLocationPlace.currentId)
    }

    func testTheLocateTimeoutWinsOverAHostThatNeverAnswers() async throws {
        let started = Date()
        do {
            _ = try await flareFirst(timeoutMs: 50) { () async throws -> FlareLocationCoordinate in
                // A host that ignores cancellation and answers seconds later.
                for _ in 0..<3 { try? await Task.sleep(nanoseconds: 1_000_000_000) }
                return FlareLocationCoordinate(latitude: 0, longitude: 0)
            }
            XCTFail("expected the timeout")
        } catch FlareLocationPickerError.timedOut {
            XCTAssertLessThan(Date().timeIntervalSince(started), 2)
        }
        let point = try await flareFirst(timeoutMs: 5000) { FlareLocationCoordinate(latitude: 1, longitude: 2) }
        XCTAssertEqual(point, FlareLocationCoordinate(latitude: 1, longitude: 2))
    }

    // MARK: Picker view

    @MainActor
    private func picker(_ model: FlareLocationPickerModel, onSend: ((FlareLocationPlace) -> Void)? = nil,
                        onCancel: (() -> Void)? = nil) -> LocationPickerView {
        LocationPickerView(initialLocation: nil, zoom: 16, locateTimeoutMs: 5000, requestCurrentLocation: nil,
                           reverseGeocode: nil, searchNearby: nil, previewUrl: nil, onSend: onSend,
                           onCancel: onCancel, model: model)
    }

    @MainActor
    func testThePickerDrawsEachState() throws {
        let cold = try picker(FlareLocationPickerModel()).inspect()
        XCTAssertNoThrow(try cold.find(text: s.locationLocating))
        XCTAssertNoThrow(try cold.find(SkeletonView.self), "no last place: a skeleton, not an empty sheet")
        XCTAssertNoThrow(try cold.find(text: s.locationTitle))
        XCTAssertNoThrow(try cold.find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == self.s.locationLocateMe }))

        var denied = FlareLocationPickerModel()
        denied.locateFailed()
        XCTAssertNoThrow(try picker(denied).inspect().find(text: s.locationDenied))

        var empty = FlareLocationPickerModel()
        empty.located(here)
        empty.queryChanged("zzz")
        empty.searchFinished("zzz", [])
        XCTAssertNoThrow(try picker(empty).inspect().find(text: s.locationNoResults))

        var noMap = FlareLocationPickerModel()
        noMap.located(here)
        noMap.previewStarted(here)
        noMap.previewLoaded(nil, for: here)
        let unavailable = try picker(noMap).inspect()
        XCTAssertNoThrow(try unavailable.find(text: s.locationMapUnavailable))
        XCTAssertNoThrow(try unavailable.find(text: "30.27410, 120.15510"), "the coordinate stands in for the map")

        var listed = FlareLocationPickerModel()
        listed.located(here)
        listed.nearbyLoaded([poi("a", 87.5)], for: here)
        let rows = try picker(listed).inspect()
        XCTAssertNoThrow(try rows.find(text: s.locationCurrent), "an unnamed position reads as the current location")
        XCTAssertNoThrow(try rows.find(text: "Road a · 88m"))
    }

    @MainActor
    func testSendAndCancelReachTheHost() throws {
        var sent: [FlareLocationPlace] = []
        var cancelled = 0
        var model = FlareLocationPickerModel()
        model.located(here)
        let view = try picker(model, onSend: { sent.append($0) }, onCancel: { cancelled += 1 }).inspect()
        try view.find(ViewType.Button.self, where: { (try? $0.labelView().find(text: self.s.locationSend)) != nil }).tap()
        XCTAssertEqual(sent.map(\.id), [FlareLocationPlace.currentId])
        XCTAssertEqual(sent.first?.title, s.locationCurrent, "the position without a name is sent as the current location")
        try view.find(ViewType.Button.self, where: { (try? $0.labelView().find(text: self.s.cancel)) != nil }).tap()
        XCTAssertEqual(cancelled, 1)

        let cold = try picker(FlareLocationPickerModel(), onSend: { sent.append($0) }).inspect()
        let send = try cold.find(ViewType.Button.self, where: { (try? $0.labelView().find(text: self.s.locationSend)) != nil })
        XCTAssertTrue(send.isDisabled(), "nothing selected, nothing to send")
    }

    func testTheCopyExistsInBothLanguages() {
        let en = FlareStrings.english
        XCTAssertEqual(s.locationTitle, "位置")
        XCTAssertEqual(en.locationTitle, "Location")
        XCTAssertEqual(en.locationOpenInMaps, "Open in Maps")
        XCTAssertEqual(s.locationDenied, "无法获取定位，可以搜索地点")
        for (zh, english) in [(s.locationSend, en.locationSend), (s.locationLocateMe, en.locationLocateMe),
                              (s.locationLocating, en.locationLocating), (s.locationSearchPlaceholder, en.locationSearchPlaceholder),
                              (s.locationNoResults, en.locationNoResults), (s.locationMapUnavailable, en.locationMapUnavailable),
                              (s.locationCurrent, en.locationCurrent)] {
            XCTAssertNotEqual(zh, english)
        }
    }
}
