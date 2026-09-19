pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        // First so an already-installed artifact is served locally — Maven Central
        // truncates the 57MB kotlin-compiler-embeddable jar on some networks.
        mavenLocal()
        google()
        mavenCentral()
    }
}

rootProject.name = "flare-im-ui-compose"
