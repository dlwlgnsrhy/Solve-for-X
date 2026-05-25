package com.sfx.legacyvault.core.models

import java.util.UUID

data class InheritanceContact(
    val id: String = UUID.randomUUID().toString(),
    val name: String = "",
    val email: String = "",
    val relationship: String = "friend",
    val notificationStatus: Int = 0
)
