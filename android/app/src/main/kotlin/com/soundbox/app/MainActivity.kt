package com.soundbox.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.soundbox.app/export"
        private const val UPDATE_CHANNEL = "com.soundbox.app/update"
        private const val REQUEST_SAVE_FILE = 1001
        private const val REQUEST_PICK_FOLDER = 1002
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingRequest = 0
    private var pendingPath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickFolder" -> {
                        pendingResult = result
                        pendingRequest = REQUEST_PICK_FOLDER
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                            flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                        }
                        startActivityForResult(intent, REQUEST_PICK_FOLDER)
                    }

                    "saveFile" -> {
                        val path = call.argument<String>("path")
                        if (path == null || !File(path).exists()) {
                            result.error("missing_file", "El archivo no existe", null)
                            return@setMethodCallHandler
                        }
                        pendingResult = result
                        pendingRequest = REQUEST_SAVE_FILE
                        pendingPath = path
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = call.argument<String>("mime") ?: "audio/mpeg"
                            putExtra(
                                Intent.EXTRA_TITLE,
                                call.argument<String>("name") ?: "musica.mp3"
                            )
                        }
                        startActivityForResult(intent, REQUEST_SAVE_FILE)
                    }

                    "exportFiles" -> {
                        val tree = call.argument<String>("tree")
                        @Suppress("UNCHECKED_CAST")
                        val files = call.argument<List<Map<String, String>>>("files")
                            ?: emptyList()
                        if (tree == null) {
                            result.error("missing_tree", "Falta la carpeta elegida", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(exportFiles(Uri.parse(tree), files))
                        } catch (error: Exception) {
                            result.error("export_error", error.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAbi" -> result.success(
                        Build.SUPPORTED_ABIS.firstOrNull() ?: ""
                    )

                    "canInstall" -> result.success(canInstallApks())

                    "openInstallSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:$packageName")
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                        }
                        result.success(true)
                    }

                    "installApk" -> {
                        val path = call.argument<String>("path")
                        val file = if (path == null) null else File(path)
                        if (file == null || !file.exists()) {
                            result.error("missing_apk", "El APK no existe", null)
                            return@setMethodCallHandler
                        }
                        if (!canInstallApks()) {
                            result.error(
                                "install_permission",
                                "Falta permiso de instalacion",
                                null
                            )
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = FileProvider.getUriForFile(
                                this,
                                "$packageName.fileprovider",
                                file
                            )
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(
                                    uri,
                                    "application/vnd.android.package-archive"
                                )
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (error: Exception) {
                            result.error("install_error", error.message, null)
                        }
                    }

                    "openUrl" -> {
                        val url = call.argument<String>("url")
                        if (url == null) {
                            result.error("missing_url", "Falta la URL", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (error: Exception) {
                            result.error("open_error", error.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun canInstallApks(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            packageManager.canRequestPackageInstalls()

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        val result = pendingResult ?: return
        if (requestCode != pendingRequest) return
        pendingResult = null
        pendingRequest = 0

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            pendingPath = null
            result.success(null)
            return
        }

        val uri = data.data!!
        when (requestCode) {
            REQUEST_PICK_FOLDER -> {
                try {
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    )
                } catch (_: SecurityException) {
                    // Algunos proveedores no permiten conservar el permiso.
                }
                result.success(uri.toString())
            }

            REQUEST_SAVE_FILE -> {
                val path = pendingPath
                pendingPath = null
                try {
                    if (path == null || !File(path).exists()) {
                        result.error("missing_file", "El archivo ya no existe", null)
                        return
                    }
                    contentResolver.openOutputStream(uri)?.use { output ->
                        FileInputStream(path).use { input -> input.copyTo(output) }
                    } ?: throw IllegalStateException("No se pudo abrir el destino")
                    result.success(uri.toString())
                } catch (error: Exception) {
                    result.error("export_error", error.message, null)
                }
            }
        }
    }

    private fun exportFiles(treeUri: Uri, files: List<Map<String, String>>): Int {
        val rootId = DocumentsContract.getTreeDocumentId(treeUri)
            ?: throw IllegalStateException("No se pudo leer la carpeta")
        val parent = DocumentsContract.buildDocumentUriUsingTree(treeUri, rootId)
        var exported = 0

        for (file in files) {
            val path = file["path"] ?: continue
            val source = File(path)
            if (!source.exists()) continue

            val name = (file["name"] ?: source.name)
                .replace(Regex("[/\\\\:*?\"<>|]"), "_")
                .ifEmpty { source.name }
            val mime = file["mime"] ?: "audio/mpeg"
            val target = DocumentsContract.createDocument(contentResolver, parent, mime, name)
                ?: throw IllegalStateException("No se pudo crear $name")

            contentResolver.openOutputStream(target)?.use { output ->
                FileInputStream(source).use { input -> input.copyTo(output) }
            } ?: throw IllegalStateException("No se pudo escribir $name")
            exported++
        }
        return exported
    }
}
