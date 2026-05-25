package com.sfx.legacyvault.core.models

import java.util.UUID

data class VaultRecord(
    val id: String = UUID.randomUUID().toString(),
    val name: String = "",
    val vaultType: String = "custom",
    val encryptedData: String = "",
    val salt: String = "",
    val lastPingDate: Long = 0L,
    val deadlineDays: Int = 0,
    val targetEmails: List<String> = emptyList(),
    val status: String = "active"
)
