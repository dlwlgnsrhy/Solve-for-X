package com.sfx.legacyvault.core.models

import java.util.UUID

data class ValueKeyword(
    val id: String = UUID.randomUUID().toString(),
    val word: String = "",
    val frequency: Int = 0,
    val firstOccurrence: Long = 0L,
    val lastOccurrence: Long = 0L,
    val category: String = ""
)
