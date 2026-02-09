allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

layout.buildDirectory.set(file("../build"))

subprojects {
    layout.buildDirectory.set(file("${rootProject.layout.buildDirectory.get()}/${project.name}"))

    afterEvaluate {
        try {
            if (project.hasProperty("android")) {
                val android = project.extensions.getByName("android") as? com.android.build.gradle.BaseExtension
                android?.apply {
                    // Use the compileSdk version from the app project if available, otherwise default to 36
                    val sdkVersion = try {
                        val appProject = rootProject.findProject(":app")
                        val appAndroid = appProject?.extensions?.findByName("android") as? com.android.build.gradle.BaseExtension
                        appAndroid?.compileSdkVersion ?: "android-36"
                    } catch (_: Exception) {
                        "android-36"
                    }
                    compileSdkVersion(sdkVersion)

                    buildFeatures.buildConfig = true

                    if (namespace == null) {
                        namespace = project.group.toString()
                    }
                }
            }
        } catch (_: Exception) {
            // Ignore when Gradle sync runs in a limited context (e.g. Cursor/VS Code without full Flutter setup)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
