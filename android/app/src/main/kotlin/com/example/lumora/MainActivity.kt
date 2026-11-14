package com.example.lumora

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Base64
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.lumora/photo_picker"
    private val reqGallery = 9001
    private val reqCamera = 9002
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "pickImage") {
                    if (pendingResult != null) {
                        pendingResult?.success(null)
                    }
                    pendingResult = result
                    val fromCamera = call.argument<Boolean>("fromCamera") ?: false
                    try {
                        @Suppress("DEPRECATION")
                        if (fromCamera) {
                            val cameraIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
                            startActivityForResult(cameraIntent, reqCamera)
                        } else {
                            val galleryIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
                                type = "image/*"
                                addCategory(Intent.CATEGORY_OPENABLE)
                            }
                            startActivityForResult(
                                Intent.createChooser(galleryIntent, "Select Photo"),
                                reqGallery
                            )
                        }
                    } catch (_: Exception) {
                        pendingResult?.success(null)
                        pendingResult = null
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != reqGallery && requestCode != reqCamera) return

        val res = pendingResult
        pendingResult = null
        if (res == null) return

        if (resultCode != Activity.RESULT_OK || data == null) {
            res.success(null)
            return
        }

        try {
            if (requestCode == reqCamera) {
                val bitmap = data.extras?.get("data") as? Bitmap
                if (bitmap != null) {
                    res.success(bitmapToDataUri(bitmap))
                    return
                }
                val uri = data.data
                if (uri != null) {
                    res.success(uriToDataUri(uri))
                    return
                }
                res.success(null)
            } else if (requestCode == reqGallery) {
                val uri = data.data
                if (uri != null) {
                    res.success(uriToDataUri(uri))
                } else {
                    res.success(null)
                }
            }
        } catch (_: Exception) {
            res.success(null)
        }
    }

    private fun uriToDataUri(uri: Uri): String? {
        val inputStream = contentResolver.openInputStream(uri) ?: return null
        val bytes = inputStream.use { it.readBytes() }
        val decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        if (decoded != null) {
            return bitmapToDataUri(decoded)
        }
        val b64 = Base64.encodeToString(bytes, Base64.NO_WRAP)
        return "data:image/jpeg;base64,$b64"
    }

    private fun bitmapToDataUri(bitmap: Bitmap): String {
        val maxDim = 1024
        val w = bitmap.width
        val h = bitmap.height
        val scaled = if (w > maxDim || h > maxDim) {
            val ratio = w.toFloat() / h.toFloat()
            val newW = if (ratio > 1f) maxDim else (maxDim * ratio).toInt().coerceAtLeast(1)
            val newH = if (ratio > 1f) (maxDim / ratio).toInt().coerceAtLeast(1) else maxDim
            Bitmap.createScaledBitmap(bitmap, newW, newH, true)
        } else {
            bitmap
        }
        val out = ByteArrayOutputStream()
        var quality = 82
        scaled.compress(Bitmap.CompressFormat.JPEG, quality, out)
        while (out.size() > 450 * 1024 && quality > 45) {
            out.reset()
            quality -= 12
            scaled.compress(Bitmap.CompressFormat.JPEG, quality, out)
        }
        val b64 = Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
        return "data:image/jpeg;base64,$b64"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            // Enable hardware acceleration
            window.setFlags(
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
            )

            // Request highest display refresh rate (90Hz / 120Hz / 144Hz)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val display = display
                val modes = display?.supportedModes
                val maxMode = modes?.maxByOrNull { it.refreshRate }
                if (maxMode != null) {
                    val params = window.attributes
                    params.preferredDisplayModeId = maxMode.modeId
                    window.attributes = params
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                @Suppress("DEPRECATION")
                val modes = window.windowManager.defaultDisplay.supportedModes
                val maxMode = modes?.maxByOrNull { it.refreshRate }
                if (maxMode != null) {
                    val params = window.attributes
                    params.preferredDisplayModeId = maxMode.modeId
                    window.attributes = params
                }
            }
        } catch (_: Exception) {
            // Fallback gracefully if vendor display mode API is restricted
        }
    }
}
