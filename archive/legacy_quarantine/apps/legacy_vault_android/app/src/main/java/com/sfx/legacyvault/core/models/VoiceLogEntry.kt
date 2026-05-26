package com.sfx.legacyvault.core.models

import java.util.UUID

data class VoiceLogEntry(
    val id: String = UUID.randomUUID().toString(),
    val title: String = "",
    val recordingDate: Long = 0L,
    val transcript: String = "",
    val aiSummary: String? = null,
    val aiEnrichment: String? = null,
    val sentiment: Int = 0,
    val durationMs: Int = 0,
    val audioURL: String? = null,
    val keywords: List<String> = emptyList(),
    val embeddingId: String? = null
) {
    val keywordsJSON: String
        get() {
            return try {
                keywords.joinToString(",")
            } catch (e: Exception) {
                ""
            }
        }
}
