package com.sfx.legacyvault.core.util

object Constants {
    const val DATABASE_NAME = "legacy_vault.db"
    const val DB_VERSION = 1

    const val ENCRYPTION_KEY_ALGORITHM = "AES/GCM/NoPadding"
    const val ENCRYPTION_KEY_SIZE = 256
    const val ANDROID_KEYSTORE = "AndroidKeyStore"
    const val KEYSTORE_KEY_ALIAS = "legacy_vault_encryption_key"

    const val EMBEDDING_DIMENSION = 384

    const val DEFAULT_VAULT_DEADLINE_DAYS = 7

    const val NOTIFICATION_CHANNEL_ID = "legacy_vault_channel"
    const val NOTIFICATION_CHANNEL_NAME = "Legacy Vault Alerts"

    const val SCHEDULED_JOB_INTERVAL_MS = 86400000L

    val SentimentRange = -100..100

    object VaultType {
        const val PASSWORDS = "passwords"
        const val LEGAL = "legal"
        const val FINANCIAL = "financial"
        const val PHOTOS = "photos"
        const val VIDEOS = "videos"
        const val CUSTOM = "custom"
    }

    object VaultStatus {
        const val ACTIVE = "active"
        const val PAUSED = "paused"
        const val EXPIRED = "expired"
        const val ALERT_SENT = "alert_sent"
    }

    object Relationship {
        const val SPOUSE = "spouse"
        const val CHILD = "child"
        const val FRIEND = "friend"
        const val ORGANIZATION = "organization"
    }

    object MessageRole {
        const val USER = "user"
        const val ASSISTANT = "assistant"
    }

    object KeywordCategory {
        const val FAMILY = "family"
        const val CAREER = "career"
        const val EMOTION = "emotion"
        const val CHALLENGE = "challenge"
        const val PEACE = "peace"
        const val GROWTH = "growth"
    }
}
