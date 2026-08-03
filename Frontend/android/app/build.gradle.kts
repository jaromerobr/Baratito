import java.util.Properties
import java.io.FileInputStream

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}


plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase (Google Services) para FCM — procesa google-services.json
    id("com.google.gms.google-services")
}

android {
    namespace = "ec.edu.uide.baratito"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Requerido por flutter_local_notifications (APIs de java.time)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "ec.edu.uide.baratito"
        // FCM/flutter_local_notifications y el paquete `record` (audios del
        // chat) requieren minSdk 23+.
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release"){
            keyAlias = keyProperties.getProperty("keyAlias")
            keyPassword = keyProperties.getProperty("keyPassword")
            storeFile = keyProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keyProperties.getProperty("storePassword")
        }
    }

    buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")

        isMinifyEnabled = false
        isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
