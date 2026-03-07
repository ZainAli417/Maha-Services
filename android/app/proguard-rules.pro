# Fix PDFBox / read_pdf_text
-keep class com.tom_roush.** { *; }
-dontwarn com.tom_roush.**

# JP2 decoder
-keep class com.gemalto.** { *; }
-dontwarn com.gemalto.**

# Keep Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**