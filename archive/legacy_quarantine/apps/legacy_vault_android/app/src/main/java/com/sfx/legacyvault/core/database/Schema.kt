package com.sfx.legacyvault.core.database

import androidx.room.Dao
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Delete
import androidx.room.Query
import androidx.room.Update

@Entity(tableName = "voice_log_entry")
data class SchemaVoiceLogEntry(
    @PrimaryKey val id: String = "",
    val title: String = "",
    val recordingDate: Long = 0L,
    val transcript: String = "",
    val aiSummary: String? = null,
    val aiEnrichment: String? = null,
    val sentiment: Int = 0,
    val durationMs: Int = 0,
    val keywords: String? = null,
    val embeddingId: String? = null
)

@Entity(tableName = "vault_record")
data class SchemaVaultRecord(
    @PrimaryKey val id: String = "",
    val name: String = "",
    val vaultType: String = "",
    val encryptedData: String = "",
    val salt: String = "",
    val lastPingDate: Long = 0L,
    val deadlineDays: Int = 0,
    val targetEmails: String? = null,
    val status: String = "active"
)

@Entity(tableName = "inheritance_contact")
data class SchemaInheritanceContact(
    @PrimaryKey val id: String = "",
    val name: String = "",
    val email: String = "",
    val relationship: String = "",
    val notificationStatus: Int = 0
)

@Entity(tableName = "chat_message")
data class SchemaChatMessage(
    @PrimaryKey val id: String = "",
    val role: String = "",
    val content: String = "",
    val timestamp: Long = 0L,
    val embeddingId: String? = null
)

@Entity(tableName = "value_keyword")
data class SchemaValueKeyword(
    @PrimaryKey val id: String = "",
    val word: String = "",
    val frequency: Int = 0,
    val firstOccurrence: Long = 0L,
    val lastOccurrence: Long = 0L,
    val category: String = ""
)

@Dao
interface VoiceLogEntryDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entry: SchemaVoiceLogEntry): Long

    @Update
    suspend fun update(entry: SchemaVoiceLogEntry)

    @Query("SELECT * FROM voice_log_entry ORDER BY recordingDate DESC")
    suspend fun getAll(): List<SchemaVoiceLogEntry>

    @Query("SELECT * FROM voice_log_entry WHERE id = :id")
    suspend fun getById(id: String): SchemaVoiceLogEntry?

    @Query("DELETE FROM voice_log_entry")
    suspend fun deleteAll()
}

@Dao
interface VaultRecordDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(record: SchemaVaultRecord): Long

    @Update
    suspend fun update(record: SchemaVaultRecord)

    @Query("SELECT * FROM vault_record ORDER BY lastPingDate DESC")
    suspend fun getAll(): List<SchemaVaultRecord>

    @Query("SELECT * FROM vault_record WHERE id = :id")
    suspend fun getById(id: String): SchemaVaultRecord?

    @Query("UPDATE vault_record SET lastPingDate = :pingTimestamp, status = 'active' WHERE id = :id")
    suspend fun ping(id: String, pingTimestamp: Long)

    @Query("DELETE FROM vault_record")
    suspend fun deleteAll()
}

@Dao
interface InheritanceContactDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(contact: SchemaInheritanceContact): Long

    @Update
    suspend fun update(contact: SchemaInheritanceContact)

    @Query("SELECT * FROM inheritance_contact ORDER BY relationship")
    suspend fun getAll(): List<SchemaInheritanceContact>

    @Query("SELECT * FROM inheritance_contact WHERE id = :id")
    suspend fun getById(id: String): SchemaInheritanceContact?

    @Query("DELETE FROM inheritance_contact")
    suspend fun deleteAll()
}

@Dao
interface ChatMessageDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(message: SchemaChatMessage): Long

    @Update
    suspend fun update(message: SchemaChatMessage)

    @Query("SELECT * FROM chat_message ORDER BY timestamp DESC")
    suspend fun getAll(): List<SchemaChatMessage>

    @Query("SELECT * FROM chat_message WHERE id = :id")
    suspend fun getById(id: String): SchemaChatMessage?

    @Query("DELETE FROM chat_message")
    suspend fun deleteAll()
}

@Dao
interface ValueKeywordDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(keyword: SchemaValueKeyword): Long

    @Update
    suspend fun update(keyword: SchemaValueKeyword)

    @Query("SELECT * FROM value_keyword ORDER BY frequency DESC")
    suspend fun getAll(): List<SchemaValueKeyword>

    @Query("SELECT * FROM value_keyword WHERE id = :id")
    suspend fun getById(id: String): SchemaValueKeyword?

    @Query("DELETE FROM value_keyword")
    suspend fun deleteAll()
}
