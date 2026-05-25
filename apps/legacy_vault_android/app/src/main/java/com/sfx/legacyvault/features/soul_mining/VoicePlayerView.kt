package com.sfx.legacyvault.features.soul_mining

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.foundation.layout.width
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.sfx.legacyvault.core.models.VoiceLogEntry
import java.util.concurrent.TimeUnit

@Composable
fun VoicePlayerView(
    entry: VoiceLogEntry,
    onBack: () -> Unit = {},
    onSummary: () -> Unit = {}
) {
    var isPlaying by remember { mutableStateOf(false) }
    var progress by remember { mutableFloatStateOf(0f) }
    var currentElapsed by remember { mutableLongStateOf(0L) }

    LaunchedEffect(isPlaying, entry.durationMs) {
        if (isPlaying) {
            var start = System.currentTimeMillis() - currentElapsed
            while (isPlaying) {
                val diff = System.currentTimeMillis() - start
                if (diff >= entry.durationMs.toLong()) {
                    isPlaying = false
                    progress = 1f
                    currentElapsed = 0L
                    break
                }
                progress = diff.toFloat() / entry.durationMs.toFloat()
                currentElapsed = diff
                kotlinx.coroutines.delay(100L)
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(24.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack) {
                Icon(
                    imageVector = Icons.Default.ArrowBack,
                    contentDescription = "Back",
                    tint = MaterialTheme.colorScheme.onBackground
                )
            }
            Text(
                text = entry.title,
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.onBackground
            )
            IconButton(onClick = onSummary) {
                Icon(
                    imageVector = Icons.Default.ArrowBack,
                    contentDescription = "Summary",
                    tint = MaterialTheme.colorScheme.primary
                )
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        Box(
            modifier = Modifier.fillMaxWidth().height(200.dp),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Box(
                    modifier = Modifier
                        .size(120.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                        contentDescription = null,
                        modifier = Modifier.size(48.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = formatDuration(currentElapsed.toInt()),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        LinearProgressIndicator(
            progress = { progress.coerceIn(0f, 1f) },
            modifier = Modifier
                .fillMaxWidth()
                .height(6.dp)
                .clip(CircleShape),
            color = MaterialTheme.colorScheme.primary,
            trackColor = MaterialTheme.colorScheme.surface,
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = formatDuration(currentElapsed.toInt()),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = formatDuration(entry.durationMs),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        FilledTonalButton(
            onClick = { isPlaying = !isPlaying },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 48.dp)
        ) {
            Icon(
                imageVector = if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                contentDescription = null,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = if (isPlaying) "Pause" else "Play",
                style = MaterialTheme.typography.titleMedium
            )
        }

        Spacer(modifier = Modifier.height(32.dp))

        entry.transcript.takeIf { it.isNotBlank() }?.let { transcript ->
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Transcript",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurface,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    highlightCurrentWords(
                        transcript = transcript,
                        progress = progress
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        if (entry.sentiment != 0) {
            SentimentBarLarge(sentiment = entry.sentiment)
        }
    }
}

@Composable
private fun highlightCurrentWords(transcript: String, progress: Float) {
    val words = transcript.trim().split(Regex("\\s+")).filter { it.isNotBlank() }
    val currentIndex = (progress * words.size).toInt().coerceIn(0, words.size - 1)
    val annotatedString = buildAnnotatedString {
        words.forEachIndexed { index, word ->
            if (index <= currentIndex) {
                pushStyle(SpanStyle(
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Bold,
                    textDecoration = TextDecoration.Underline
                ))
                append(word)
                pop()
            } else {
                append(word)
            }
            if (index < words.size - 1) append(" ")
        }
    }
    Text(
        text = annotatedString,
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
}

@Composable
private fun SentimentBarLarge(sentiment: Int) {
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Sentiment",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            val sentimentText = when {
                sentiment > 0 -> "Positive"
                sentiment < 0 -> "Negative"
                else -> "Neutral"
            }
            val sentimentColor = if (sentiment > 0) Color(0xFF4CAF50) else Color(0xFFFF5252)
            Text(
                text = sentimentText,
                style = MaterialTheme.typography.labelMedium,
                color = sentimentColor
            )
        }
        Spacer(modifier = Modifier.height(8.dp))
        Row(
            modifier = Modifier.fillMaxWidth().height(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            val positiveWidth = (sentiment / 200f + 0.5f)
            Box(
                modifier = Modifier
                    .weight(positiveWidth)
                    .height(8.dp)
                    .clip(CircleShape)
                    .background(Color(0xFF4CAF50))
            )
            Box(
                modifier = Modifier
                    .weight(maxOf(0f, 1f - positiveWidth))
                    .height(8.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFFF5252))
            )
        }
    }
}

private fun formatDuration(ms: Int): String {
    val secs = TimeUnit.MILLISECONDS.toSeconds(ms.toLong())
    val mins = TimeUnit.MILLISECONDS.toMinutes(ms.toLong())
    val remainingSecs = secs - TimeUnit.MINUTES.toSeconds(mins)
    return String.format("%02d:%02d", mins, remainingSecs)
}
