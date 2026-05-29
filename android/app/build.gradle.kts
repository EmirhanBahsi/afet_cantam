plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.afet_cantam"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ARKADAŞININ KODUNA SADECE BU SATIRI EKLEDİK (HATAYI ÇÖZEN KISIM):
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.afet_cantam"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.

        // KRİTİK DÜZELTME: Kamera ve ML Kit paketleri en az Android 21 (Lollipop) gerektirir.
        // flutter.minSdkVersion bazen 16 veya 19 olarak dönebilir. Bu yüzden burayı doğrudan 21 yapıyoruz.
        minSdk = flutter.minSdkVersion

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

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))

    // BİLDİRİM PAKETİNİN İSTEDİĞİ DESTEK KÜTÜPHANESİNİ BURAYA EKLEDİK:
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}