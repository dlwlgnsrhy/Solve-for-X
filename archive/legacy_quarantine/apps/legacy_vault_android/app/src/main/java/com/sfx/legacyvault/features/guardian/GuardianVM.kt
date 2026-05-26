package com.sfx.legacyvault.features.guardian

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sfx.legacyvault.core.models.InheritanceContact
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class GuardianVM : ViewModel() {
    sealed class Status {
        object Active : Status()
        object Paused : Status()
        object Expired : Status()
    }

    private val _vaultCount = MutableStateFlow(0)
    private val _heirCount = MutableStateFlow(0)
    private val _switchStatus = MutableStateFlow<Status>(Status.Active)
    private val _heirs = MutableStateFlow<List<InheritanceContact>>(emptyList())
    private val _backupStatus = MutableStateFlow<BackupStatus?>(null)

    val vaultCount: StateFlow<Int> = _vaultCount
    val heirCount: StateFlow<Int> = _heirCount.asStateFlow()
    val switchStatus: StateFlow<Status> = _switchStatus.asStateFlow()
    val heirs: StateFlow<List<InheritanceContact>> = _heirs
    val backupStatus: StateFlow<BackupStatus?> = _backupStatus

    data class BackupStatus(
        val lastBackup: Long = 0L,
        val isEncrypted: Boolean = true
    )

    fun updateVaultCount(count: Int) {
        _vaultCount.value = count
    }

    fun updateHeirCount(count: Int) {
        _heirCount.value = count
    }

    fun addHeir(contact: InheritanceContact) {
        viewModelScope.launch {
            val current = _heirs.value.toMutableList()
            current.add(contact)
            _heirs.value = current
            _heirCount.value = current.size
        }
    }

    fun updateHeir(contact: InheritanceContact) {
        viewModelScope.launch {
            val current = _heirs.value.map {
                if (it.id == contact.id) contact else it
            }
            _heirs.value = current
        }
    }

    fun deleteHeir(id: String) {
        viewModelScope.launch {
            val current = _heirs.value.filter { it.id != id }
            _heirs.value = current
            _heirCount.value = current.size
        }
    }

    fun setupSwitch(deadlineDays: Int) {
        _switchStatus.value = Status.Active
        // TODO: integrate with DeadManSwitchService
    }

    fun pingSwitch() {
        _switchStatus.value = Status.Active
        // TODO: call DeadManSwitchService.ping()
    }

    fun unlockVault(passphrase: String, callback: (Boolean) -> Unit) {
        viewModelScope.launch {
            // TODO: integrate with EncryptionService
            // Stub: accept any non-empty passphrase
            callback(passphrase.isNotBlank())
        }
    }

    fun unlockVaultWithBiometric(callback: (Boolean) -> Unit) {
        viewModelScope.launch {
            // TODO: integrate with Android BiometricPrompt API
            callback(false)
        }
    }

    fun exportAllBackups() {
        viewModelScope.launch {
            // TODO: trigger backupService.exportData()
            val timestamp = System.currentTimeMillis() / 1000
            _backupStatus.value = BackupStatus(lastBackup = timestamp)
        }
    }

    fun setBackupStatus(status: BackupStatus) {
        _backupStatus.value = status
    }
}
