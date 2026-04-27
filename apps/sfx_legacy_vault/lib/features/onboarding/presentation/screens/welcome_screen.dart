import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_legacy_vault/core/constants/app_colors.dart';
import 'package:sfx_legacy_vault/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:sfx_legacy_vault/features/onboarding/presentation/screens/eula_screen.dart';

/// Welcome/landing screen shown before EULA acceptance.
/// Focuses on security messaging and trust building.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final welcomeAccepted = ref.watch(welcomeAcceptedProvider);
    final size = MediaQuery.of(context).size;

    if (welcomeAccepted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EulaScreen()),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Background ambient glow
            Positioned(
              top: -100,
              left: size.width / 2 - 200,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.neonGreen.withValues(alpha: 0.06),
                      AppColors.neonCyan.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.neonPink.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Animated shield lock icon
                  _buildHeroIcon(context),
                  const SizedBox(height: 28),

                  // App name
                  Text(
                    'SFX Legacy Vault',
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(
                      color: AppColors.neonGreen,
                      fontSize: 28,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 700.ms)
                      .slideY(begin: -0.3, end: 0, duration: 700.ms),

                  const SizedBox(height: 8),

                  // Korean subtitle
                  Text(
                    '데드맨스위치 디지털 유산 보관',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 450.ms, duration: 600.ms),

                  const SizedBox(height: 12),

                  // English tagline
                  Text(
                    "Your dead man's switch for the digital age.",
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 550.ms, duration: 600.ms),

                  const SizedBox(height: 40),

                  // Security headline
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          AppColors.neonGreen.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            AppColors.neonGreen.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          color: AppColors.neonGreen,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Military-Grade AES-256 Encryption',
                          style: TextStyle(
                            color: AppColors.neonGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 650.ms, duration: 600.ms),

                  const SizedBox(height: 16),

                  // Security First messaging
                  Text(
                    'Security First',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 600.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Your secrets never leave your device unencrypted.\n'
                    'We cannot read, access, or decrypt your data.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 750.ms, duration: 600.ms),

                  const SizedBox(height: 36),

                  // Trust badges row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _TrustBadge(
                        icon: Icons.lock_outline_rounded,
                        label: 'Zero-Knowledge',
                        desc: 'Server cannot decrypt',
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 850.ms, duration: 500.ms),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _TrustBadge(
                        icon: Icons.device_hub_rounded,
                        label: 'Client-Side Only',
                        desc: 'Keys stay on device',
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 950.ms, duration: 500.ms),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _TrustBadge(
                        icon: Icons.delete_sweep_rounded,
                        label: 'Auto-Delete',
                        desc: 'Gone after delivery',
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 1050.ms, duration: 500.ms),

                  const SizedBox(height: 50),

                  // Start button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(welcomeAcceptedProvider.notifier)
                            .acceptWelcome();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        foregroundColor: AppColors.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '시작하기',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 1150.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0, duration: 600.ms),

                  const SizedBox(height: 16),

                  // Bottom trust line
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: AppColors.textSecondary
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'No account required for security review',
                        style: TextStyle(
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 1250.ms, duration: 400.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroIcon(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating ring
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 2000),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.neonGreen.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ).animate().scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.15, 1.15),
              duration: 1500.ms,
              curve: Curves.easeInOut,
            ),
          ),
          // Inner ring
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 2000),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.neonCyan.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ).animate().scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(0.95, 0.95),
              duration: 1800.ms,
              curve: Curves.easeInOut,
            ),
          ),
          // Shield icon
          Icon(
            Icons.vpn_key_rounded,
            size: 48,
            color: AppColors.neonGreen,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.6, 0.6));
  }
}

/// Trust badge widget for the welcome screen.
class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;

  const _TrustBadge({
    required this.icon,
    required this.label,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.6),
        border: Border.all(
          color: AppColors.neonGreen.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.neonGreen),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.neonGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            desc,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
