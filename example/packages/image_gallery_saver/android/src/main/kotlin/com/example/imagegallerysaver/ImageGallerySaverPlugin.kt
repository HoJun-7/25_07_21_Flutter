package com.example.imagegallerysaver

import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileInputStream
import java.io.OutputStream
import java.text.SimpleDateFormat
import java.util.*

/** ImageGallerySaverPlugin */
class ImageGallerySaverPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "image_gallery_saver")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "saveImageToGallery" -> {
                val imageBytes = call.argument<ByteArray>("imageBytes")
                val quality = call.argument<Int>("quality") ?: 100
                val name = call.argument<String>("name") ?: generateFileName()

                if (imageBytes == null) {
                    result.success(mapOf("isSuccess" to false, "filePath" to null, "errorMessage" to "Image bytes are null"))
                    return
                }

                val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                saveBitmapToGallery(bitmap, quality, name, result)
            }

            "saveFileToGallery" -> {
                val filePath = call.argument<String>("file")
                val name = call.argument<String>("name") ?: generateFileName()

                if (filePath == null) {
                    result.success(mapOf("isSuccess" to false, "filePath" to null, "errorMessage" to "File path is null"))
                    return
                }

                saveFileToGallery(filePath, name, result)
            }

            else -> result.notImplemented()
        }
    }

    private fun saveBitmapToGallery(bmp: Bitmap, quality: Int, name: String, result: Result) {
        val resolver = context?.contentResolver
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "$name.jpg")
            put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
        }

        val uri = resolver?.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
        val outputStream = uri?.let { resolver.openOutputStream(it) }

        if (outputStream != null) {
            outputStream.use {
                bmp.compress(Bitmap.CompressFormat.JPEG, quality, it)
            }
            result.success(mapOf("isSuccess" to true, "filePath" to uri.toString()))
        } else {
            result.success(mapOf("isSuccess" to false, "filePath" to null, "errorMessage" to "Output stream is null"))
        }
    }

    private fun saveFileToGallery(filePath: String, name: String, result: Result) {
        val resolver = context?.contentResolver
        val originalFile = File(filePath)

        if (!originalFile.exists()) {
            result.success(mapOf("isSuccess" to false, "filePath" to null, "errorMessage" to "File does not exist"))
            return
        }

        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, originalFile.name)
            put(MediaStore.MediaColumns.MIME_TYPE, "image/*")
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
        }

        val uri = resolver?.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
        val outputStream = uri?.let { resolver.openOutputStream(it) }

        if (outputStream != null) {
            FileInputStream(originalFile).use { input ->
                outputStream.use { output ->
                    val buffer = ByteArray(1024)
                    var length: Int
                    while (input.read(buffer).also { length = it } > 0) {
                        output.write(buffer, 0, length)
                    }
                }
            }
            result.success(mapOf("isSuccess" to true, "filePath" to uri.toString()))
        } else {
            result.success(mapOf("isSuccess" to false, "filePath" to null, "errorMessage" to "Output stream is null"))
        }
    }

    private fun generateFileName(): String {
        val formatter = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault())
        return "IMG_${formatter.format(Date())}"
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
