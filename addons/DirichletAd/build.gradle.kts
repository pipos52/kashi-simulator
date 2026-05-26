plugins {
    id("com.android.library") version "8.2.2"
    id("org.jetbrains.kotlin.android") version "1.9.22"
}

val pluginName = "DirichletAd"
val pluginPackageName = "com.kashi.dirichlet"

android {
    namespace = pluginPackageName
    compileSdk = 34

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        minSdk = 24
        manifestPlaceholders["godotPluginName"] = pluginName
        manifestPlaceholders["godotPluginPackageName"] = pluginPackageName
        buildConfigField("String", "GODOT_PLUGIN_NAME", "\"${pluginName}\"")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

dependencies {
    // Godot Android library from Maven Central
    compileOnly("org.godotengine:godot:4.6.2.stable")

    // Dirichlet SDK classes.jar (extracted from AAR — bundled directly for runtime availability)
    implementation(files("src/main/libs/classes.jar"))

    // Transitive dependencies from Dirichlet AAR (must be bundled for runtime)
    implementation("com.squareup.okhttp3:okhttp:3.12.1")
    implementation("com.github.bumptech.glide:glide:4.9.0")
    implementation("com.android.support:support-v4:28.0.0")
    implementation("com.android.support:appcompat-v7:28.0.0")
    implementation("com.android.support:recyclerview-v7:28.0.0")
}