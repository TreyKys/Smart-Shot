# Isar — reflection-free but keeps generated schema/collection classes
-keep class dev.isar.isar_flutter_libs.** { *; }
-keep class **$$IsarCollection { *; }
-keepclassmembers class * {
    @dev.isar.isar.annotations.* <fields>;
}

# ML Kit text recognition
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-dontwarn com.google.mlkit.**

# Google Generative AI (Gemini)
-keep class com.google.ai.client.generativeai.** { *; }
-dontwarn com.google.ai.client.generativeai.**

# RevenueCat / Purchases
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# WorkManager
-keep class androidx.work.** { *; }

# Gson/JSON models used across the above SDKs commonly need this
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
