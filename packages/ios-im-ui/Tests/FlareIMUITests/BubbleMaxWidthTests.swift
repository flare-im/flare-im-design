import XCTest
@testable import FlareIMUI

/// 气泡最大宽是四端共享的一条规则，这里断言规则本身而不是某一次渲染的结果。
///
/// 为什么值得一条专门的测试：改前四端是四种规则 —— 这一端完全不设上限（宽栏/iPad 上
/// 一条长消息贴满整栏）、Android 固定 320dp（平板上气泡不跟窗格长）、Flutter 取**屏宽**
/// 而不是窗格宽的 72%、web 是 `min(62%, 640)` 且窄栏给到 88%。同一条长消息四种宽度，
/// 而气泡是全 app 出现频率最高的组件。
final class BubbleMaxWidthTests: XCTestCase {
    func testNarrowPanesGetTheFullerRatio() {
        // 手机宽：给得更满，否则右边留一大条空白。
        let phone: CGFloat = 390
        XCTAssertEqual(flareBubbleMaxWidth(paneWidth: phone),
                       phone * FlareSizes.componentBubbleMaxWidthRatioCompact, accuracy: 0.01)
    }

    func testWidePanesGetTheNarrowerRatio() {
        // 窗格够宽时比例收窄：一行字太长就不好读了。
        let pane: CGFloat = 700
        XCTAssertEqual(flareBubbleMaxWidth(paneWidth: pane),
                       pane * FlareSizes.componentBubbleMaxWidthRatioRegular, accuracy: 0.01)
    }

    func testTheAbsoluteCeilingBinds() {
        // 再宽也不超过 layout.bubbleMaxWidth —— 这是改前这一端缺的那一半。
        XCTAssertEqual(flareBubbleMaxWidth(paneWidth: 4000), FlareSizes.bubbleMaxWidth, accuracy: 0.01)
    }

    func testTheRatioSwitchesAtTheKitBreakpoint() {
        let bp = FlareSizes.navigationRailMinWidth
        XCTAssertEqual(flareBubbleMaxWidth(paneWidth: bp - 1),
                       (bp - 1) * FlareSizes.componentBubbleMaxWidthRatioCompact, accuracy: 0.01)
        XCTAssertEqual(flareBubbleMaxWidth(paneWidth: bp),
                       bp * FlareSizes.componentBubbleMaxWidthRatioRegular, accuracy: 0.01)
    }
}
