import SwiftUI
import XCTest
@testable import FlareIMUI

/// §7 button feedback: the press scale and the fills a kit button takes under a pointer and a press.
final class ButtonFeedbackTests: XCTestCase {
    private let colors = FlareColors.of(.light)

    func testAPressScalesUnlessMotionIsReducedOrTheButtonIsOff() {
        XCTAssertEqual(FlareButtonFeedbackStyle.scale(pressed: true, enabled: true, reduceMotion: false), 0.98)
        XCTAssertEqual(FlareButtonFeedbackStyle.scale(pressed: true, enabled: true, reduceMotion: true), 1, "colour only")
        XCTAssertEqual(FlareButtonFeedbackStyle.scale(pressed: true, enabled: false, reduceMotion: false), 1, "no feedback")
        XCTAssertEqual(FlareButtonFeedbackStyle.scale(pressed: false, enabled: true, reduceMotion: false), 1)
    }

    func testThePrimaryFillsComeFromThePrimaryStateTokens() {
        func fill(_ pressed: Bool, _ variant: FlareButtonVariant = .primary,
                  _ appearance: FlareButtonAppearance = .standard) -> Color {
            ButtonView.feedbackFill(variant: variant, appearance: appearance, pressed: pressed, base: colors.primary,
                                    ink: colors.primaryText, colors: colors)
        }
        XCTAssertEqual(fill(true), colors.primaryActive)
        XCTAssertEqual(fill(false), colors.primaryHover)
        XCTAssertEqual(fill(true, .secondary), colors.bgHover)
        XCTAssertEqual(fill(true, .danger), colors.errorActive)
        XCTAssertEqual(fill(false, .danger), colors.errorHover)
        XCTAssertEqual(fill(true, .primary, .text), colors.primaryText.opacity(FlareOpacity.tintWeak))
    }
}
