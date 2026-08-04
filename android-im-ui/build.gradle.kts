import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library") version "8.7.3"
    id("org.jetbrains.kotlin.android") version "2.2.20"
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.20"
    `maven-publish`
}

// Maven coordinates — consumers reference `com.flare.im:im-ui-compose:0.1.0`.
group = "com.flare.im"
version = "1.0.6"

android {
    namespace = "com.flare.im.ui"
    compileSdk = 35

    defaultConfig {
        minSdk = 26
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }

    // publish the release variant as an AAR (+ sources)
    publishing {
        singleVariant("release") {
            withSourcesJar()
        }
    }
}

afterEvaluate {
    publishing {
        publications {
            create<MavenPublication>("release") {
                from(components["release"])
                groupId = "com.flare.im"
                artifactId = "im-ui-compose"
                version = "1.0.5"
            }
        }
        // `./gradlew publish` targets this; point it at your Maven repo:
        // repositories { maven { url = uri("...") ; credentials { ... } } }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2024.12.01")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    // Network image loading for URL-backed message bodies (Image/Video/Location/Contact/LinkCard).
    implementation("io.coil-kt:coil-compose:2.7.0")
    // Animated webp (emoji packs / stickers) via ImageDecoderDecoder (API 28+).
    implementation("io.coil-kt:coil-gif:2.7.0")

    testImplementation(kotlin("test"))
}
