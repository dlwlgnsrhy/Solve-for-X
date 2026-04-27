import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:sfx_memento_mori/core/theme/neon_colors.dart';
import 'package:sfx_memento_mori/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:sfx_memento_mori/features/onboarding/presentation/providers/onboarding_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  int? _currentTargetAge;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _loadCurrentTargetAge();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _loadCurrentTargetAge() {
    final prefs = ref.read(preferenceServiceProvider);
    setState(() {
      _currentTargetAge = prefs.targetAge;
    });
  }

  Future<void> _showResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeonColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '데이터 초기화',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '모든 온보딩 데이터가 초기화됩니다.\n이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(color: NeonColors.neonPink),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '초기화',
              style: TextStyle(color: NeonColors.neonGreen),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final prefs = ref.read(preferenceServiceProvider);
      await prefs.resetAll();
      ref.read(onboardingProvider.notifier).resetState();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingPage()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _showChangeTargetAgeDialog() async {
    final controller =
        TextEditingController(text: _currentTargetAge?.toString() ?? '80');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeonColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '목표 나이 변경',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: NeonColors.neonCyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  '현재: ${_currentTargetAge ?? 80}세',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '목표 나이를 입력하세요',
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: NeonColors.darkGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: NeonColors.statsBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: NeonColors.neonGreen),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '취소',
              style: TextStyle(color: NeonColors.neonPink),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newAge = int.tryParse(controller.text);
              if (newAge != null && newAge >= 70 && newAge <= 120) {
                final navigator = Navigator.of(ctx);
                final prefs = ref.read(preferenceServiceProvider);
                await prefs.setTargetAge(newAge);
                if (mounted) {
                  setState(() {
                    _currentTargetAge = newAge;
                  });
                  navigator.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('목표 나이가 $newAge세로 변경되었습니다.'),
                      backgroundColor: NeonColors.darkGrey,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text(
              '저장',
              style: TextStyle(color: NeonColors.neonGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeonColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '개인정보 처리방침',
          style: TextStyle(
            color: NeonColors.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SFX Memento Mori는 사용자의 개인정보를 최대한 보호합니다.',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 16),
              _privacySection(
                '수집하는 정보',
                '본 앱은 사용자의 생년월일과 목표 나이만을 수집합니다. 이 정보는 인생 주수를 계산하기 위한 필수 정보입니다.',
              ),
              _privacySection(
                '정보의 저장',
                '모든 데이터는 사용자의 기기 내에서만 저장됩니다. 외부 서버로 전송되거나 제3자와 공유되지 않습니다.',
              ),
              _privacySection(
                '정보의 사용',
                '수집된 정보는 사용자의 인생 그리드를 시각화하고 개인 통계를 표시하는 목적으로만 사용됩니다.',
              ),
              _privacySection(
                '추적 및 분석',
                '본 앱은 어떤 형태의 분석 도구, 광고 추적, 또는 사용자 행동 추적을 사용하지 않습니다.',
              ),
              _privacySection(
                '데이터 삭제',
                '설정 메뉴에서 "온보딩 데이터 초기화"를 통해 모든 저장된 데이터를 삭제할 수 있습니다. 또한 앱을 제거하면 모든 데이터가 자동으로 삭제됩니다.',
              ),
              _privacySection(
                '어린이 개인정보',
                '본 앱은 13세 미만 어린이의 개인정보를 수집하지 않습니다.',
              ),
              _privacySection(
                '변경 사항',
                '본 개인정보 처리방침은 언제든지 변경될 수 있습니다. 변경 시 앱 업데이트를 통해 공지됩니다.',
              ),
              const SizedBox(height: 16),
              const Text(
                '마지막 업데이트: 2025년 1월',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '닫기',
              style: TextStyle(color: NeonColors.neonGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _privacySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeonColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'SFX Memento Mori',
          style: TextStyle(
            color: NeonColors.neonGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: NeonColors.neonCyan, size: 18),
                const SizedBox(width: 8),
                const Text(
                  '버전 1.0.0',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'SFX Memento Mori는 당신의 인생을 주간 단위로 시각화하여,',
              style: TextStyle(color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 4),
            const Text(
              '매일 매일이 소중함을 상기시켜주는 앱입니다.',
              style: TextStyle(color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 16),
            const Divider(color: NeonColors.statsBorder),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showPrivacyPolicyDialog,
              child: RichText(
                text: const TextSpan(
                  text: '개인정보 처리방침',
                  style: TextStyle(
                    color: NeonColors.neonCyan,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '© 2025 SFX. All rights reserved.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '닫기',
              style: TextStyle(color: NeonColors.neonGreen),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    } else {
      // Fallback: show a dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: NeonColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              '앱 평가하기',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'SFX Memento Mori를 좋아해 주셔서 감사합니다!\n\nApp Store에서 별점을 남겨주시면 큰 힘이 됩니다.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  '닫기',
                  style: TextStyle(color: NeonColors.neonGreen),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: AppBar(
        backgroundColor: NeonColors.background,
        elevation: 0,
        title: const Text(
          '설정',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Vault icon with pulsing glow
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Container(
                    width: 80 + 20 * _glowAnimation.value,
                    height: 80 + 20 * _glowAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: NeonColors.neonGreen.withValues(
                          alpha: 0.05 * _glowAnimation.value),
                    ),
                  ),
                  // Inner glow
                  Container(
                    width: 80 + 10 * _glowAnimation.value,
                    height: 80 + 10 * _glowAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: NeonColors.neonGreen.withValues(
                          alpha: 0.1 * _glowAnimation.value),
                    ),
                  ),
                  // Vault icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: NeonColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: NeonColors.neonGreen.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NeonColors.glowGreen.withValues(
                              alpha: 0.3 * _glowAnimation.value),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      color: NeonColors.neonGreen,
                      size: 36,
                    ),
                  ),
                ],
              );
            },
          ).animate().fadeIn(duration: 600.ms).scale(
              begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
          const SizedBox(height: 8),
          Text(
            '데이터는 안전하게 보호됩니다',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
          const SizedBox(height: 28),

          // Target Age Section
          _buildSectionTitle('인생 설정'),
          _buildSettingsCard(
            icon: Icons.calendar_month_outlined,
            title: '목표 나이',
            subtitle: '${_currentTargetAge ?? 80}세',
            onTap: _showChangeTargetAgeDialog,
          ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 24),

          // Data Management Section
          _buildSectionTitle('데이터 관리'),
          _buildSettingsCard(
            icon: Icons.delete_outline,
            title: '온보딩 데이터 초기화',
            subtitle: '모든 데이터를 삭제하고 다시 시작',
            isDestructive: true,
            onTap: _showResetDialog,
          ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 24),

          // About Section
          _buildSectionTitle('앱 정보'),
          _buildSettingsCard(
            icon: Icons.info_outline,
            title: 'SFX Memento Mori에 대해',
            subtitle: '버전 1.0.0 · 개인정보 처리방침',
            onTap: _showAboutDialog,
          ).animate().fadeIn(duration: 500.ms, delay: 500.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 12),
          _buildSettingsCard(
            icon: Icons.rate_review_outlined,
            title: '앱 평가하기',
            subtitle: '앱 스토어에서 리뷰 남기기',
            onTap: _rateApp,
          ).animate().fadeIn(duration: 500.ms, delay: 600.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 12),
          _buildSettingsCard(
            icon: Icons.info_outline,
            title: '개인정보 처리방침',
            subtitle: '데이터 보호 정책 보기',
            onTap: _showPrivacyPolicyDialog,
          ).animate().fadeIn(duration: 500.ms, delay: 700.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 32),

          // Version footer
          Center(
            child: Text(
              'SFX Memento Mori v1.0.0',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 800.ms),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: NeonColors.neonCyan.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: NeonColors.neonCyan.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NeonColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDestructive
                  ? NeonColors.neonPink.withValues(alpha: 0.2)
                  : NeonColors.statsBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? NeonColors.neonPink.withValues(alpha: 0.1)
                      : NeonColors.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? NeonColors.neonPink
                      : NeonColors.neonGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDestructive
                            ? NeonColors.neonPink
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDestructive
                    ? NeonColors.neonPink.withValues(alpha: 0.5)
                    : Colors.white38,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
