package com.sfx.legacyvault.features.soul_mining

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sfx.legacyvault.core.models.VoiceLogEntry
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID
import java.util.concurrent.TimeUnit

class RecordingSessionVM : ViewModel() {

    private val _state = MutableStateFlow<RecordingState>(RecordingState.Idle)
    val state: StateFlow<RecordingState> = _state.asStateFlow()

    private val _transcript = MutableStateFlow("")
    val transcript: StateFlow<String> = _transcript.asStateFlow()

    private val _currentEntry = MutableStateFlow<VoiceLogEntry?>(null)
    val currentEntry: StateFlow<VoiceLogEntry?> = _currentEntry.asStateFlow()

    private val _completedEntries = Channel<VoiceLogEntry>(Channel.BUFFERED)
    val completedEntries: Flow<VoiceLogEntry> = _completedEntries.receiveAsFlow()

    private var recordingStartTime: Long = 0
    private var recordingCount: Int = 0

    fun startRecording(): Flow<VoiceLogEntry> {
        _state.value = RecordingState.Recording
        recordingStartTime = System.currentTimeMillis()
        _transcript.value = ""

        return _completedEntries.receiveAsFlow()
    }

    fun stopRecording(): VoiceLogEntry? {
        val duration = System.currentTimeMillis() - recordingStartTime
        val entry = VoiceLogEntry(
            id = UUID.randomUUID().toString(),
            title = "Recording #${recordingCount + 1}",
            recordingDate = recordingStartTime,
            transcript = _transcript.value,
            durationMs = duration.toInt(),
            sentiment = estimateSentiment(_transcript.value),
            keywords = extractKeywords(_transcript.value),
        )
        recordingCount++
        _transcript.value = ""
        _currentEntry.value = entry
        _state.value = RecordingState.Idle
        return entry
    }

    fun updateTranscript(text: String) {
        _transcript.update { current ->
            if (current.isBlank()) text else "$current $text"
        }
    }

    fun dismissCurrentEntry() {
        _currentEntry.value = null
    }

    private fun estimateSentiment(text: String): Int {
        if (text.isBlank()) return 0
        val words = text.lowercase().trim().split(Regex("\\s+"))
        val positive = setOf("happy", "good", "great", "wonderful", "excellent", "beautiful",
            "love", "joy", "hope", "dream", "success", "bright", "smile", "laugh", "peace")
        val negative = setOf("sad", "bad", "terrible", "awful", "hate", "anger", "fear",
            "worried", "lost", "empty", "dark", "pain", "struggle", "fail", "doubt")
        var score = 0
        words.forEach { w ->
            if (positive.contains(w)) score++
            if (negative.contains(w)) score--
        }
        return ((score.toDouble() / maxOf(words.size, 1)) * 100).toInt().coerceIn(-100, 100)
    }

    private fun extractKeywords(text: String): List<String> {
        if (text.isBlank()) return emptyList()
        val stopWords = setOf("the", "a", "an", "is", "are", "was", "were", "be", "been",
            "being", "have", "has", "had", "do", "does", "did", "will", "would", "could",
            "should", "may", "might", "shall", "can", "to", "of", "in", "for", "on",
            "with", "at", "by", "from", "as", "into", "through", "during", "before",
            "after", "above", "below", "between", "and", "but", "or", "nor", "not",
            "so", "yet", "both", "either", "neither", "each", "every", "all", "any",
            "little", "more", "most", "other", "some", "such", "no", "only", "own",
            "same", "than", "too", "very", "just", "because", "that", "this", "these",
            "those", "i", "me", "my", "we", "our", "you", "your", "he", "him", "his",
            "she", "her", "it", "its", "they", "them", "their")
        return text.lowercase()
            .replace(Regex("[^a-zA-Z 가-힣\\s]"), " ")
            .trim()
            .split(Regex("\\s+"))
            .filter { it.length > 1 && !stopWords.contains(it) }
            .distinct()
            .take(8)
    }

    fun getTotalRecordingCount(): Int = recordingCount
}

sealed class RecordingState {
    object Idle : RecordingState()
    object Recording : RecordingState()
}
