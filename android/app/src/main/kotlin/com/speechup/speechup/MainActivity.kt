package com.speechup.speechup

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val METHOD_CHANNEL = "com.speechup/speech"
        private const val EVENT_CHANNEL = "com.speechup/speech_events"
        private const val TAG = "NativeSpeech"
        private const val MIC_PERMISSION_CODE = 1001
    }

    private var speechRecognizer: SpeechRecognizer? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isListening = false
    private var pendingLocale: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel for start/stop
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        val success = initializeSpeechRecognizer()
                        result.success(success)
                    }
                    "start" -> {
                        val locale = call.argument<String>("locale") ?: "vi-VN"
                        startListening(locale)
                        result.success(true)
                    }
                    "stop" -> {
                        stopListening()
                        result.success(true)
                    }
                    "cancel" -> {
                        cancelListening()
                        result.success(true)
                    }
                    "isAvailable" -> {
                        // We bypass the standard check and try to create recognizer directly
                        result.success(initializeSpeechRecognizer())
                    }
                    "requestPermission" -> {
                        requestMicPermission()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Event channel for streaming results
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    private fun initializeSpeechRecognizer(): Boolean {
        return try {
            if (speechRecognizer == null) {
                // Skip isRecognitionAvailable() check - just try to create it
                Log.d(TAG, "Creating SpeechRecognizer directly (bypassing availability check)")
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
                speechRecognizer?.setRecognitionListener(createListener())
                Log.d(TAG, "SpeechRecognizer created successfully")
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create SpeechRecognizer: ${e.message}")
            false
        }
    }

    private fun hasMicPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
                PackageManager.PERMISSION_GRANTED
    }

    private fun requestMicPermission() {
        if (!hasMicPermission()) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                MIC_PERMISSION_CODE
            )
        }
    }

    private fun startListening(locale: String) {
        if (!hasMicPermission()) {
            Log.w(TAG, "No mic permission, requesting...")
            pendingLocale = locale
            requestMicPermission()
            return
        }

        try {
            if (speechRecognizer == null) {
                initializeSpeechRecognizer()
            }

            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, locale)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 1000L)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 3000L)
            }

            isListening = true
            speechRecognizer?.startListening(intent)
            sendEvent("status", "listening")
            Log.d(TAG, "Started listening with locale: $locale")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start listening: ${e.message}")
            isListening = false
            sendEvent("error", "Failed to start: ${e.message}")
        }
    }

    private fun stopListening() {
        try {
            speechRecognizer?.stopListening()
            isListening = false
            Log.d(TAG, "Stopped listening")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping: ${e.message}")
        }
    }

    private fun cancelListening() {
        try {
            speechRecognizer?.cancel()
            isListening = false
            Log.d(TAG, "Cancelled listening")
        } catch (e: Exception) {
            Log.e(TAG, "Error cancelling: ${e.message}")
        }
    }

    private fun createListener(): RecognitionListener {
        return object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                Log.d(TAG, "Ready for speech")
                sendEvent("status", "listening")
            }

            override fun onBeginningOfSpeech() {
                Log.d(TAG, "Speech began")
            }

            override fun onRmsChanged(rmsdB: Float) {
                sendEvent("soundLevel", rmsdB.toString())
            }

            override fun onBufferReceived(buffer: ByteArray?) {}

            override fun onEndOfSpeech() {
                Log.d(TAG, "Speech ended")
                isListening = false
                sendEvent("status", "done")
            }

            override fun onError(error: Int) {
                val errorMsg = mapErrorCode(error)
                Log.e(TAG, "Recognition error: $error ($errorMsg)")
                isListening = false
                sendEvent("error", errorMsg)
            }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val text = matches?.firstOrNull() ?: ""
                Log.d(TAG, "Final result: $text")
                isListening = false
                sendEvent("result", text)
                sendEvent("status", "done")
            }

            override fun onPartialResults(partialResults: Bundle?) {
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val text = matches?.firstOrNull() ?: ""
                if (text.isNotEmpty()) {
                    sendEvent("partial", text)
                }
            }

            override fun onEvent(eventType: Int, params: Bundle?) {}
        }
    }

    private fun sendEvent(type: String, data: String) {
        runOnUiThread {
            eventSink?.success(mapOf("type" to type, "data" to data))
        }
    }

    private fun mapErrorCode(error: Int): String {
        return when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
            SpeechRecognizer.ERROR_CLIENT -> "Client error"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
            SpeechRecognizer.ERROR_NETWORK -> "Network error"
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
            SpeechRecognizer.ERROR_NO_MATCH -> "No speech match"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer busy"
            SpeechRecognizer.ERROR_SERVER -> "Server error"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech detected"
            else -> "Unknown error ($error)"
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == MIC_PERMISSION_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Log.d(TAG, "Mic permission granted")
                pendingLocale?.let { startListening(it) }
                pendingLocale = null
            } else {
                Log.w(TAG, "Mic permission denied")
                sendEvent("error", "Microphone permission denied")
            }
        }
    }

    override fun onDestroy() {
        speechRecognizer?.destroy()
        speechRecognizer = null
        super.onDestroy()
    }
}
