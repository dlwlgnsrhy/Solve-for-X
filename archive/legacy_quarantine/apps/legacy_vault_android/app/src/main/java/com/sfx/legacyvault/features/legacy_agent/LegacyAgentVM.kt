package com.sfx.legacyvault.features.legacy_agent

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.UUID

class LegacyAgentVM : ViewModel() {
    data class ChatMessage(
        val id: String = UUID.randomUUID().toString(),
        val role: String,
        val content: String,
        val timestamp: Long = System.currentTimeMillis()
    )

    private val _messages = MutableStateFlow<List<ChatMessage>>(emptyList())
    val messages = _messages.asStateFlow()

    private var _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    init {
        loadPersonaConfig()
    }

    fun addUserMessage(text: String) {
        val userMessage = ChatMessage(role = "user", content = text)
        val updatedMessages = _messages.value + userMessage
        _messages.value = updatedMessages

        viewModelScope.launch {
            _isLoading.value = true
            delay(1000L)
            val assistantMessage = ChatMessage(
                role = "assistant",
                content = generateResponse(text)
            )
            _messages.value = updatedMessages + assistantMessage
            _isLoading.value = false
        }
    }

    fun clearConversation() {
        _messages.value = emptyList()
    }

    private fun generateResponse(userMessage: String): String {
        return "This is a placeholder response for: $userMessage"
    }

    fun loadPersonaConfig() {
        viewModelScope.launch {
            delay(500)
        }
    }
}
