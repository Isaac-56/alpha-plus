import java.util.Properties as AlphaPlusMapsBuildProperties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.alpharide.driver"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.alpharide.driver"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // ML Kit face detection requires Android API 21 or newer.
        minSdk = maxOf(24, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// BEGIN ALPHA PLUS MAPS KEY WIRING v1
// Keep the restricted Maps key in android/secrets.properties, outside Git.
android {
    defaultConfig {
        val alphaPlusMapsProperties = AlphaPlusMapsBuildProperties()
        val alphaPlusMapsSecretsFile = rootProject.file("secrets.properties")
        if (alphaPlusMapsSecretsFile.exists()) {
            alphaPlusMapsSecretsFile.inputStream().use {
                alphaPlusMapsProperties.load(it)
            }
        }

        val alphaPlusMapsKey = alphaPlusMapsProperties.getProperty("MAPS_API_KEY")
            ?.trim()?.takeIf { it.isNotEmpty() }
            ?: providers.environmentVariable("MAPS_API_KEY").orNull
                ?.trim()?.takeIf { it.isNotEmpty() }

        if (alphaPlusMapsKey == null) {
            throw GradleException(
                "MAPS_API_KEY is missing. Add it to android/secrets.properties " +
                    "or set the MAPS_API_KEY environment variable before building.",
            )
        }
        manifestPlaceholders["MAPS_API_KEY"] = alphaPlusMapsKey
    }
}
// END ALPHA PLUS MAPS KEY WIRING v1
