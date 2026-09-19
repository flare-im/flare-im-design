package com.flare.consumer

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import com.flare.im.ui.Button
import com.flare.im.ui.FlareThemeProvider

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { FlareThemeProvider { Button(label = "Consumer ready", onClick = {}) } }
    }
}
