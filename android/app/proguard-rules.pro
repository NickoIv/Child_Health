# Rules for the plugins this app uses. Firebase, Play Services and the Flutter
# engine ship their own consumer rules and need nothing here; what follows is
# the part R8 cannot work out on its own.

# flutter_local_notifications serialises scheduled reminders with Gson and
# reads them back after a reboot. Gson works through reflection, so a renamed
# or removed class turns every pending reminder into a silent failure that
# only shows up on a device that has been restarted.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Gson's own reflective machinery, which the above depends on.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Sign in with Apple and the Google popup flow run through Firebase Auth's
# generic OAuth path, which resolves handlers reflectively.
-keep class com.google.firebase.auth.** { *; }

# R8 warns about optional dependencies these libraries reference but do not
# require. They are absent by design, not by mistake.
-dontwarn javax.annotation.**
-dontwarn com.google.errorprone.annotations.**
