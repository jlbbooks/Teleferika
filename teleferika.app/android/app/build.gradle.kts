import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
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

// Load local.properties for Flutter version (written by Flutter tooling)
val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) FileInputStream(file).use { load(it) }
}
val flutterVersionCode = localProperties.getProperty("flutter.versionCode", "1")
val flutterVersionName = localProperties.getProperty("flutter.versionName", "1.0.0")

// Configure Kotlin compiler options at the top level
kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_21)
    }
}

android {
    namespace = "com.jlbbooks.teleferika"
    compileSdkVersion(flutter.compileSdkVersion)
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        create("release") { // This will be used for your release build if you don't override it
            if (keystoreProperties.isNotEmpty()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                // Resolve keystore path relative to root project (android/ directory)
                val keystorePath = keystoreProperties.getProperty("storeFile")
                storeFile = rootProject.file(keystorePath)
                storePassword = keystoreProperties.getProperty("storePassword")
            } else {
                // Fallback or error if properties are not found,
                // or use the default debug signing config.
                // For Flutter, the default signingConfig in buildTypes.release
                // often points to 'debug' initially.
                println("Warning: Keystore properties not found. Using default signing. Remember to import the keys folder to the project")
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
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
        isCoreLibraryDesugaringEnabled = true
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.jlbbooks.teleferika"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
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


dependencies {
    "coreLibraryDesugaring"("com.android.tools:desugar_jdk_libs:2.1.5")
}

