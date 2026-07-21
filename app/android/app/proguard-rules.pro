# Flutter engine + embedding
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.embedding.**

# --- supabase_flutter ---
# Ktor (Supabase's HTTP layer) resolves engines reflectively via ServiceLoader.
-keep class io.ktor.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn io.ktor.**
-dontwarn kotlinx.coroutines.**
# kotlinx.serialization generates $$serializer companions that must survive R8.
-keepattributes *Annotation*, InnerClasses, Signature, RuntimeVisibleAnnotations, AnnotationDefault
-keepclassmembers class ** {
    @kotlinx.serialization.SerialName <fields>;
}
-keepclasseswithmembers class ** {
    public static ** Companion;
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,includedescriptorclasses class **$$serializer { *; }
-keepclassmembers class ** {
    *** Companion;
}
# OkHttp / Conscrypt are optional deps pulled in transitively.
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# --- health (Health Connect) ---
-keep class androidx.health.connect.client.** { *; }
-keep class androidx.health.platform.client.** { *; }
-keep class cachet.plugins.health.** { *; }
-dontwarn androidx.health.**
# Google Fit fallback path on older devices.
-dontwarn com.google.android.gms.fitness.**
-keep class com.google.android.gms.fitness.** { *; }

# --- flutter_local_notifications ---
-keep class com.dexterous.** { *; }
# Notification payloads are deserialized with Gson via reflection.
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-dontwarn com.google.gson.**

# Core library desugaring stubs.
-dontwarn java.lang.invoke.**
-dontwarn build.IgnoreJava8API

# Keep native-callable entry points and enum values used over method channels.
-keepclassmembers class * {
    native <methods>;
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
