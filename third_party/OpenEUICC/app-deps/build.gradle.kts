import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "im.angry.openeuicc_deps"
    compileSdk = 35

    defaultConfig {
        minSdk = 28
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("consumer-rules.pro")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_11
    }
}

dependencies {
    api("androidx.core:core-ktx:1.15.0")
    api("androidx.appcompat:appcompat:1.7.0")
    api("com.google.android.material:material:1.12.0")
    api("androidx.constraintlayout:constraintlayout:2.2.0")
    api("androidx.preference:preference:1.2.1")
    api("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    api("androidx.lifecycle:lifecycle-service:2.8.7")
    api("androidx.swiperefreshlayout:swiperefreshlayout:1.1.0")
    api("androidx.cardview:cardview:1.0.0")
    api("androidx.viewpager2:viewpager2:1.1.0")
    api("androidx.datastore:datastore-preferences:1.1.1")
    api("com.journeyapps:zxing-android-embedded:4.3.0")
    api("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
}
