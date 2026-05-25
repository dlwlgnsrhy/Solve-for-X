package com.sfx.legacyvault.features.guardian

import android.util.Log
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import com.sfx.legacyvault.core.models.InheritanceContact
import com.sfx.legacyvault.core.util.Constants

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HeirManagerView(
    onBack: () -> Unit = {},
    viewModel: GuardianVM = androidx.lifecycle.viewmodel.compose.viewModel()
) {
    val heirs by viewModel.heirs.collectAsState(initial = emptyList())
    var showAddDialog by remember { mutableStateOf(false) }
    var editingHeir by remember { mutableStateOf<InheritanceContact?>(null) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Inheritance Heirs", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { showAddDialog = true }) {
                        Icon(Icons.Default.Add, "Add Heir")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showAddDialog = true },
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = Color.Black
            ) {
                Icon(Icons.Default.Add, "Add Heir")
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (heirs.isEmpty()) {
                Box(

                    modifier = Modifier
                        .fillMaxSize()
                        .padding(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            Icons.Default.PeopleOutline,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(64.dp)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            "No heirs added yet",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            "Add inheritance contacts to secure your legacy",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(heirs, key = { it.id }) { heir ->
                        HeirItem(
                            heir = heir,
                            onEdit = { editingHeir = it },
                            onDelete = {}

                        )
                    }
                }
            }
        }
    }

    // Add/Edit Heir Dialog
    if (showAddDialog || editingHeir != null) {
        HeirDialog(
            heir = editingHeir,
            onDismiss = {
                showAddDialog = false
                editingHeir = null
            },
            onSave = { name, email, relationship ->
                if (editingHeir != null) {
                    viewModel.updateHeir(editingHeir!!.copy(name = name, email = email, relationship = relationship))
                } else {
                    viewModel.addHeir(InheritanceContact(name = name, email = email, relationship = relationship))
                }
                showAddDialog = false
                editingHeir = null
            }
        )
    }
}

@Composable
private fun HeirItem(
    heir: InheritanceContact,
    onEdit: (InheritanceContact) -> Unit,
    onDelete: (InheritanceContact) -> Unit
) {
    val relationshipColor = when (heir.relationship.lowercase()) {
        Constants.Relationship.SPOUSE -> Color(0xFF8B5CF6)
        Constants.Relationship.CHILD -> Color(0xFF4CAF50)
        Constants.Relationship.FRIEND -> Color(0xFF2196F3)
        Constants.Relationship.ORGANIZATION -> Color(0xFFFF9800)
        else -> Color(0xFF607D8B)
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onEdit(heir) },
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(

                modifier = Modifier
                    .size(48.dp)
                    .background(relationshipColor.copy(alpha = 0.2f), RoundedCornerShape(24.dp)),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    heir.name.ifEmpty { "?" }[0].toString().uppercase(),
                    style = MaterialTheme.typography.titleMedium,
                    color = relationshipColor,
                    fontWeight = FontWeight.Bold
                )
            }

            Spacer(modifier = Modifier.width(16.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    heir.name,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    heir.email,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Badge(color = relationshipColor) {

                Text(
                    heir.relationship.take(1).uppercase(),
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.White
                )
            }
        }
    }
}

@Composable
private fun Badge(
    modifier: Modifier = Modifier,
    color: Color,
    content: @Composable BoxScope.() -> Unit = {}
) {
    Box(
        modifier = modifier
            .size(32.dp)
            .background(color, RoundedCornerShape(16.dp)),
        contentAlignment = Alignment.Center,
        content = content
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun HeirDialog(
    heir: InheritanceContact?,
    onDismiss: () -> Unit,
    onSave: (name: String, email: String, relationship: String) -> Unit
) {
    var name by remember { mutableStateOf(heir?.name ?: "") }
    var email by remember { mutableStateOf(heir?.email ?: "") }
    var relationship by remember { mutableStateOf(heir?.relationship ?: Constants.Relationship.FRIEND) }

    val relationships = listOf(
        Constants.Relationship.SPOUSE to "Spouse",
        Constants.Relationship.CHILD to "Child",
        Constants.Relationship.FRIEND to "Friend",
        Constants.Relationship.ORGANIZATION to "Organization"
    )

    androidx.compose.material3.AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                if (heir != null) "Edit Heir" else "Add Heir",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Full Name") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Spacer(modifier = Modifier.height(12.dp))
                OutlinedTextField(
                    value = email,
                    onValueChange = { email = it },
                    label = { Text("Email Address") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    "Relationship",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(8.dp))
                relationships.forEach { (value, label) ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { relationship = value }
                            .padding(vertical = 8.dp)
                    ) {
                        RadioButton(
                            selected = relationship == value,
                            onClick = { relationship = value }
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(label)
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (name.isNotBlank()) {
                        onSave(name, email, relationship)
                    }
                },
                enabled = name.isNotBlank()
            ) {
                Text(if (heir != null) "Update" else "Add")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
