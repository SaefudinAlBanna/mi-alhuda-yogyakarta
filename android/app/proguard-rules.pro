# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Gson / JSON
-keepattributes Signature, Annotation

-keep class com.google.gson.stream.** { *; }
-keep class com.google.gson.** { *; }

# SerializedName dan Expose agar field JSON tidak dihapus
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
    @com.google.gson.annotations.Expose <fields>;
}