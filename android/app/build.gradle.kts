plugins {
    id("com.android.application")
    id("kotlin-android")

    // ✅ Firebase services
    id("com.google.gms.google-services")

    // ✅ Flutter plugin must be last
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.cart"
    compileSdk = 34
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.cart"
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
    getByName("release") {
        isMinifyEnabled = false       // ✅ Already false
        isShrinkResources = false     // ✅ Add this line
        signingConfig = signingConfigs.getByName("debug")
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.15.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}
