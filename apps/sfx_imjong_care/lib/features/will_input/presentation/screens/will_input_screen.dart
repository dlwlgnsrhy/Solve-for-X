import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sfx_imjong_care/core/constants/app_constants.dart';
import 'package:sfx_imjong_care/core/services/app_storage.dart';
import 'package:sfx_imjong_care/core/theme/neon_colors.dart';
import 'package:sfx_imjong_care/core/theme/app_typography.dart';
import 'package:sfx_imjong_care/core/theme/card_template.dart';
import 'package:sfx_imjong_care/features/will_input/domain/providers/will_form_provider.dart';
import 'package:sfx_imjong_care/features/will_input/domain/providers/card_template_provider.dart';
import 'package:sfx_imjong_care/features/will_input/domain/entities/will_card.dart';
import 'package:sfx_imjong_care/features/will_input/presentation/widgets/eula_checkbox.dart';
import 'package:sfx_imjong_care/features/will_input/presentation/widgets/value_input_field.dart';
import 'package:sfx_imjong_care/features/will_card/presentation/screens/will_card_screen.dart';
import 'package:sfx_imjong_care/features/card_history/presentation/widgets/card_history_section.dart';

class WillInputScreen extends ConsumerStatefulWidget {
  const WillInputScreen({super.key});

  @override
  ConsumerState<WillInputScreen> createState() => _WillInputScreenState();
}

class _WillInputScreenState extends ConsumerState<WillInputScreen> {
  bool _eulaChecked = false;
  bool _generating = false;

  final _nameController = TextEditingController();
  final _valueControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final _willController = TextEditingController();

  // ref is NOT available in initState() for ConsumerStatefulWidget.
  // It becomes available in didChangeDependencies(), so we restore state there
  // instead of in initState() to avoid a white-screen crash.
  // IMPORTANT: We guard against re-setting controllers on every dependency
  // change (keyboard dismiss, theme change, etc.) to prevent cursor jump /
  // input loss. We only restore when controllers are empty (first load).
  bool _hasRestoredState = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasRestoredState) return; // Guard: only restore once
    _hasRestoredState = true;
    final form = ref.read(willFormControllerProvider);
    if (_nameController.text.isEmpty) {
      _nameController.text = form.name;
    }
    for (var i = 0; i < 3; i++) {
      if (_valueControllers[i].text.isEmpty) {
        _valueControllers[i].text = form.values[i];
      }
    }
    if (_willController.text.isEmpty) {
      _willController.text = form.will;
    }
  }

  @override
  void didUpdateWidget(WillInputScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _valueControllers) {
      c.dispose();
    }
    _willController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    ref.read(willFormControllerProvider.notifier).updateName(value);
  }

  void _onValueChanged(int index, String value) {
    ref.read(willFormControllerProvider.notifier).updateValue(index, value);
  }

  void _onWillChanged(String value) {
    ref.read(willFormControllerProvider.notifier).updateWill(value);
  }

  bool get _canGenerate {
    return ref.read(willFormControllerProvider.notifier).isValid && _eulaChecked;
  }

  Future<void> _generateCard() async {
    if (_generating) return;
    setState(() => _generating = true);
    await Future.delayed(const Duration(milliseconds: 400));
    final form = ref.read(willFormControllerProvider);
    final templateState = ref.read(cardTemplateControllerProvider);
    final card = WillCard(
      name: form.name.trim(),
      values: form.values.map((v) => v.trim()).toList(),
      will: form.will.trim(),
    );
    final template = templateState.template;
    // Save card to history
    await AppStorage.addToCardHistory(card, template);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WillCardRenderScreen(
          card: card,
          template: template,
        ),
      ),
    );
    setState(() => _generating = false);
  }

  void _showEulaDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to click Agree/Close
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NeonColors.neonCyan, width: 1),
            boxShadow: [
              BoxShadow(
                color: NeonColors.neonCyan.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppConstants.eulaTitle,
                  style: AppTypography.eulaTitle,
                ),
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.25)),
              SizedBox(
                height: 350,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    AppConstants.eulaText,
                    style: AppTypography.eulaBody,
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.25)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '닫기',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _eulaChecked = true);
                        Navigator.pop(context);
                        // Consumer feedback: confirm agreement
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'EULA에 동의했습니다.',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                            ),
                            backgroundColor: const Color(0xFF00FF88),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF88),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '동의합니다',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: 0,
          maxHeight: double.infinity,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 24),
                      _buildTemplateSelector(),
                      const SizedBox(height: 20),
                      _buildCardHistory(),
                      const SizedBox(height: 24),
                      // Section divider
                      _buildSectionDivider(),
                      const SizedBox(height: 20),
                      _buildNameField(context),
                      const SizedBox(height: 24),
                      // Section divider
                      _buildSectionDivider(),
                      const SizedBox(height: 20),
                      _buildTitleSection('MY VALUES / 내 가치'),
                      const SizedBox(height: 16),
                      _buildValueFields(context),
                      const SizedBox(height: 24),
                      // Section divider
                      _buildSectionDivider(),
                      const SizedBox(height: 20),
                      _buildTitleSection('ONE-LINE WILL / 한 줄 유언'),
                      const SizedBox(height: 16),
                      _buildWillField(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              // EULA section with background container
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D15).withValues(alpha: 0.5),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    EulaCheckbox(
                      onChecked: (checked) {
                        setState(() {
                          _eulaChecked = checked;
                        });
                        // Consumer feedback: if EULA unchecked while form is valid,
                        // show a hint so the user knows why the button is disabled.
                        if (!checked && ref.read(willFormControllerProvider.notifier).isValid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                '카드 생성을 위해 EULA에 동의해주세요.',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                              ),
                              backgroundColor: const Color(0xFFFF00AA),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      onViewEula: _showEulaDialog,
                      initialValue: _eulaChecked,
                    ),
                    const SizedBox(height: 8),
                    // Disclaimer text
                    Text(
                      '카드는 실제 법적 효력이 없습니다. 엔터테인먼트 목적의 콘텐츠입니다.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: const Color(0xFF555555),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _GenerateButton(
                        enabled: _canGenerate,
                        generating: _generating,
                        onTap: _generateCard,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'SFX 임종 케어',
      style: AppTypography.titleLarge,
    );
  }

  Widget _buildTitleSection(String text) {
    return Text(
      text,
      style: AppTypography.sectionLabel,
    );
  }

  Widget _buildCardHistory() {
    return const CardHistorySection();
  }

  /// Subtle gradient section divider
  Widget _buildSectionDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSelector() {
    return Consumer(
      builder: (context, ref, child) {
        final templateState = ref.watch(cardTemplateControllerProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CARD STYLE / 카드 스타일',
              style: AppTypography.sectionLabel,
            ),
            const SizedBox(height: 14),
            Row(
              children: CardTemplate.values.map((template) {
                final isSelected = templateState.template == template;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(cardTemplateControllerProvider.notifier).setTemplate(template),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? template.accentColor : const Color(0xFF3A3A45),
                          width: isSelected ? 2 : 1,
                        ),
                        color: isSelected
                            ? template.accentColor.withValues(alpha: 0.12)
                            : const Color(0xFF1A1A25),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: template.accentColor.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          // Larger, more colorful preview icon
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        template.accentColor.withValues(alpha: 0.3),
                                        template.accentColor.withValues(alpha: 0.05),
                                      ],
                                    )
                                  : null,
                              border: isSelected
                                  ? Border.all(
                                      color: template.accentColor.withValues(alpha: 0.4),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Icon(
                              template.icon,
                              color: isSelected ? template.accentColor : const Color(0xFF888888),
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            template.name.split('/')[0].trim(),
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? template.accentColor : const Color(0xFF888888),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNameField(BuildContext context) {
    return NeonTextField(
      label: 'YOUR NAME / 당신의 이름',
      hintText: '이름을 입력하세요',
      onChanged: _onNameChanged,
      controller: _nameController,
      borderColor: NeonColors.neonPink,
      maxLength: 20,
      charCountHint: '최대 20자',
    );
  }

  Widget _buildValueFields(BuildContext context) {
    return Column(
      children: [
        NeonTextField(
          label: 'VALUE 1',
          hintText: '나의 가치 #1',
          onChanged: (v) => _onValueChanged(0, v),
          controller: _valueControllers[0],
          borderColor: NeonColors.neonCyan,
          maxLength: 30,
          charCountHint: '최대 30자',
        ),
        const SizedBox(height: 16),
        NeonTextField(
          label: 'VALUE 2',
          hintText: '나의 가치 #2',
          onChanged: (v) => _onValueChanged(1, v),
          controller: _valueControllers[1],
          borderColor: NeonColors.neonGreen,
          maxLength: 30,
          charCountHint: '최대 30자',
        ),
        const SizedBox(height: 16),
        NeonTextField(
          label: 'VALUE 3',
          hintText: '나의 가치 #3',
          onChanged: (v) => _onValueChanged(2, v),
          controller: _valueControllers[2],
          borderColor: NeonColors.neonPink,
          maxLength: 30,
          charCountHint: '최대 30자',
        ),
      ],
    );
  }

  Widget _buildWillField(BuildContext context) {
    return NeonTextField(
      label: 'YOUR WILL / 당신의 유언',
      hintText: '한 줄 유언을 입력하세요',
      onChanged: _onWillChanged,
      controller: _willController,
      borderColor: NeonColors.neonGreen,
      maxLines: 2,
      maxLength: 80,
      charCountHint: '최대 80자',
    );
  }
}

class _GenerateButton extends StatelessWidget {
  final bool enabled;
  final bool generating;
  final VoidCallback onTap;

  const _GenerateButton({
    required this.enabled,
    required this.generating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [
                  Color(0xFF00FF88),
                  Color(0xFF00CC6A),
                ],
              )
            : const LinearGradient(
                colors: [
                  Color(0xFF2A2A35),
                  Color(0xFF3A3A45),
                ],
              ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: -2,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: generating ? null : () {
            if (enabled) {
              onTap();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    '모든 필드를 입력하고 EULA에 동의해주세요.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                  ),
                  backgroundColor: const Color(0xFFFF00AA),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: generating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Center(
                  child: Text(
                    'CARD GENERATE / 카드 생성',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
