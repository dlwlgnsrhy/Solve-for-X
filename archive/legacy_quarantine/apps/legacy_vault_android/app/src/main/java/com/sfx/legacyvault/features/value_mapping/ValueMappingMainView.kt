package com.sfx.legacyvault.features.value_mapping

import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cloud
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Insights
import androidx.compose.material.icons.filled.Note
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sfx.legacyvault.core.theme.Accent
import com.sfx.legacyvault.core.theme.Background
import com.sfx.legacyvault.core.theme.SecondaryAccent

@Composable
fun ValueMappingMainView(
    onNavigateToKeywordCloud: () -> Unit = {},
    onNavigateToTimeline: () -> Unit = {},
    viewModel: ValueMappingVM = viewModel()
) {
    val state by viewModel.state.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Value Mapping",
                style = MaterialTheme.typography.headlineLarge,
                color = MaterialTheme.colorScheme.onBackground
            )
            Text(
                text = "Track your values over time",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onNavigateToKeywordCloud)
                .padding(bottom = 4.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = "Keyword Cloud",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.height(8.dp))
                KeywordCloudThumbnail(viewModel = viewModel)
            }
        }

        val cardHeight = 120.dp
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(cardHeight),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            TimelinePreviewCard(
                modifier = Modifier
                    .wrapContentWidth()
                    .height(cardHeight),
                viewModel = viewModel
            )
            InsightsCard(
                modifier = Modifier
                    .wrapContentWidth()
                    .height(cardHeight),
                viewModel = viewModel
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        LatestEntriesCard(viewModel = viewModel)
    }
}

@Composable
private fun KeywordCloudThumbnail(viewModel: ValueMappingVM) {
    val state by viewModel.state.collectAsState()
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(80.dp),
        contentAlignment = Alignment.Center
    ) {
        when (state) {
            is ValueMappingVM.State.Loading -> {
                Text(
                    text = "Loading...",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            is ValueMappingVM.State.Ready -> {
                val keywords = (state as ValueMappingVM.State.Ready).keywords.take(8)
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                    keywords.forEachIndexed { index, keyword ->
                        val fontSize = when (index % 3) {
                            0 -> MaterialTheme.typography.bodyLarge
                            1 -> MaterialTheme.typography.bodyMedium
                            else -> MaterialTheme.typography.labelLarge
                        }
                        val color = when (index % 4) {
                            0 -> Accent
                            1 -> SecondaryAccent
                            2 -> Color(0xFFFFB74D)
                            else -> Color(0xFFE0E0E0)
                        }
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = keyword,
                            style = fontSize,
                            color = color,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun TimelinePreviewCard(modifier: Modifier = Modifier, viewModel: ValueMappingVM) {
    val state by viewModel.state.collectAsState()
    Card(
        modifier = modifier
            .clickable { },
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                Icons.Default.DateRange,
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = Accent
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Timeline",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(2.dp))
            when (state) {
                is ValueMappingVM.State.Loading -> Text(
                    text = "...",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                is ValueMappingVM.State.Ready -> Text(
                    text = "${(state as ValueMappingVM.State.Ready).entries.size} entries",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun InsightsCard(modifier: Modifier = Modifier, viewModel: ValueMappingVM) {
    val state by viewModel.state.collectAsState()
    Card(
        modifier = modifier
            .clickable { },
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                Icons.Default.Insights,
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = SecondaryAccent
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Sentiment",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(2.dp))
            when (state) {
                is ValueMappingVM.State.Loading -> Text(
                    text = "...",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                is ValueMappingVM.State.Ready -> Text(
                    text = "${viewModel.calculateSentiment()} Avg",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun LatestEntriesCard(viewModel: ValueMappingVM) {
    val state by viewModel.state.collectAsState()
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { },
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.Note,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp),
                        tint = Accent
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Latest Entries",
                        style = MaterialTheme.typography.titleSmall,
                        color = MaterialTheme.colorScheme.onSurface,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(60.dp)
                    .background(
                        MaterialTheme.colorScheme.onSurface.copy(alpha = 0.05f),
                        RoundedCornerShape(8.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Tap to view entries",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
