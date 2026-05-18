# Flutter Firebase and Local Notifications ProGuard Rules
-keep class io.flutter.plugins.firebase.messaging.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class io.flutter.app.** { *; }
-dontwarn io.flutter.plugins.firebase.messaging.**
-dontwarn com.google.firebase.**
