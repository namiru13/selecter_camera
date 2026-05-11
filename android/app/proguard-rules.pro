# Flutter向けProGuardルール
# R8コード縮小時にネイティブプラグインが正しく動作するよう保護する

# Flutter関連
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# FFmpeg Kit
-keep class com.arthenica.ffmpegkit.** { *; }
-dontwarn com.arthenica.ffmpegkit.**

# Gal（ギャラリー保存）
-keep class dev.gal.** { *; }

# Camera CameraX
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# image_cropper (UCrop)
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# video_thumbnail
-keep class com.example.video_thumbnail.** { *; }

# Kotlin Coroutines
-dontwarn kotlinx.coroutines.**

# Native Device Orientation
-keep class com.github.rmtmckenzie.nativedeviceorientation.** { *; }
-dontwarn com.github.rmtmckenzie.nativedeviceorientation.**

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Sensors Plus
-keep class dev.fluttercommunity.plus.sensors.** { *; }
-dontwarn dev.fluttercommunity.plus.sensors.**

# Share Plus
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# FFmpeg kit flutter new (antonkarpenko)
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-dontwarn com.antonkarpenko.ffmpegkit.**
