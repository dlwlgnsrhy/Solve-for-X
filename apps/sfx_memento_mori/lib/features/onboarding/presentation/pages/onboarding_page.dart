import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_memento_mori/core/theme/neon_colors.dart';
import 'package:sfx_memento_mori/features/home/presentation/pages/home_page.dart';
import 'package:sfx_memento_mori/features/onboarding/presentation/providers/onboarding_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with TickerProviderStateMixin {
  // Date selection glow effect
  late AnimationController _dateGlowController;
  late Animation<double> _dateGlowAnimation;
  bool _dateSelected = false;

  @override
  void initState() {
    super.initState();
    _dateGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _dateGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dateGlowController, curve: Curves.easeOut),
    );
  }

  void _triggerDateGlow() {
    if (!_dateSelected) {
      setState(() => _dateSelected = true);
      _dateGlowController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _dateGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final canSubmit = notifier.canSubmit;

    // Calculate weeks left preview based on current slider value
    final targetAge = state.targetAge ?? 80;
    final previewWeeks = targetAge * 52;

    return Scaffold(
      backgroundColor: NeonColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Title
            const SizedBox(height: 20),
            Text(
              'SFX Memento Mori',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: NeonColors.neonGreen,
                shadows: [
                  Shadow(
                    color: NeonColors.glowGreen,
                    blurRadius: 15,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0),
            const SizedBox(height: 4),
            Text(
              '당신의 남은 인생을 주간으로 시각화합니다',
              style: Theme.of(context).textTheme.bodyLarge,
            ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: -0.2, end: 0),
            const SizedBox(height: 40),

            // Birth Date with glow feedback
            Text(
              '생년월일',
              style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _dateGlowAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Glow effect when date is selected
                    if (_dateSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: NeonColors.neonPink.withValues(
                                    alpha: 0.3 * _dateGlowAnimation.value),
                                blurRadius: 20,
                                spreadRadius: 2 * _dateGlowAnimation.value,
                              ),
                            ],
                          ),
                        ),
                      ),
                    child!,
                  ],
                );
              },
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(1990, 1, 1),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (ctx, child) {
                      return Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: NeonColors.neonGreen,
                            onPrimary: NeonColors.background,
                            surface: NeonColors.surface,
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    notifier.setBirthDate(picked);
                    _triggerDateGlow();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: NeonColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.birthDate != null
                          ? NeonColors.neonPink.withValues(alpha: 0.4)
                          : Colors.white10,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NeonColors.neonPink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          state.birthDate != null
                              ? Icons.cake
                              : Icons.cake_outlined,
                          color: NeonColors.neonPink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        state.birthDate != null
                            ? '${state.birthDate!.year}년 ${state.birthDate!.month}월 ${state.birthDate!.day}일'
                            : '생년월일을 선택하세요',
                        style: TextStyle(
                          color: state.birthDate != null ? Colors.white : Colors.white54,
                          fontSize: 16,
                          fontWeight: state.birthDate != null ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 32),

            // Target Age with improved slider
            Text(
              '목표 나이',
              style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: NeonColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  // Large age display
                  Text(
                    '${state.targetAge ?? 80}세',
                    style: TextStyle(
                      color: NeonColors.neonGreen,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: NeonColors.glowGreen,
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Weeks preview
                  Text(
                    '총 $previewWeeks주 (${(previewWeeks / 52).toStringAsFixed(0)}년)',
                    style: TextStyle(
                      color: NeonColors.neonCyan.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Custom slider with milestones
                  _buildCustomSlider(
                    value: (state.targetAge ?? 80).toDouble(),
                    min: 70,
                    max: 90,
                    divisions: 20,
                    onChanged: (value) {
                      notifier.setTargetAge(value.round());
                    },
                  ),
                  const SizedBox(height: 8),
                  // Age milestones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MilestoneLabel(age: 70, label: '70'),
                      _MilestoneLabel(age: 75, label: '75'),
                      _MilestoneLabel(age: 80, label: '80', isDefault: true),
                      _MilestoneLabel(age: 85, label: '85'),
                      _MilestoneLabel(age: 90, label: '90'),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 600.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 32),

            // EULA with improved formatting
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NeonColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: NeonColors.neonCyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.security_outlined,
                          color: NeonColors.neonCyan,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '이용약관 동의',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: state.eulaAccepted,
                    onChanged: (_) => notifier.toggleEulaAccepted(),
                    activeColor: NeonColors.neonGreen,
                    checkColor: NeonColors.background,
                    title: const Text(
                      '약관에 동의합니다',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: GestureDetector(
                      onTap: () => _showEulaDialog(context),
                      child: const Text(
                        '서비스 이용약관 자세히 보기',
                        style: TextStyle(
                          color: NeonColors.neonCyan,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 800.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 40),

            // Submit button with gradient
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: canSubmit
                      ? LinearGradient(
                          colors: [
                            NeonColors.neonGreen,
                            NeonColors.neonCyan,
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.white10,
                            Colors.white10,
                          ],
                        ),
                  boxShadow: canSubmit
                      ? [
                          BoxShadow(
                            color: NeonColors.glowGreen,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: canSubmit
                      ? () async {
                          await notifier.completeOnboarding();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const HomePage()),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '시작하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: canSubmit ? NeonColors.background : Colors.white30,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 1000.ms).slideY(begin: 0.5, end: 0),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Custom slider with neon styling and milestone markers
  Widget _buildCustomSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: NeonColors.neonGreen,
            inactiveTrackColor: NeonColors.darkGrey,
            trackHeight: 4,
            thumbColor: NeonColors.neonGreen,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            overlayColor: NeonColors.neonGreen.withValues(alpha: 0.2),
            valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
            valueIndicatorColor: NeonColors.surface,
            valueIndicatorTextStyle: TextStyle(
              color: NeonColors.neonGreen,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: '${value.round()}',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _showEulaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _EulaDialog(),
    );
  }
}

/// Milestone label below the slider
class _MilestoneLabel extends StatelessWidget {
  final int age;
  final String label;
  final bool isDefault;

  const _MilestoneLabel({
    required this.age,
    required this.label,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 2,
          color: isDefault
              ? NeonColors.neonGreen
              : Colors.white24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDefault
                ? NeonColors.neonGreen
                : Colors.white54,
            fontSize: 11,
            fontWeight: isDefault ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Improved EULA dialog with collapsible sections
class _EulaDialog extends StatefulWidget {
  @override
  State<_EulaDialog> createState() => _EulaDialogState();
}

class _EulaDialogState extends State<_EulaDialog> {
  // ignore: prefer_final_fields
  Set<int> _expandedSections = {0}; // First section expanded by default

  final List<_EulaSection> _sections = const [
    _EulaSection(
      '제1조 (목적)',
      '본 약관은 SFX Memento Mori 서비스(이하 "서비스")의 이용조건 및 절차, 이용자와 서비스 제공자 간의 권리와 의무를 정함을 목적으로 합니다.',
    ),
    _EulaSection(
      '제2조 (정의)',
      '"서비스"란 사용자의 생년월일과 목표 나이를 기반으로 남은 인생 주수를 시각화하는 모바일 애플리케이션을 의미합니다.\n"이용자"란 본 서비스를 이용하는 사용자를 의미합니다.',
    ),
    _EulaSection(
      '제3조 (이용 계약의 성립)',
      '이용자가 본 약관에 동의하고 개인정보를 입력하면 이용 계약이 성립됩니다.',
    ),
    _EulaSection(
      '제4조 (개인정보 보호)',
      '본 서비스는 사용자의 생년월일과 목표 나이 정보를 장치 내에서만 저장하며, 외부 서버로 전송하지 않습니다.',
    ),
    _EulaSection(
      '제5조 (서비스 제공 및 변경)',
      '서비스 제공자는 서비스의 품질 개선을 위해 언제든지 서비스 내용을 변경할 수 있습니다.',
    ),
    _EulaSection(
      '제6조 (면책조항)',
      '본 서비스는 참고용 시각화 도구이며, 의학적·법학적 조언을 제공하지 않습니다.',
    ),
    _EulaSection(
      '제7조 (기타)',
      '본 약관에 명시되지 않은 사항은 관련 법령 및 서비스 제공자의 정책을 따릅니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: NeonColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NeonColors.neonGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: NeonColors.neonGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '서비스 이용약관',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: NeonColors.statsBorder, height: 1),
            // Collapsible sections
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _sections.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final section = _sections[index];
                  final isExpanded = _expandedSections.contains(index);
                  return Container(
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? NeonColors.darkGrey.withValues(alpha: 0.5)
                          : NeonColors.darkGrey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isExpanded
                            ? NeonColors.neonGreen.withValues(alpha: 0.2)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedSections.remove(index);
                              } else {
                                _expandedSections.add(index);
                              }
                            });
                          },
                          title: Text(
                            section.title,
                            style: TextStyle(
                              color: isExpanded
                                  ? NeonColors.neonGreen
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: Transform.rotate(
                              angle: isExpanded ? 3.14159 : 0,
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white54,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        if (isExpanded)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Text(
                              section.content,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ).animate()
                      .fadeIn(duration: 300.ms, delay: (index * 80).ms)
                      .slideY(begin: 0.2, end: 0, duration: 300.ms);
                },
              ),
            ),
            // Close button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: NeonColors.neonGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      '닫기',
                      style: TextStyle(
                        color: NeonColors.neonGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EulaSection {
  final String title;
  final String content;

  const _EulaSection(this.title, this.content);
}
