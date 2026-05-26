package com.sfx.legacyvault.core.models

import java.util.UUID

data class ChatMessage(
    val id: String = UUID.randomUUID().toString(),
    val role: String = "user",
    val content: String = "",
    val timestamp: Long = 0L,
    val embeddingId: String? = null
)
