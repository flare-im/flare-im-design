pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "flare-im-compose-example"
include(":app", ":flare-im-ui")
project(":flare-im-ui").projectDir = file("../../packages/android-im-ui")
