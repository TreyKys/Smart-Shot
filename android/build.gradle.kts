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
    // (?android:attr/lStar, added in API 31) that needs compileSdk >= 31 to
    // resolve. isar_flutter_libs' own build.gradle sets its own (lower)
    // compileSdkVersion as literally the next line after `apply plugin:
    // "com.android.library"` runs — and `pluginManager.withPlugin(...)`
    // fires its callback AT THE MOMENT that plugin is applied, i.e. before
    // isar_flutter_libs' own build.gradle has executed its own `android {
    // compileSdkVersion ... }` block. So a compileSdk assignment inside
    // withPlugin() here runs FIRST and then gets silently clobbered by
    // isar's own lower value running SECOND — which is exactly why bumping
    // the literal previously had zero effect: neither value was ever the
    // one actually in force. afterEvaluate runs once isar_flutter_libs'
    // entire build.gradle — plugin application AND its own android {}
    // block — has already executed, so this override applies last and
    // actually sticks.
    if (name == "isar_flutter_libs") {
        afterEvaluate {
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