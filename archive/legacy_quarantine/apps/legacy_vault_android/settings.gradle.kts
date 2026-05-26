pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

rootProject.name = "LegacyVault"

include(":app")

enableFeaturePreview("TYPESAFE_PROJECT_ACCESSORS")
