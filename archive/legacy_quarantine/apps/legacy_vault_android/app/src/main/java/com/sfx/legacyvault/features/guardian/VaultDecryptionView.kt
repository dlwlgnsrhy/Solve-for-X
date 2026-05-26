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
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VaultDecryptionView(
    passphrase: String = "",
    onSuccess: () -> Unit = {},
    onBack: () -> Unit = {},
    viewModel: GuardianVM = androidx.lifecycle.viewmodel.compose.viewModel()
) {
    var enteredPassphrase by remember { mutableStateOf(passphrase) }
    var isPasswordVisible by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var isLoading by remember { mutableStateOf(false) }
    var showBiometricPrompt by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Unlock Vault", fontWeight = FontWeight.Bold) },
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
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(

                Icons.Default.Lock,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(72.dp)
            )
            Spacer(modifier = Modifier.height(24.dp))

            Text(
                text = "Enter Passphrase",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(8.dp))

            Text(
                "Your vault is encrypted. Enter your passphrase to unlock.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
            Spacer(modifier = Modifier.height(32.dp))

            OutlinedTextField(

                value = enteredPassphrase,
                onValueChange = {
                    enteredPassphrase = it
                    errorMessage = null
                },
                label = { Text("Vault Passphrase") },
                placeholder = { Text("Enter your passkey or passphrase") },
                visualTransformation = if (isPasswordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                trailingIcon = {
                    IconButton(onClick = { isPasswordVisible = !isPasswordVisible }) {
                        Icon(
                            if (isPasswordVisible) Icons.Default.Visibility else Icons.Default.VisibilityOff,
                            contentDescription = if (isPasswordVisible) "Hide password" else "Show password"
                        )
                    }
                },
                isError = errorMessage != null
            )

            errorMessage?.let { error ->
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    error,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            Button(

                onClick = {
                    if (enteredPassphrase.isBlank()) {
                        errorMessage = "Please enter a passphrase"
                        return@Button
                    }
                    isLoading = true
                    viewModel.unlockVault(enteredPassphrase) { success ->
                        isLoading = false
                        if (success) {
                            errorMessage = null
                            onSuccess()
                        } else {
                            errorMessage = "Incorrect passphrase. Please try again."
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(12.dp),
                enabled = !isLoading
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp,
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                }
                Icon(Icons.Default.LockOpen, "Lock")
                Spacer(modifier = Modifier.width(8.dp))
                Text("Unlock Vault", fontWeight = FontWeight.Bold)
            }

            Spacer(modifier = Modifier.height(16.dp))

            OutlinedButton(

                onClick = { showBiometricPrompt = true },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(12.dp),
                enabled = !isLoading
            ) {
                Icon(Icons.Default.Fingerprint, "Biometric")
                Spacer(modifier = Modifier.width(8.dp))
                Text("Use Passkey / Biometric")
            }

            Spacer(modifier = Modifier.height(24.dp))

            Row(

                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top
            ) {
                Icon(
                    Icons.Default.Info,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    "Uses your system passkey (PIN, pattern, or biometric). The vault remains encrypted until unlocked.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }

    if (showBiometricPrompt) {
        AndroidBiometricPrompt(
            onAuthenticationResult = { success ->
                showBiometricPrompt = false
                if (success) {
                    viewModel.unlockVaultWithBiometric { unlocked ->
                        if (unlocked) {
                            onSuccess()
                        }
                    }
                }
            },
            onDismiss = { showBiometricPrompt = false }
        )
    }
}

@Composable
private fun AndroidBiometricPrompt(
    onAuthenticationResult: (Boolean) -> Unit,
    onDismiss: () -> Unit
) {
    // Biometric stub - full implementation requires BiometricPrompt API
    onAuthenticationResult(false)

    DisposableEffect(Unit) {
        onDispose { onDismiss() }
    }
}
