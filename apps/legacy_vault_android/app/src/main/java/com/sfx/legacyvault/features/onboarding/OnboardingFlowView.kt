package com.sfx.legacyvault.features.onboarding

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.sfx.legacyvault.core.theme.Accent
import com.sfx.legacyvault.core.theme.Background
import com.sfx.legacyvault.core.theme.SecondaryAccent

@Composable
fun OnboardingFlowView(
    onComplete: () -> Unit = {}
) {
    var currentPage by remember { mutableStateOf(0) }
    var privacyAccepted by remember { mutableStateOf(false) }
    var passphrase by remember { mutableStateOf("") }
    var confirmPassphrase by remember { mutableStateOf("") }
    var showPassphraseField by remember { mutableStateOf(false) }
    var passphraseConfirmed by remember { mutableStateOf(false) }
    var isComplete by remember { mutableStateOf(false) }

    val pageCount = 4

    if (isComplete) {
        LaunchAppScreen(onComplete = onComplete)
        return
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Background)
            .verticalScroll(rememberScrollState())
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            repeat(pageCount) { index ->
                Box(
                    modifier = Modifier
                        .size(if (index == currentPage) 10.dp else 8.dp)
                        .clip(CircleShape)
                        .background(
                            if (index == currentPage) Accent
                            else if (index < currentPage) SecondaryAccent
                            else Color.White.copy(alpha = 0.2f)
                        )
                        .clickable { currentPage = index }
                        .weight(1f)
                )
                if (index < pageCount - 1) {
                    Box(
                        modifier = Modifier.width(6.dp)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        when (currentPage) {
            0 -> WelcomeCard { currentPage = 1 }
            1 -> PrivacyCard(
                accepted = privacyAccepted,
                onAcceptedChange = { privacyAccepted = it },
                onNext = { currentPage = 2 }
            )
            2 -> PassphraseCard(
                passphrase = passphrase,
                onPassphraseChange = { passphrase = it },
                showPassphrase = showPassphraseField,
                onTogglePassphrase = { showPassphraseField = !showPassphraseField },
                confirmPassphrase = confirmPassphrase,
                onConfirmPassphraseChange = { confirmPassphrase = it },
                onConfirmShowPassphrase = { showPassphraseField = !showPassphraseField },
                onNext = {
                    passphraseConfirmed = passphrase == confirmPassphrase && passphrase.isNotBlank()
                    if (passphraseConfirmed) currentPage = 3
                }
            )
            3 -> CompletionCard {
                isComplete = true
            }
        }
    }
}

@Composable
private fun WelcomeCard(onNext: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            Icons.Default.Shield,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = Accent
        )
        Spacer(modifier = Modifier.height(24.dp))
        Text(
            text = "Welcome to Solve for X",
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.onBackground,
            textAlign = TextAlign.Center,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            text = "Your personal legacy vault. Secure, private, and always yours.",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(48.dp))
        androidx.compose.material3.Button(
            onClick = onNext,
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp),
            shape = RoundedCornerShape(12.dp),
            colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                containerColor = Accent
            )
        ) {
            Text(
                text = "Get Started",
                style = MaterialTheme.typography.titleMedium,
                color = Color.Black
            )
        }
    }
}

@Composable
private fun PrivacyCard(
    accepted: Boolean,
    onAcceptedChange: (Boolean) -> Unit,
    onNext: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            Icon(
                Icons.Default.Lock,
                contentDescription = null,
                modifier = Modifier.size(56.dp),
                tint = SecondaryAccent
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "Privacy First",
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = "Your data is encrypted end-to-end. We never see your content. Your legacy stays yours.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(24.dp))

            Row(
                modifier = Modifier
                    .clickable { onAcceptedChange(!accepted) },
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(24.dp)
                        .clip(RoundedCornerShape(4.dp))
                        .background(
                            if (accepted) Accent else Color.Transparent,
                            RoundedCornerShape(4.dp)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                        if (accepted) {
                            Icon(
                                Icons.Default.Check,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp),
                                tint = Color.Black
                            )
                        }
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = "I accept the privacy terms",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface
                    )
            }
        }

        androidx.compose.material3.Button(
            onClick = onNext,
            enabled = accepted,
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp),
            shape = RoundedCornerShape(12.dp),
            colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                containerColor = Accent
            )
        ) {
            Text(
                text = "Continue",
                style = MaterialTheme.typography.titleMedium,
                color = Color.Black
            )
        }
    }
}

@Composable
private fun PassphraseCard(
    passphrase: String,
    onPassphraseChange: (String) -> Unit,
    showPassphrase: Boolean,
    onTogglePassphrase: () -> Unit,
    confirmPassphrase: String,
    onConfirmPassphraseChange: (String) -> Unit,
    onConfirmShowPassphrase: () -> Unit,
    onNext: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            Text(
                text = "Create Passphrase",
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.onBackground,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = "Create a secure passphrase to protect your legacy vault. Keep it safe — it cannot be recovered.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(24.dp))

            OutlinedSecureTextField(
                value = passphrase,
                onValueChange = onPassphraseChange,
                show = showPassphrase,
                onToggle = onTogglePassphrase,
                hint = "Enter passphrase"
            )
            Spacer(modifier = Modifier.height(12.dp))
            OutlinedSecureTextField(
                value = confirmPassphrase,
                onValueChange = onConfirmPassphraseChange,
                show = showPassphrase,
                onToggle = onConfirmShowPassphrase,
                hint = "Confirm passphrase"
            )
            if (passphrase.isNotBlank() && confirmPassphrase.isNotBlank() && passphrase != confirmPassphrase) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "Passphrases do not match",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFFFF3860)
                )
            }
        }

        androidx.compose.material3.Button(
            onClick = onNext,
            enabled = passphrase == confirmPassphrase && passphrase.length >= 4,
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp),
            shape = RoundedCornerShape(12.dp),
            colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                containerColor = Accent
            )
        ) {
            Text(
                text = "Continue",
                style = MaterialTheme.typography.titleMedium,
                color = Color.Black
            )
        }
    }
}

@Composable
private fun OutlinedSecureTextField(
    value: String,
    onValueChange: (String) -> Unit,
    show: Boolean,
    onToggle: () -> Unit,
    hint: String
) {
    androidx.compose.material3.OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        placeholder = { Text(hint, color = MaterialTheme.colorScheme.onSurfaceVariant) },
        textStyle = MaterialTheme.typography.bodyLarge,
        visualTransformation = if (show) androidx.compose.ui.text.input.VisualTransformation.None else androidx.compose.ui.text.input.PasswordVisualTransformation(),
        modifier = Modifier.fillMaxWidth(),
        singleLine = true,
        trailingIcon = {
            androidx.compose.material3.IconButton(onClick = onToggle) {
                Icon(
                    imageVector = androidx.compose.material.icons.Icons.Default.Check,
                    contentDescription = if (show) "Hide" else "Show",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(20.dp)
                )
            }
        },
        shape = RoundedCornerShape(8.dp),
        colors = androidx.compose.material3.OutlinedTextFieldDefaults.colors(
            focusedContainerColor = MaterialTheme.colorScheme.surface,
            unfocusedContainerColor = MaterialTheme.colorScheme.surface,
            cursorColor = Accent
        )
    )
}

@Composable
private fun CompletionCard(onComplete: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            Icons.Default.Check,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = Accent
        )
        Spacer(modifier = Modifier.height(24.dp))
        Text(
            text = "You're Ready!",
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.onBackground,
            textAlign = TextAlign.Center,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(12.dp))
        Text(
            text = "Your legacy vault is set up and ready to protect what matters most to you.",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(48.dp))
        androidx.compose.material3.Button(
            onClick = onComplete,
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp),
            shape = RoundedCornerShape(12.dp),
            colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                containerColor = Accent
            )
        ) {
            Text(
                text = "Launch App",
                style = MaterialTheme.typography.titleMedium,
                color = Color.Black
            )
        }
    }
}

@Composable
private fun LaunchAppScreen(onComplete: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Background),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        CircularProgressIndicator(
            modifier = Modifier.size(60.dp),
            color = Accent,
            strokeWidth = 4.dp
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "Launching...",
            style = MaterialTheme.typography.titleLarge,
            color = Accent
        )
    }
    androidx.compose.runtime.LaunchedEffect(Unit) {
        kotlinx.coroutines.delay(1500L)
        onComplete()
    }
}
