import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_legacy_vault/core/constants/app_colors.dart';
import 'package:sfx_legacy_vault/main.dart';

/// Setup Required screen shown when Firebase initialization fails.
/// Provides clear Korean instructions and retry/demo mode options.
class SetupRequiredScreen extends ConsumerWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isRetryLoading = ref.watch(firebaseConfigProvider).when(
          data: (_) => false,
          loading: () => true,
          error: (_, __) => false,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Top ambient glow
            Positioned(
              top: -100,
              left: size.width / 2 - 180,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.neonGreen.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  // Shield warning icon
                  _buildWarningIcon(),

                  const SizedBox(height: 28),

                  // Title
                  Text(
                    'Firebase 설정이 필요합니다',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .slideY(begin: -0.2, end: 0, duration: 600.ms),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    'SFX Legacy Vault는 Firebase를 사용하여 안전한 '
                    '데이터 보관 서비스를 제공합니다.\n\n'
                    'Firebase 설정이 완료되지 않았습니다.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.7,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 600.ms),

                  const SizedBox(height: 32),

                  // Instruction box
                  _buildInstructionBox(),

                  const SizedBox(height: 48),

                  // Retry button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: isRetryLoading
                          ? null
                          : () => ref
                              .read(firebaseConfigProvider.notifier)
                              .retryInitialization(),
                      icon: isRetryLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.background,
                              ),
                            )
                          : Icon(
                              Icons.refresh_rounded,
                              color: AppColors.background,
                              size: 22,
                            ),
                      label: Text(
                        isRetryLoading ? '재시도 중...' : '다시 시도',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.background,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 500.ms)
                      .slideY(begin: 0.2, end: 0, duration: 500.ms),

                  const SizedBox(height: 14),

                  // Demo mode button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(firebaseConfigProvider.notifier)
                            .acceptDemoMode();
                      },
                      icon: Icon(
                        Icons.bubble_chart_rounded,
                        color: AppColors.neonCyan,
                        size: 22,
                      ),
                      label: Text(
                        '데모 모드로 계속하기',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neonCyan,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.neonCyan.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 500.ms)
                      .slideY(begin: 0.2, end: 0, duration: 500.ms),

                  const SizedBox(height: 32),

                  // Footer note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.textSecondary
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '데모 모드에서는 일부 기능이 제한됩니다',
                        style: TextStyle(
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 850.ms, duration: 400.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningIcon() {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing ring
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 2000),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.neonGreen.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
            ).animate().scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2),
                  duration: 1800.ms,
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
                  color: AppColors.neonGreen.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ).animate().scale(
                  begin: const Offset(0.65, 0.65),
                  end: const Offset(0.9, 0.9),
                  duration: 2200.ms,
                  curve: Curves.easeInOut,
                ),
          ),
          // Shield + warning overlay
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.shield_rounded,
                size: 44,
                color: AppColors.neonGreen.withValues(alpha: 0.35),
              ),
              Icon(
                Icons.warning_amber_rounded,
                size: 32,
                color: AppColors.neonGreen,
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.5, 0.5));
  }

  Widget _buildInstructionBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.build_rounded,
                color: AppColors.neonGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                '설정 방법',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InstructionRow(
            step: '1',
            text: '프로젝트 루트에서 다음 명령어를 실행하세요',
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.neonCyan.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Text(
              'flutterfire configure',
              style: TextStyle(
                color: AppColors.neonCyan,
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _InstructionRow(
            step: '2',
            text: 'Firebase 프로젝트와 연결하여 완료하세요',
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 600.ms);
  }
}

/// Instruction row widget for the instruction box.
class _InstructionRow extends StatelessWidget {
  final String step;
  final String text;

  const _InstructionRow({
    required this.step,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.neonGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: TextStyle(
              color: AppColors.neonGreen,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
