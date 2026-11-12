package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight

private val consentIcons = mapOf(
    "capabilityDocumentCapture" to "camera", "capabilityCamera" to "camera", "capabilityPaymentConfirmation" to "wallet",
    "capabilityLocationCoarse" to "location", "capabilityLocationFine" to "location", "capabilityMicrophone" to "mic",
    "capabilityRtcSession" to "video",
)

/**
 * The consent a host shows the first time a plugin uses a host capability (design 7.4; spec Message/CapabilityConsent):
 * "〈plugin〉 wants to use 〈capability〉", the purpose, and allow once, always allow, don't allow.
 *
 * Composing it shows it in a kit [BottomSheet]; dismissing it is a deny. The kit keeps no consent record: [onDecide]
 * hands the choice back and the host answers the engine with [FlareCapabilityConsentDecision.granted] (revoking a once
 * grant when the request is done). A one-time location is confirmed every time, so it offers no "always".
 */
@Composable
fun FlareCapabilityConsent(
    pluginName: String,
    capability: String,
    onDecide: (FlareCapabilityConsentDecision) -> Unit,
    params: Map<String, Any?>? = null,
    purpose: String? = null,
    busy: Boolean = false,
) {
    val strings = flareStrings()
    BottomSheet(
        onClose = { if (!busy) onDecide(FlareCapabilityConsentDecision.Deny) },
        title = strings.capabilityConsentTitle.replace("{plugin}", pluginName),
        dismissible = !busy,
    ) {
        FlareCapabilityConsentBody(capability, onDecide, params, purpose, busy)
    }
}

@Composable
internal fun FlareCapabilityConsentBody(
    capability: String,
    onDecide: (FlareCapabilityConsentDecision) -> Unit,
    params: Map<String, Any?>? = null,
    purpose: String? = null,
    busy: Boolean = false,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val always = FlareCapabilityRules.allowsAlways(capability)
    val key = FlareCapabilityRules.labelKey(capability, params)
    fun decide(d: FlareCapabilityConsentDecision) { if (!busy) onDecide(d) }
    Column(
        Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        Row(Modifier.semantics(mergeDescendants = true) {}, verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
            Box(Modifier.size(FlareSizes.touchTarget).background(colors.bgSecondary, CircleShape), contentAlignment = Alignment.Center) {
                FlareIcon(consentIcons[key] ?: "info", tint = colors.primaryText)
            }
            Text(FlareCapabilityRules.label(strings, capability, params), color = colors.textPrimary,
                fontSize = FlareSizes.fontSize2xl, fontWeight = FontWeight.Medium, modifier = Modifier.testTag("flare-consent-label"))
        }
        if (!purpose.isNullOrBlank()) {
            Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                Text(strings.capabilityConsentPurpose, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
                Text(purpose, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg)
            }
        }
        if (always) Text(strings.capabilityConsentNote, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
        Column(Modifier.fillMaxWidth().padding(top = FlareSizes.spacingSm), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            if (always) Button(label = strings.capabilityConsentAllowAlways, size = FlareControlSize.Lg, disabled = busy, block = true,
                onClick = { decide(FlareCapabilityConsentDecision.Always) })
            Button(label = strings.capabilityConsentAllowOnce, variant = if (always) FlareButtonVariant.Secondary else FlareButtonVariant.Primary,
                size = FlareControlSize.Lg, disabled = busy, block = true, onClick = { decide(FlareCapabilityConsentDecision.Once) })
            Button(label = strings.capabilityConsentDeny, variant = FlareButtonVariant.Quiet, size = FlareControlSize.Lg, disabled = busy,
                block = true, onClick = { decide(FlareCapabilityConsentDecision.Deny) })
        }
    }
}
