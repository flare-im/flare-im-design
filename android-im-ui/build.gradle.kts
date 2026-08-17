import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library") version "8.7.3"
    id("org.jetbrains.kotlin.android") version "2.2.20"
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.20"
    `maven-publish`
}

// Maven coordinates — consumers reference `com.flare.im:im-ui-compose:<version>` below.
group = "com.flare.im"
version = "1.0.9"

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
                // 跟随上面的 project version，不要在这里再写死一遍。
                // 两处硬编码曾经漂移成 1.0.6 / 1.0.5：发布出去的永远是旧号，
                // 而消费方按新号解析，直接 "Could not find im-ui-compose:1.0.6"，
                // 且这个错只有真去构建消费方 app 才会暴露。
                version = project.version.toString()
            }
        }
        repositories {
            // dev 分支：`./gradlew publishToMavenLocal`，产物进 ~/.m2，
            // 消费方立刻命中（无需任何凭据）。mavenLocal 是 Gradle 内置目标，
            // 不需要在这里声明。

            // main 分支：`./gradlew publish`，产物进 GitHub Packages。
            //
            // 为什么是 GitHub Packages 而不是 Maven Central：
            // Central 要 Sonatype 账号 + GPG 签名 + `com.flare.im` 的域名所有权证明，
            // 且发布不可撤回。kit 现阶段一天可能动几次版本号，那套流程是纯阻力。
            // 等有了外部集成者、版本稳定下来再上 Central——届时本块换个 url 即可。
            //
            // 为什么不是 GitHub Release 附件 AAR：**裸 AAR 没有 POM**，
            // 传递依赖不会自动带过来。这个坑已经吃过一次——手动引入时必须抄
            // 8 个依赖，漏一个就运行时崩，而编译期完全看不出来。
            //
            // 凭据来自环境变量，仓库里不留 token。缺失时**跳过**该仓库而不是报错：
            // 本地开发只用 mavenLocal，不该被逼着配 GitHub token。
            val githubUser = providers.gradleProperty("gpr.user")
                .orElse(providers.environmentVariable("GITHUB_ACTOR"))
            val githubToken = providers.gradleProperty("gpr.token")
                .orElse(providers.environmentVariable("GITHUB_TOKEN"))

            if (githubUser.isPresent && githubToken.isPresent) {
                maven {
                    name = "GitHubPackages"
                    url = uri("https://maven.pkg.github.com/flare-im/flare-im-design")
                    credentials {
                        username = githubUser.get()
                        password = githubToken.get()
                    }
                }
            } else {
                logger.lifecycle(
                    "跳过 GitHubPackages 发布目标：未提供凭据。" +
                        "只发本地用 publishToMavenLocal；要发远端请设 GITHUB_ACTOR / GITHUB_TOKEN。"
                )
            }
        }
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
