package com.sunodownloader.mobile

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.FileNotFoundException

class MainActivity : FlutterActivity() {
    private val channelName = "com.sunodownloader.mobile/storage"
    private val requestTree = 2417
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "chooseFolder" -> chooseFolder(result)
                    "saveFile" -> saveFile(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun chooseFolder(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("BUSY", "Folder picker is already open", null)
            return
        }
        pendingResult = result
        startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            getPreferences(MODE_PRIVATE).getString("tree_uri", null)?.let {
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, Uri.parse(it))
            }
        }, requestTree)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != requestTree) return
        val result = pendingResult
        pendingResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result?.success(null)
            return
        }
        val flags = data.flags and
            (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        contentResolver.takePersistableUriPermission(uri, flags)
        getPreferences(MODE_PRIVATE).edit().putString("tree_uri", uri.toString()).apply()
        val name = DocumentsContract.getTreeDocumentId(uri).substringAfterLast(':').ifBlank { "Выбранная папка" }
        result?.success(mapOf("name" to name))
    }

    private fun saveFile(call: MethodCall, result: MethodChannel.Result) {
        val fileName = call.argument<String>("fileName")
        val bytes = call.argument<ByteArray>("bytes")
        val tree = getPreferences(MODE_PRIVATE).getString("tree_uri", null)
        if (fileName == null || bytes == null) {
            result.error("ARGS", "Missing file name or bytes", null)
            return
        }
        if (tree == null) {
            result.error("NO_FOLDER", "Сначала выберите папку", null)
            return
        }
        try {
            val treeUri = Uri.parse(tree)
            val parentId = DocumentsContract.getTreeDocumentId(treeUri)
            val parentUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, parentId)
            val outputUri = DocumentsContract.createDocument(contentResolver, parentUri, "audio/mpeg", fileName)
                ?: throw FileNotFoundException("Cannot create document")
            contentResolver.openOutputStream(outputUri, "w")!!.use { it.write(bytes) }
            val folder = parentId.substringAfterLast(':').ifBlank { "выбранную папку" }
            result.success(folder)
        } catch (error: Exception) {
            result.error("SAVE_FAILED", error.localizedMessage, null)
        }
    }
}
