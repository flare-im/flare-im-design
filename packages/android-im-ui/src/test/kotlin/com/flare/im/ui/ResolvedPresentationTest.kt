package com.flare.im.ui
import java.io.File
import kotlin.test.*
class ResolvedPresentationTest {
 private fun fixture(name:String):PluginViewModel {val file=File("../../spec/financial-presentation-vectors.json");val all=FlareJson.parse(file.readText()) as Map<*,*>;return PluginViewModel.fromMap(all[name] as Map<*,*>)}
 @Test fun resolvedAmountsAndCallbackIdsRemainExact(){val view=fixture("payment");assertTrue(hasResolvedPresentation(view));val p=view.presentation!!;assertEquals("999999999999999999.99",(p["props"] as Map<*,*>)["amount"]);assertEquals("approve",(p["actions"] as Map<*,*>)["authorize"])}
 @Test fun unavailableViewsNeverSelectSpecializedRendering(){assertFalse(hasResolvedPresentation(fixture("card").copy(available=false)));assertFalse(hasResolvedPresentation(fixture("card").copy(presentation=mapOf("renderer" to "unknown"))))}
 @Test fun dynamicWalletUnitsKeepAllTwelvePlaces(){assertEquals("123456789012",flareRedPacketAmountMinor("0.123456789012",12));assertEquals("0.00000001",flareRedPacketAmountText("1",8));assertNull(flareRedPacketAmountText("1",1000000))}
}
