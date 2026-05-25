package com.sfx.legacyvault.features.value_mapping

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sfx.legacyvault.core.models.VoiceLogEntry
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ValueMappingVM : ViewModel() {
    sealed class State {
        object Loading : State()
        data class Ready(
            val keywords: List<String>,
            val entries: List<VoiceLogEntry>
        ) : State()
    }

    private val _state = MutableStateFlow<State>(State.Loading)
    val state: StateFlow<State> = _state.asStateFlow()

    private var _entries = emptyList<VoiceLogEntry>()

    init {
        calculateKeywords()
    }

    fun calculateKeywords() {
        viewModelScope.launch {
            val keywordMap = mutableMapOf<String, Int>()
            _entries.forEach { entry ->
                entry.keywords.forEach { keyword ->
                    keywordMap[keyword] = keywordMap.getOrDefault(keyword, 0) + 1
                }
            }
            val sortedKeywords = keywordMap.entries
                .sortedByDescending { it.value }
                .map { it.key }
            _state.value = State.Ready(
                keywords = sortedKeywords,
                entries = _entries
            )
        }
    }

    fun calculateSentiment(): Int {
        if (_entries.isEmpty()) return 42
        val avgSentiment = _entries.map { it.sentiment }.average()
        return avgSentiment.toInt()
    }

    fun updateEntries(entries: List<VoiceLogEntry>) {
        _entries = entries
        calculateKeywords()
    }
}
