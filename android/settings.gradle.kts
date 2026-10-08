pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    // START: FlutterFire Configuration
    // Version relevée à 4.4.4 (depuis 4.3.15) : le plugin Gradle Crashlytics
    // 3.x ci-dessous exige google-services >= 4.4.1 (voir
    // https://firebase.google.com/docs/crashlytics/upgrade-to-crashlytics-gradle-plugin-v3),
    // vérifié par un `flutter build apk` complet qui échouait sinon à la
    // tâche `uploadCrashlyticsMappingFile*`.
    id("com.google.gms.google-services") version("4.4.4") apply false
    // END: FlutterFire Configuration
    // Remontée de plantage (dette D13, `docs/dette-technique.md`) — plugin
    // Gradle Crashlytics (upload des fichiers de mapping ProGuard/R8 et des
    // symboles natifs, association de l'ID de build) : pas ajouté
    // automatiquement par `flutterfire configure` comme le bloc "FlutterFire
    // Configuration" ci-dessus, contrairement à google-services — étape
    // manuelle documentée par Firebase, ajoutée ici une fois pour toutes.
    id("com.google.firebase.crashlytics") version "3.0.8" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
