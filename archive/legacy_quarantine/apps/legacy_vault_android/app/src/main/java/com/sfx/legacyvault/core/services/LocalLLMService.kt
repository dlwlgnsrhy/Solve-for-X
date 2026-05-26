package com.sfx.legacyvault.core.services

class LocalLLMService {

    private var isReady = false

    fun initialize(modelPath: String? = null, onReady: () -> Unit) {
        isReady = true
        onReady()
    }

    fun generate(prompt: String, callback: (String) -> Unit) {
        if (!isReady) {
            callback("")
            return
        }
        // Placeholder: On-device LLM inference via ONNX.
        // In production: load model from modelPath and run inference.
        val summary = generateSummary(prompt)
        callback(summary)
    }

    fun release() {
        isReady = false
    }

    private fun generateSummary(prompt: String): String {
        val sentences = prompt.split('.').filter { it.trim().isNotEmpty() }
        val keyLines = sentences.take(minOf(3, sentences.size))
        return if (keyLines.isNotEmpty()) {
            "요약: ${keyLines.joinToString(". ") { it.trim() }}."
        } else {
            prompt.take(200) + "..."
        }
    }
}
