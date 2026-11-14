group = "com.flare.im.ui.bundlehost"
version = "0.1.0"

buildscript {
    val kotlinVersion = "2.2.20"

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.11.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // The kit (com.flare.im:im-ui-compose): mavenLocal on the dev branch (`./gradlew publishToMavenLocal` in
        // flare-im-design/packages/android-im-ui), GitHub Packages for the released build. The app resolves its
        // runtime classpath from its own repositories, so it lists the same two.
        // Only the kit's group is looked up in these two, so nothing else waits on them or fails on their answers.
        mavenLocal {
            content { includeGroup("com.flare.im") }
        }
        maven {
            name = "GitHubPackages"
            url = uri("https://maven.pkg.github.com/flare-im/flare-im-design")
            content { includeGroup("com.flare.im") }
            credentials {
                username = (providers.gradleProperty("gpr.user")
                    .orElse(providers.environmentVariable("GITHUB_ACTOR"))).orNull ?: ""
                password = (providers.gradleProperty("gpr.token")
                    .orElse(providers.environmentVariable("GITHUB_TOKEN"))).orNull ?: ""
            }
        }
    }
}

plugins {
    id("com.android.library")
}

val agpMajor = com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION.substringBefore('.').toInt()

// AGP 9 compiles Kotlin itself unless the app opts out with android.builtInKotlin=false.
val builtInKotlinEnabled =
    agpMajor >= 9 &&
        (providers.gradleProperty("android.builtInKotlin").orNull?.toBoolean() ?: true)

if (!builtInKotlinEnabled) {
    apply(plugin = "org.jetbrains.kotlin.android")
}

project.extensions.configure(org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension::class.java) {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

android {
    namespace = "com.flare.im.ui.bundlehost"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        // The kit declares 26; the host runs it only from there (BUNDLE_MIN_SDK) and reports no runtime below.
        minSdk = 24
    }

    testOptions {
        // org.json and Handler come from android.jar; the JVM tests touch only the pure mappings.
        unitTests.isReturnDefaultValues = true
    }

    lint {
        disable.add("InvalidPackage")
    }
}

dependencies {
    // The native host (FlarePluginBundleView, FlarePluginBundleChannel, FlarePluginBundleEvents, FlarePluginBundleRuntime).
    implementation("com.flare.im:im-ui-compose:2.0.0-rc.1")
    testImplementation("junit:junit:4.13.2")
}
