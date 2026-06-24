# flutter_gemma / MediaPipe GenAI — keep protobuf classes referenced by the
# native MediaPipe framework that R8 cannot resolve at compile time.
-dontwarn com.google.mediapipe.proto.**
-keep class com.google.mediapipe.proto.** { *; }
-keep class com.google.mediapipe.framework.** { *; }

# flutter_secure_storage — uses reflection for Android Keystore operations.
-dontwarn com.it_nomads.fluttersecurestorage.**
-keep class com.it_nomads.fluttersecurestorage.** { *; }
