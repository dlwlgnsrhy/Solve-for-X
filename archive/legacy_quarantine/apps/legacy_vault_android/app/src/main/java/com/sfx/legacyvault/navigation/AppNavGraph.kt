package com.sfx.legacyvault.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.sfx.legacyvault.features.legacy_agent.LegacyAgentChatView
import com.sfx.legacyvault.features.legacy_agent.LegacyAgentMainView
import com.sfx.legacyvault.features.legacy_agent.LegacyAgentPersonaView
import com.sfx.legacyvault.features.home.HomeDashboardView
import com.sfx.legacyvault.features.onboarding.OnboardingFlowView
import com.sfx.legacyvault.features.soul_mining.RecordingView
import com.sfx.legacyvault.features.soul_mining.SoulMiningMainView
import com.sfx.legacyvault.features.soul_mining.VoicePlayerView
import com.sfx.legacyvault.features.guardian.GuardianDeadManView
import com.sfx.legacyvault.features.guardian.GuardianMainView
import com.sfx.legacyvault.features.guardian.HeirManagerView
import com.sfx.legacyvault.features.value_mapping.ValueMappingMainView
import com.sfx.legacyvault.core.models.VoiceLogEntry

@Composable
fun AppNavGraph(
    navController: NavHostController,
    startDestination: String = "onboarding"
) {
    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        composable("home") {
            HomeDashboardView(
                onNavigateToSoulMining = { navController.navigate("soul_mining") },
                onNavigateToRecording = { navController.navigate("recording") },
                onNavigateToGuardian = { navController.navigate("guardian") },
                onNavigateToLegacyAgent = { navController.navigate("legacy_agent") },
                onNavigateToValueMapping = { navController.navigate("value_mapping") }
            )
        }

        composable("soul_mining") {
            SoulMiningMainView(
                onNavigateToRecording = { navController.navigate("recording") }
            )
        }

        composable("recording") {
            RecordingView(
                onComplete = { navController.popBackStack() }
            )
        }

        composable("recording_player/{entryId}") { backStackEntry ->
            val entryId = backStackEntry.arguments?.getString("entryId") ?: ""
            VoicePlayerView(
                entry = VoiceLogEntry(id = entryId, title = "Sample Entry"),
                onBack = { navController.popBackStack() }
            )
        }

        composable("value_mapping") {
            ValueMappingMainView()
        }

        composable("guardian") {
            GuardianMainView(
                onNavigateDeadMan = { navController.navigate("guardian_deadman") },
                onNavigateHeir = { navController.navigate("guardian_heirs") },
                onNavigateBackup = { },
                onNavigateDecryption = { }
            )
        }

        composable("guardian_deadman") {
            GuardianDeadManView(
                onBack = { navController.popBackStack() }
            )
        }

        composable("guardian_heirs") {
            HeirManagerView(
                onBack = { navController.popBackStack() }
            )
        }

        composable("legacy_agent") {
            LegacyAgentMainView(
                onNavigateToChat = { navController.navigate("legacy_chat") },
                onNavigateToPersona = { navController.navigate("legacy_persona") }
            )
        }

        composable("legacy_chat") {
            LegacyAgentChatView(
                onBack = { navController.popBackStack() }
            )
        }

        composable("legacy_persona") {
            LegacyAgentPersonaView(
                onBack = { navController.popBackStack() }
            )
        }

        composable("onboarding") {
            OnboardingFlowView(
                onComplete = {
                    navController.navigate("home") {
                        popUpTo("onboarding") { inclusive = true }
                    }
                }
            )
        }
    }
}
