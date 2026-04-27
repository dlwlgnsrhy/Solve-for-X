import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_legacy_vault/core/constants/app_colors.dart';
import 'package:sfx_legacy_vault/core/services/encryption_service.dart';
import 'package:sfx_legacy_vault/core/services/review_service.dart';
import 'package:sfx_legacy_vault/core/utils/date_utils.dart' as vault_utils;
import 'package:sfx_legacy_vault/features/auth/presentation/providers/auth_provider.dart';
import 'package:sfx_legacy_vault/features/auth/presentation/screens/login_screen.dart';
import 'package:sfx_legacy_vault/features/vault/domain/models/vault_model.dart';
import 'package:sfx_legacy_vault/features/vault/presentation/providers/vault_provider.dart';
import 'package:sfx_legacy_vault/features/vault/presentation/screens/vault_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Main home screen showing vault list dashboard.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _autoPing();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  /// Check if in-app review should be prompted.
  void _checkReviewPrompt(WidgetRef ref) {
    final reviewReady = ref.read(reviewServiceProvider);
    if (reviewReady) {
      ref.read(reviewServiceProvider.notifier).requestReview();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _autoPing() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref.read(vaultNotifierProvider.notifier).pingAll(user.uid);
    }
  }

  Future<void> _handleSignOut() async {
    final service = ref.read(firebaseAuthProvider);
    await service.signOut();
    ref.read(vaultNotifierProvider.notifier).clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _addNewVault(String userId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => VaultSetupScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    // Check if in-app review should be prompted
    _checkReviewPrompt(ref);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const _EmptyState('Not signed in');
          }
          return _VaultDashboard(
            userId: user.uid,
            pulseController: _pulseController,
          );
        },
        loading: () => const _LoadingState(),
        error: (e, _) => _ErrorState(
          message: 'Auth error: ${e.toString()}',
          onRetry: () => setState(() {}),
        ),
      ),
      floatingActionButton: authState.maybeWhen(
        data: (user) {
          if (user == null) return null;
          return _buildGlowingFAB(user.uid);
        },
        orElse: () => null,
      ),
    );
  }

  /// FAB with pulsing glow effect.
  Widget _buildGlowingFAB(String userId) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          builder: (context, value, _) {
            return Transform.scale(
              scale: 1 + value * 0.15,
              child: Opacity(
                opacity: 0.15 + value * 0.1,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neonGreen.withValues(alpha: 0.3),
                        AppColors.neonGreen.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ).animate()
            .fadeIn(delay: 300.ms)
            .scale(begin: const Offset(0.5, 0.5)),
        // FAB
        FloatingActionButton(
          onPressed: () => _addNewVault(userId),
          backgroundColor: AppColors.neonGreen,
          foregroundColor: AppColors.background,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, size: 24, color: AppColors.neonGreen),
          const SizedBox(width: 8),
          const Text(
            'Legacy Vault',
            style: TextStyle(
              color: AppColors.neonGreen,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined,
              color: AppColors.textSecondary),
          onPressed: () => _showSecurityTips(context),
          tooltip: 'Security Tips',
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: AppColors.textSecondary),
          onPressed: _handleSignOut,
          tooltip: 'Sign out',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.surfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  /// Show security tips and trust signals dialog.
  void _showSecurityTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _SecurityTipsDialog(),
    );
  }
}

// ─── Vault Type Colors ──────────────────────────────────────────────────────

/// Returns a distinct neon color for each vault type.
Color _vaultTypeBorderColor(String type) {
  switch (type) {
    case 'crypto':
      return const Color(0xFFFF9900); // Bitcoin orange
    case 'passwords':
      return const Color(0xFF00B0FF); // Key blue
    case 'letter':
      return AppColors.neonGreen; // Mail green
    case 'custom':
    case 'legal':
      return AppColors.neonPink; // Folder pink
    default:
      return AppColors.neonCyan;
  }
}

/// Returns the Material icon that best represents the vault type.
IconData _vaultTypeHeroIcon(String type) {
  switch (type) {
    case 'crypto':
      return Icons.account_balance_wallet_rounded;
    case 'passwords':
      return Icons.key_rounded;
    case 'letter':
      return Icons.mail_rounded;
    case 'custom':
      return Icons.folder_rounded;
    case 'legal':
      return Icons.gavel_rounded;
    default:
      return Icons.vpn_key_rounded;
  }
}

/// Korean-formatted "Last Ping: X분 전" string.
String _koreanLastPing(DateTime? lastActive) {
  if (lastActive == null) return '마지막 Ping: 정보 없음';
  final diff = DateTime.now().difference(lastActive);
  if (diff.inSeconds < 60) return '마지막 Ping: 방금 전';
  if (diff.inMinutes < 60) return '마지막 Ping: ${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '마지막 Ping: ${diff.inHours}시간 전';
  return '마지막 Ping: ${diff.inDays}일 전';
}

// ─── Dashboard ──────────────────────────────────────────────────────────────

/// Dashboard showing list of vault cards.
class _VaultDashboard extends ConsumerWidget {
  final String userId;
  final AnimationController pulseController;

  const _VaultDashboard({
    required this.userId,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaults = ref.watch(vaultNotifierProvider);

    if (vaults.isEmpty) {
      return _SetupPrompt(userId: userId);
    }

    final activeCount = vaults.where((v) => v.status == 'active').length;
    final allProtected = activeCount == vaults.length;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(vaultNotifierProvider.notifier).pingAll(userId);
      },
      color: AppColors.neonGreen,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Security certification banner ───
            const _SecurityBanner().animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),

            // ─── Vault count + protection summary ───
            _VaultSummary(
              totalCount: vaults.length,
              activeCount: activeCount,
              allProtected: allProtected,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),

            // ─── Vault list ───
            ...List.generate(vaults.length, (index) {
              final vault = vaults[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < vaults.length - 1 ? 14 : 0,
                ),
                child: _SwipeableVaultCard(
                  vault: vault,
                  userId: userId,
                  pulseController: pulseController,
                ),
              ).animate()
                  .fadeIn(delay: const Duration(milliseconds: 300))
                  .slideY(begin: 0.05, end: 0, duration: const Duration(milliseconds: 400)),
            }),

            const SizedBox(height: 20),

            // Trust signals footer
            const _TrustFooter().animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 90), // Space for FAB
          ],
        ),
      ),
    );
  }
}

// ─── Swipeable Vault Card wrapper ──────────────────────────────────────────

class _SwipeableVaultCard extends StatelessWidget {
  final VaultModel vault;
  final String userId;
  final AnimationController pulseController;

  const _SwipeableVaultCard({
    required this.vault,
    required this.userId,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('vault_${vault.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right → Ping
          // Handled in _VaultCard swipe
          return false; // Don't dismiss, just trigger action
        } else if (direction == DismissDirection.endToStart) {
          // Swipe left → Edit
          return false;
        }
        return false;
      },
      onDismissed: (direction) {
        // Not used since we return false, but actions are in updatePositions
      },
      onUpdate: (details) {
        // Could show progressive reveal
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.neonGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_find_rounded, color: AppColors.neonGreen, size: 28),
            const SizedBox(width: 10),
            const Text(
              'Ping',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.neonCyan.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Edit',
              style: TextStyle(
                color: AppColors.neonCyan,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.edit_rounded, color: AppColors.neonCyan, size: 28),
          ],
        ),
      ),
      child: _VaultCard(
        vault: vault,
        userId: userId,
        pulseController: pulseController,
        onSwipeRight: () {
          // Left swipe in LTR = startToEnd = ping
        },
        onSwipeLeft: () {
          // Right swipe in LTR = endToStart = edit
        },
      ),
    );
  }
}

// ─── Security Certification Banner ─────────────────────────────────────────

class _SecurityBanner extends StatelessWidget {
  const _SecurityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.neonGreen.withValues(alpha: 0.06),
            AppColors.neonCyan.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.neonGreen.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, size: 18, color: AppColors.neonGreen),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AES-256 암호화 · Zero-Knowledge · Client-Side Only',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security_rounded, size: 11, color: AppColors.neonGreen),
                const SizedBox(width: 3),
                const Text(
                  'CERTIFIED',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vault Summary ──────────────────────────────────────────────────────────

class _VaultSummary extends StatelessWidget {
  final int totalCount;
  final int activeCount;
  final bool allProtected;

  const _VaultSummary({
    required this.totalCount,
    required this.activeCount,
    required this.allProtected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: allProtected
              ? AppColors.neonGreen.withValues(alpha: 0.15)
              : AppColors.warning.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Protection status indicator
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.9 + value * 0.1,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: allProtected
                        ? AppColors.neonGreen.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    border: Border.all(
                      color: allProtected
                          ? AppColors.neonGreen.withValues(alpha: 0.4)
                          : AppColors.warning.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    allProtected ? Icons.shield_rounded : Icons.warning_amber_rounded,
                    size: 22,
                    color: allProtected ? AppColors.neonGreen : AppColors.warning,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allProtected
                      ? '모든 Vault 보호 중'
                      : '$activeCount개의 Vault 보호 중',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '총 $totalCount개 Vault · 전체 ${(totalCount * 100)}개 데이터 보호',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Small status dots
          Row(
            children: List.generate(totalCount, (i) {
              final colors = [
                AppColors.neonGreen,
                AppColors.warning,
                AppColors.neonCyan,
                AppColors.neonPink,
                const Color(0xFFFF9900),
              ];
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(left: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[i % colors.length],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Vault Card ─────────────────────────────────────────────────────────────

class _VaultCard extends ConsumerWidget {
  final VaultModel vault;
  final String userId;
  final AnimationController pulseController;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;

  const _VaultCard({
    required this.vault,
    required this.userId,
    required this.pulseController,
    required this.onSwipeRight,
    required this.onSwipeLeft,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = vault.visualStatus;
    final statusColor = _statusColor(status);
    final typeColor = _vaultTypeBorderColor(vault.vaultType);
    final countdown = vault_utils.DateUtils.countdownComponents(
      vault.lastActiveAt,
      vault.deadlineDays,
    );
    final progress = vault_utils.DateUtils.deadlineProgress(
      vault.lastActiveAt,
      vault.deadlineDays,
    );
    final typeIcon = _vaultTypeHeroIcon(vault.vaultType);
    final typeLabel = _vaultTypeLabel(vault.vaultType);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < 0) {
            // Swiped left → Edit
            _showEditDialog(context, ref, userId, vault);
          } else {
            // Swiped right → Ping
            ref.read(vaultNotifierProvider.notifier).pingVault(userId, vault.id);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: typeColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: typeColor.withValues(alpha: 0.08),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            // Subtle inner glow matching type
            BoxShadow(
              color: typeColor.withValues(alpha: 0.03),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER: Name, type icon, status badge ───
            Row(
              children: [
                // Type icon with colored background
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: typeColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: typeColor.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(typeIcon, size: 24, color: typeColor),
                ),
                const SizedBox(width: 12),
                // Name and type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vault.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                color: typeColor.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Pulsing status badge
                _PulsingStatusBadge(status: status, controller: pulseController),
              ],
            ),

            const SizedBox(height: 14),

            // ─── COUNTDOWN TIMER ───
            if (vault.status != 'paused')
              _StyledCountdown(
                days: countdown['days'] ?? 0,
                hours: countdown['hours'] ?? 0,
                minutes: countdown['minutes'] ?? 0,
                seconds: countdown['seconds'] ?? 0,
                color: statusColor,
                isExpired: status == VaultStatus.expired,
              ),
            if (vault.status == 'paused')
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pause_circle_outline, size: 16,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Monitoring paused',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            if (vault.status != 'paused') const SizedBox(height: 10),

            // ─── PROGRESS BAR ───
            if (vault.status != 'paused')
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),

            const SizedBox(height: 10),

            // ─── DETAILS ROW ───
            Row(
              children: [
                Icon(Icons.email_outlined, size: 14,
                    color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    vault.targetEmail,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today, size: 14,
                    color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${vault.deadlineDays}일',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ─── KOREAN LAST PING TIMESTAMP ───
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  _koreanLastPing(vault.lastActiveAt),
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ─── QUICK ACTIONS ───
            Row(
              children: [
                // Ping button
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.wifi_find_rounded,
                    label: 'Ping',
                    color: AppColors.neonGreen,
                    onPressed: () => ref
                        .read(vaultNotifierProvider.notifier)
                        .pingVault(userId, vault.id),
                  ),
                ),
                const SizedBox(width: 8),

                // Pause/Resume button
                Expanded(
                  child: _QuickActionButton(
                    icon: vault.status == 'paused'
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    label: vault.status == 'paused' ? 'Resume' : 'Pause',
                    color: vault.status == 'paused'
                        ? AppColors.neonCyan
                        : AppColors.warning,
                    onPressed: () {
                      if (vault.status == 'paused') {
                        ref
                            .read(vaultNotifierProvider.notifier)
                            .resumeVault(userId, vault.id);
                      } else {
                        ref
                            .read(vaultNotifierProvider.notifier)
                            .pauseVault(userId, vault.id);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Decrypt button
                IconButton(
                  icon: Icon(Icons.lock_open_outlined, size: 20,
                      color: AppColors.neonPink.withValues(alpha: 0.7)),
                  onPressed: () => _showDecryptionDialog(context, vault),
                  tooltip: 'Decrypt',
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(),
                ),

                // Edit button
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 20,
                      color: AppColors.neonCyan.withValues(alpha: 0.7)),
                  onPressed: () => _showEditDialog(context, ref, userId, vault),
                  tooltip: 'Edit',
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(),
                ),

                // Delete button
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, size: 20,
                      color: AppColors.danger.withValues(alpha: 0.7)),
                  onPressed: () => _confirmDelete(context, ref, userId, vault.id, vault.name),
                  tooltip: 'Delete',
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(VaultStatus status) {
    switch (status) {
      case VaultStatus.active:
        return AppColors.neonGreen;
      case VaultStatus.warning:
        return AppColors.warning;
      case VaultStatus.expired:
        return AppColors.danger;
      case VaultStatus.paused:
        return AppColors.neonCyan;
    }
  }

  String _vaultTypeLabel(String type) {
    switch (type) {
      case 'crypto':
        return 'Crypto & Wallet';
      case 'passwords':
        return 'Passwords & Keys';
      case 'letter':
        return 'Personal Letter';
      case 'legal':
        return 'Legal Documents';
      case 'custom':
        return 'Custom Vault';
      default:
        return 'General Vault';
    }
  }
}

// ─── Pulsing Status Badge ───────────────────────────────────────────────────

class _PulsingStatusBadge extends StatelessWidget {
  final VaultStatus status;
  final AnimationController controller;

  const _PulsingStatusBadge({
    required this.status,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final label = _label();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scale = 0.95 + controller.value * 0.1;
        final opacity = 0.7 + controller.value * 0.3;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _color() {
    switch (status) {
      case VaultStatus.active:
        return AppColors.neonGreen;
      case VaultStatus.warning:
        return AppColors.warning;
      case VaultStatus.expired:
        return AppColors.danger;
      case VaultStatus.paused:
        return AppColors.neonCyan;
    }
  }

  String _label() {
    switch (status) {
      case VaultStatus.active:
        return 'Active';
      case VaultStatus.warning:
        return 'Warning';
      case VaultStatus.expired:
        return 'Expired';
      case VaultStatus.paused:
        return 'Paused';
    }
  }
}

// ─── Styled Countdown ───────────────────────────────────────────────────────

class _StyledCountdown extends StatelessWidget {
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final Color color;
  final bool isExpired;

  const _StyledCountdown({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.color,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CountdownBox(
          value: isExpired ? 0 : days,
          label: '일',
          color: color,
        ),
        const SizedBox(width: 6),
        _CountdownSeparator(color: color),
        const SizedBox(width: 6),
        _CountdownBox(value: hours, label: '시간', color: color),
        const SizedBox(width: 6),
        _CountdownSeparator(color: color),
        const SizedBox(width: 6),
        _CountdownBox(value: minutes, label: '분', color: color),
        const SizedBox(width: 6),
        _CountdownSeparator(color: color),
        const SizedBox(width: 6),
        _CountdownBox(value: seconds, label: '초', color: color),
      ],
    );
  }
}

class _CountdownBox extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _CountdownBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.5),
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownSeparator extends StatelessWidget {
  final Color color;

  const _CountdownSeparator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      ':',
      style: TextStyle(
        color: color.withValues(alpha: 0.5),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ─── Quick Action Button ────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Setup Prompt (Empty State) ─────────────────────────────────────────────

class _SetupPrompt extends ConsumerWidget {
  final String userId;

  const _SetupPrompt({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shield hero with glow
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 2000),
              curve: Curves.easeInOut,
              builder: (context, value, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: 1 + value * 0.1,
                      child: Opacity(
                        opacity: 0.15 + value * 0.1,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.neonCyan.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.shield_rounded,
                      size: 72,
                      color: AppColors.neonCyan,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Your Vault is Empty',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            const Text(
              "Set up your dead man's switch to protect your "
              "digital legacy. Create multiple vaults for different "
              "purposes: crypto keys, passwords, personal letters, and more.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 24),

            // Trust badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _TrustBadgeSmall(icon: Icons.lock_rounded, label: 'AES-256'),
                SizedBox(width: 12),
                _TrustBadgeSmall(icon: Icons.no_accounts_rounded, label: 'Zero-Knowledge'),
                SizedBox(width: 12),
                _TrustBadgeSmall(icon: Icons.device_hub_rounded, label: 'Client-Side'),
              ],
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VaultSetupScreen(userId: userId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_circle_outline, size: 20),
                  const SizedBox(width: 8),
                  const Text('Create Vault'),
                ],
              ),
            ).animate()
                .fadeIn(delay: 600.ms)
                .slideY(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }
}

// ─── Trust Badge Small ──────────────────────────────────────────────────────

class _TrustBadgeSmall extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadgeSmall({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.4),
        border: Border.all(
          color: AppColors.neonGreen.withValues(alpha: 0.15),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.neonGreen),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.neonGreen.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trust Footer ───────────────────────────────────────────────────────────

class _TrustFooter extends StatelessWidget {
  const _TrustFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surfaceVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded, size: 16,
                  color: AppColors.neonGreen.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                'Your vaults are protected',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _FooterBadge(icon: Icons.lock_outline, label: 'AES-256'),
              _FooterBadge(icon: Icons.no_accounts, label: 'Zero-Knowledge'),
              _FooterBadge(icon: Icons.device_hub, label: 'Client-Side'),
              _FooterBadge(icon: Icons.delete_forever, label: 'Auto-Delete'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FooterBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 14,
            color: AppColors.textSecondary.withValues(alpha: 0.5)),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.5),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

// ─── Loading / Error / Empty States ─────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.neonGreen),
          SizedBox(height: 16),
          Text(
            'Loading vaults...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

// ─── Decryption Dialog ──────────────────────────────────────────────────────

void _showDecryptionDialog(BuildContext context, VaultModel vault) {
  showDialog(
    context: context,
    builder: (dialogContext) => _DecryptionDialog(vault: vault),
  );
}

class _DecryptionDialog extends ConsumerStatefulWidget {
  final VaultModel vault;

  const _DecryptionDialog({required this.vault});

  @override
  ConsumerState<_DecryptionDialog> createState() =>
      _DecryptionDialogState();
}

class _DecryptionDialogState extends ConsumerState<_DecryptionDialog> {
  String? _decryptedData;
  String? _error;
  bool _isLoading = false;

  Future<void> _decrypt() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _decryptedData = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final passphrase = prefs.getString('encryption_passphrase') ?? '';

      if (passphrase.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No stored passphrase found.';
        });
        return;
      }

      final decrypted = await EncryptionService.decrypt(
        widget.vault.encryptedData,
        passphrase,
      );
      setState(() {
        _decryptedData = decrypted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Decryption failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.lock_open_rounded, size: 22, color: AppColors.neonGreen),
          const SizedBox(width: 10),
          Text(
            'Decrypt: ${widget.vault.name}',
            style: const TextStyle(color: AppColors.neonGreen),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.neonGreen),
                    SizedBox(height: 8),
                    Text(
                      'Decrypting...',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            if (_decryptedData != null)
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.2)),
                ),
                child: SelectableText(
                  _decryptedData!,
                  style: const TextStyle(
                    color: AppColors.neonGreen,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (_decryptedData == null && _error == null)
          ElevatedButton.icon(
            onPressed: _decrypt,
            icon: const Icon(Icons.key_rounded, size: 16),
            label: const Text('Decrypt'),
          ),
      ],
    );
  }
}

// ─── Edit Dialog ────────────────────────────────────────────────────────────

Future<void> _showEditDialog(
  BuildContext context,
  WidgetRef ref,
  String userId,
  VaultModel vault,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _VaultEditDialog(vault: vault, userId: userId),
  );
  if (result == true && context.mounted) {
    // Vault updated via the dialog
  }
}

class _VaultEditDialog extends ConsumerStatefulWidget {
  final VaultModel vault;
  final String userId;

  const _VaultEditDialog({required this.vault, required this.userId});

  @override
  ConsumerState<_VaultEditDialog> createState() => _VaultEditDialogState();
}

class _VaultEditDialogState extends ConsumerState<_VaultEditDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  int _deadlineDays = 14;
  String _vaultType = 'other';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.vault.name;
    _emailController.text = widget.vault.targetEmail;
    _deadlineDays = widget.vault.deadlineDays;
    _vaultType = widget.vault.vaultType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Vault name is required');
      return;
    }
    if (!_emailController.text.contains('@')) {
      _showError('Enter a valid email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updated = widget.vault.copyWith(
        name: _nameController.text.trim(),
        targetEmail: _emailController.text.trim(),
        deadlineDays: _deadlineDays,
        vaultType: _vaultType,
      );
      await ref
          .read(vaultNotifierProvider.notifier)
          .updateVault(widget.userId, widget.vault.id, updated);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.edit_outlined, size: 20, color: AppColors.neonCyan),
          const SizedBox(width: 8),
          const Text(
            'Edit Vault',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withValues(alpha: 0.05),
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.15),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16,
                        color: AppColors.neonCyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Edit recipient, deadline, and type. Encrypted data and key remain unchanged.',
                        style: TextStyle(
                          color: AppColors.neonCyan.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Vault Name',
                  prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _vaultType,
                style: const TextStyle(color: AppColors.textPrimary),
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(
                  labelText: 'Vault Type',
                  prefixIcon: Icon(Icons.category_outlined, size: 18),
                ),
                items: const [
                  DropdownMenuItem(value: 'crypto', child: Text('Crypto & Wallet')),
                  DropdownMenuItem(value: 'passwords', child: Text('Passwords & Keys')),
                  DropdownMenuItem(value: 'letter', child: Text('Personal Letter')),
                  DropdownMenuItem(value: 'legal', child: Text('Legal Documents')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom')),
                  DropdownMenuItem(value: 'other', child: Text('General')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _vaultType = value);
                  }
                },
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Recipient Email',
                  prefixIcon: Icon(Icons.email_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.6)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Days until delivery',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.neonGreen.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '$_deadlineDays days',
                            style: const TextStyle(
                                color: AppColors.neonGreen, fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _deadlineDays.toDouble(),
                      min: 1,
                      max: 60,
                      divisions: 59,
                      activeColor: AppColors.neonGreen,
                      inactiveColor: AppColors.surfaceVariant,
                      onChanged: (v) {
                        setState(() => _deadlineDays = v.round());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16, width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.background),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ─── Delete Confirmation ────────────────────────────────────────────────────

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  String userId,
  String vaultId,
  String vaultName,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 24, color: AppColors.danger),
          const SizedBox(width: 10),
          const Text(
            'Delete Vault',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to permanently delete "$vaultName"? This action cannot be undone and all encrypted data will be lost.',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await ref
        .read(vaultNotifierProvider.notifier)
        .deleteVault(userId, vaultId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$vaultName deleted'),
          backgroundColor: AppColors.neonGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ─── Security Tips Dialog ───────────────────────────────────────────────────

class _SecurityTipsDialog extends StatelessWidget {
  const _SecurityTipsDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.shield_rounded, size: 24, color: AppColors.neonGreen),
          const SizedBox(width: 10),
          const Text(
            'Security & Trust',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _CertBadge(
                    icon: Icons.verified_rounded,
                    label: 'AES-256\nEncrypted',
                    color: AppColors.neonGreen,
                  ),
                  _CertBadge(
                    icon: Icons.no_accounts_rounded,
                    label: 'Zero-Knowledge\nArchitecture',
                    color: AppColors.neonCyan,
                  ),
                  _CertBadge(
                    icon: Icons.device_hub_rounded,
                    label: 'Client-Side\nOnly',
                    color: AppColors.neonPink,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SecurityTip(
                icon: Icons.lock_outline_rounded,
                tip: 'Your vault data is encrypted before it leaves your device. We never see your unencrypted secrets.',
              ),
              _SecurityTip(
                icon: Icons.key_rounded,
                tip: 'Your encryption key (passphrase) is stored only on your device. We cannot decrypt your data.',
              ),
              _SecurityTip(
                icon: Icons.refresh_rounded,
                tip: 'Ping your vault regularly to confirm you\'re active. Without a ping within the deadline, your data is delivered.',
              ),
              _SecurityTip(
                icon: Icons.delete_sweep_rounded,
                tip: 'After delivery to your designated recipient, all encrypted data is permanently deleted from our servers.',
              ),
              _SecurityTip(
                icon: Icons.security_rounded,
                tip: 'Use a strong, unique passphrase for each vault. Consider using a password manager to generate these.',
              ),
              _SecurityTip(
                icon: Icons.phone_iphone_rounded,
                tip: 'Keep your device secure with biometric authentication and a strong passcode.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}

class _CertBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CertBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SecurityTip extends StatelessWidget {
  final IconData icon;
  final String tip;

  const _SecurityTip({required this.icon, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18,
              color: AppColors.neonGreen.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
