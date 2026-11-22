package com.taezeem.auratube

import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.MediaScannerConnection
import android.media.audiofx.AudioEffect
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.sqrt

class MainActivity : AudioServiceActivity(), SensorEventListener {
    private val EFFECTS_CHANNEL = "com.taezeem.auratube/audio_effects"
    private val GESTURE_CHANNEL = "com.taezeem.auratube/gestures"

    private var gestureChannel: MethodChannel? = null
    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null

    private var isShakeToSkipEnabled = false
    private var isFlipToPauseEnabled = false
    private var lastShakeTime = 0L
    private var isFlippedDown = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Hardware Audio Effects & Media Scanner Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EFFECTS_CHANNEL).setMethodCallHandler { call, result ->
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
                "scanMediaFile" -> {
                    val filePath = call.argument<String>("filePath")
                    if (!filePath.isNullOrBlank()) {
                        MediaScannerConnection.scanFile(context, arrayOf(filePath), null) { _, _ -> }
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 2. Hardware Sensor Gestures Channel (Shake-to-Skip & Flip-to-Pause from Sine)
        gestureChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GESTURE_CHANNEL)
        gestureChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "configureGestures" -> {
                    isShakeToSkipEnabled = call.argument<Boolean>("shakeToSkip") ?: false
                    isFlipToPauseEnabled = call.argument<Boolean>("flipToPause") ?: false
                    updateSensorRegistration()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun updateSensorRegistration() {
        val manager = sensorManager ?: (getSystemService(Context.SENSOR_SERVICE) as? SensorManager)?.also {
            sensorManager = it
            accelerometer = it.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        }
        manager?.unregisterListener(this)
        if ((isShakeToSkipEnabled || isFlipToPauseEnabled) && accelerometer != null) {
            manager?.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_NORMAL)
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || event.sensor.type != Sensor.TYPE_ACCELEROMETER) return
        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]

        if (isShakeToSkipEnabled) {
            val gForce = sqrt((x * x + y * y + z * z).toDouble()) / SensorManager.GRAVITY_EARTH
            val now = System.currentTimeMillis()
            if (gForce > 2.65 && (now - lastShakeTime) > 1200) {
                lastShakeTime = now
                gestureChannel?.invokeMethod("onShakeSkip", null)
            }
        }

        if (isFlipToPauseEnabled) {
            if (z < -7.8 && !isFlippedDown) {
                isFlippedDown = true
                gestureChannel?.invokeMethod("onFlipPause", null)
            } else if (z > 6.0 && isFlippedDown) {
                isFlippedDown = false
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onDestroy() {
        sensorManager?.unregisterListener(this)
        super.onDestroy()
    }
}
