import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

kotlin { compilerOptions { jvmTarget.set(JvmTarget.JVM_17) } }

android {
    namespace = "com.flare.consumer"
    compileSdk = 35
    defaultConfig { applicationId = "com.flare.consumer"; minSdk = 26; targetSdk = 35; versionCode = 1; versionName = "1" }
    compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
    buildFeatures { compose = true }
}

dependencies {
    implementation("com.flare.im:im-ui-compose:2.0.0-rc.1")
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation(platform("androidx.compose:compose-bom:2024.12.01"))
    implementation("androidx.compose.material3:material3")
}
