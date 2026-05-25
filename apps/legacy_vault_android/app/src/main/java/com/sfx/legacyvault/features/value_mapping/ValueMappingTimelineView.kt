package com.sfx.legacyvault.features.value_mapping

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sfx.legacyvault.core.models.VoiceLogEntry
import com.sfx.legacyvault.core.theme.Accent
import com.sfx.legacyvault.core.theme.Background

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ValueMappingTimelineView(
    entries: List<VoiceLogEntry>,
    onBack: () -> Unit = {},
    onEntryClick: (VoiceLogEntry) -> Unit = {}
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Timeline", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp)
                .background(Background)
        ) {
            if (entries.isEmpty()) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "No timeline entries",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    verticalArrangement = Arrangement.spacedBy(0.dp)
                ) {
                    items(entries, key = { it.id }) { entry ->
                        TimelineEntryItem(
                            entry = entry,
                            isLast = false,
                            onClick = { onEntryClick(entry) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun TimelineEntryItem(
    entry: VoiceLogEntry,
    isLast: Boolean,
    onClick: () -> Unit
) {
    var isExpanded by remember { mutableStateOf(false) }

    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.width(2.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(16.dp)
                        .border(
                            1.dp,
                            Accent,
                            RoundedCornerShape(8.dp)
                        )
                        .background(Accent.copy(alpha = 0.3f), RoundedCornerShape(8.dp))
                )
                if (!isLast) {
                    Box(
                        modifier = Modifier
                            .width(2.dp)
                            .height(40.dp)
                            .background(Accent.copy(alpha = 0.3f))
                    )
                }
            }

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(onClick = {
                        isExpanded = !isExpanded
                        onClick()
                    }),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
            ) {
                Column(modifier = Modifier.padding(12.dp)) {
                    Box(
                        modifier = Modifier
                            .background(
                                Accent.copy(alpha = 0.15f),
                                RoundedCornerShape(8.dp)
                            )
                            .padding(horizontal = 8.dp, vertical = 4.dp)
                    ) {
                        Text(
                            text = formatEntryDate(entry.recordingDate),
                            style = MaterialTheme.typography.labelMedium,
                            color = Accent,
                            fontWeight = FontWeight.SemiBold
                        )
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    if (entry.keywords.isNotEmpty()) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            entry.keywords.take(4).forEach { keyword ->
                                androidx.compose.material3.FilterChip(
                                    onClick = { },
                                    colors = androidx.compose.material3.FilterChipDefaults.filterChipColors(
                                        containerColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f)
                                    ),
                                    label = {
                                        Text(keyword)
                                    },
                                    selected = false
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(6.dp))

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = SentimentEmoji(entry.sentiment),
                            style = MaterialTheme.typography.bodyLarge
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = getSentimentLabel(entry.sentiment),
                            style = MaterialTheme.typography.bodySmall,
                            color = getSentimentColor(entry.sentiment)
                        )
                    }

                    if (isExpanded) {
                        Spacer(modifier = Modifier.height(10.dp))
                        Divider()
                        Spacer(modifier = Modifier.height(8.dp))
                        entry.title.takeIf { it.isNotBlank() }?.let { title ->
                            Text(
                                text = title,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                        }
                        entry.transcript.takeIf { it.isNotBlank() }?.let { transcript ->
                            Text(
                                text = if (transcript.length > 200) transcript.take(200) + "..." else transcript,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        }
    }
}

internal fun formatEntryDate(timestampMs: Long): String {
    if (timestampMs <= 0) return "Unknown date"
    val seconds = timestampMs / 1000
    val day = (seconds % 86400L) / 3600L
    return "Day ${day + 1}"
}

private fun SentimentEmoji(sentiment: Int): String {
    return when {
        sentiment > 20 -> "😊"
        sentiment > 0 -> "🙂"
        sentiment == 0 -> "😐"
        sentiment > -20 -> "🙁"
        else -> "😔"
    }
}

internal fun getSentimentColor(sentiment: Int): Color {
    return when {
        sentiment > 20 -> Color(0xFF4CAF50)
        sentiment > 0 -> Color(0xFF8BC34A)
        sentiment == 0 -> Color(0xFF9E9E9E)
        sentiment > -20 -> Color(0xFFFF9800)
        else -> Color(0xFFFF3860)
    }
}

internal fun getSentimentLabel(sentiment: Int): String {
    return when {
        sentiment > 40 -> "Very Positive"
        sentiment > 20 -> "Positive"
        sentiment > 0 -> "Slightly Positive"
        sentiment == 0 -> "Neutral"
        sentiment > -20 -> "Slightly Negative"
        sentiment > -40 -> "Negative"
        else -> "Very Negative"
    }
}
