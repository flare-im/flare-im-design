import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI
final class ResolvedPresentationTests: XCTestCase {
 func testOnlyTheCompiledRenderersStaySpecial() {
  // The composer and the detail renderers moved to blocks (money input, hero, entries, banner): their views draw as
  // plain plugin views now.
  for renderer in ["redPacket.composer", "redPacket.detail", "account", "flare.qr"] {
   let view = PluginViewModel(available: true, title: "x", presentation: PluginPresentation(renderer: renderer, props: [:], actions: [:]))
   XCTAssertFalse(flareHasResolvedPresentation(view), renderer)
  }
  for renderer in ["redPacket.card", "redPacket.pay", "payment.confirm"] {
   let view = PluginViewModel(available: true, title: "x", presentation: PluginPresentation(renderer: renderer, props: [:], actions: [:]))
   XCTAssertTrue(flareHasResolvedPresentation(view), renderer)
  }
 }
 func testPaymentCancelClosesClearsCredentialAndReopensWithoutReuse() {
  var state = ResolvedPaymentState()
  XCTAssertTrue(state.presented)
  state.password = "839271"
  state.close(busy: false)
  XCTAssertFalse(state.presented)
  XCTAssertEqual(state.password, "")
  state.reopen(busy: false, blocked: false)
  XCTAssertTrue(state.presented)
  XCTAssertEqual(state.password, "")
 }
 func testBusyOrBlockedConfirmationCannotDismissOrReopen() {
  var state = ResolvedPaymentState()
  state.password = "839271"
  state.close(busy: true)
  XCTAssertTrue(state.presented)
  XCTAssertEqual(state.password, "839271")
  state.close(busy: false)
  state.reopen(busy: true, blocked: false)
  XCTAssertFalse(state.presented)
  state.reopen(busy: false, blocked: true)
  XCTAssertFalse(state.presented)
  XCTAssertEqual(state.password, "")
 }
 func testRefreshClearsCredentialWithoutReopeningADismissedPayment() {
  var state = ResolvedPaymentState()
  state.password = "839271"
  state.close(busy: false)
  state.refreshed()
  XCTAssertFalse(state.presented)
  XCTAssertEqual(state.password, "")
  state.reopen(busy: false, blocked: false)
  state.password = "839271"
  state.refreshed()
  XCTAssertTrue(state.presented)
  XCTAssertEqual(state.password, "")
 }
 func testNoPasswordConfirmationDispatchesOnceUntilExplicitReopen() {
  var state = ResolvedPaymentState()
  var sent: [String] = []
  func confirm() {
   let opaqueAction = "declared-confirm"
   guard state.close(busy: false) else { return }
   sent.append(opaqueAction)
  }
  confirm(); confirm()
  XCTAssertEqual(sent, ["declared-confirm"])
  state.refreshed(); confirm()
  XCTAssertFalse(state.presented)
  XCTAssertEqual(sent, ["declared-confirm"])
  state.reopen(busy: false, blocked: false); confirm()
  XCTAssertEqual(sent, ["declared-confirm", "declared-confirm"])
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
  let body=ResolvedPresentationView(view:v,busy:false,error:nil,formErrors:[],members:[],settleToken:0,resolveUser:nil,onAction:nil,onRequest:{ids.append($0)})
  let card=try body.inspect().find(RedPacketCardView.self)
  try card.find(ViewType.Button.self).tap();XCTAssertEqual(ids,["open"])
 }
 func testDynamicWalletPrecisionAndMalformedDisplayBounds() {
  XCTAssertEqual(flareRedPacketAmountMinor("0.123456789012",exponent:12),"123456789012")
  XCTAssertEqual(FlareRedPacketMoney.text(minor:"1",exponent:8),"0.00000001")
  XCTAssertNil(FlareRedPacketMoney.text(minor:"1",exponent:1000000))
 }
 func testConfirmedPaymentWaitsForDismissalAndItsCredentialSnapshotIsTakenOnce() throws {
  let source = try fixture("payment")
  var state = ResolvedPaymentState(); state.password = "839271"
  XCTAssertTrue(state.confirm(source: source, actionId: "authorize", passwordInput: "pin"))
  XCTAssertFalse(state.presented); XCTAssertEqual(state.password, "")
  XCTAssertFalse(state.confirm(source: source, actionId: "authorize", passwordInput: "pin"))
  state.reopen(busy: false, blocked: false); XCTAssertFalse(state.presented)
  XCTAssertFalse(state.close(busy: false), "system binding writes after confirm preserve the pending snapshot")
  let pending = state.dismissed(source: source, busy: false, blocked: false)
  XCTAssertEqual(pending?.actionId, "authorize")
  XCTAssertEqual(pending?.payload?.formValues?["pin"], .string("839271"))
  XCTAssertNil(state.dismissed(source: source, busy: false, blocked: false))
 }
 func testCancelledRefreshedOrReplacedPaymentNeverDispatchesAfterDismissal() throws {
  let source = try fixture("payment"), other = try fixture("card")
  var state = ResolvedPaymentState(); state.password = "839271"
  XCTAssertTrue(state.confirm(source: source, actionId: "authorize", passwordInput: "pin"))
  state.refreshed()
  XCTAssertNil(state.dismissed(source: source, busy: false, blocked: false))
  state.reopen(busy: false, blocked: false)
  XCTAssertTrue(state.confirm(source: source, actionId: "authorize", passwordInput: nil))
  XCTAssertNil(state.dismissed(source: other, busy: false, blocked: false))
  state.reopen(busy: false, blocked: false)
  XCTAssertTrue(state.confirm(source: source, actionId: "authorize", passwordInput: nil))
  XCTAssertNil(state.dismissed(source: source, busy: true, blocked: false))
 }

}
