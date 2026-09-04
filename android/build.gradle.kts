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

    // 2. The JVM Mismatch Fix — make each plugin's Kotlin task follow its
    // OWN Java task, instead of forcing every plugin to one fixed version.
    //
    // Earlier attempts here tried to force every plugin's *Java* compile
    // task to 17 (to give fix #3 below, which pins Kotlin to 17, something
    // consistent to match) — via pluginManager.withPlugin, then afterEvaluate,
    // then configuring the JavaCompile tasks directly, then an eager
    // gradle.projectsEvaluated backstop. Every one of those either lost a
    // silent last-write race against AGP's own configuration (so the plugin
    // shipped targeting 1.8 regardless — this is what actually broke
    // add_2_calendar), hit "sourceCompatibility has been finalized" because
    // AGP locks that Property partway through evaluation, or — worse, for
    // the eager backstop — broke flutter_local_notifications' compile
    // classpath entirely (100 "package android.* does not exist" errors)
    // by writing to JavaCompile's fields through a path that skips whatever
    // else AGP's own configuration wires up alongside them.
    //
    // None of that is actually necessary: the only real requirement is that
    // a module's Java and Kotlin compile tasks agree with EACH OTHER, not
    // that every module in the whole build target the same JVM version.
    // Reading each module's Java target back out (safe — a read, not a
    // write, so it isn't affected by the finalization AGP applies to writes)
    // after that module has fully configured itself, and pointing that
    // SAME module's Kotlin task at it, guarantees the two agree without
    // needing to fight AGP for control of the Java side at all — whether a
    // plugin ends up at AGP's own default, or an explicit value it set
    // itself (1.8 for add_2_calendar), Kotlin now simply follows suit.
    //
    // The first cut of this registered afterEvaluate directly from here —
    // which runs too EARLY: this subprojects{} block's own content is
    // injected before the module's own build.gradle (and therefore before
    // com.android.library) even applies, so multiple afterEvaluate callbacks
    // fire in registration order and ours went first, before AGP's own
    // internal task-creation afterEvaluate (AGP commonly defers creating the
    // JavaCompile task itself to its own afterEvaluate) had created the task
    // at all — so the read silently found nothing for receive_sharing_intent
    // and skipped it, leaving its Kotlin task at Gradle's own JDK (21).
    // Registering from inside withPlugin("org.jetbrains.kotlin.android")
    // instead means our registration call itself only happens once that
    // module's script reaches its kotlin-android plugin id — which, by the
    // near-universal Flutter-plugin-template convention of listing
    // com.android.library before kotlin-android in the same plugins{} block,
    // is after AGP's own plugin (and whatever afterEvaluate it registered)
    // is already in the queue — so ours lands later in the same project's
    // afterEvaluate queue and runs after AGP's task-creation has completed.
    pluginManager.withPlugin("org.jetbrains.kotlin.android") {
        val matchKotlinToJava: Project.() -> Unit = {
            val javaTarget = tasks.withType<JavaCompile>()
                .firstOrNull()
                ?.targetCompatibility
            if (javaTarget != null) {
                tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                    compilerOptions.jvmTarget.set(
                        org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget(javaTarget)
                    )
                }
            }
        }
        // :app itself is already fully evaluated by the time this runs,
        // because the evaluationDependsOn(":app") above forces it to finish
        // first — calling afterEvaluate on an already-evaluated project
        // throws, so run directly for it and defer everyone else normally.
        if (state.executed) matchKotlinToJava() else afterEvaluate(matchKotlinToJava)
    }
}
