plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "org.openhearth.reckon"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Core library desugaring is required by flutter_local_notifications so
        // its Java 8+ time APIs work on minSdk 24 devices.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "org.openhearth.reckon"
        // Reckon requires minSdk 24 for flutter_gemma / MediaPipe GenAI.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    packaging {
        jniLibs {
            // flutter_gemma 0.13.2 bundles MediaPipe/LiteRT-LM native
            // families Reckon never calls — we do TEXT INFERENCE only.
            // Verified against the plugin's Kotlin source (pub cache,
            // android/src/main/kotlin/): the inference path imports only
            // com.google.mediapipe.tasks.genai.llminference.* (loads
            // libllm_inference_engine_jni.so) and com.google.ai.edge.
            // litertlm.* (loads liblitertlm_jni.so); framework.image is
            // Java-only. Everything excluded below is loaded by classes no
            // Reckon code path can reach. KEEP: libllm_inference_engine_jni,
            // liblitertlm_jni, libflutter, libapp, libsqlite3 (drift's
            // SQLite — NOT the RAG vector store), libdartjni,
            // libdatastore_shared_counter. Reversible: delete this block to
            // re-bundle everything.

            // Image generation (tasks-vision-image-generator): NO plugin
            // Kotlin class imports the ImageGenerator task at all in
            // 0.13.2 — the artifact is a declared-but-unreferenced dep.
            excludes += "lib/**/libmediapipe_tasks_vision_image_generator_jni.so"
            excludes += "lib/**/libimagegenerator_gpu.so"
            // Vision tasks base: loaded only by BaseVisionTaskApi vision
            // tasks (the image generator's base). The text path's
            // LlmInference has its own JNI and never touches it; Reckon
            // sends no images either way.
            excludes += "lib/**/libmediapipe_tasks_vision_jni.so"
            // RAG stack (localagents-rag): reachable only through the
            // plugin's EmbeddingModel.kt. Reckon's Dart never calls any
            // embedding/RAG/vector-store API (grep-verified: no
            // createEmbedder/embedding/retrieval/vectorStore usage).
            excludes += "lib/**/libgemma_embedding_model_jni.so"
            excludes += "lib/**/libgecko_embedding_model_jni.so"
            excludes += "lib/**/libtext_chunker_jni.so"
            excludes += "lib/**/libsqlite_vector_store_jni.so"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for flutter_local_notifications' Java 8+ time APIs on
    // minSdk 24 devices (core library desugaring).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
