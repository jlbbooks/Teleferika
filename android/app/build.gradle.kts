import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Function to load keystore properties
fun loadKeystoreProperties(): Properties {
    val properties = Properties()
    val keystorePropertiesFile =
        rootProject.file("../keys/keystore.properties") // Path relative to android directory
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { fis ->
            properties.load(fis)
        }
    }
    return properties
}

val keystoreProperties = loadKeystoreProperties()

//kotlin {
//    compilerOptions {
//        jvmTarget = JvmTarget.fromTarget("17")
//    }
//}

android {
    namespace = "com.jlbbooks.teleferika"
    compileSdk = flutter.compileSdkVersion
    // https://developer.android.com/ndk/downloads/
    ndkVersion = "27.2.12479018" //flutter.ndkVersion

    signingConfigs {
        create("release") { // This will be used for your release build if you don't override it
            if (keystoreProperties.isNotEmpty()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile =
                    file(keystoreProperties.getProperty("storeFile")) // Ensure 'file()' is used for path
                storePassword = keystoreProperties.getProperty("storePassword")
            } else {
                // Fallback or error if properties are not found,
                // or use the default debug signing config.
                // For Flutter, the default signingConfig in buildTypes.release
                // often points to 'debug' initially.
                println("Warning: Keystore properties not found. Using default signing.")
            }
        }
        // You can define other signing configs here if needed, e.g., for different product flavors.
        // create("uploadKeyConfig") { // If you specifically want to name it 'upload'
        //     if (keystoreProperties.isNotEmpty() && keystoreProperties.getProperty("keyAlias") == "upload") {
        //         keyAlias = keystoreProperties.getProperty("keyAlias")
        //         keyPassword = keystoreProperties.getProperty("keyPassword")
        //         storeFile = file(keystoreProperties.getProperty("storeFile"))
        //         storePassword = keystoreProperties.getProperty("storePassword")
        //     }
        // }
    }



    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.jlbbooks.teleferika"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            // Other release build type configurations like ProGuard, R8, etc.
            // e.g., isMinifyEnabled = true
            isMinifyEnabled = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        // You might have a debug build type as well, typically it doesn't need explicit signing here
        // as it uses the debug keystore by default.
        getByName("debug") {
            // ...
        }
    }

    // Define product flavors
    flavorDimensions += "version"
    productFlavors {
        create("opensource") {
            dimension = "version"
            applicationIdSuffix = ".open"
            versionNameSuffix = "-opensource"
            // You can also add resValue or buildConfigField for flavor-specific settings
            resValue("string", "app_name", "TeleferiKa Open")
        }
        create("full") {
            dimension = "version"
            // No suffix for production, or define as needed
            applicationIdSuffix = ""
            versionNameSuffix = "-full"
            // You can also add resValue or buildConfigField for flavor-specific settings
            resValue("string", "app_name", "TeleferiKa")
        }
    }
}

flutter {
    source = "../.."
}
