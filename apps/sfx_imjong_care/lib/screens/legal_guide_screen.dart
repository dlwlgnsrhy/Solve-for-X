import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../providers/language_provider.dart';

class LegalGuideScreen extends ConsumerStatefulWidget {
  const LegalGuideScreen({super.key});

  @override
  ConsumerState<LegalGuideScreen> createState() => _LegalGuideScreenState();
}

class _LegalGuideScreenState extends ConsumerState<LegalGuideScreen> {
  // Pre-notary checklist items state
  final Map<int, bool> _checklistChecked = {
    0: false,
    1: false,
    2: false,
    3: false,
    4: false,
  };

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final isEn = locale == LanguageLocale.en;

    final title = isEn ? 'LEGAL PREPARATION GUIDE' : '법률 및 유언공증 가이드';
    final subtitle = isEn 
        ? 'Ensure your final words hold full legal force under Civil Act.' 
        : '당신의 마지막 한마디가 민법상 온전한 효력을 가질 수 있도록 준비합니다.';

    final checklistTitle = isEn ? 'Pre-Notary Checklist' : '유언공증 사전 체크리스트';
    final checklistItems = isEn ? [
      'Original Resident Registration Certificate (주민등록등본)',
      'Family Relations Certificate (Detailed) (가족관계증명서 상세)',
      'Registered Seal Certificate of the Testator (유언자 인감증명서)',
      'Valid Photo IDs of 2 Qualified Witnesses (증인 2인의 신분증)',
      'Witness Certificates of Registered Seal (증인 2인의 인감증명서)',
    ] : [
      '유언자의 주민등록등본 1통',
      '유언자의 가족관계증명서(상세) 1통',
      '유언자의 인감증명서 1통',
      '증인 2인의 주민등록등본 및 각 인감증명서 각 1통',
      '증인 2인의 신분증 및 인감도장',
    ];

    final witnessWarningTitle = isEn ? '⚠️ Crucial Witness Qualifications' : '⚠️ 매우 중요한 증인 결격 사유';
    final witnessWarningBody = isEn 
        ? 'Under Civil Act Article 1072, the following persons CANNOT be witnesses. If any disqualifying person participates, the entire will becomes completely VOID:\n'
          '• Minors (under 19)\n'
          '• Beneficiaries of the will (수증자) and their spouses or direct blood relatives\n'
          '• Persons unable to read/write or see'
        : '민법 제1072조에 의거, 다음 사람은 증인이 될 수 없으며 결격자가 단 한 명이라도 입회하면 유언 공증 전체가 소급하여 무효가 됩니다:\n'
          '• 미성년자\n'
          '• 유언으로 이익을 받을 사람 (수증자), 그 배우자 및 직계혈족\n'
          '• 시각장애인 또는 문자를 알지 못하는 사람 등';

    final legalTypesTitle = isEn ? '5 Valid Will Types (Civil Act)' : '민법상 인정되는 5대 유언 방식';
    
    final legalTypes = [
      _WillTypeModel(
        title: isEn ? '1. Holographic Will (자필증서)' : '1. 자필증서에 의한 유언',
        body: isEn 
            ? 'Written entirely by testator\'s own hand (no print/typing allowed), specifying date, address, full name, and stamped/sealed. Easiest, but highest risk of formal invalidity.' 
            : '유언자가 전문과 연월일, 주소, 성명을 직접 손으로 쓰고 날인해야 합니다. 타이핑이나 대필은 전면 무효입니다. 보관 분실 위험이 높습니다.',
      ),
      _WillTypeModel(
        title: isEn ? '2. Notarial Document (공정증서)' : '2. 공정증서에 의한 유언 (추천)',
        body: isEn 
            ? 'Written by a notary public based on the oral statement of the testator in the presence of 2 witnesses. Highly robust, no court verification required after death.' 
            : '유언자가 증인 2명이 참여한 공증인 면전에서 취지를 말하고, 공증인이 필기 낭독하여 각자 서명날인합니다. 사후 법원 검인 없이 즉각 집행이 가능한 가장 안전한 방식입니다.',
      ),
      _WillTypeModel(
        title: isEn ? '3. Sound Recording (녹음)' : '3. 녹음에 의한 유언',
        body: isEn 
            ? 'Testator records their spoken will, stating their full name, date, and the witness states their name and verification orally.' 
            : '유언자가 유언의 취지, 성명과 연월일을 구두로 녹음하고, 입회한 증인이 유언의 정확함과 성명을 직접 녹음하여 완성합니다.',
      ),
      _WillTypeModel(
        title: isEn ? '4. Secret Document (비밀증서)' : '4. 비밀증서에 의한 유언',
        body: isEn 
            ? 'Written, sealed and presented to a notary/court within 5 days of signing with 2 witnesses to prove its existence without revealing contents.' 
            : '유언서의 내용을 비밀로 하고 밀봉하여 2명 이상의 증인에게 제출하여 봉인 서명날인 후, 5일 이내에 법원이나 공증인에게 확정일자를 받습니다.',
      ),
      _WillTypeModel(
        title: isEn ? '5. Dictation (구수증서)' : '5. 구수증서에 의한 유언',
        body: isEn 
            ? 'Used only in extreme emergency (disease/accident) where testator speaks to 1 witness in the presence of 2 others, who write and sign it. Must be verified by court within 7 days.' 
            : '질병이나 사고 등 급박한 사유 시, 2명 이상의 증인 입회하에 1명에게 유언을 받아 적게 하고 서명날인한 후, 사유 종료일로부터 7일 이내에 법원 검인을 받습니다.',
      ),
    ];

    final o2oTitle = isEn ? 'Connect to Partner Legal Services' : '제휴 리걸테크 전문 변호사 연계';
    final o2oBtn1 = isEn ? 'Find Local Notary Offices' : '📍 내 주변 공증 변호사/사무소 찾기';
    final o2oBtn2 = isEn ? 'Send Prep Documents via Email' : '✉️ 작성한 내용 제휴 법무법인 전송';

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
          isEn ? 'LEGAL GUIDE' : '법률 가이드',
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
              // Header description
              Text(
                title,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.espressoText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTheme.espressoTextLight,
                ),
              ),
              const Divider(height: 32),

              // 1. 5 legal types
              Text(
                legalTypesTitle,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.terracottaAccent,
                ),
              ),
              const SizedBox(height: 12),
              ...legalTypes.map((type) => Card(
                color: AppTheme.cardBg,
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                  side: const BorderSide(color: AppTheme.sepiaBorder, width: 1.0),
                ),
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ExpansionTile(
                  title: Text(
                    type.title,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.espressoText,
                    ),
                  ),
                  iconColor: AppTheme.terracottaAccent,
                  collapsedIconColor: AppTheme.espressoTextLight,
                  childrenPadding: const EdgeInsets.all(16.0),
                  children: [
                    Text(
                      type.body,
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 13,
                        height: 1.6,
                        color: AppTheme.espressoText,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 24),

              // 2. Checklist card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: AppTheme.sepiaBorder, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checklistTitle,
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.espressoText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(checklistItems.length, (index) {
                      final item = checklistItems[index];
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _checklistChecked[index] = !(_checklistChecked[index] ?? false);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Icon(
                                _checklistChecked[index] == true 
                                    ? Icons.check_box 
                                    : Icons.check_box_outline_blank,
                                color: _checklistChecked[index] == true 
                                    ? AppTheme.terracottaAccent 
                                    : AppTheme.espressoTextLight,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: GoogleFonts.notoSerifKr(
                                    fontSize: 13,
                                    color: _checklistChecked[index] == true 
                                        ? AppTheme.espressoTextLight 
                                        : AppTheme.espressoText,
                                    decoration: _checklistChecked[index] == true 
                                        ? TextDecoration.lineThrough 
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Witness Alert box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: AppTheme.terracottaAccent.withValues(alpha: 0.5), width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      witnessWarningTitle,
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.heartStampRed,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      witnessWarningBody,
                      style: GoogleFonts.notoSerifKr(
                        fontSize: 12,
                        height: 1.6,
                        color: AppTheme.espressoText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 4. O2O matching panel
              Text(
                o2oTitle,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.espressoText,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEn 
                              ? 'Searching for verified notary offices near you...' 
                              : '현재 위치 주변의 유언 전문 공증 변호사/사무소를 검색합니다...',
                        ),
                        backgroundColor: AppTheme.terracottaAccent,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.terracottaAccent, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  child: Text(
                    o2oBtn1,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.terracottaAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEn 
                              ? 'Connecting documents to partner Law Firm "Soluni Law"...' 
                              : '준비 서류를 제휴 법무법인 "솔루니 상속 전문 센터"로 연동 발송합니다...',
                        ),
                        backgroundColor: AppTheme.espressoText,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.espressoText,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  child: Text(
                    o2oBtn2,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.creamBg,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WillTypeModel {
  final String title;
  final String body;
  _WillTypeModel({required this.title, required this.body});
}
