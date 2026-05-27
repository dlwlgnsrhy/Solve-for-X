import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sfx_imjong_care/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full User Journey Integration Test', (WidgetTester tester) async {
    // Save the original builder to satisfy TestWidgetsFlutterBinding verification
    final originalErrorBuilder = ErrorWidget.builder;

    try {
      // Start application
      app.main();
      await tester.pumpAndSettle();

      // 1. Home Screen (Front of the card)
      print('[SCREENSHOT] stage_1_home_front');
      await Future.delayed(const Duration(seconds: 4)); // allow screenshot script to snap

      // 2. Test Language Switcher
      print('[INTEGRATION] Action: Toggle Language to English');
      final langToggle = find.byKey(const ValueKey('lang_toggle_btn'));
      expect(langToggle, findsOneWidget);
      await tester.tap(langToggle);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      print('[INTEGRATION] Action: Toggle Language back to Korean');
      await tester.tap(langToggle);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      // 3. Flip the card to Back
      print('[INTEGRATION] Action: Flip Card to Back');
      final flipButton = find.text('뒷면 보기');
      expect(flipButton, findsOneWidget);
      await tester.tap(flipButton);
      await tester.pumpAndSettle();
      
      print('[SCREENSHOT] stage_2_home_back');
      await Future.delayed(const Duration(seconds: 4)); // allow screenshot script to snap

      // 4. Flip back to Front
      print('[INTEGRATION] Action: Flip Card to Front');
      final frontButton = find.text('앞면 보기');
      expect(frontButton, findsOneWidget);
      await tester.tap(frontButton);
      await tester.pumpAndSettle();

      // 5. Tap Info Button to show Dialog
      print('[INTEGRATION] Action: Open Info Dialog');
      final infoButton = find.byIcon(Icons.info_outline);
      expect(infoButton, findsOneWidget);
      await tester.tap(infoButton);
      await tester.pumpAndSettle();
      
      print('[SCREENSHOT] stage_3_info_dialog');
      await Future.delayed(const Duration(seconds: 4)); // allow screenshot script to snap

      // 6. Dismiss Dialog
      print('[INTEGRATION] Action: Close Info Dialog');
      final okButton = find.text('확인');
      expect(okButton, findsOneWidget);
      await tester.tap(okButton);
      await tester.pumpAndSettle();

      // 7. Navigate to Empathy Feed Screen
      print('[INTEGRATION] Action: Open Empathy Feed Screen');
      final feedButton = find.byIcon(Icons.forum_outlined);
      expect(feedButton, findsOneWidget);
      await tester.tap(feedButton);
      await tester.pumpAndSettle();
      
      print('[SCREENSHOT] stage_4_empathy_feed');
      await Future.delayed(const Duration(seconds: 4)); // allow screenshot script to snap

      // Go back to Home Screen
      print('[INTEGRATION] Action: Back to Home Screen');
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // 8. Test Navigation to Legal Guide Screen
      print('[INTEGRATION] Action: Open Legal Guide Screen');
      final legalGuideBtn = find.text('⚖️ 유언공증 & 법률 준비 가이드');
      expect(legalGuideBtn, findsOneWidget);
      await tester.tap(legalGuideBtn);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      // Expand Notary Type Card
      print('[INTEGRATION] Action: Expand Legal Will Notarial Type');
      final expansionTile = find.text('2. 공정증서에 의한 유언 (추천)');
      expect(expansionTile, findsOneWidget);
      await tester.tap(expansionTile);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      // Click checklist item
      print('[INTEGRATION] Action: Click Checklist Item');
      final checklistItem = find.text('유언자의 주민등록등본 1통');
      expect(checklistItem, findsOneWidget);
      await tester.tap(checklistItem);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      // 8b. Click OutlinedButton to open NotaryMapScreen
      print('[INTEGRATION] Action: Open Notary Map Screen');
      final findNotaryBtn = find.text('📍 내 주변 공증 변호사/사무소 찾기');
      expect(findNotaryBtn, findsOneWidget);
      await tester.ensureVisible(findNotaryBtn);
      await tester.pumpAndSettle();
      await tester.tap(findNotaryBtn);
      await tester.pumpAndSettle();
      
      print('[SCREENSHOT] stage_8_notary_map');
      await Future.delayed(const Duration(seconds: 4)); // allow screenshot script to snap
      
      // Go back from NotaryMapScreen
      print('[INTEGRATION] Action: Go Back from Notary Map');
      final mapBackBtn = find.byIcon(Icons.arrow_back);
      expect(mapBackBtn, findsOneWidget);
      await tester.tap(mapBackBtn);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      // 8c. Click ElevatedButton to open DocumentSubmitScreen
      print('[INTEGRATION] Action: Open Document Submit Screen');
      final sendDocBtn = find.text('✉️ 작성한 내용 제휴 법무법인 전송');
      expect(sendDocBtn, findsOneWidget);
      await tester.ensureVisible(sendDocBtn);
      await tester.pumpAndSettle();
      await tester.tap(sendDocBtn);
      await tester.pumpAndSettle();
      
      print('[SCREENSHOT] stage_9_document_submit');
      await Future.delayed(const Duration(seconds: 4)); // allow screenshot script to snap
      
      // Go back from DocumentSubmitScreen
      print('[INTEGRATION] Action: Go Back from Document Submit');
      final submitBackBtn = find.byIcon(Icons.arrow_back);
      expect(submitBackBtn, findsOneWidget);
      await tester.tap(submitBackBtn);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      // Go back to Home Screen from Legal Guide
      print('[INTEGRATION] Action: Go Back from Legal Guide');
      final legalBackBtn = find.byIcon(Icons.arrow_back);
      expect(legalBackBtn, findsOneWidget);
      await tester.tap(legalBackBtn);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      // 9. Navigate to Will Editor Screen
      print('[INTEGRATION] Action: Open Will Editor Screen');
      final writeButton = find.text('마지막 편지 작성하기');
      expect(writeButton, findsOneWidget);
      await tester.tap(writeButton);
      await tester.pumpAndSettle();
      
      print('[SCREENSHOT] stage_5_will_editor');
      await Future.delayed(const Duration(seconds: 4)); // allow screenshot script to snap

      // 10. Test Question Shuffling in Editor
      print('[INTEGRATION] Action: Shuffle Questions');
      final shuffleButton = find.byIcon(Icons.shuffle);
      expect(shuffleButton, findsOneWidget);
      await tester.tap(shuffleButton);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      // 11. Test Template Injection
      print('[INTEGRATION] Action: Inject Template Answer');
      final templateButton = find.text('이 질문의 답변 템플릿 가져오기');
      expect(templateButton, findsOneWidget);
      await tester.tap(templateButton);
      await tester.pumpAndSettle();
      
      print('[SCREENSHOT] stage_5_will_editor_template');
      await Future.delayed(const Duration(seconds: 4)); // allow screenshot script to snap

      // 12. Enter Legal Holographic Will Content and Author Name
      print('[INTEGRATION] Action: Enter Legal Holographic Will Content and Author Name');
      final textFields = find.byType(TextField);
      // Editor has two text fields: content (index 0) and author (index 1)
      await tester.enterText(textFields.at(0), '유언자 테스터 지훈은 2026년 05월 27일에 서울시 강남구 테헤란로 152에서 이 글을 유언서로 남깁니다. (서명)');
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));
      await tester.enterText(textFields.at(1), '테스터 지훈');
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      // 13. Click "3D 아날로그 엽서 생성하기"
      print('[INTEGRATION] Action: Click Generate Postcard');
      final generateButton = find.text('3D 아날로그 엽서 생성하기');
      expect(generateButton, findsOneWidget);
      await tester.tap(generateButton);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 5)); // Allow uploading/local fallback navigation
      await tester.pumpAndSettle();

      // 14. View generated custom postcard
      print('[SCREENSHOT] stage_6_custom_postcard_front');
      await Future.delayed(const Duration(seconds: 4)); // allow screenshot script to snap

      // 15. Flip generated custom postcard to Back
      print('[INTEGRATION] Action: Flip Custom Postcard to Back');
      final customFlipButton = find.text('뒷면 보기');
      expect(customFlipButton, findsOneWidget);
      await tester.tap(customFlipButton);
      await tester.pumpAndSettle();
      
      print('[SCREENSHOT] stage_7_custom_postcard_back');
      await Future.delayed(const Duration(seconds: 4)); // allow screenshot script to snap

      // 16. Click Legal Guide button from custom postcard
      print('[INTEGRATION] Action: Open Legal Guide from Custom Postcard');
      final customLegalGuideBtn = find.text('⚖️ 유언공증 & 법률 준비 가이드');
      expect(customLegalGuideBtn, findsOneWidget);
      await tester.ensureVisible(customLegalGuideBtn);
      await tester.pumpAndSettle();
      await tester.tap(customLegalGuideBtn);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      // 17. Click send to law firm to view DocumentSubmitScreen
      print('[INTEGRATION] Action: Open Document Submit from Legal Guide');
      final customSendDocBtn = find.text('✉️ 작성한 내용 제휴 법무법인 전송');
      expect(customSendDocBtn, findsOneWidget);
      await tester.ensureVisible(customSendDocBtn);
      await tester.pumpAndSettle();
      await tester.tap(customSendDocBtn);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      // 18. DocumentSubmitScreen showing all requirements met (stage_10_legal_validated)
      print('[SCREENSHOT] stage_10_legal_validated');
      await Future.delayed(const Duration(seconds: 4)); // allow screenshot script to snap
    } finally {
      // Restore original error builder to prevent TestWidgetsFlutterBinding assertion crash
      ErrorWidget.builder = originalErrorBuilder;
    }
  });
}
