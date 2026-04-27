import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
val requestedTasks = gradle.startParameter.taskNames.map { it.lowercase() }
val isReleaseTaskRequested = requestedTasks.any { it.contains("release") }

if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val releaseStoreFilePath = keystoreProperties.getProperty("storeFile")
val releaseStoreFile = if (releaseStoreFilePath.isNullOrBlank()) {
    null
} else {
    rootProject.file(releaseStoreFilePath)
}

if (isReleaseTaskRequested && !hasReleaseKeystore) {
    throw GradleException(
        "Release signing is not configured. Copy android/key.properties.example to android/key.properties and point storeFile to your release keystore."
    )
}

if (isReleaseTaskRequested && (releaseStoreFile == null || !releaseStoreFile.exists())) {
    throw GradleException(
        "Release keystore was not found at '$releaseStoreFilePath'. Check storeFile in android/key.properties."
    )
}

android {
    namespace = "com.example.guesstogether"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.guesstogether"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = requireNotNull(releaseStoreFile) {
                    "storeFile is missing in android/key.properties"
                }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
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
