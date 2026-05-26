package com.sfx.legacyvault.features.soul_mining

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sfx.legacyvault.core.models.VoiceLogEntry
import java.util.concurrent.TimeUnit

@Composable
fun RecordingView(
    onComplete: (VoiceLogEntry) -> Unit = {},
    viewModel: RecordingSessionVM = viewModel()
) {
    val state by viewModel.state.collectAsState()
    val transcript by viewModel.transcript.collectAsState()

    var isRecording by remember { mutableStateOf(state == RecordingState.Recording) }
    var durationMs by remember { mutableLongStateOf(0L) }
    var waveformValues by remember { mutableStateOf(FloatArray(20) { 0.5f }) }

    LaunchedEffect(isRecording) {
        if (isRecording) {
            var start = System.currentTimeMillis()
            while (isRecording) {
                durationMs = System.currentTimeMillis() - start
                waveformValues = FloatArray(20) {
                    kotlin.random.Random.nextFloat() * 0.8f + 0.2f
                }
                kotlinx.coroutines.delay(100L)
            }
        }
    }

    LaunchedEffect(state) {
        isRecording = state == RecordingState.Recording
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Recording",
                    style = MaterialTheme.typography.headlineMedium,
                    color = MaterialTheme.colorScheme.onBackground
                )
                IconButton(onClick = {
                    isRecording = false
                    if (!isRecording) {
                        val entry = viewModel.stopRecording()
                        entry?.let { onComplete(it) }
                    }
                }) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Stop & Save",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(12.dp)
                        .clip(CircleShape)
                        .background(
                            if (isRecording) MaterialTheme.colorScheme.primary.copy(alpha = 0.3f)
                            else MaterialTheme.colorScheme.error.copy(alpha = 0.5f)
                        )
                )
                Text(
                    text = if (isRecording) "REC" else "Finished",
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (isRecording) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.error
                )
            }

            WaveformVisualization(
                values = waveformValues,
                isRecording = isRecording
            )

            Text(
                text = formatTimer(durationMs),
                style = MaterialTheme.typography.displaySmall,
                color = MaterialTheme.colorScheme.onBackground
            )

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp)
                ) {
                    if (transcript.isNotBlank()) {
                        Text(
                            text = transcript,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurface,
                            modifier = Modifier.fillMaxSize()
                        )
                    } else {
                        Text(
                            text = if (isRecording) "Listening..." else "No transcript yet",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                        )
                    }
                }
            }

            if (isRecording) {
                FilledTonalButton(
                    onClick = {
                        isRecording = false
                        val entry = viewModel.stopRecording()
                        entry?.let { onComplete(it) }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 32.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Stop & Save",
                        style = MaterialTheme.typography.titleMedium
                    )
                }
            }
        }
    }
}

@Composable
private fun WaveformVisualization(
    values: FloatArray,
    isRecording: Boolean
) {
    val infiniteTransition = rememberInfiniteTransition(label = "waveform pulse")
    val pulseAlpha by infiniteTransition.animateFloat(
        initialValue = 0.4f,
        targetValue = 1.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(800, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulse alpha"
    )

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(80.dp),
        horizontalArrangement = Arrangement.spacedBy(3.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        for (i in values.indices) {
            val targetHeight = values.getOrElse(i) { 0.5f }
            val animatedHeight by animateFloatAsState(
                targetValue = if (isRecording) targetHeight else 0.1f,
                animationSpec = tween(durationMillis = 200),
                label = "waveform bar $i"
            )
            val alpha = if (isRecording) (0.3f + animatedHeight * 0.7f) * pulseAlpha else 0.2f
            Box(
                modifier = Modifier
                    .fillMaxHeight(animatedHeight)
                    .fillMaxWidth(0.15f)
                    .background(
                        MaterialTheme.colorScheme.primary.copy(alpha = alpha)
                    )
            )
        }
    }
}

private fun formatTimer(ms: Long): String {
    val seconds = (ms / 1000) % 60
    val minutes = (ms / 1000 / 60) % 60
    val hours = ms / 1000 / 3600
    return if (hours > 0) {
        String.format("%02d:%02d:%02d", hours, minutes, seconds)
    } else {
        String.format("%02d:%02d", minutes, seconds)
    }
}
