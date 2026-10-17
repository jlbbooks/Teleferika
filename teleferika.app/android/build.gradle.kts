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
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                try {
                    val method = androidExt.javaClass.getMethod("setCompileSdk", Int::class.javaObjectType)
                    method.invoke(androidExt, 37)
                } catch (_: Exception) {
                    try {
                        val method = androidExt.javaClass.getMethod("compileSdkVersion", String::class.java)
                        method.invoke(androidExt, "android-37")
                    } catch (_: Exception) {}
                }

                try {
                    val getBuildFeatures = androidExt.javaClass.getMethod("getBuildFeatures")
                    val buildFeatures = getBuildFeatures.invoke(androidExt)
                    val setBuildConfig = buildFeatures.javaClass.getMethod("setBuildConfig", Boolean::class.javaObjectType)
                    setBuildConfig.invoke(buildFeatures, true)
                } catch (_: Exception) {}

                try {
                    val getNamespace = androidExt.javaClass.getMethod("getNamespace")
                    if (getNamespace.invoke(androidExt) == null) {
                        val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                        setNamespace.invoke(androidExt, project.group.toString())
                    }
                } catch (_: Exception) {}
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
