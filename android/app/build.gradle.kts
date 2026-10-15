import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Public Google/Facebook sign-in IDs, shared with the Dart code (assets/config/social.json).
@Suppress("UNCHECKED_CAST")
val socialConfig: Map<String, Any?> = run {
    val f = rootProject.file("../assets/config/social.json")
    if (f.exists()) groovy.json.JsonSlurper().parse(f) as Map<String, Any?> else emptyMap()
}
fun social(key: String): String = (socialConfig[key] as? String)?.trim() ?: ""

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.rrc.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.rrc.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "Reliiance"
        // Facebook SDK reads these; empty until a Meta app is set up (the app then hides nothing,
        // it just shows "not set up yet" when the Facebook button is tapped).
        resValue("string", "facebook_app_id", social("facebook_app_id"))
        resValue("string", "facebook_client_token", social("facebook_client_token"))
        resValue("string", "fb_login_protocol_scheme", "fb" + social("facebook_app_id"))
    }

    // Test builds (flutter build ... --android-project-arg=rrcTestBuild=true) install next to
    // the store app as "Reliiance TEST" instead of replacing it. Store builds are unaffected.
    if (project.hasProperty("rrcTestBuild")) {
        defaultConfig.applicationIdSuffix = ".test"
        defaultConfig.versionNameSuffix = "-test"
        defaultConfig.manifestPlaceholders["appLabel"] = "Reliiance TEST"
    }

    signingConfigs {
        // Fixed key for test builds only (package com.rrc.app.test), so Google and Facebook
        // can recognise them. Never used for the store app.
        create("test") {
            storeFile = file("test-signing.jks")
            storePassword = "rrctest123"
            keyAlias = "rrctest"
            keyPassword = "rrctest123"
        }
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = if (project.hasProperty("rrcTestBuild")) {
                signingConfigs.getByName("test")
            } else if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}


dependencies {
    // AppCompat themes (styles.xml) for the Face ID / fingerprint dialog on Android 8 and below
    implementation("androidx.appcompat:appcompat:1.7.0")
}
