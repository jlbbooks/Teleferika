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

    // Define product flavors if you use them. Example:
//    flavorDimensions += "environment" // Or any dimension you use
//    productFlavors {
//        create("development") {
//            dimension = "environment"
//            applicationIdSuffix = ".dev"
//            versionNameSuffix = "-dev"
//            // You can also add resValue or buildConfigField for flavor-specific settings
//        }
//        create("production") {
//            dimension = "environment"
//            // No suffix for production, or define as needed
//        }
//    }

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
        release {
            signingConfig = signingConfigs.getByName("release")
            // Other release build type configurations like ProGuard, R8, etc.
            // e.g., isMinifyEnabled = true
            isMinifyEnabled = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        // You might have a debug build type as well, typically it doesn't need explicit signing here
        // as it uses the debug keystore by default.
        debug {
            // ...
        }
    }

    // THIS IS THE KEY PART FOR CUSTOMIZING APK FILENAME
    applicationVariants.all {
        val variant = this // 'this' is the variant
        variant.outputs.all {
            val output = this // 'this' is the output (e.g., APK)
            // Ensure we are dealing with an APK output
            if (output is com.android.build.gradle.internal.api.ApkVariantOutputImpl) {
                // Get the base name from the applicationId
                // The variant.applicationId will include any applicationIdSuffix from flavors
                val baseApplicationId = defaultConfig.applicationId
                val appNameFromId =
                    baseApplicationId?.substringAfterLast('.', baseApplicationId) ?: "app"

                val flavorName = variant.flavorName.takeIf { it.isNotEmpty() } ?: ""
                val buildTypeName = variant.buildType.name
                val versionName = variant.versionName
                val versionCode = variant.versionCode

                // Construct the desired file name
                // Example: app-production-release-1.0.0-1.apk
                // Example: app-development-debug-1.0.1-dev-2.apk
                var newApkName = appNameFromId
                if (flavorName.isNotEmpty()) {
                    newApkName += "-$flavorName"
                }
                newApkName += "-$buildTypeName"
                newApkName += "-v$versionName"
                newApkName += "-vc$versionCode.apk"

                output.outputFileName = newApkName
            }
        }
    }
}

flutter {
    source = "../.."
}
