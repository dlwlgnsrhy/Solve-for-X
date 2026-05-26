import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/will_card_model.dart';

/// 유서(WillCardModel)의 생성(Create), 수정(Update), 삭제(Delete) 라이프사이클을
/// 전역적으로 관장하고 변경 상태를 UI 레이어로 실시간/반응형으로 전파하는 핵심 StateNotifier입니다.
class WillStateNotifier extends StateNotifier<List<WillCardModel>> {
  WillStateNotifier() : super(_initialWills);

  // HTML 원본 파일의 4가지 유서 데이터를 프리미엄 템플릿 정보와 함께 기본 적재
  static final List<WillCardModel> _initialWills = [
    WillCardModel(
      uuid: 'will-001',
      content: '우리가 함께한 소중한 시간들을\n따뜻한 기억으로 간직해주렴.',
      author: 'Imjong Care',
      styleId: 'classic',
      updatedAt: DateTime(2026, 5, 26, 9, 0, 0),
    ),
    WillCardModel(
      uuid: 'will-002',
      content: '부족한 나를 늘 응원해주고\n사랑해줘서 정말 고마웠어.',
      author: 'Imjong Care',
      styleId: 'warm',
      updatedAt: DateTime(2026, 5, 26, 9, 0, 0),
    ),
    WillCardModel(
      uuid: 'will-003',
      content: '슬퍼하기보다는 우리가 나눈\n웃음들을 떠올려주길 바란다.',
      author: 'Imjong Care',
      styleId: 'serene',
      updatedAt: DateTime(2026, 5, 26, 9, 0, 0),
    ),
    WillCardModel(
      uuid: 'will-004',
      content: '너희의 앞날에 늘 햇살 같은\n평온함이 가득하기를 빌게.',
      author: 'Imjong Care',
      styleId: 'hopeful',
      updatedAt: DateTime(2026, 5, 26, 9, 0, 0),
    ),
  ];

  /// 새로운 유서(WillCardModel)를 상태 리스트에 영구히 추가합니다.
  void createWill(WillCardModel will) {
    state = [...state, will];
  }

  /// 특정 ID를 식별하여 기존 유서의 세부 내용을 무결하게 수정 및 치환합니다.
  void updateWill(WillCardModel updatedWill) {
    state = [
      for (final will in state)
        if (will.uuid == updatedWill.uuid) updatedWill else will
    ];
  }

  /// 고유 식별자(UUID)를 기반으로 해당 유서를 영속 리스트에서 반응형으로 삭제합니다.
  void deleteWill(String uuid) {
    state = state.where((will) => will.uuid != uuid).toList();
  }
}

/// 전역 앱 상태 전파를 지원하는 글로벌 Riverpod Provider 정의입니다.
final willStateProvider =
    StateNotifierProvider<WillStateNotifier, List<WillCardModel>>((ref) {
  return WillStateNotifier();
});
