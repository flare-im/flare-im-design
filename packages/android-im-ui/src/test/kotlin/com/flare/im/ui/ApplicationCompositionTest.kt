package com.flare.im.ui

import androidx.compose.ui.unit.Dp
import java.io.File
import androidx.compose.ui.unit.dp
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ApplicationCompositionTest {
    @Test
    fun responsiveModeUsesSharedBreakpoints() {
        assertEquals(FlareApplicationResponsiveMode.Mobile, resolveApplicationResponsiveMode(375.dp))
        assertEquals(FlareApplicationResponsiveMode.Tablet, resolveApplicationResponsiveMode(800.dp))
        assertEquals(FlareApplicationResponsiveMode.Desktop, resolveApplicationResponsiveMode(1000.dp))
        assertEquals(FlareApplicationResponsiveMode.Desktop, resolveApplicationResponsiveMode(1200.dp))
        assertEquals(FlareApplicationResponsiveMode.WideDesktop, resolveApplicationResponsiveMode(1600.dp))
    }

    /** The one pane rule (FR-110): every layout in the kit asks it how many panes fit. */
    @Test
    fun theOnePaneRuleFollowsTheSharedTable() {
        val panes = layoutTable()["panes"] as List<*>
        assertTrue(panes.size >= 20, "the shared table lost cases: ${panes.size}")
        for (raw in panes) {
            val v = raw as Map<*, *>
            val mode = resolvePaneMode(
                (v["width"] as Number).toFloat().dp,
                v["hasDetail"] as Boolean,
                (v["scale"] as Number).toFloat(),
                (v["navigationWidth"] as Number).toFloat().dp,
                (v["primaryWidth"] as Number?)?.toFloat()?.dp ?: FlareSizes.primaryPaneDefaultWidth,
                (v["detailWidth"] as Number?)?.toFloat()?.dp ?: FlareSizes.detailPaneDefaultWidth,
            )
            assertEquals(v["expected"], mode.name.replaceFirstChar { it.lowercase() }, "${v["id"]}: ${v["why"]}")
        }
        assertEquals(752f, paneModeMinWidth(FlareWorkspacePaneMode.DualPane, resolveNavigationWidth(FlareApplicationResponsiveMode.Tablet)).value)
        assertEquals(980f, paneModeMinWidth(FlareWorkspacePaneMode.TriplePane).value)
        assertEquals(0f, paneModeMinWidth(FlareWorkspacePaneMode.SinglePane).value)
    }

    @Test
    fun workspacePresentationFollowsSharedVectors() {
        val cases = layoutTable()["cases"] as List<*>
        assertTrue(cases.size >= 20, "the shared table lost cases: ${cases.size}")
        fun wire(name: String) = name.replaceFirstChar { it.lowercase() }
        for (raw in cases) {
            val v = raw as Map<*, *>
            val id = v["id"] as String
            val width = (v["width"] as Number).toFloat()
            val scale = (v["scale"] as Number).toFloat()
            val expected = v["expected"] as Map<*, *>
            val mode = resolveApplicationResponsiveMode(width.dp, scale)
            assertEquals(expected["mode"], wire(mode.name), id)
            val presentation = resolveWorkspacePresentation(
                mode, v["hasDetail"] as Boolean, width.dp, scale, if (v["navigation"] as Boolean) null else 0.dp,
            )
            assertEquals(expected["paneMode"], wire(presentation.paneMode.name), id)
            assertEquals(expected["detail"], wire(presentation.detail.name), id)
        }
    }

    @Test
    fun aTabletTooNarrowForAUsableChatShowsOnePane() {
        // The rule, not a magic number: rail + list + the chat minimum.
        assertEquals(752f, paneModeMinWidth(FlareWorkspacePaneMode.DualPane, resolveNavigationWidth(FlareApplicationResponsiveMode.Tablet)).value)
        // A host that gives its own column widths moves the threshold with them.
        assertEquals(660f, paneModeMinWidth(FlareWorkspacePaneMode.DualPane, navigationWidth = 0.dp, primaryWidth = 300.dp).value)
        // Only the chat grows with the text: 72 + 320 + 360 x 1.5.
        assertEquals(932f, paneModeMinWidth(FlareWorkspacePaneMode.DualPane, navigationWidth = 72.dp, textScale = 1.5f).value)
        fun paneMode(width: Float, scale: Float = 1f, hasDetail: Boolean = false, navigation: Dp? = null) =
            resolveWorkspacePresentation(
                resolveApplicationResponsiveMode(width.dp, scale), hasDetail, width.dp, scale, navigation,
            ).paneMode
        assertEquals(FlareWorkspacePaneMode.SinglePane, paneMode(751f))
        assertEquals(FlareWorkspacePaneMode.DualPane, paneMode(752f))
        // Without a navigation rail the same container fits two panes 72dp earlier.
        assertEquals(FlareWorkspacePaneMode.DualPane, paneMode(700f, navigation = 0.dp))
        // A desktop sidebar (280) takes its room too: 280 + 320 + 360 = 960.
        assertEquals(FlareWorkspacePaneMode.SinglePane, paneMode(959f))
        assertEquals(FlareWorkspacePaneMode.DualPane, paneMode(1000f))
        assertEquals(FlareWorkspacePaneMode.TriplePane, paneMode(1400f, hasDetail = true))
        // A width the host does not know keeps the old answer (two panes) instead of collapsing.
        assertEquals(
            FlareWorkspacePaneMode.DualPane,
            resolveWorkspacePresentation(FlareApplicationResponsiveMode.Tablet).paneMode,
        )
    }

    @Test
    fun aDetailIsAPageWhenOnlyOnePaneFits() {
        fun detail(width: Float) = resolveWorkspacePresentation(
            resolveApplicationResponsiveMode(width.dp), hasDetail = true, width = width.dp,
        ).detail
        // One pane: the detail is a route the host pushes, never an overlay over a full-width pane.
        assertEquals(FlareWorkspaceDetailPresentation.Route, detail(700f))
        assertEquals(FlareWorkspaceDetailPresentation.Overlay, detail(800f))
    }

    @Test
    fun messageActionsRespectCapabilitiesAndPredicate() {
        val actions = listOf(
            FlareMessageActionExtension("translate", "Translate", "translate", order = 1, invoke = {}),
            FlareMessageActionExtension("debug", "Debug", order = 2, enabled = { false }, invoke = {}),
            FlareMessageActionExtension("hidden", "Hidden", available = { false }, invoke = {}),
        )
        val resolved = resolveMessageActionExtensions(actions, FlareCapabilitySet(setOf("translate")), "m1")
        assertEquals(listOf("translate", "debug"), resolved.map { it.id })
        assertEquals(false, resolved.last().enabled("m1"))
    }

    @Test
    fun navigationDefaultsAreReplaceableAndOrdered() {
        val defaults = flareDefaultIMNavigation()
        assertEquals(listOf("chats", "contacts", "profile"), defaults.map { it.id })
        assertEquals(listOf("friends", "groups", "newFriends", "favorites"), flareDefaultContactNavigation().map { it.id })
        val resolved = resolveNavigationItems(
            defaults,
            listOf(
                defaults[2].copy(order = 3),
                defaults[1].copy(visible = false),
                defaults[0].copy(order = 0),
                defaults[0].copy(id = "work", label = "Work", order = 2),
            ),
        )
        assertEquals(listOf("chats", "work", "profile"), resolved.map { it.id })
    }

    @Test
    fun navigationDefaultsAreLabelledFromTheStringsTableAndDrawRegistryIcons() {
        // Chinese out of the box — no English label reaches a Chinese UI.
        assertEquals(listOf("消息", "通讯录", "我"), flareDefaultIMNavigation().map { it.label })
        assertEquals(listOf("好友", "群聊", "新的朋友", "收藏"), flareDefaultContactNavigation().map { it.label })
        // A host that translates the kit gets its own wording here too.
        val english = FlareStrings {
            navigationChats = "Chats"; navigationContacts = "Contacts"; navigationProfile = "Me"
        }
        assertEquals(listOf("Chats", "Contacts", "Me"), flareDefaultIMNavigation(english).map { it.label })
        // Icons are registry names, not platform glyphs.
        assertEquals(listOf("chats", "people", "person"), flareDefaultIMNavigation().map { it.icon })
        assertEquals(listOf("person", "people", "person-add", "star"), flareDefaultContactNavigation().map { it.icon })
        for (item in flareDefaultIMNavigation() + flareDefaultContactNavigation()) {
            assertTrue(item.icon in flareIconNames, "`${'$'}{item.icon}` is a registry name")
        }
    }

    @Test
    fun configurationCanDescribeUnsupportedDirectoryCapabilities() {
        val configuration = FlareIMAppConfiguration(
            features = FlareApplicationFeatures(contacts = false, groups = false),
        )
        assertEquals(false, configuration.features.contacts)
        assertEquals(false, configuration.features.groups)
    }
}

/** The table lives beside the four kits, so find the repository root from the module's directory. */
private fun layoutTable(): Map<*, *> {
    var dir: File? = File(".").absoluteFile
    while (dir != null) {
        val candidate = File(dir, "spec/application-layout-vectors.json")
        if (candidate.isFile) return FlareJson.parse(candidate.readText()) as Map<*, *>
        dir = dir.parentFile
    }
    error("spec/application-layout-vectors.json not found above ${File(".").absolutePath}")
}
