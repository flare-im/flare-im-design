import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI
final class ResolvedPresentationTests: XCTestCase {
 private func fixture(_ name:String)throws->PluginViewModel {
  let file=URL(fileURLWithPath:#filePath).resolvingSymlinksInPath().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("spec/financial-presentation-vectors.json")
  let all=try JSONSerialization.jsonObject(with:Data(contentsOf:file)) as! [String:Any]
  return try JSONDecoder().decode(PluginViewModel.self,from:JSONSerialization.data(withJSONObject:all[name]!))
 }
 func testResolvedPropsDecodeAndSurviveRoundTripWithoutRounding()throws {
  let v=try fixture("payment");XCTAssertEqual(v.presentation?.renderer,"payment.confirm");XCTAssertEqual(v.presentation?.props["amount"]?.stringValue,"999999999999999999.99")
  let again=try JSONDecoder().decode(PluginViewModel.self,from:JSONEncoder().encode(v));XCTAssertEqual(again.presentation,v.presentation)
 }
 @MainActor func testComposedCardUsesKitCardAndOnlyItsDeclaredRequest()throws {
  let v=try fixture("card");var ids=[String]()
  let body=ResolvedPresentationView(view:v,busy:false,error:nil,formErrors:[],members:[],settleToken:0,resolveUser:nil,onAction:nil,onRequest:{ids.append($0)})
  let card=try body.inspect().find(RedPacketCardView.self)
  try card.find(ViewType.Button.self).tap();XCTAssertEqual(ids,["open"])
 }
 func testDynamicWalletPrecisionAndMalformedDisplayBounds() {
  XCTAssertEqual(flareRedPacketAmountMinor("0.123456789012",exponent:12),"123456789012")
  XCTAssertEqual(FlareRedPacketMoney.text(minor:"1",exponent:8),"0.00000001")
  XCTAssertNil(FlareRedPacketMoney.text(minor:"1",exponent:1000000))
 }
 @MainActor func testComposerStartsWithAmountWithoutFundingSetup()throws {
  let view=try fixture("composer")
  let body=ResolvedPresentationView(view:view,busy:false,error:nil,formErrors:[],members:[],settleToken:0,resolveUser:nil,onAction:nil,onRequest:{_ in})
  XCTAssertNoThrow(try body.inspect().find(RedPacketComposerView<InputView>.self))
  XCTAssertThrowsError(try body.inspect().find(PluginFormView.self))
  XCTAssertEqual(view.presentation?.props["funding"]?["currencyExponent"]?.numberValue,2)
 }
}
