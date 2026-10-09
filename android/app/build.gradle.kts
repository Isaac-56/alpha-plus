import java.util.Properties as AlphaPlusMapsBuildProperties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val alphaPlusSigningProperties = AlphaPlusMapsBuildProperties()
val alphaPlusSigningFile = rootProject.file("key.properties")
if (alphaPlusSigningFile.exists()) {
    alphaPlusSigningFile.inputStream().use { alphaPlusSigningProperties.load(it) }
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

    signingConfigs {
        if (alphaPlusSigningFile.exists()) {
            create("release") {
                keyAlias = alphaPlusSigningProperties.getProperty("keyAlias")
                keyPassword = alphaPlusSigningProperties.getProperty("keyPassword")
                storeFile = file(alphaPlusSigningProperties.getProperty("storeFile"))
                storePassword = alphaPlusSigningProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Use the same release certificate on every build machine/device.
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
        if (gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) } &&
            !alphaPlusSigningFile.exists() && alphaPlusMapsKey != "CI_PLACEHOLDER") {
            throw GradleException("Production release requires android/key.properties and the existing release keystore. Register its SHA-1 for com.alpharide.driver on the Maps key.")
        }
        manifestPlaceholders["MAPS_API_KEY"] = alphaPlusMapsKey
    }
}
// END ALPHA PLUS MAPS KEY WIRING v1
