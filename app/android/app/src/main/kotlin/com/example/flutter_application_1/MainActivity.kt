package com.example.flutter_application_1

import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors

/**
 * Two small native channels, our own code on purpose (see the end of this
 * comment):
 *
 * Shared PO photos ("Bagikan > Harga Toko" from WhatsApp and others), channel
 * harga_toko/share. Each shared image is shrunk to [SHARE_MAX_SIDE] px on its
 * long side, turned upright, and saved as a JPEG in the cache. Dart takes the
 * files with "takeShared"; while the app runs, "sharedAvailable" tells it new
 * ones arrived.
 *
 * Backups in the public Download folder, through MediaStore (Android 10+).
 *
 * MediaStore needs no storage permission and no folder prompt for files this
 * app created itself, which is exactly the backups it saved. Android 9 and
 * older are not supported here (they would need a runtime permission); the app
 * tells the owner to use Google Drive instead.
 *
 * This is our own code on purpose, not a plugin: plugins that apply the Kotlin
 * Gradle plugin are going to stop building in future Flutter versions.
 */
class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()

    /** Shrunk shared photos Dart hasn't taken yet. Touched only on [worker]. */
    private val pendingShared = mutableListOf<String>()
    private var shareChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
            .also { channel ->
                channel.setMethodCallHandler { call, result ->
                    if (call.method != "takeShared") {
                        result.notImplemented()
                        return@setMethodCallHandler
                    }
                    // Same single thread as the shrinking, so a share that is
                    // still being processed is included.
                    worker.execute {
                        val files = pendingShared.toList()
                        pendingShared.clear()
                        runOnUiThread { result.success(files) }
                    }
                }
            }
        receiveShare(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        receiveShare(intent)
    }

    /** Shrinks the images of a share intent and keeps them for Dart. */
    private fun receiveShare(intent: Intent?) {
        val uris = sharedImageUris(intent)
        if (uris.isEmpty()) return
        // Consume it, so turning the phone (activity recreated) doesn't
        // import the same photos twice.
        intent?.action = null
        worker.execute {
            val files = uris.mapIndexedNotNull { i, uri ->
                try {
                    shrinkImage(uri, i)
                } catch (e: Exception) {
                    null // not a readable image: skip it, keep the others
                }
            }
            pendingShared.addAll(files)
            if (files.isNotEmpty()) {
                runOnUiThread { shareChannel?.invokeMethod("sharedAvailable", files.size) }
            }
        }
    }

    private fun sharedImageUris(intent: Intent?): List<Uri> {
        if (intent == null) return emptyList()
        val type = intent.type ?: ""
        if (!type.startsWith("image/")) return emptyList()
        val uris = mutableListOf<Uri>()
        when (intent.action) {
            Intent.ACTION_SEND -> streamExtra(intent)?.let { uris.add(it) }
            Intent.ACTION_SEND_MULTIPLE -> uris.addAll(streamListExtra(intent))
            else -> return emptyList()
        }
        // Some apps only fill ClipData.
        if (uris.isEmpty()) {
            intent.clipData?.let { clip ->
                for (i in 0 until clip.itemCount) clip.getItemAt(i).uri?.let { uris.add(it) }
            }
        }
        return uris.distinct()
    }

    private fun streamExtra(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    private fun streamListExtra(intent: Intent): List<Uri> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
        } ?: emptyList()

    /**
     * Decodes [uri] at a reduced size (never the full photo in memory), turns
     * it upright from its EXIF orientation, scales the long side down to
     * [SHARE_MAX_SIDE] and writes a JPEG to the cache. Returns the file path.
     */
    private fun shrinkImage(uri: Uri, index: Int): String {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
        val longSide = maxOf(bounds.outWidth, bounds.outHeight)
        if (longSide <= 0) throw IOException("Bukan gambar")

        var sample = 1
        while (longSide / (sample * 2) >= SHARE_MAX_SIDE) sample *= 2
        val decoded = contentResolver.openInputStream(uri)?.use {
            BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = sample })
        } ?: throw IOException("Gambar tidak bisa dibaca")

        val matrix = Matrix()
        val rotation = exifRotation(uri)
        if (rotation != 0) matrix.postRotate(rotation.toFloat())
        val scale = SHARE_MAX_SIDE.toFloat() / maxOf(decoded.width, decoded.height)
        if (scale < 1f) matrix.postScale(scale, scale)
        val upright = if (matrix.isIdentity) decoded else
            Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, matrix, true)

        val dir = File(cacheDir, "shared").apply { mkdirs() }
        val file = File(dir, "${System.currentTimeMillis()}_${index + 1}.jpg")
        file.outputStream().use { upright.compress(Bitmap.CompressFormat.JPEG, SHARE_JPEG_QUALITY, it) }
        if (upright !== decoded) upright.recycle()
        decoded.recycle()
        return file.absolutePath
    }

    private fun exifRotation(uri: Uri): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return 0
        return try {
            contentResolver.openInputStream(uri)?.use { stream ->
                when (ExifInterface(stream).getAttributeInt(
                    ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL,
                )) {
                    ExifInterface.ORIENTATION_ROTATE_90 -> 90
                    ExifInterface.ORIENTATION_ROTATE_180 -> 180
                    ExifInterface.ORIENTATION_ROTATE_270 -> 270
                    else -> 0
                }
            } ?: 0
        } catch (e: Exception) {
            0
        }
    }

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }

    /** File work runs off the main thread; results go back on it. */
    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        worker.execute {
            try {
                val value: Any? = when (call.method) {
                    "saveToDownloads" -> saveToDownloads(
                        call.argument<String>("sourcePath")!!,
                        call.argument<String>("name")!!,
                    )
                    "listBackups" -> listBackups(call.argument<String>("prefix")!!)
                    "copyToFile" -> {
                        copyToFile(
                            call.argument<String>("uri")!!,
                            call.argument<String>("destPath")!!,
                        )
                        true
                    }
                    else -> {
                        runOnUiThread { result.notImplemented() }
                        return@execute
                    }
                }
                runOnUiThread { result.success(value) }
            } catch (e: Exception) {
                runOnUiThread { result.error("backup_files", e.message, null) }
            }
        }
    }

    /**
     * Copies [sourcePath] into Download. MediaStore picks a free name if one
     * is taken, so nothing is overwritten. Returns the saved name, or null on
     * Android 9 and older.
     */
    private fun saveToDownloads(sourcePath: String, name: String): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, "application/zip")
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            // Hidden from other apps until the copy is complete.
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IOException("Tidak bisa membuat file di folder Download")
        try {
            val out = contentResolver.openOutputStream(uri)
                ?: throw IOException("Tidak bisa menulis ke folder Download")
            out.use { stream -> File(sourcePath).inputStream().use { it.copyTo(stream) } }
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
        } catch (e: Exception) {
            contentResolver.delete(uri, null, null) // do not leave a half file
            throw e
        }
        return displayName(uri) ?: name
    }

    private fun displayName(uri: Uri): String? =
        contentResolver.query(
            uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null,
        )?.use { if (it.moveToFirst()) it.getString(0) else null }

    /**
     * Backups this app saved in Download whose name starts with [prefix],
     * newest first. Each entry: uri, name, size (bytes), modified (epoch ms).
     */
    private fun listBackups(prefix: String): List<Map<String, Any>> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return emptyList()

        val found = mutableListOf<Map<String, Any>>()
        contentResolver.query(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            arrayOf(
                MediaStore.MediaColumns._ID,
                MediaStore.MediaColumns.DISPLAY_NAME,
                MediaStore.MediaColumns.SIZE,
                MediaStore.MediaColumns.DATE_MODIFIED,
            ),
            "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ? ESCAPE '\\'",
            arrayOf(prefix.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%"),
            "${MediaStore.MediaColumns.DATE_MODIFIED} DESC",
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                val uri = ContentUris.withAppendedId(
                    MediaStore.Downloads.EXTERNAL_CONTENT_URI, cursor.getLong(0),
                )
                found.add(
                    mapOf(
                        "uri" to uri.toString(),
                        "name" to cursor.getString(1),
                        "size" to cursor.getLong(2),
                        "modified" to cursor.getLong(3) * 1000, // seconds -> ms
                    ),
                )
            }
        }
        return found
    }

    /** Copies a content URI from [listBackups] into a normal file. */
    private fun copyToFile(uri: String, destPath: String) {
        val input = contentResolver.openInputStream(Uri.parse(uri))
            ?: throw IOException("Tidak bisa membaca file cadangan")
        input.use { source -> File(destPath).outputStream().use { source.copyTo(it) } }
    }

    companion object {
        const val CHANNEL = "harga_toko/backup_files"
        const val SHARE_CHANNEL = "harga_toko/share"

        /** Same as the app's camera/gallery setting (poMaxSide in Dart). */
        const val SHARE_MAX_SIDE = 1600
        const val SHARE_JPEG_QUALITY = 82
    }
}
