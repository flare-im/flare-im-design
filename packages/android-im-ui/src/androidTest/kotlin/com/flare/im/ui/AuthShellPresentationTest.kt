package com.flare.im.ui

import android.graphics.Bitmap
import java.io.File
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.test.platform.app.InstrumentationRegistry
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalTestApi::class)
class AuthShellPresentationTest {
    @get:Rule val compose = createComposeRule()

    @Test fun phoneKeepsTheBrandAndSingleTaskHeadingWithEditableAccount() {
        compose.setContent {
            MaterialTheme { Box(Modifier.requiredSize(320.dp, 500.dp)) { subject() } }
        }
        compose.onNodeWithText("Flare IM").assertIsDisplayed()
        compose.onNodeWithText("Welcome back").assertIsDisplayed()
        compose.onNodeWithText("Closer conversations").assertDoesNotExist()
        compose.onNode(hasSetTextAction()).performClick().performTextInput("aster")
        compose.onNode(hasSetTextAction()).assertIsFocused()
        compose.onNodeWithText("aster").assertIsDisplayed()
    }

    @Test fun shortPhoneAndLargeTypeAllowTheLastActionToScrollIntoView() {
        compose.setContent {
            val density = LocalDensity.current
            CompositionLocalProvider(LocalDensity provides Density(density.density, 1.6f)) {
                MaterialTheme { Box(Modifier.requiredSize(320.dp, 360.dp)) { subject(longForm = true) } }
            }
        }
        compose.onNodeWithText("Flare IM").assertIsDisplayed()
        compose.onNodeWithText("Closer conversations").assertDoesNotExist()
        compose.onNodeWithText("Create account").performScrollTo().assertIsDisplayed()
        compose.onNodeWithText("Your conversations stay together.").performScrollTo().assertIsDisplayed()
    }

    @Test fun wideLayoutShowsTheBrandStoryAndCapsTheFormWidth() {
        var formPixelsPerDp = 1f
        compose.setContent {
            val density = LocalDensity.current
            CompositionLocalProvider(LocalDensity provides Density(density.density / 3.5f, 1f)) {
                formPixelsPerDp = LocalDensity.current.density
                MaterialTheme { Box(Modifier.fillMaxSize()) { subject() } }
            }
        }
        compose.onNodeWithText("Closer conversations").assertIsDisplayed()
        val account = compose.onNode(hasSetTextAction()).fetchSemanticsNode().boundsInRoot
        assertTrue(account.width / formPixelsPerDp <= FlareSizes.authFormMaxWidth.value + 1f)
        val brand = compose.onNodeWithText("Flare IM").fetchSemanticsNode().boundsInRoot
        assertTrue(account.left > brand.right)
    }

    @Test fun phoneAccountCardIsVisibleInBothThemes() {
        val mode = mutableStateOf(FlareThemeMode.Light)
        compose.setContent { FlareThemeProvider(mode = mode.value) { subject(signIn = true) } }
        compose.onNodeWithText("Welcome back").assertIsDisplayed()
        capture("auth-phone-light.png")
        compose.runOnIdle { mode.value = FlareThemeMode.Dark }
        compose.onNodeWithText("Welcome back").assertIsDisplayed()
        capture("auth-phone-dark.png")
    }

    private fun capture(name: String) {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val file = File(context.getExternalFilesDir(null), name)
        file.outputStream().use { compose.onRoot().captureToImage().asAndroidBitmap().compress(Bitmap.CompressFormat.PNG, 100, it) }
        assertTrue(file.length() > 0)
    }

    @Test fun backActionReturnsOnceWithoutSubmittingOrErasingTheDraft() {
        var back = 0
        compose.setContent { MaterialTheme { subject(onBack = { back++ }) } }
        compose.onNode(hasSetTextAction()).performTextInput("aster")
        compose.onNodeWithText("Back to sign in").performClick()
        assertEquals(1, back)
        compose.onNodeWithText("aster").assertExists()
    }

    @Composable private fun subject(longForm: Boolean = false, signIn: Boolean = false, onBack: (() -> Unit)? = null) {
        var account by remember { mutableStateOf("") }
        FlareAuthShell(
            product = "Flare IM",
            tagline = "Stay connected",
            headline = "Closer conversations",
            description = "Connect with the people who matter.",
            eyebrow = "YOUR CONVERSATION SPACE",
            title = "Welcome back",
            subtitle = "Sign in to continue your conversations.",
            footer = "Your conversations stay together.",
            backLabel = if (onBack == null) null else "Back to sign in",
            onBack = onBack,
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg)) {
                FormField(label = "Account") { Input(value = account, onValueChange = { account = it }) }
                if (signIn) FormField(label = "Password") { Input(value = "", onValueChange = {}, secure = true, revealable = true) }
                if (longForm) repeat(4) { FormField(label = "Register field ${it + 1}") { Input(value = "", onValueChange = {}) } }
                Button(label = if (signIn) "Sign in" else "Create account", block = true, onClick = {})
            }
        }
    }
}
