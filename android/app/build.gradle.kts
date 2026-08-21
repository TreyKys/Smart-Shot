import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
// TEMPORARY — diagnosing a build that keeps signing release with the debug
// key despite key.properties existing on disk. Remove once resolved.
println("DIAG rootProject.projectDir = ${rootProject.projectDir}")
println("DIAG keystorePropertiesFile.absolutePath = ${keystorePropertiesFile.absolutePath}")
println("DIAG hasReleaseKeystore = $hasReleaseKeystore")
if (hasReleaseKeystore) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
    println("DIAG keyAlias read = ${keystoreProperties["keyAlias"]}")
    println("DIAG storeFile read = ${keystoreProperties["storeFile"]}")
}

// Google's shared public test AdMob App ID — safe to use in every build
// that isn't the one actually shipped to Play.
val testAdmobAppId = "ca-app-pub-3940256099942544~3347511713"
val releaseAdmobAppId = (keystoreProperties["admobAppId"] as String?)
    ?: System.getenv("ADMOB_APP_ID")
if (releaseAdmobAppId.isNullOrBlank()) {
    logger.warn(
        "WARNING: no real AdMob App ID configured (set 'admobAppId' in " +
            "android/key.properties or the ADMOB_APP_ID env var). Release " +
            "build will use Google's TEST AdMob App ID — do not upload " +
            "this build to Play Console."
    )
}

android {
    namespace = "com.neurodevlabs.sift"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.neurodevlabs.sift"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        manifestPlaceholders["admobAppId"] = testAdmobAppId
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Uses the real upload keystore (android/key.properties) when present.
            // Falls back to the debug key so `flutter run --release` still works
            // without a keystore on hand (e.g. CI, fresh clones).
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            println("DIAG at assignment, release buildType signingConfig = ${signingConfig?.name}")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            manifestPlaceholders["admobAppId"] = releaseAdmobAppId ?: testAdmobAppId
        }
    }
}

flutter {
    source = "../.."
}

// TEMPORARY — runs after every plugin (including the Flutter Gradle plugin)
// has finished configuring the project, so it catches a late override even
// if nothing in this file is the culprit. Remove alongside the other DIAG
// lines once this is resolved.
afterEvaluate {
    val releaseBt = android.buildTypes.getByName("release")
    println("DIAG afterEvaluate, release buildType signingConfig = ${releaseBt.signingConfig?.name}")
    println("DIAG afterEvaluate, storeFile = ${releaseBt.signingConfig?.storeFile}")
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
