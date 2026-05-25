package com.sfx.legacyvault.features.guardian

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp


@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GuardianMainView(
    onNavigateDeadMan: () -> Unit = {},
    onNavigateHeir: () -> Unit = {},
    onNavigateBackup: () -> Unit = {},
    onNavigateDecryption: () -> Unit = {},
    viewModel: GuardianVM = androidx.lifecycle.viewmodel.compose.viewModel()
) {
    val vaultCount by viewModel.vaultCount.collectAsState()
    val heirCount by viewModel.heirCount.collectAsState()
    val switchStatus by viewModel.switchStatus.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "Guardian Protocol",
                        fontWeight = FontWeight.Bold
                    )
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
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        "Digital Legacy Guardian",
                        style = MaterialTheme.typography.headlineSmall,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        "Secure your digital inheritance",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                IconButton(onClick = onNavigateDecryption) {
                    Icon(
                        Icons.Default.Lock,
                        contentDescription = "Vault Status",
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
            }

            Divider(color = MaterialTheme.colorScheme.outlineVariant)

            GuardianStatusCard(

                title = "Dead Man Switch",
                status = switchStatus,
                clickAction = onNavigateDeadMan
            )

            GuardianStatCard(
                title = "Vault Records",
                count = vaultCount,
                icon = Icons.Default.Folder,
                clickAction = onNavigateDecryption
            )

            GuardianStatCard(
                title = "Heirs",
                count = heirCount,
                icon = Icons.Default.People,
                clickAction = onNavigateHeir
            )

            GuardianStatCard(
                title = "Backup Status",
                count = vaultCount,
                icon = Icons.Default.CloudUpload,

                clickAction = onNavigateBackup
            )
        }
    }
}

@Composable
private fun GuardianStatusCard(
    title: String,
    status: GuardianVM.Status,
    clickAction: () -> Unit
) {
    val (bgColor, statusText, statusColor) = when (status) {
        is GuardianVM.Status.Active -> Triple(
            Color(0xFF1B5E20).copy(alpha = 0.15f),
            "Active",
            Color(0xFF4CAF50)
        )
        is GuardianVM.Status.Paused -> Triple(
            Color(0xFFF57F17).copy(alpha = 0.15f),
            "Paused",
            Color(0xFFFFC107)
        )
        is GuardianVM.Status.Expired -> Triple(
            Color(0xFFB71C1C).copy(alpha = 0.15f),
            "Expired",
            Color(0xFFFF3860)
        )
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = clickAction),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.bodyMedium)
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        statusText,
                        style = MaterialTheme.typography.headlineSmall,
                        color = statusColor,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        "tap to configure",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            Box(

                modifier = Modifier
                    .size(12.dp)
                    .background(statusColor, Shape.Circle)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Icon(
                Icons.Default.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun GuardianStatCard(
    title: String,
    count: Int,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    clickAction: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = clickAction),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(32.dp)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.bodyMedium)
                Text(
                    "$count",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
            }
            Icon(
                Icons.Default.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

private object Shape {
    val Circle = RoundedCornerShape(50)
}
