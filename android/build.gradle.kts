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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    // 1. The Isar Namespace + compileSdk Fix
    //
    // isar_flutter_libs' own AAR pulls in an AndroidX resource
    // (?android:attr/lStar, added in API 31) that its own plugin manifest
    // doesn't declare a high-enough compileSdk to resolve. A hardcoded
    // literal here (e.g. 35) can itself fail — resource linking for
    // isar_flutter_libs breaks with "resource android:attr/lStar not
    // found" whenever that literal names an SDK platform this machine's
    // Android SDK manager doesn't actually have installed. Deriving it
    // from flutter.compileSdkVersion instead pins it to whatever platform
    // the :app module itself already builds against successfully — same
    // platform, so if :app resolves, this does too, on any machine.
    if (name == "isar_flutter_libs") {
        pluginManager.withPlugin("com.android.library") {
            extensions.configure<com.android.build.api.dsl.LibraryExtension> {
                namespace = "dev.isar.isar_flutter_libs"
                compileSdk = project(":app").extensions
                    .getByType(com.android.build.api.dsl.ApplicationExtension::class.java)
                    .compileSdk
            }
        }
    }

    // 2. The JVM Mismatch Fix (Forces all plugins to use Java 17)
    pluginManager.withPlugin("com.android.library") {
        extensions.configure<com.android.build.api.dsl.LibraryExtension> {
            compileOptions {
                sourceCompatibility = org.gradle.api.JavaVersion.VERSION_17
                targetCompatibility = org.gradle.api.JavaVersion.VERSION_17
            }
        }
    }
}