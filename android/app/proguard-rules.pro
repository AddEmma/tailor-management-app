# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Prevent obfuscation of Firebase model classes
-keepclassmembers class ** {
    @com.google.firebase.firestore.PropertyName <fields>;
    @com.google.firebase.firestore.PropertyName <methods>;
}

# Keep custom model classes (adjust package name as needed)
-keep class com.example.tailor_management.models.** { *; }

# General Android rules
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
