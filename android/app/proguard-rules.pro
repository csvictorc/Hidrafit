# Flutter default rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.android.** { *; }
# Keep all classes related to Play Core Split Install
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }

# Gson (caso algum plugin use)
-keep class com.google.gson.annotations.SerializedName
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Google Sign-In
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.ResultCallback
-keep class com.google.android.gms.common.api.Status
-dontwarn com.google.android.gms.**

# SharedPreferences
-keep class android.content.SharedPreferences { *; }
-keep class android.preference.PreferenceManager { *; }

# FlutterLocalNotificationsPlugin
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# WorkManager (caso use em segundo plano)
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# General AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# Sensors Plus (usado pelo pedometer e outros)
-dontwarn io.flutter.plugins.sensors.**

# Connectivity Plus
-dontwarn io.flutter.plugins.connectivity.**

# Desugar / Java 8 APIs
-dontwarn j$.**

# Reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Evita remoção de classes usadas via reflexão (padrão defensivo)
-keepclassmembers class * {
    public <init>(...);
}
-keepclassmembers class * {
    public *;
}

# Evita problemas com entrypoints e componentes nativos
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
