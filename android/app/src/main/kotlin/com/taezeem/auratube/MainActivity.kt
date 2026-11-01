package com.taezeem.auratube

import android.content.Intent
import android.media.audiofx.AudioEffect
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.taezeem.auratube/audio_effects"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAudioEffectSession" -> {
                    val sessionId = call.argument<Int>("sessionId") ?: 0
                    if (sessionId > 0) {
                        try {
                            val intent = Intent(AudioEffect.ACTION_OPEN_AUDIO_EFFECT_CONTROL_SESSION).apply {
                                putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
                                putExtra(AudioEffect.EXTRA_PACKAGE_NAME, packageName)
                                putExtra(AudioEffect.EXTRA_CONTENT_TYPE, AudioEffect.CONTENT_TYPE_MUSIC)
                            }
                            sendBroadcast(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("BROADCAST_ERROR", e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "closeAudioEffectSession" -> {
                    val sessionId = call.argument<Int>("sessionId") ?: 0
                    if (sessionId > 0) {
                        try {
                            val intent = Intent(AudioEffect.ACTION_CLOSE_AUDIO_EFFECT_CONTROL_SESSION).apply {
                                putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
                                putExtra(AudioEffect.EXTRA_PACKAGE_NAME, packageName)
                            }
                            sendBroadcast(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("BROADCAST_ERROR", e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "openSystemEqualizer" -> {
                    val sessionId = call.argument<Int>("sessionId") ?: 0
                    try {
                        val intent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL).apply {
                            if (sessionId > 0) {
                                putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
                            }
                            putExtra(AudioEffect.EXTRA_PACKAGE_NAME, packageName)
                            putExtra(AudioEffect.EXTRA_CONTENT_TYPE, AudioEffect.CONTENT_TYPE_MUSIC)
                        }
                        if (intent.resolveActivity(packageManager) != null) {
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
