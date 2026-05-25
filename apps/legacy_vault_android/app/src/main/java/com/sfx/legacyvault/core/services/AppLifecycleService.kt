package com.sfx.legacyvault.core.services

import com.sfx.legacyvault.R

class AppLifecycleService {

    enum class AppState {
        Active, Background, Foreground
    }

    private var _state = AppState.Active

    var state: AppState
        get() = _state
        private set(value) { _state = value }

    fun updateState(newState: AppState) {
        state = newState
    }
}
