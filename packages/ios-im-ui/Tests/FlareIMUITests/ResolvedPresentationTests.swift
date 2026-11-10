import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI
final class ResolvedPresentationTests: XCTestCase {
 func testOpenWaitsForHostResultAndBlocksASecondTap() {
  var state = ResolvedRedPacketOpenState()
  state.show(busy: false, unknown: false)
  XCTAssertTrue(state.begin(actionId: "claim", unknown: false, host: PluginHostSignal(settleToken: 4)))
  XCTAssertTrue(state.presented, "opening the envelope must not hide the pending claim")
  XCTAssertTrue(state.pending)
  XCTAssertFalse(state.begin(actionId: "claim", unknown: false, host: PluginHostSignal(settleToken: 4)))
  state.hostChanged(to: PluginHostSignal(busy: true, settleToken: 4))
  XCTAssertTrue(state.presented)
  XCTAssertTrue(state.pending)
  state.hostChanged(to: PluginHostSignal(settleToken: 5))
  XCTAssertFalse(state.pending)
  XCTAssertFalse(state.presented, "a clean host result closes the envelope")
 }
 func testOpenFailureRemainsVisibleAndNeedsAnExplicitRetry() {
  var state = ResolvedRedPacketOpenState()
  state.show(busy: false, unknown: false)
  XCTAssertTrue(state.begin(actionId: "claim", unknown: false, host: PluginHostSignal()))
  state.hostChanged(to: PluginHostSignal(error: "Connection lost", settleToken: 1))
  XCTAssertTrue(state.presented, "a failed claim keeps its error visible")
  XCTAssertFalse(state.pending)
  state.hostChanged(to: PluginHostSignal(error: "Connection lost", settleToken: 2))
  XCTAssertTrue(state.presented, "host refreshes must never retry or close the failed claim")
  XCTAssertTrue(state.begin(actionId: "claim", unknown: false, host: PluginHostSignal(error: "Connection lost", settleToken: 2)))
  state.hostChanged(to: PluginHostSignal(formErrors: [PluginFormError(input: "request", issue: .required)], settleToken: 3))
  XCTAssertTrue(state.presented)
  XCTAssertFalse(state.pending)
 }
 func testOpenSameFrameCompletionAndUnknownResults() {
  var state = ResolvedRedPacketOpenState()
  state.show(busy: false, unknown: true)
  XCTAssertFalse(state.presented)
  state.show(busy: false, unknown: false)
  XCTAssertFalse(state.begin(actionId: "claim", unknown: true, host: PluginHostSignal()))
  XCTAssertFalse(state.begin(actionId: "claim", unknown: false, host: PluginHostSignal(busy: true)))
  XCTAssertTrue(state.begin(actionId: "claim", unknown: false, host: PluginHostSignal(settleToken: 8)))
  state.hostChanged(to: PluginHostSignal(settleToken: 9))
  XCTAssertFalse(state.presented, "the token also settles a request that completed before a busy frame rendered")
  state.show(busy: false, unknown: false)
  XCTAssertTrue(state.begin(actionId: "claim", unknown: false, host: PluginHostSignal(settleToken: 9)))
  state.hostChanged(to: PluginHostSignal(settleToken: 10), unknown: true)
  XCTAssertTrue(state.presented, "an unknown outcome is not a successful claim")
  XCTAssertFalse(state.pending)
  XCTAssertFalse(state.begin(actionId: "claim", unknown: true, host: PluginHostSignal(settleToken: 10)))
 }
 func testExplicitCloseDuringOpenDoesNotCancelOrReopenTheHostAction() {
  var state = ResolvedRedPacketOpenState()
  state.show(busy: false, unknown: false)
  XCTAssertTrue(state.begin(actionId: "claim", unknown: false, host: PluginHostSignal()))
  state.presented = false
  state.show(busy: false, unknown: false)
  XCTAssertFalse(state.presented, "an in-flight request cannot be started again by reopening")
  XCTAssertTrue(state.pending)
  state.hostChanged(to: PluginHostSignal(error: "Connection lost", settleToken: 1))
  XCTAssertFalse(state.pending)
  XCTAssertFalse(state.presented, "a late failure respects an explicit user dismissal")
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
 @MainActor func testComposerStartsWithAmountWithoutFundingSetup()throws {
  let view=try fixture("composer")
  let body=ResolvedPresentationView(view:view,busy:false,error:nil,formErrors:[],members:[],settleToken:0,resolveUser:nil,onAction:nil,onRequest:{_ in})
  XCTAssertNoThrow(try body.inspect().find(RedPacketComposerView<AnyView>.self))
  XCTAssertThrowsError(try body.inspect().find(PluginFormView.self))
  XCTAssertEqual(view.presentation?.props["funding"]?["currencyExponent"]?.numberValue,2)
 }
 private func composer(_ conversationType: String?) throws -> PluginViewModel {
  let value = try fixture("composer")
  var raw = try JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as! [String: Any]
  var presentation = raw["presentation"] as! [String: Any]
  var props = presentation["props"] as! [String: Any]
  props["conversationType"] = conversationType
  presentation["props"] = props; raw["presentation"] = presentation
  return try JSONDecoder().decode(PluginViewModel.self, from: JSONSerialization.data(withJSONObject: raw))
 }
 @MainActor func testSingleComposerHasNoKindSwitchAndSubmitsOneShareWithoutAScalarRecipient() throws {
  let view = try composer("single"); var payloads: [PluginActionPayload] = []
  let body = ResolvedPresentationView(view: view, busy: false, error: nil, formErrors: [], members: [], settleToken: 0,
    resolveUser: nil, onAction: { _, payload in payloads.append(payload) }, onRequest: { _ in })
  let inspected = try body.inspect()
  XCTAssertThrowsError(try inspected.find(SegmentedControlView.self))
  XCTAssertThrowsError(try inspected.find(InputView.self), "recipient ids are never typed")
  try inspected.find(ViewType.Button.self, where: { (try? $0.labelView().find(text: view.actions[0].label)) != nil }).tap()
  XCTAssertEqual(payloads.count, 1)
  XCTAssertEqual(payloads[0].formValues?["kind"], .string("normal"))
  XCTAssertEqual(payloads[0].formValues?["shareCount"], .number(1))
  XCTAssertEqual(payloads[0].formValues?["designatedUserIds"], .array([]))
  XCTAssertNil(payloads[0].formValues?["designatedUserId"])
 }
 @MainActor func testGroupOffersTheKindSwitchAndUnknownConversationCannotSubmit() throws {
  let group = try composer("group")
  let groupBody = ResolvedPresentationView(view: group, busy: false, error: nil, formErrors: [], members: [], settleToken: 0,
    resolveUser: nil, onAction: nil, onRequest: { _ in })
  XCTAssertNoThrow(try groupBody.inspect().find(SegmentedControlView.self))
  let unknown = try composer(nil)
  var calls = 0
  let body = ResolvedPresentationView(view: unknown, busy: false, error: nil, formErrors: [], members: [], settleToken: 0,
    resolveUser: nil, onAction: { _, _ in calls += 1 }, onRequest: { _ in })
  let button = try body.inspect().find(ViewType.Button.self, where: { (try? $0.labelView().find(text: unknown.actions[0].label)) != nil })
  XCTAssertTrue(button.isDisabled())
  XCTAssertThrowsError(try button.tap())
  XCTAssertEqual(calls, 0)
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
