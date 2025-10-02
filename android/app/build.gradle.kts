plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // mejor que 'kotlin-android'
    // El plugin de Flutter SIEMPRE después de Android y Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.miguecoordenadas"

    // Puedes usar los valores de Flutter o fijar números explícitos:
    compileSdk = flutter.compileSdkVersion.toInt() // o = 34

    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.miguecoordenadas"

        // Kotlin DSL: usa 'minSdk', no 'minSdkVersion'
        minSdk = flutter.minSdkVersion.toInt() // o = 21
        targetSdk = flutter.targetSdkVersion.toInt() // o = 34

        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
        // multiDexEnabled = true // si lo necesitas
    }

    buildTypes {
        release {
            // De momento firma con la debug (cámbialo al firmar release real)
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // ✅ Java 17 + desugaring activado
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true   // <<--- IMPORTANTE
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

// ✅ Añade la lib de desugaring
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // Si te pide una versión más nueva, puedes probar 2.0.4 -> 2.0.5 o 2.1.x
}
