package com.sfx.legacyvault.core.services

import android.content.Context
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer

class STTService(private val context: Context) {

    interface TranscriptionListener {
        fun onResult(text: String)
        fun onError()
        fun onReady()
    }

    private var speechRecognizer: SpeechRecognizer? = null
    private var listener: TranscriptionListener? = null

    fun startTranscription(l: TranscriptionListener) {
        listener = l
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context).also { sr ->
            sr.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(ignored: android.os.Bundle?) { l.onReady() }
                override fun onRmsChanged(ignored: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {
                    if (buffer != null && buffer.isNotEmpty()) {
                        speechRecognizer?.stopListening()
                    }
                }
                override fun onPartialResults(results: android.os.Bundle?) {
                    val matches = results?.getStringArrayList(
                        android.speech.SpeechRecognizer.RESULTS_RECOGNITION
                    )
                    matches?.firstOrNull()?.let { l.onResult(it) }
                }
                override fun onResults(results: android.os.Bundle?) {
                    val matches = results?.getStringArrayList(
                        android.speech.SpeechRecognizer.RESULTS_RECOGNITION
                    )
                    matches?.firstOrNull()?.let { l.onResult(it) }
                }
                override fun onError(error: Int) { l.onError() }
                override fun onEndOfSpeech() {}
                override fun onEvent(eventType: Int, params: android.os.Bundle?) {}
                override fun onBeginningOfSpeech() {}
            })

            val intent = android.content.Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ko-KR")
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            }
            speechRecognizer?.startListening(intent)
        }
    }

    fun stopTranscription() {
        speechRecognizer?.stopListening()
        release()
    }

    fun release() {
        speechRecognizer?.destroy()
        speechRecognizer = null
        listener = null
    }
}
