plugins {
  id("com.android.application")
  id("org.jetbrains.kotlin.android")
}

android {
  namespace = "io.soletalk.mobile"
  compileSdk = 35
  val productionBaseUrl = "https://soletalk-rails-production.up.railway.app/"
  val debugBaseUrl = (project.findProperty("SOLETALK_DEBUG_BASE_URL") as String?) ?: "http://127.0.0.1:3000/"

  defaultConfig {
    applicationId = "io.soletalk.mobile"
    minSdk = 26
    targetSdk = 35
    versionCode = 1
    versionName = "0.1.0"
  }

  buildTypes {
    debug {
      buildConfigField("String", "WEB_BASE_URL", "\"${normalizeBaseUrl(debugBaseUrl)}\"")
    }

    release {
      buildConfigField("String", "WEB_BASE_URL", "\"${normalizeBaseUrl(productionBaseUrl)}\"")
      isMinifyEnabled = false
      proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro"
      )
    }
  }

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }

  kotlinOptions {
    jvmTarget = "17"
  }

  buildFeatures {
    buildConfig = true
    viewBinding = true
  }
}

dependencies {
  implementation("androidx.core:core-ktx:1.13.1")
  implementation("androidx.appcompat:appcompat:1.7.0")
  implementation("androidx.constraintlayout:constraintlayout:2.2.0")
  implementation("androidx.browser:browser:1.8.0")
  implementation("androidx.webkit:webkit:1.11.0")
  implementation("com.google.android.material:material:1.12.0")
  implementation("com.squareup.okhttp3:okhttp:4.12.0")
}

fun normalizeBaseUrl(baseUrl: String): String {
  return if (baseUrl.endsWith("/")) baseUrl else "$baseUrl/"
}
