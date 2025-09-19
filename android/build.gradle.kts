allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Workaround for third-party Android library modules that don't declare a namespace (AGP 8+ requirement)
subprojects {
    plugins.withId("com.android.library") {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                val getNs = androidExt.javaClass.methods.firstOrNull { it.name == "getNamespace" }
                val currentNs = getNs?.invoke(androidExt) as? String
                if (currentNs.isNullOrEmpty()) {
                    val setNs = androidExt.javaClass.methods.firstOrNull {
                        it.name == "setNamespace" && it.parameterTypes.size == 1 && it.parameterTypes[0] == String::class.java
                    }
                    val fallback = "com.example." + project.name.replace('-', '_')
                    setNs?.invoke(androidExt, fallback)
                    println("Applied fallback namespace '$fallback' to module '${project.path}'")
                }
            } catch (_: Throwable) {
                // Ignore reflection issues; this is a best-effort fallback.
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
