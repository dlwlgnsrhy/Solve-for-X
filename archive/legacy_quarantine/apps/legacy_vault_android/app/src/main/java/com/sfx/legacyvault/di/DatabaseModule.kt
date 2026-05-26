package com.sfx.legacyvault.di

import androidx.room.Room
import com.sfx.legacyvault.core.database.AppDatabase
import com.sfx.legacyvault.core.database.DB_NAME
import org.koin.android.ext.koin.androidContext
import org.koin.dsl.module

val databaseModule = module {
    single {
        Room.databaseBuilder(
            androidContext(),
            AppDatabase::class.java,
            DB_NAME
        ).build()
    }

    single { get<AppDatabase>().voiceLogEntryDao() }
    single { get<AppDatabase>().vaultRecordDao() }
    single { get<AppDatabase>().inheritanceContactDao() }
    single { get<AppDatabase>().chatMessageDao() }
    single { get<AppDatabase>().valueKeywordDao() }
}
