package com.example.iac_export_logs_ext

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileInputStream
import java.io.OutputStream

/** IacExportLogsExtPlugin */
class IacExportLogsExtPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "iac_export_logs_ext")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "shareFile" -> {
        handleShareFile(call, result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun handleShareFile(call: MethodCall, result: Result) {
    val filePath = call.argument<String>("filePath")

    if (filePath == null) {
      result.success(false)
      return
    }

    val sourceFile = File(filePath)
    if (!sourceFile.exists()) {
      result.success(false)
      return
    }

    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        // Use MediaStore for Android 10 (Q) and above
        saveToDownloadsUsingMediaStore(sourceFile, result)
      } else {
        // Use legacy method for Android 9 and below
        saveToDownloadsLegacy(sourceFile, result)
      }
    } catch (e: Exception) {
      e.printStackTrace()
      result.success(false)
    }
  }

  private fun saveToDownloadsUsingMediaStore(sourceFile: File, result: Result) {
    try {
      val contentValues = ContentValues().apply {
        put(MediaStore.MediaColumns.DISPLAY_NAME, sourceFile.name)
        put(MediaStore.MediaColumns.MIME_TYPE, "text/plain")
        put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
      }

      val resolver = context.contentResolver
      val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)

      if (uri != null) {
        resolver.openOutputStream(uri)?.use { outputStream ->
          FileInputStream(sourceFile).use { inputStream ->
            inputStream.copyTo(outputStream)
          }
        }
        result.success(true)
      } else {
        result.success(false)
      }
    } catch (e: Exception) {
      e.printStackTrace()
      result.success(false)
    }
  }

  private fun saveToDownloadsLegacy(sourceFile: File, result: Result) {
    try {
      val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
      if (!downloadsDir.exists()) {
        downloadsDir.mkdirs()
      }

      val destFile = File(downloadsDir, sourceFile.name)
      sourceFile.copyTo(destFile, overwrite = true)

      result.success(destFile.exists())
    } catch (e: Exception) {
      e.printStackTrace()
      result.success(false)
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
