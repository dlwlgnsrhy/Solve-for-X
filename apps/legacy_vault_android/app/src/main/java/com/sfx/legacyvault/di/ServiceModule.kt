package com.sfx.legacyvault.di

import com.sfx.legacyvault.core.services.AppLifecycleService
import com.sfx.legacyvault.core.services.DeadManSwitchService
import com.sfx.legacyvault.core.services.EmbeddingService
import com.sfx.legacyvault.core.services.EncryptionService
import com.sfx.legacyvault.core.services.LocalLLMService
import com.sfx.legacyvault.core.services.NotificationHandler
import com.sfx.legacyvault.core.services.STTService
import com.sfx.legacyvault.core.services.VectorDBService
import org.koin.dsl.module

val serviceModule = module {
    factory { EncryptionService() }
    factory { STTService(get()) }
    factory { LocalLLMService() }
    factory { EmbeddingService() }
    factory { VectorDBService() }
    factory { DeadManSwitchService() }
    factory { AppLifecycleService() }
    factory { NotificationHandler(get()) }
}
