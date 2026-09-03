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
    //
    // Started as the same withPlugin-vs-afterEvaluate timing trap as fix #1
    // above (add_2_calendar defaults to Java 1.8, and setting
    // LibraryExtension.compileOptions from withPlugin ran too early, getting
    // clobbered by the plugin's own lower value running second). Moving that
    // override into afterEvaluate — the fix #1 pattern — traded that bug for
    // a different one: AGP finalizes compileOptions.sourceCompatibility /
    // targetCompatibility (locks the Property so nothing can set it again)
    // partway through evaluation, and by afterEvaluate that lock is often
    // already in place, so the assignment throws "sourceCompatibility has
    // been finalized" instead of silently doing nothing.
    //
    // Configuring the JavaCompile tasks directly — the same approach fix #3
    // below already uses for Kotlin — sidesteps both problems at once: task
    // properties aren't finalized the way the compileOptions DSL is, and
    // tasks.withType(...).configureEach runs lazily against every matching
    // task as it's created, so ordering relative to any particular plugin's
    // own build.gradle stops mattering.
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = org.gradle.api.JavaVersion.VERSION_17.toString()
        targetCompatibility = org.gradle.api.JavaVersion.VERSION_17.toString()
    }

    // 3. The other half of the JVM Mismatch Fix — Kotlin's side.
    //
    // Fix #2 above pins every plugin's *Java* compile task to 17. Kotlin
    // Gradle Plugin 2.2+ no longer inherits that: with no jvmTarget set
    // explicitly, it defaults a plugin's *Kotlin* compile task to whatever
    // JDK is running Gradle itself (21 here), which is exactly what fix #2
    // was written to prevent — just for the other compiler. Any plugin that
    // has Kotlin sources but doesn't set kotlinOptions.jvmTarget itself
    // (receive_sharing_intent, at minimum) ends up with
    // compileReleaseJavaWithJavac targeting 17 and compileReleaseKotlin
    // targeting 21 in the same module, which Gradle refuses to build.
    // Pinning every Kotlin compile task's jvmTarget to 17 here, the same way
    // fix #2 already pins the Java side, keeps both compilers in a module
    // agreeing no matter what JDK happens to be running Gradle.
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions.jvmTarget.set(
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        )
    }
}