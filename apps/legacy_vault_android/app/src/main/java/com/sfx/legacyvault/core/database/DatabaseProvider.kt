package com.sfx.legacyvault.core.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

const val DB_NAME = "legacy_vault.db"
const val DB_VERSION = 1

@Database(
    entities = [
        SchemaVoiceLogEntry::class,
        SchemaVaultRecord::class,
        SchemaInheritanceContact::class,
        SchemaChatMessage::class,
        SchemaValueKeyword::class
    ],
    version = DB_VERSION
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun voiceLogEntryDao(): VoiceLogEntryDao
    abstract fun vaultRecordDao(): VaultRecordDao
    abstract fun inheritanceContactDao(): InheritanceContactDao
    abstract fun chatMessageDao(): ChatMessageDao
    abstract fun valueKeywordDao(): ValueKeywordDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    DB_NAME
                ).build()
                INSTANCE = instance
                instance
            }
        }
    }
}
