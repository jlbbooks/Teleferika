allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

layout.buildDirectory.set(file("../build"))

subprojects {
    layout.buildDirectory.set(file("${rootProject.layout.buildDirectory.get()}/${project.name}"))

    // Plugins such as android_file_picker read extensions.getByName("flutter") during their
    // own evaluation. Flutter only creates that extension while configuring :app, so plugins
    // must wait for :app first (otherwise AGP 8 builds fail with "Extension 'flutter' does not exist").
    if (name != "app") {
        evaluationDependsOn(":app")
    }

    fun configureAndroidCompat() {
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

    // evaluationDependsOn(":app") can evaluate this project as a side effect before we register
    // afterEvaluate, so guard against "project is already evaluated".
    if (state.executed) {
        configureAndroidCompat()
    } else {
        afterEvaluate { configureAndroidCompat() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
