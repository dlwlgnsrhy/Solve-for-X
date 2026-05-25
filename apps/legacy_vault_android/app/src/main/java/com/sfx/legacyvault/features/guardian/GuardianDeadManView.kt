package com.sfx.legacyvault.features.guardian

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.sfx.legacyvault.core.util.Constants
import com.sfx.legacyvault.features.guardian.GuardianVM
import com.sfx.legacyvault.features.guardian.GuardianVM.Status
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GuardianDeadManView(
    onBack: () -> Unit = {},
    viewModel: GuardianVM = androidx.lifecycle.viewmodel.compose.viewModel()
) {
    val switchStatus by viewModel.switchStatus.collectAsState()
    var daysInput by remember { mutableIntStateOf(Constants.DEFAULT_VAULT_DEADLINE_DAYS) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Dead Man Switch", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back")
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
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            CurrentStatusCard(status = switchStatus)

            WarningCard()

            Spacer(modifier = Modifier.height(8.dp))

            Card(

                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        "Check-in Interval (days)",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        OutlinedTextField(
                            value = daysInput.toString(),
                            onValueChange = { newValue ->
                                daysInput = newValue.toIntOrNull()
                                    ?.coerceIn(1, 365)
                                    ?: daysInput
                            },
                            keyboardOptions = KeyboardOptions(
                                keyboardType = KeyboardType.Number
                            ),
                            modifier = Modifier
                                .width(80.dp)
                                .height(56.dp),
                            singleLine = true,
                            colors = OutlinedTextFieldDefaults.colors()
                        )
                        Text(
                            "days",
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                    Text(
                        "If you don't check in within this period, your backup will be triggered",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Alert action buttons
            Card(
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        "Alert Actions",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedButton(
                        onClick = {},

                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.Notifications, "Alert")
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Schedule Alert Before Deadline")
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedButton(
                        onClick = {},

                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(Icons.Default.People, "Contacts")
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Configure Notification Contacts")
                    }
                }
            }

            Button(

                onClick = {
                    viewModel.setupSwitch(daysInput)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Default.PlayArrow, "Start")
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    "Start Dead Man Switch",
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@Composable
private fun CurrentStatusCard(status: Status) {
    val (statusText, statusColor, icon) = when (status) {
        is Status.Active -> Triple("Monitoring Active", Color(0xFF4CAF50), Icons.Default.Verified)
        is Status.Paused -> Triple("Switch Paused", Color(0xFFFFC107), Icons.Default.Pause)
        is Status.Expired -> Triple("Switch Expired", Color(0xFFFF3860), Icons.Default.Warning)
    }

    Card(
        colors = CardDefaults.cardColors(
            containerColor = statusColor.copy(alpha = 0.1f)
        ),
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
                tint = statusColor,
                modifier = Modifier.size(48.dp)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column {
                Text(
                    statusText,
                    style = MaterialTheme.typography.headlineSmall,
                    color = statusColor,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    "Check your vault before the deadline",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun WarningCard() {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFFFFF3E0)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.Top
        ) {
            Icon(
                Icons.Default.Warning,
                contentDescription = null,
                tint = Color(0xFFFF9800),
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                "If you don't ping in time, your backup will be sent to your designated heirs.",
                style = MaterialTheme.typography.bodySmall,
                color = Color(0xFFE65100)
            )
        }
    }
}
