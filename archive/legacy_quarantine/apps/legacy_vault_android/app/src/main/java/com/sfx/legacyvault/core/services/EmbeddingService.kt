package com.sfx.legacyvault.core.services

import kotlin.collections.copyInto
import com.sfx.legacyvault.core.util.Constants

class EmbeddingService {

    private var isReady = false
    private val dimension = Constants.EMBEDDING_DIMENSION

    fun initialize(onReady: () -> Unit) {
        isReady = true
        onReady()
    }

    fun generateEmbedding(text: String): FloatArray {
        if (!isReady) {
            return hashEmbedding(text)
        }
        // Placeholder: ONNX runtime inference for 384-dim embedding.
        return hashEmbedding(text)
    }

    fun release() {
        isReady = false
    }

    private fun hashEmbedding(text: String): FloatArray {
        val vector = FloatArray(dimension)
        val encoded = text.toByteArray(Charsets.UTF_8)
        for (i in encoded.indices) {
            val pos = encoded[i].toInt() % dimension
            val value = (encoded[i] / 255f - 0.5f) * (i + 1) * 0.01f
            vector[pos] += value
        }
        val magnitude = kotlin.math.sqrt(vector.map { it * it }.sum())
        if (magnitude > 0) {
            for (i in vector.indices) {
                vector[i] = vector[i] / magnitude
            }
        }
        return vector
    }
}
