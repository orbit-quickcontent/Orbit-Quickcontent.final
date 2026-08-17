plugins {
    id("com.google.gms.google-services") version "4.5.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val extension = project.extensions.findByName("android")
            if (extension != null) {
                try {
                    val getNamespace = extension.javaClass.getMethod("getNamespace")
                    val currentNamespace = getNamespace.invoke(extension)
                    if (currentNamespace == null || currentNamespace.toString().isEmpty()) {
                        val setNamespace = extension.javaClass.getMethod("setNamespace", String::class.java)
                        val pkgName = project.group.toString().takeIf { it.isNotBlank() } ?: "com.orbit.${project.name.replace('-', '_')}"
                        setNamespace.invoke(extension, pkgName)
                    }
                } catch (_: Exception) {
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
