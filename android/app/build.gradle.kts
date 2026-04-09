plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Namespace compartilhado — identifica o R class e código Kotlin.
    // Não varia por flavor. applicationId varia (definido nos flavors abaixo).
    namespace = "com.appfieldops.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // applicationId é sobrescrito pelos flavors abaixo.
        // Mantido aqui como fallback para runs sem flavor especificado.
        applicationId = "com.appfieldops.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Multi-brand: um flavor por marca.
    // Cada flavor gera um APK/AAB independente com seu próprio applicationId,
    // app_name e assets de launcher. Esses valores são build-time e NÃO podem
    // ser alterados por configuração remota em runtime.
    flavorDimensions += "brand"

    productFlavors {
        create("kaptur") {
            dimension = "brand"
            applicationId = "com.kaptur.field"
            // app_name fornecido aqui — AndroidManifest usa @string/app_name
            resValue("string", "app_name", "Kaptur")
        }

        create("compass") {
            dimension = "brand"
            applicationId = "com.compass.avaliacoes"
            resValue("string", "app_name", "Compass Avaliações")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
