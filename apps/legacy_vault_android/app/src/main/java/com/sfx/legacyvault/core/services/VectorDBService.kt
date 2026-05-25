package com.sfx.legacyvault.core.services

class VectorDBService {

    data class VectorResult(val id: Long, val distance: Float)

    private val storage = HashMap<Long, FloatArray>()
    private var nextId = 1L

    fun insertEmbedding(vector: FloatArray): Long {
        val id = nextId++
        storage[id] = vector
        return id
    }

    fun searchNearest(vector: FloatArray, limit: Int, distanceThreshold: Float): List<VectorResult> {
        val results = storage.map { (id, stored) ->
            val distance = cosineDistance(vector, stored)
            VectorResult(id, distance)
        }
            .filter { it.distance <= distanceThreshold }
            .sortedBy { it.distance }
        return results.take(limit)
    }

    fun deleteEmbedding(vectorId: Long): Boolean {
        return storage.remove(vectorId) != null
    }

    fun getEmbeddingCount(): Int {
        return storage.size
    }

    private fun cosineDistance(a: FloatArray, b: FloatArray): Float {
        if (a.size != b.size || a.isEmpty()) return Int.MAX_VALUE.toFloat()
        var dot = 0f
        var magA = 0f
        var magB = 0f
        for (i in a.indices) {
            dot += a[i] * b[i]
            magA += a[i] * a[i]
            magB += b[i] * b[i]
        }
        val denom = kotlin.math.sqrt(magA) * kotlin.math.sqrt(magB)
        return if (denom > 0) 1f - (dot / denom) else Float.MAX_VALUE
    }
}
