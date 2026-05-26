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
  final WillCard? editCard;

  const WillInputScreen({super.key, this.editCard});

  @override
  ConsumerState<WillInputScreen> createState() => _WillInputScreenState();
}

class _WillInputScreenState extends ConsumerState<WillInputScreen> {
  bool _eulaChecked = false;
  bool _generating = false;
  bool _showErrors = false;

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

    if (widget.editCard != null) {
      // Force set form values for editing existing card to prevent routing data loss
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(willFormControllerProvider.notifier).setForm(widget.editCard!);
        }
      });
      _nameController.text = widget.editCard!.name;
      for (var i = 0; i < 3; i++) {
        _valueControllers[i].text = widget.editCard!.values[i];
      }
      _willController.text = widget.editCard!.will;
    } else {
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
    
    // Restore persistent EULA state
    AppStorage.isEulaAccepted().then((accepted) {
      if (mounted) {
        setState(() {
          _eulaChecked = accepted;
        });
      }
    });
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

  void _handleGenerateTap() {
    if (_generating) return;

    final form = ref.read(willFormControllerProvider);
    final isFormValid = ref.read(willFormControllerProvider.notifier).isValid;

    if (isFormValid && _eulaChecked) {
      _generateCard();
    } else {
      setState(() {
        _showErrors = true;
      });

      String errorMessage = '모든 필드를 입력하고 EULA에 동의해주세요.';
      if (!isFormValid) {
        if (form.name.trim().isEmpty) {
          errorMessage = '이름을 입력해주세요.';
        } else if (form.values.any((v) => v.trim().isEmpty)) {
          errorMessage = '내 가치를 모두 입력해주세요.';
        } else if (form.will.trim().isEmpty) {
          errorMessage = '한 줄 유언을 입력해주세요.';
        }
      } else if (!_eulaChecked) {
        errorMessage = '카드 생성을 위해 EULA에 동의해주세요.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
          ),
          backgroundColor: const Color(0xFFFF0055),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                        AppStorage.setEulaAccepted(true);
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

  int _currentPromptIndex = 0;

  static const List<_LifeValuePrompt> _prompts = [
    _LifeValuePrompt(
      question: '내 장례식에서 사람들이 슬피 우는 대신 신나게 춤출 수 있도록 틀어줬으면 하는 단 하나의 노래는?',
      suggestedValues: ['음악과 축제', '마지막 댄스', '유쾌한 작별'],
      suggestedWill: '슬퍼하기보다 나의 마지막 플레이리스트를 들으며 신나게 춤춰줘!',
    ),
    _LifeValuePrompt(
      question: '오늘 밤 지구의 생이 마감된다면, 지인들에게 꼭 추천하고 싶은 내 인생 최애 명작은?',
      suggestedValues: ['예술적 영감', '최고의 명작', '지혜의 전수'],
      suggestedWill: '우리가 함께 살아온 날들은 한 편의 영화보다 훨씬 찬란했던 명작이었어.',
    ),
    _LifeValuePrompt(
      question: '내 장례식장에 조의금 봉투 대신 들고 왔으면 하는 내가 가장 좋아하던 꽃이나 간식은?',
      suggestedValues: ['달콤한 추억', '화사한 꽃다발', '소박한 작별'],
      suggestedWill: '조의금 대신 맛있는 마카롱과 따뜻한 아메리카노 한 잔씩 들고 가볍게 모여줘.',
    ),
    _LifeValuePrompt(
      question: '사후 세계로 갈 때 단 하나의 소지품만 가방에 넣어갈 수 있다면 무엇을 가져갈 것인가?',
      suggestedValues: ['소중한 사진첩', '낡은 손편지', '추억의 물건'],
      suggestedWill: '그 어떤 보석보다 우리들이 함께 웃으며 찍은 사진 한 장이 내 가방 속 최고 보물이야.',
    ),
    _LifeValuePrompt(
      question: '먼 훗날 나의 힙한 묘비명(슬로건)을 딱 한 줄로 유쾌하게 정의한다면?',
      suggestedValues: ['유쾌한 인생', '힙한 작별인사', '잠시 쉬어가기'],
      suggestedWill: '실컷 놀다 갑니다! 너희도 남은 생 후회 없이 뜨겁게 놀아라!',
    ),
    _LifeValuePrompt(
      question: '내가 사라진 후, 지인들이 나를 떠올릴 때 기억해 줬으면 하는 나의 가장 해맑은 버릇은?',
      suggestedValues: ['해맑은 웃음', '익살스런 윙크', '따뜻한 포옹'],
      suggestedWill: '슬퍼하기보다 내 멍청했던 윙크를 기억하며 다들 배꼽 빠지게 한번 웃어주렴.',
    ),
    _LifeValuePrompt(
      question: '남겨진 소중한 가족/친구들에게 비밀로 숨겨둔 마지막 맛집 보물 지도를 양도한다면?',
      suggestedValues: ['숨겨진 맛집', '소소한 비상금', '맛있는 공유'],
      suggestedWill: '냉장고 뒤편 상자에 비상금이 있어! 그걸로 다들 내 단골 떡볶이집에서 먹방 파티해줘.',
    ),
  ];

  void _shufflePrompt() {
    setState(() {
      _currentPromptIndex = (_currentPromptIndex + 1) % _prompts.length;
    });
  }

  void _applyPrompt() {
    final prompt = _prompts[_currentPromptIndex];
    if (_nameController.text.isEmpty) {
      _nameController.text = '임종 버디';
      _onNameChanged('임종 버디');
    }
    for (var i = 0; i < 3; i++) {
      _valueControllers[i].text = prompt.suggestedValues[i];
      _onValueChanged(i, prompt.suggestedValues[i]);
    }
    _willController.text = prompt.suggestedWill;
    _onWillChanged(prompt.suggestedWill);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '💡 질문 카드 내용이 입력 폼에 기품 있게 반영되었습니다!',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.black),
        ),
        backgroundColor: Color(0xFF00FF88),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch willFormControllerProvider to trigger real-time validation updates
    ref.watch(willFormControllerProvider);

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
                      const SizedBox(height: 16),
                      _buildPromptDeck(),
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
                        AppStorage.setEulaAccepted(checked);
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
                        onTap: _handleGenerateTap,
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

  Widget _buildPromptDeck() {
    final prompt = _prompts[_currentPromptIndex];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E2A), Color(0xFF13131C)],
        ),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF88).withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_incandescent_outlined, color: Color(0xFF00FF88), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'LIFE QUESTION / 성찰 질문 카드',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00FF88).withValues(alpha: 0.8),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _shufflePrompt,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.casino_outlined, color: Color(0xFF00FF88), size: 12),
                      SizedBox(width: 4),
                      Text(
                        'SHUFFLE',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00FF88),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            prompt.question,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _applyPrompt,
                icon: const Icon(Icons.auto_fix_high, size: 14),
                label: const Text(
                  '예시 답변 적용하기',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF88),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
    final form = ref.read(willFormControllerProvider);
    return NeonTextField(
      label: 'YOUR NAME / 당신의 이름',
      hintText: '이름을 입력하세요',
      onChanged: _onNameChanged,
      controller: _nameController,
      borderColor: NeonColors.neonPink,
      maxLength: 20,
      charCountHint: '최대 20자',
      errorText: _showErrors && form.name.trim().isEmpty ? '이름을 입력해주세요.' : null,
    );
  }

  Widget _buildValueFields(BuildContext context) {
    final form = ref.read(willFormControllerProvider);
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
          errorText: _showErrors && form.values[0].trim().isEmpty ? '첫 번째 가치를 입력해주세요.' : null,
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
          errorText: _showErrors && form.values[1].trim().isEmpty ? '두 번째 가치를 입력해주세요.' : null,
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
          errorText: _showErrors && form.values[2].trim().isEmpty ? '세 번째 가치를 입력해주세요.' : null,
        ),
      ],
    );
  }

  Widget _buildWillField(BuildContext context) {
    final form = ref.read(willFormControllerProvider);
    return NeonTextField(
      label: 'YOUR WILL / 당신의 유언',
      hintText: '한 줄 유언을 입력하세요',
      onChanged: _onWillChanged,
      controller: _willController,
      borderColor: NeonColors.neonGreen,
      maxLines: 2,
      maxLength: 80,
      charCountHint: '최대 80자',
      errorText: _showErrors && form.will.trim().isEmpty ? '한 줄 유언을 입력해주세요.' : null,
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
          onTap: generating ? null : onTap,
          child: generating
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
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

class _LifeValuePrompt {
  final String question;
  final List<String> suggestedValues;
  final String suggestedWill;

  const _LifeValuePrompt({
    required this.question,
    required this.suggestedValues,
    required this.suggestedWill,
  });
}
