package com.sfx.legacyvault.core.services

import com.sfx.legacyvault.core.util.Constants

class DeadManSwitchService {

    data class SwitchStatus(
        val lastPing: Long,
        val deadline: Long,
        val status: String
    )

    private var configured = false
    private var deadlineDays = Constants.DEFAULT_VAULT_DEADLINE_DAYS
    private var lastPing: Long = 0L

    fun setup(deadlineDays: Int) {
        this.deadlineDays = deadlineDays
        this.configured = true
        lastPing = System.currentTimeMillis() / 1000
    }

    fun ping() {
        lastPing = System.currentTimeMillis() / 1000
    }

    fun getStatus(): SwitchStatus {
        if (!configured) {
            return SwitchStatus(0L, 0L, "disabled")
        }
        val deadline = (lastPing + deadlineDays * 86400L) * 1000
        val now = System.currentTimeMillis()
        val status = when {
            now > deadline -> "triggered"
            now > deadline - 3 * 86400000L -> "alert"
            else -> "idle"
        }
        return SwitchStatus(
            lastPing = lastPing,
            deadline = deadline,
            status = status
        )
    }
}
