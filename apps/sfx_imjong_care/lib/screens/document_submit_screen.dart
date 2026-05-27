import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../models/will_card.dart';
import '../providers/language_provider.dart';
import '../utils/legal_validator.dart';

class DocumentSubmitScreen extends ConsumerStatefulWidget {
  final WillCardModel? customWillCard;
  const DocumentSubmitScreen({super.key, this.customWillCard});

  @override
  ConsumerState<DocumentSubmitScreen> createState() => _DocumentSubmitScreenState();
}

class _DocumentSubmitScreenState extends ConsumerState<DocumentSubmitScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedLawFirm = '법무법인 솔루니 상속 전문 센터';
  bool _isSubmitting = false;

  void _submitDraft(bool isEn) async {
    if (_phoneController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn ? 'Please fill in all contact information.' : '모든 연락처 정보를 입력해 주세요.',
          ),
          backgroundColor: AppTheme.heartStampRed,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    HapticFeedback.heavyImpact();

    // Simulate SSL/AES-256 secure encryption & transfer handshake
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      _showSuccessDialog(isEn);
    }
  }

  void _showSuccessDialog(bool isEn) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
        title: Row(
          children: [
            const Icon(Icons.verified, color: AppTheme.terracottaAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              isEn ? 'SECURELY SENT' : '서류 연동 발송 완료',
              style: GoogleFonts.notoSerifKr(
                fontWeight: FontWeight.bold,
                color: AppTheme.espressoText,
              ),
            ),
          ],
        ),
        content: Text(
          isEn
              ? 'Your draft will card has been encrypted with AES-256 and securely transmitted to "$_selectedLawFirm". A certified notary lawyer will review it within 24 hours.'
              : '작성하신 유언 엽서 원본 파일이 AES-256 암호화 처리를 거쳐 "$_selectedLawFirm"으로 안전하게 전송되었습니다. 공증 담당 상속 전문 변호사가 24시간 내에 서류 적격성을 검토한 뒤 연락을 취합니다.',
          style: GoogleFonts.notoSerifKr(
            fontSize: 13,
            height: 1.6,
            color: AppTheme.espressoText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back
            },
            child: Text(
              isEn ? 'Confirm' : '확인',
              style: const TextStyle(color: AppTheme.terracottaAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final isEn = locale == LanguageLocale.en;

    // Use default preview card if none passed
    final activeCard = widget.customWillCard ?? WillCardModel(
      id: 'preview',
      author: isEn ? 'Anonymous' : '익명',
      content: isEn 
          ? 'Write down your sincere words on the postcard first.' 
          : '먼저 메인화면의 작성하기 단추를 통해 진심 어린 엽서를 만들어 주세요.',
      questionPrompt: isEn 
          ? 'Reflection Question' 
          : '성찰 질문',
      createdAt: DateTime.now(),
    );

    final lawFirms = isEn ? [
      'Soluni Inheritance Specialists Law Firm',
      'Gangnam Notary Public Joint Office',
      'Central Law & Notary Corporation',
    ] : [
      '법무법인 솔루니 상속 전문 센터',
      '서울 강남 합동 공증인 사무소',
      '태평양 합동 법률공증사무소',
    ];

    if (!lawFirms.contains(_selectedLawFirm)) {
      _selectedLawFirm = lawFirms[0];
    }

    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.espressoText),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          isEn ? 'SECURE SEND' : '서류 연동 발송',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: AppTheme.espressoText,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security status badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: AppTheme.sepiaBorder, width: 1.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: AppTheme.terracottaAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? 'AES-256 Military Grade Encryption' : 'AES-256 군용 규격 종단간 암호화',
                            style: GoogleFonts.notoSerifKr(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.espressoText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEn 
                                ? 'Your private letter is protected securely during transmission.'
                                : '작성하신 성찰 편지의 사생활 보호를 위해 모든 데이터는 암호화 전송됩니다.',
                            style: GoogleFonts.notoSerifKr(
                              fontSize: 10,
                              color: AppTheme.espressoTextLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Draft Will Preview Section
              Text(
                isEn ? 'Draft Will Preview' : '전송할 유언 편지 가안',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.espressoText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: AppTheme.sepiaBorder, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isEn ? "Question: " : "질문: "}${activeCard.questionPrompt ?? ""}',
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.terracottaAccent,
                      ),
                    ),
                    const Divider(height: 16),
                    Text(
                      activeCard.content,
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 13,
                        height: 1.6,
                        color: AppTheme.espressoText,
                      ),
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${isEn ? "Signature" : "서명"}: ${activeCard.author}',
                          style: GoogleFonts.notoSerifKr(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.espressoText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 민법 제1060조 요식 요건 진단표
              Text(
                isEn ? 'Civil Act Article 1060 Legal Diagnosis' : '민법 제1060조 요식 요건 진단표',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.espressoText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: LegalValidator.validate(activeCard.content, author: activeCard.author).isFullyValid 
                        ? AppTheme.terracottaAccent
                        : AppTheme.heartStampRed.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    final validationResult = LegalValidator.validate(activeCard.content, author: activeCard.author);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: validationResult.isFullyValid
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                validationResult.isFullyValid ? Icons.check_circle : Icons.warning,
                                color: validationResult.isFullyValid
                                    ? const Color(0xFF2E7D32)
                                    : AppTheme.heartStampRed,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  validationResult.isFullyValid
                                      ? (isEn 
                                          ? '✓ Civil Act Art. 1060 Satisfied (Legally Prepared)' 
                                          : '✓ 민법 제1060조 충족 완료 (법적 효력 준비 완료)')
                                      : (isEn 
                                          ? '⚠️ Requirements Missing (Risk of Invalidity)' 
                                          : '⚠️ 필수 요건 미흡 (법적 효력 상실 우려)'),
                                  style: GoogleFonts.notoSerifKr(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: validationResult.isFullyValid
                                        ? const Color(0xFF2E7D32)
                                        : AppTheme.heartStampRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // The 4 requirements check list
                        _buildCheckItem(
                          isEn ? '1. Testator Name' : '1. 성명 (testator name)',
                          validationResult.hasName,
                          validationResult.matchedName,
                          isEn ? 'Please write your name in the letter content' : '성찰 내용 속에 본인의 이름을 명시해야 합니다.',
                          isEn,
                        ),
                        const Divider(height: 16),
                        _buildCheckItem(
                          isEn ? '2. Signature / Seal' : '2. 날인/서명 여부 (signature/seal)',
                          validationResult.hasSignature,
                          validationResult.matchedSignature,
                          isEn ? 'Include (Signature) or (Seal) at the end of content' : '내용 끝에 (인) 또는 (서명) 표시를 기재해야 합니다.',
                          isEn,
                        ),
                        const Divider(height: 16),
                        _buildCheckItem(
                          isEn ? '3. Specific Date' : '3. 연월일 (specific date)',
                          validationResult.hasDate,
                          validationResult.matchedDate,
                          isEn ? 'Specify year, month, and day (e.g. 2026.05.27)' : '연, 월, 일을 상세히 명시해야 합니다. (예: 2026년 5월 27일)',
                          isEn,
                        ),
                        const Divider(height: 16),
                        _buildCheckItem(
                          isEn ? '4. Physical Address' : '4. 주소 (physical address)',
                          validationResult.hasAddress,
                          validationResult.matchedAddress,
                          isEn ? 'Specify physical address in the content' : '구체적인 거주지 주소를 텍스트에 포함해야 합니다.',
                          isEn,
                        ),
                        
                        if (!validationResult.isFullyValid) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: AppTheme.creamBg,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(color: AppTheme.sepiaBorder, width: 1.0),
                            ),
                            child: Text(
                              isEn
                                  ? '⚠️ Under Korean Civil Act Article 1066, a holographic will must contain the testator\'s name, signature/seal, specific date, and detailed address inside the handwritten text to be legally binding.'
                                  : '⚠️ 대한민국 민법 제1066조에 의거하여, 자필증서에 의한 유언은 유언자가 그 전문과 연월일, 주소, 성명을 자서하고 날인(또는 서명)하여야 법적 효력을 갖습니다. 누락된 항목이 있을 시 유언의 효력이 상실될 수 있으므로, 뒤로 가기 후 유언 편집 화면에서 텍스트 내에 추가해 주시기 바랍니다.',
                              style: GoogleFonts.notoSerifKr(
                                fontSize: 10,
                                height: 1.5,
                                color: AppTheme.espressoTextLight,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }
                ),
              ),
              const SizedBox(height: 24),

              // Target law firm selector
              Text(
                isEn ? 'Select Partner Law Firm' : '제휴 법무법인 선택',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.espressoText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: AppTheme.sepiaBorder, width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLawFirm,
                    iconEnabledColor: AppTheme.terracottaAccent,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.espressoText,
                    ),
                    dropdownColor: AppTheme.cardBg,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedLawFirm = newValue;
                        });
                      }
                    },
                    items: lawFirms.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contact input form
              Text(
                isEn ? 'Contact Phone Number' : '연락처 (휴대폰 번호)',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.espressoText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: AppTheme.sepiaBorder, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 14,
                    color: AppTheme.espressoText,
                  ),
                  decoration: InputDecoration(
                    hintText: isEn ? 'e.g. +82 10-1234-5678' : '예: 010-1234-5678',
                    hintStyle: GoogleFonts.notoSerifKr(
                      fontSize: 13,
                      color: AppTheme.espressoTextLight.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                isEn ? 'Email Address' : '이메일 주소',
                style: GoogleFonts.notoSerifKr(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.espressoText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: AppTheme.sepiaBorder, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 14,
                    color: AppTheme.espressoText,
                  ),
                  decoration: InputDecoration(
                    hintText: isEn ? 'e.g. love@soluni.com' : '예: user@example.com',
                    hintStyle: GoogleFonts.notoSerifKr(
                      fontSize: 13,
                      color: AppTheme.espressoTextLight.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _submitDraft(isEn),
                  icon: _isSubmitting 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: AppTheme.creamBg, strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: AppTheme.creamBg),
                  label: Text(
                    _isSubmitting 
                        ? (isEn ? 'Encrypting & Sending...' : '암호화 전송 중...') 
                        : (isEn ? 'Send to Law Firm Securely' : '보안 연동 전송하기'),
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.creamBg,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.terracottaAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(String title, bool isSatisfied, String? matchedValue, String guideline, bool isEn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isSatisfied ? Icons.check_circle_outline : Icons.error_outline,
              color: isSatisfied ? const Color(0xFF2E7D32) : AppTheme.heartStampRed,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.notoSerifKr(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.espressoText,
              ),
            ),
            const Spacer(),
            Text(
              isSatisfied ? (isEn ? 'Detected' : '감지됨') : (isEn ? 'Missing' : '누락됨'),
              style: GoogleFonts.notoSerifKr(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSatisfied ? const Color(0xFF2E7D32) : AppTheme.heartStampRed,
              ),
            ),
          ],
        ),
        if (isSatisfied && matchedValue != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Text(
              '${isEn ? "Matched: " : "감지 내용: "}"$matchedValue"',
              style: GoogleFonts.notoSerifKr(
                fontSize: 12,
                color: AppTheme.espressoTextLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        if (!isSatisfied) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Text(
              guideline,
              style: GoogleFonts.notoSerifKr(
                fontSize: 11,
                color: AppTheme.espressoTextLight.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
