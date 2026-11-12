import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI
final class ResolvedPresentationTests: XCTestCase {
 func testOnlyTheCompiledRenderersStaySpecial() {
  // The composer and the detail renderers moved to blocks (money input, hero, entries, banner): their views draw as
  // plain plugin views now.
  for renderer in ["redPacket.composer", "redPacket.detail", "account", "flare.qr", "redPacket.pay", "payment.confirm"] {
   let view = PluginViewModel(available: true, title: "x", presentation: PluginPresentation(renderer: renderer, props: [:], actions: [:]))
   XCTAssertFalse(flareHasResolvedPresentation(view), renderer)
  }
  let card = PluginViewModel(available: true, title: "x", presentation: PluginPresentation(renderer: "redPacket.card", props: [:], actions: [:]))
  XCTAssertTrue(flareHasResolvedPresentation(card))
 }
 private func fixture(_ name:String)throws->PluginViewModel {
  let file=URL(fileURLWithPath:#filePath).resolvingSymlinksInPath().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("spec/financial-presentation-vectors.json")
  let all=try JSONSerialization.jsonObject(with:Data(contentsOf:file)) as! [String:Any]
  return try JSONDecoder().decode(PluginViewModel.self,from:JSONSerialization.data(withJSONObject:all[name]!))
 }
 func testPasswordDraftNeverPrefillsAndValuesPreserveExactSecret() throws {
  let input=try JSONDecoder().decode(PluginInput.self,from:Data(#"{"id":"password","kind":"password","label":"PIN","required":true,"maxLength":6,"default":"111111"}"#.utf8))
  XCTAssertEqual(PluginFormRules.draft([input], values:["password":.string("222222")])["password"],.string(""))
  XCTAssertEqual(PluginFormRules.values([input],["password":.string("839271")])["password"],.string("839271"))
 }
 func testResolvedPropsDecodeAndSurviveRoundTripWithoutRounding()throws {
  let v=try fixture("payment");XCTAssertEqual(v.presentation?.renderer,"payment.confirm");XCTAssertEqual(v.presentation?.props["amount"]?.stringValue,"999999999999999999.99")
  let again=try JSONDecoder().decode(PluginViewModel.self,from:JSONEncoder().encode(v));XCTAssertEqual(again.presentation,v.presentation)
 }
 @MainActor func testComposedCardUsesKitCardAndOnlyItsDeclaredRequest()throws {
  let v=try fixture("card");var ids=[String]()
  let body=ResolvedPresentationView(view:v,busy:false,onRequest:{ids.append($0)})
  let card=try body.inspect().find(RedPacketCardView.self)
  try card.find(ViewType.Button.self).tap();XCTAssertEqual(ids,["open"])
 }
 func testDynamicWalletPrecisionAndMalformedDisplayBounds() {
  XCTAssertEqual(flareRedPacketAmountMinor("0.123456789012",exponent:12),"123456789012")
  XCTAssertEqual(FlareRedPacketMoney.text(minor:"1",exponent:8),"0.00000001")
  XCTAssertNil(FlareRedPacketMoney.text(minor:"1",exponent:1000000))
 }
}
