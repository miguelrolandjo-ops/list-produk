package com.example.flutter_application_1

import android.content.ContentUris
import android.content.ContentValues
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
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
    }
}
