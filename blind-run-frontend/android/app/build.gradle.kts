import java.nio.charset.StandardCharsets
import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun decodeFlutterDartDefines(encodedDefines: String?): Map<String, String> {
    if (encodedDefines.isNullOrBlank()) {
        return emptyMap()
    }

    return encodedDefines
        .split(',')
        .mapNotNull { encoded ->
            runCatching {
                String(Base64.getDecoder().decode(encoded), StandardCharsets.UTF_8)
            }.getOrNull()
        }
        .mapNotNull { decoded ->
            val separatorIndex = decoded.indexOf('=')
            if (separatorIndex <= 0) {
                return@mapNotNull null
            }
            decoded.substring(0, separatorIndex) to decoded.substring(separatorIndex + 1)
        }
        .toMap()
}

// Flutter forwards --dart-define values to Gradle as a base64-encoded property.
val flutterDartDefines = decodeFlutterDartDefines(project.findProperty("dart-defines") as? String)
fun resolveAmapValue(name: String): String =
    flutterDartDefines[name]?.takeIf { it.isNotBlank() } ?: System.getenv(name).orEmpty()

val amapAndroidKey = resolveAmapValue("AMAP_ANDROID_KEY")
val amapIosKey = resolveAmapValue("AMAP_IOS_KEY")
val amapWebKey = resolveAmapValue("AMAP_WEB_KEY")

android {
    namespace = "com.aidrun.aidrun_demo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.aidrun.aidrun_demo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["AMAP_ANDROID_KEY"] = amapAndroidKey
        buildConfigField("String", "AMAP_ANDROID_KEY", "\"$amapAndroidKey\"")
        buildConfigField("String", "AMAP_IOS_KEY", "\"$amapIosKey\"")
        buildConfigField("String", "AMAP_WEB_KEY", "\"$amapWebKey\"")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.amap.api:3dmap:8.1.0")
    implementation("com.amap.api:location:5.6.0")
}
