package com.mipendiente.app.mi_pendiente

import android.app.Activity
import android.content.Intent
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mipendiente.app/ringtones"
    private val RINGTONE_PICKER_REQUEST_CODE = 991
    private var pendingResult: MethodChannel.Result? = null
    private var currentRingtone: Ringtone? = null

    override fun getRenderMode(): RenderMode {
        return RenderMode.texture
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSystemRingtones" -> {
                    try {
                        val manager = RingtoneManager(this)
                        manager.setType(RingtoneManager.TYPE_NOTIFICATION)
                        val cursor = manager.cursor
                        val list = mutableListOf<Map<String, String>>()
                        while (cursor.moveToNext()) {
                            val title = cursor.getString(RingtoneManager.TITLE_COLUMN_INDEX)
                            val uri = manager.getRingtoneUri(cursor.position)?.toString() ?: ""
                            if (uri.isNotEmpty() && title != null) {
                                list.add(mapOf("title" to title, "uri" to uri))
                            }
                        }
                        result.success(list)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "openRingtonePicker" -> {
                    try {
                        val currentUriStr = call.argument<String>("currentUri")
                        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_NOTIFICATION)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Selecciona tono de notificación")
                            if (!currentUriStr.isNullOrEmpty() && currentUriStr.startsWith("content://")) {
                                putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(currentUriStr))
                            }
                        }
                        pendingResult = result
                        startActivityForResult(intent, RINGTONE_PICKER_REQUEST_CODE)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "playRingtone" -> {
                    val uriStr = call.argument<String>("uri")
                    try {
                        currentRingtone?.stop()
                        if (!uriStr.isNullOrEmpty()) {
                            val uri = Uri.parse(uriStr)
                            currentRingtone = RingtoneManager.getRingtone(applicationContext, uri)
                            currentRingtone?.play()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "stopRingtone" -> {
                    try {
                        currentRingtone?.stop()
                        currentRingtone = null
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == RINGTONE_PICKER_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                @Suppress("DEPRECATION")
                val uri: Uri? = data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
                if (uri != null) {
                    val ringtone = RingtoneManager.getRingtone(this, uri)
                    val title = ringtone?.getTitle(this) ?: "Tono del teléfono"
                    pendingResult?.success(mapOf("title" to title, "uri" to uri.toString()))
                } else {
                    pendingResult?.success(null)
                }
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        currentRingtone?.stop()
        currentRingtone = null
    }
}
