import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../providers/language_provider.dart';

class NotaryMapScreen extends ConsumerWidget {
  const NotaryMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isEn = locale == LanguageLocale.en;

    final title = isEn ? 'FIND NOTARY OFFICES' : '내 주변 공증 사무소 찾기';
    final subtitle = isEn 
        ? 'Showing verified legal notary offices within 5km from your location.' 
        : '현재 위치에서 5km 이내의 검증된 공증 인가 법무법인을 조회합니다.';

    final notaryList = [
      _NotaryOffice(
        name: isEn ? 'Soluni Inheritance Specialists Law Firm' : '법무법인 솔루니 상속 전문 센터',
        address: isEn 
            ? '12F, Tehran-ro 427, Gangnam-gu, Seoul' 
            : '서울특별시 강남구 테헤란로 427, 12층',
        distance: '1.2 km',
        phone: '02-555-9876',
        rating: '4.9',
      ),
      _NotaryOffice(
        name: isEn ? 'Gangnam Notary Public Joint Office' : '서울 강남 합동 공증인 사무소',
        address: isEn 
            ? '3F, Yeoksam-ro 108, Gangnam-gu, Seoul' 
            : '서울특별시 강남구 역삼로 108, 3층',
        distance: '2.5 km',
        phone: '02-345-1234',
        rating: '4.7',
      ),
      _NotaryOffice(
        name: isEn ? 'Central Law & Notary Corporation' : '태평양 합동 법률공증사무소',
        address: isEn 
            ? '8F, Seocho-daero 280, Seocho-gu, Seoul' 
            : '서울특별시 서초구 서초대로 280, 8층',
        distance: '4.1 km',
        phone: '02-588-4567',
        rating: '4.8',
      ),
    ];

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
          isEn ? 'FIND NOTARY' : '공증인 매칭',
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map Visual Mock box
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: AppTheme.sepiaBorder, width: 1.5),
                ),
                child: Stack(
                  children: [
                    // Mock Gridlines to simulate Map GPS
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                          itemBuilder: (context, index) => Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.espressoText, width: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Mock Pins and circles
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.terracottaAccent.withValues(alpha: 0.15),
                          border: Border.all(color: AppTheme.terracottaAccent, width: 1.0),
                        ),
                      ),
                    ),
                    const Center(
                      child: Icon(Icons.my_location, color: AppTheme.terracottaAccent, size: 24),
                    ),
                    // Mock Pins around
                    const Positioned(
                      top: 40,
                      left: 80,
                      child: Icon(Icons.location_on, color: AppTheme.heartStampRed, size: 30),
                    ),
                    const Positioned(
                      bottom: 50,
                      right: 90,
                      child: Icon(Icons.location_on, color: AppTheme.espressoText, size: 30),
                    ),
                    const Positioned(
                      top: 60,
                      right: 120,
                      child: Icon(Icons.location_on, color: AppTheme.espressoText, size: 30),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                title,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.espressoText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 12,
                  color: AppTheme.espressoTextLight,
                ),
              ),
              const Divider(height: 24),

              Expanded(
                child: ListView.builder(
                  itemCount: notaryList.length,
                  itemBuilder: (context, index) {
                    final office = notaryList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: AppTheme.sepiaBorder, width: 1.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  office.name,
                                  style: GoogleFonts.notoSerifKr(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.espressoText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.terracottaAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                                child: Text(
                                  office.distance,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.terracottaAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            office.address,
                            style: GoogleFonts.notoSerifKr(
                              fontSize: 12,
                              color: AppTheme.espressoTextLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                office.rating,
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.espressoText,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _showBookingCompletedDialog(context, office.name, isEn);
                                },
                                icon: const Icon(Icons.calendar_month, size: 14, color: AppTheme.terracottaAccent),
                                label: Text(
                                  isEn ? 'Book Appointment' : '예약하기',
                                  style: GoogleFonts.notoSerifKr(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.terracottaAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingCompletedDialog(BuildContext context, String officeName, bool isEn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(
          isEn ? 'Appointment Request' : '상담 예약 신청 완료',
          style: GoogleFonts.notoSerifKr(
            fontWeight: FontWeight.bold,
            color: AppTheme.espressoText,
          ),
        ),
        content: Text(
          isEn 
              ? 'Your booking request for a notary consultation at "$officeName" has been submitted. A staff member will contact you shortly.'
              : '"$officeName"에 유언공증 대면상담 예약 신청이 전송되었습니다. 담당 서기가 24시간 내에 연락드립니다.',
          style: GoogleFonts.notoSerifKr(color: AppTheme.espressoText, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isEn ? 'Confirm' : '확인',
              style: const TextStyle(color: AppTheme.terracottaAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotaryOffice {
  final String name;
  final String address;
  final String distance;
  final String phone;
  final String rating;

  _NotaryOffice({
    required this.name,
    required this.address,
    required this.distance,
    required this.phone,
    required this.rating,
  });
}
