# --- FLUTTER ENGINE & CORE ---
# Protects the Flutter engine and its core communication channels
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keepattributes *Annotation*

# --- FIREBASE & GOOGLE PLAY SERVICES ---
# Firebase relies on Play Services for device-level routing (like push notifications)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# --- SPECIFIC THIRD-PARTY PACKAGES ---
# Fix PDFBox / read_pdf_text
-keep class com.tom_roush.** { *; }
-dontwarn com.tom_roush.**

# JP2 decoder
-keep class com.gemalto.** { *; }
-dontwarn com.gemalto.**
# --- FIX FOR MISSING PLAY CORE CLASSES ---
# Flutter references these for dynamic feature loading.
# If you aren't using deferred components, these are safe to ignore.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Also ignore Flutter's own embedding references to Play Store split installs
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
# --- CUSTOM NATIVE CODE ---
# If you have written custom Kotlin code in MainActivity
# (e.g., MethodChannels to interface with hardware sensors or custom APIs),
# uncomment the line below and update the package name to prevent it from being stripped.
# -keep class com.example.lora.MainActivity { *; }