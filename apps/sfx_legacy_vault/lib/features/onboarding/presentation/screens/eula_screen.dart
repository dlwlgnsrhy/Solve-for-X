import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_legacy_vault/core/constants/app_colors.dart';
import 'package:sfx_legacy_vault/features/auth/presentation/screens/login_screen.dart';
import 'package:sfx_legacy_vault/features/onboarding/presentation/providers/onboarding_provider.dart';

/// EULA and Privacy Policy screen - Professional & Trustworthy
class EulaScreen extends StatefulWidget {
  const EulaScreen({super.key});

  @override
  State<EulaScreen> createState() => _EulaScreenState();
}

class _EulaScreenState extends State<EulaScreen> {
  // Track which sections are expanded
  bool _eulaExpanded = false;
  bool _privacyExpanded = false;
  bool _dataSecurityExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (ctx, ref, _) {
        final eulaAccepted = ref.watch(onboardingProvider);
        final size = MediaQuery.of(ctx).size;

        if (eulaAccepted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(ctx).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          });
        }

        return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomPaint(
          painter: _GlowPainter(
            color: AppColors.neonGreen.withValues(alpha:0.03),
            radius: size.width * 0.6,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // ─── Shield icon with glow ───
                _buildShieldHero(),
                const SizedBox(height: 16),

                // App title
                Text(
                  'SFX Legacy Vault',
                  style: Theme.of(ctx)
                      .textTheme
                      .displaySmall
                      ?.copyWith(color: AppColors.neonGreen, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: -0.3, end: 0, duration: 600.ms),
                const SizedBox(height: 4),

                // Tagline
                const Text(
                  'Your Digital Legacy, Securely Protected',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 600.ms),
                const SizedBox(height: 24),

                // ─── Trust badges row ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _TrustBadge(icon: Icons.lock_rounded, label: 'AES-256'),
                    SizedBox(width: 8),
                    _TrustBadge(icon: Icons.no_accounts_rounded, label: 'Zero-Knowledge'),
                    SizedBox(width: 8),
                    _TrustBadge(icon: Icons.device_hub_rounded, label: 'Client-Side'),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 500.ms),
                const SizedBox(height: 28),

                // ─── Collapsible EULA Section ───
                _buildCollapsibleSection(
                  title: 'End User License Agreement',
                  icon: Icons.gavel_rounded,
                  iconColor: AppColors.neonCyan,
                  isExpanded: _eulaExpanded,
                  onToggle: () => setState(() => _eulaExpanded = !_eulaExpanded),
                  content: _eulaText,
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms)
                    .slideY(begin: 0.15, end: 0, duration: 600.ms),
                const SizedBox(height: 12),

                // ─── Collapsible Privacy Policy Section ───
                _buildCollapsibleSection(
                  title: 'Privacy Policy',
                  icon: Icons.privacy_tip_rounded,
                  iconColor: AppColors.neonPink,
                  isExpanded: _privacyExpanded,
                  onToggle: () => setState(() => _privacyExpanded = !_privacyExpanded),
                  content: _privacyText,
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 600.ms)
                    .slideY(begin: 0.15, end: 0, duration: 600.ms),
                const SizedBox(height: 12),

                // ─── Collapsible Data Security Preview ───
                _buildCollapsibleSection(
                  title: 'Data Security Overview',
                  icon: Icons.security_rounded,
                  iconColor: AppColors.neonGreen,
                  isExpanded: _dataSecurityExpanded,
                  onToggle: () => setState(() => _dataSecurityExpanded = !_dataSecurityExpanded),
                  content: _dataSecurityText,
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 600.ms)
                    .slideY(begin: 0.15, end: 0, duration: 600.ms),
                const SizedBox(height: 24),

                // ─── Security guarantee banner ───
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withValues(alpha:0.05),
                    border: Border.all(
                      color: AppColors.neonGreen.withValues(alpha:0.15),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          color: AppColors.neonGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your data is encrypted before it ever leaves your device. We cannot read, access, or decrypt your vault contents.',
                          style: TextStyle(
                            color: AppColors.neonGreen.withValues(alpha:0.9),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 500.ms),
                const SizedBox(height: 24),

                // ─── Agree button with glow ───
                _buildAgreeButton(ref),
                const SizedBox(height: 12),

                // ─── Decline button ───
                _buildDeclineButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  },
);
  }

  /// Shield hero with pulsing glow
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final scale = 1.0 + value * 0.15;
        final opacity = 0.05 + value * 0.08;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neonGreen.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.neonGreen.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
            ).animate().scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.1, 1.1),
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                ),
            Icon(
              Icons.shield_rounded,
              size: 40,
              color: AppColors.neonGreen,
            ),
          ],
        );
      },
    ).animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.5, end: 0, duration: 600.ms);
  }

  /// Collapsible section widget
  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isExpanded,
    required VoidCallback onToggle,
    required String content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? iconColor.withValues(alpha: 0.3)
              : AppColors.surfaceVariant.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    content,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  /// Agree button with glow effect
  Widget _buildAgreeButton(WidgetRef ref) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow behind button
        Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonGreen.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            await ref.read(onboardingProvider.notifier).acceptEula();
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_forward_rounded,
                  size: 20, color: AppColors.background),
              const SizedBox(width: 8),
              const Text(
                'I Agree & Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 1000.ms, duration: 600.ms)
        .slideY(begin: 0.3, end: 0, duration: 600.ms);
  }

  /// Decline button
  Widget _buildDeclineButton() {
    return OutlinedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => _buildDeclineDialog(),
        );
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(
            color: AppColors.surfaceVariant.withValues(alpha:0.5)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            'Decline',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 1100.ms, duration: 600.ms);
  }

  /// Decline dialog
  AlertDialog _buildDeclineDialog() {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 24),
          const SizedBox(width: 10),
          const Text(
            'Decline',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
      content: const Text(
        'You must agree to the EULA and Privacy Policy to use SFX Legacy Vault. These terms protect both you and the security of your vault.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Understood'),
        ),
      ],
    );
  }

  static const String _eulaText = '''1. ACCEPTANCE OF TERMS
By using SFX Legacy Vault ("the App"), you agree to these terms. If you do not agree, do not use the App.

2. DESCRIPTION OF SERVICE
SFX Legacy Vault is a dead man's switch application that stores encrypted data and delivers it to a designated recipient if the user fails to periodically confirm their status.

3. ENCRYPTION AND SECURITY
All data is encrypted client-side using AES-256 encryption. The encryption key (passphrase) is stored only on your device. SFX Legacy Vault cannot decrypt your data without your passphrase. If you lose your passphrase, your data is permanently inaccessible.

4. NO GUARANTEE
The service is provided "AS IS" without warranty. While we make reasonable efforts to ensure reliable delivery, no system is 100% guaranteed. Do not rely solely on this service for critical data delivery.

5. USER RESPONSIBILITY
You are responsible for maintaining your account security, keeping your passphrase safe, and regularly pinging the app within your chosen deadline period.

6. DATA RETENTION
Encrypted data is stored on our servers only until delivery. Once data is delivered to your designated recipient, it is permanently deleted from our servers.

7. TERMINATION
We reserve the right to terminate access if we detect abuse or illegal activity.

8. LIMITATION OF LIABILITY
SFX Legacy Vault and its developers shall not be liable for any damages arising from the use or inability to use this application, including data loss or failed delivery.

9. INDEMNIFICATION
You agree to indemnify and hold harmless SFX Legacy Vault from any claims arising from your use of the application or the content of your stored data.

10. GOVERNING LAW
These terms shall be governed by applicable law without regard to conflict of law principles.''';

  static const String _privacyText = '''Information We Collect:
- Email address (for authentication only)
- Encrypted data blob (we cannot read its contents)
- Last active timestamp (for deadline monitoring)
- Target recipient email (for delivery only)

How We Use Your Information:
- To provide the dead man's switch functionality
- To deliver encrypted data if a deadline is missed
- To maintain service security and prevent abuse

Data Security:
- All vault data is encrypted with AES-256 before server storage
- Encryption keys never leave your device
- We use Firebase security rules to protect data at rest
- Data is deleted after successful delivery

Third-Party Services:
- Firebase (authentication, database)
- Apple Sign-In (if selected)
- SendGrid/Nodemailer (email delivery via Cloud Functions)

Your Rights:
- Request data deletion at any time
- Export your encrypted data
- Withdraw consent for data processing

Contact:
For privacy inquiries, contact: privacy@sfxvault.com''';

  static const String _dataSecurityText = '''🔐 Encryption Standard: AES-256-GCM
   - Same standard used by government & military
   - Client-side encryption (data encrypted on your device)
   - Zero-knowledge architecture (we never see your data)

🔑 Key Management:
   - Passphrase generated locally on your device
   - Never transmitted to our servers
   - Stored only in your device's secure storage
   - If lost, data is permanently unrecoverable

📡 Data Flow:
   1. You enter secrets → encrypted on device
   2. Encrypted blob → stored in Firebase
   3. Deadline missed → email triggered
   4. Recipient receives → encrypted data + instructions
   5. After delivery → permanent deletion

🛡️ Security Measures:
   - Firebase security rules prevent unauthorized access
   - Email delivery uses authenticated SMTP
   - All API calls use HTTPS/TLS
   - Regular security audits and updates

⚠️ Important Limitations:
   - No system is 100% guaranteed
   - Do not rely solely on this for critical data
   - Keep backups of important information
   - Use strong, unique passphrases for each vault''';
}

/// Small trust badge widget
class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha:0.5),
        border: Border.all(
          color: AppColors.neonGreen.withValues(alpha:0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.neonGreen),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.neonGreen,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Background glow painter
class _GlowPainter extends CustomPainter {
  final Color color;
  final double radius;

  _GlowPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.0,
        colors: [color, Colors.transparent],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, 0),
          radius: radius,
        ),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) => false;
}
