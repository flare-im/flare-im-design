import XCTest
@testable import FlareIMUI

final class EmojiStickerRuntimeCatalogTests: XCTestCase {
    override func tearDown() {
        FlareEmojiStickerCatalog.shared.clearRegisteredEmojiAssets()
        FlareEmojiStickerCatalog.shared.clearRegisteredStickerPacks()
        super.tearDown()
    }

    func testRuntimeEmojiSeparatesAnimatedURLAndStaticPreview() throws {
        let animated = URL(string: "https://cdn.example/user-wave.webp")!
        let preview = Data([1, 2, 3])
        let catalog = FlareEmojiStickerCatalog.shared
        catalog.registerEmojiAssets([
            FlareEmojiAssetRegistration(
                key: "user_wave", animatedURL: animated, staticPreviewData: preview,
                labels: ["en": "User wave", "zh-Hans": "用户挥手"]
            )
        ])

        XCTAssertTrue(catalog.hasEmojiKey("user_wave"))
        XCTAssertEqual(catalog.emojiImageURL("user_wave"), animated)
        XCTAssertEqual(catalog.emojiStaticPreviewData("user_wave"), preview)
        XCTAssertEqual(catalog.emojiLabel("user_wave", locale: "zh-CN"), "用户挥手")
        XCTAssertEqual(flareLoneEmojiPackKey(" [user_wave] "), "user_wave")
    }

    func testRuntimeStickerPackUsesStableProtocolIds() {
        let url = URL(fileURLWithPath: "/tmp/party.webp")
        let catalog = FlareEmojiStickerCatalog.shared
        catalog.registerStickerPacks([
            FlareStickerPackRegistration(
                id: "my_pack", title: "My Pack",
                stickers: [FlareStickerAssetRegistration(stickerId: "party", url: url, staticPreviewData: Data([9]))]
            )
        ])

        XCTAssertEqual(catalog.loadedStickerPacks().first { $0.id == "my_pack" }?.stickerIds, ["party"])
        XCTAssertEqual(catalog.stickerImageURL(stickerId: "party", packageId: "my_pack"), url)
        XCTAssertEqual(catalog.stickerStaticPreviewData(stickerId: "party", packageId: "my_pack"), Data([9]))
    }
}
