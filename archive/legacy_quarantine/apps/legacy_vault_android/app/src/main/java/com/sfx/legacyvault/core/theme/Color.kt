package com.sfx.legacyvault.core.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.material3.darkColorScheme

val Background = Color(0xFF0A0A0F)
val Surface = Color(0xFF1A1A2E)
val SecondarySurface = Color(0xFF2A2A3E)
val Accent = Color(0xFF00FF88)
val SecondaryAccent = Color(0xFF8B5CF6)
val Alert = Color(0xFFFF3860)
val TextPrimary = Color(0xFFE8E8ED)
val TextSecondary = Color(0xFF8E8EA0)

@Composable
fun LegacyVaultTheme(
    dark: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    androidx.compose.material3.MaterialTheme(
        colorScheme = darkColorScheme(
            primary = Accent,
            secondary = SecondaryAccent,
            tertiary = SecondaryAccent,
            background = Background,
            surface = Surface,
            onPrimary = Background,
            onSecondary = TextPrimary,
            onBackground = TextPrimary,
            onSurface = TextPrimary,
            error = Alert,
        ),
        typography = Typography,
        content = content
    )
}
