import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LanguageLocale { ko, en }

class LocalizationPack {
  final LanguageLocale locale;
  LocalizationPack(this.locale);

  String translate(String key) {
    if (locale == LanguageLocale.en) {
      return _en[key] ?? key;
    }
    return _ko[key] ?? key;
  }

  static const Map<String, String> _ko = {
    'post_card': 'POST CARD',
    'reflection_question': 'Reflection Question',
    'sender': '보내는 사람',
    'date': '작성일',
    'my_last_will': 'MY LAST WILL',
    'signature': '서명',
    'view_back': '뒷면 보기',
    'view_front': '앞면 보기',
    'share_postcard': '엽서 이미지 공유',
    'write_will': '마지막 편지 작성하기',
    'write_will_title': 'WRITE WILL',
    'legal_guide': '⚖️ 유언공증 & 법률 준비 가이드',
    'tap_to_flip': '엽서를 터치하여 돌려보세요',
    'info_guide': '엽서 사용 설명서',
    'info_step1': '1. 앞뒷면 보기: 엽서를 누르거나 아래 \'앞/뒷면 보기\' 버튼을 클릭해 엽서의 앞뒷면을 뒤집을 수 있습니다.',
    'info_step2': '2. 공유하기: \'엽서 이미지 공유\' 단추를 클릭해 아날로그 감성이 담긴 엽서를 이미지 파일로 보존하고 공유할 수 있습니다.',
    'info_step3': '3. 편지 작성: 메인화면 하단의 작성 단추를 눌러 성찰 질문과 프리필 가이드를 활용해 엽서를 직접 디자인하고 생성할 수 있습니다.',
    'close': '확인',
    
    // Editor screen
    'letter_content': '편지 내용',
    'content_hint': '여기에 진심을 담아 마지막 한마디를 적어 내려가 보세요...\n(상단의 성찰 질문을 활용하면 보다 편하게 적을 수 있습니다)',
    'author_signature': '서명인 이름',
    'author_hint': '이름을 적어주세요 (기본값: 익명)',
    'get_template': '이 질문의 답변 템플릿 가져오기',
    'generate_card': '3D 아날로그 엽서 생성하기',
    'error_title': '작성 오류',
    'error_empty_content': '마지막 편지의 내용을 입력해 주세요.',
    'offline_fallback': '오프라인 환경으로 전환되어 로컬 엽서 뷰어로 안전하게 연결합니다.',
    'template_applied': '성찰 답변 가이드라인이 주입되었습니다.',
    
    // Sample card
    'sample_author': '홍길동',
    'sample_question': 'Q. 사랑하는 이들에게 평소 말하지 못했던, 가슴속 깊이 묻어둔 고마운 기억은 무엇인가요?',
    'sample_content': '내가 먼저 떠나도 슬퍼하지 마세요.\n우리가 나누었던 그 따스했던 미소와 다정한 말들은\n바람이 되어 언제나 당신 곁에 머물 것입니다.\n사랑합니다, 그리고 고맙습니다.',
  };

  static const Map<String, String> _en = {
    'post_card': 'POST CARD',
    'reflection_question': 'Reflection Question',
    'sender': 'Sender',
    'date': 'Date',
    'my_last_will': 'MY LAST WILL',
    'signature': 'Signature',
    'view_back': 'View Back',
    'view_front': 'View Front',
    'share_postcard': 'Share Postcard',
    'write_will': 'Write Last Letter',
    'write_will_title': 'WRITE WILL',
    'legal_guide': '⚖️ Will Notary & Legal Preparation Guide',
    'tap_to_flip': 'Tap the postcard to flip it',
    'info_guide': 'Postcard User Guide',
    'info_step1': '1. View Back/Front: Tap the postcard or click the \'View Back\' button below to flip the postcard.',
    'info_step2': '2. Share: Click the \'Share Postcard\' button to save and share your elegant analog postcard as a high-res image file.',
    'info_step3': '3. Write Will: Click the write button at the bottom of the main screen to design and generate your custom postcard using reflection questions and preset guidance.',
    'close': 'Confirm',
    
    // Editor screen
    'letter_content': 'Letter Content',
    'content_hint': 'Write down your sincere final words here...\n(You can use the reflection questions above to help write your letter)',
    'author_signature': 'Your Signature Name',
    'author_hint': 'Enter your name (Default: Anonymous)',
    'get_template': 'Get Sincere Answer Template',
    'generate_card': 'Generate 3D Postcard',
    'error_title': 'Writing Error',
    'error_empty_content': 'Please enter the content of your final letter.',
    'offline_fallback': 'Offline mode activated. Safely connecting to local postcard viewer.',
    'template_applied': 'Sincere reflective answer template has been auto-filled.',
    
    // Sample card
    'sample_author': 'John Doe',
    'sample_question': 'Q. What is a deeply cherished memory with your loved ones that you never expressed before?',
    'sample_content': 'Please do not grieve even if I depart first.\nThe warm smiles and tender words we shared\nwill become the gentle breeze, always lingering by your side.\nI love you, and thank you from the bottom of my heart.',
  };
}

class LocalizedQuestions {
  static const List<String> koQuestions = [
    "Q. 사랑하는 이들에게 평소 말하지 못했던, 가슴속 깊이 묻어둔 고마운 기억은 무엇인가요?",
    "Q. 내가 떠난 후, 남겨진 사람들이 나를 기억할 때 떠올려 주었으면 하는 모습이 있나요?",
    "Q. 인생의 마지막 여정에서 가장 아름다웠던 한 순간을 고른다면 언제인가요?",
    "Q. 지금 당장 내일 떠난다면, 가장 미안해서 마음 한구석이 아련해지는 사람은 누구인가요?",
    "Q. 남겨진 소중한 이들에게 남기는 마지막 조언이나 응원의 한마디는 무엇인가요?",
    "Q. 인생을 돌아보며 나 스스로에게 가장 칭찬해주고 싶은 나의 자랑스러운 선택은 무엇인가요?",
    "Q. 나의 소중한 물건이나 유품을 누구에게 어떤 마음으로 전하고 싶나요?"
  ];

  static const List<String> enQuestions = [
    "Q. What is a deeply cherished memory with your loved ones that you never expressed before?",
    "Q. What image of yourself do you want people to remember and hold onto after you depart?",
    "Q. If you had to choose the most beautiful single moment of your life journey, when would it be?",
    "Q. If you had to depart tomorrow, who is the person you feel most apologetic towards in your heart?",
    "Q. What is your final word of advice or encouragement to those you leave behind?",
    "Q. Looking back on your life, what is the proudest choice you would most praise yourself for?",
    "Q. To whom and with what sentiment do you want to pass on your most precious possession?"
  ];

  static const Map<String, String> koTemplates = {
    "Q. 사랑하는 이들에게 평소 말하지 못했던, 가슴속 깊이 묻어둔 고마운 기억은 무엇인가요?":
        "가장 힘들고 지쳤던 밤, 묵묵히 내 어깨를 토닥여주던 당신의 그 따스한 손길이 기억납니다. 늘 곁에 있어줘서 참 고마웠습니다.",
    "Q. 내가 떠난 후, 남겨진 사람들이 나를 기억할 때 떠올려 주었으면 하는 모습이 있나요?":
        "기억할 때 슬퍼하기보다는, 늘 활짝 웃으며 긍정적인 에너지를 건네던 사람으로 웃으며 추억해 주었으면 좋겠습니다.",
    "Q. 인생의 마지막 여정에서 가장 아름다웠던 한 순간을 고른다면 언제인가요?":
        "눈이 부시도록 맑은 날, 우리 가족이 함께 떠나 마음껏 웃고 떠들었던 소소한 여행길이 내 삶의 가장 찬란한 봄날이었습니다.",
    "Q. 지금 당장 내일 떠난다면, 가장 미안해서 마음 한구석이 아련해지는 사람은 누구인가요?":
        "내가 조금 더 다정하게 안아주고 더 많은 시간을 함께 보내지 못했던 우리 아이에게 미안한 마음이 아스라이 밀려옵니다.",
    "Q. 남겨진 소중한 이들에게 남기는 마지막 조언이나 응원의 한마디는 무엇인가요?":
        "인생의 거친 파도가 닥쳐도, 서로의 손을 꼭 쥐고 한 걸음씩 걸어 나간다면 반드시 따스한 햇살이 비칠 것입니다. 용기를 잃지 마세요.",
    "Q. 인생을 돌아보며 나 스스로에게 가장 칭찬해주고 싶은 나의 자랑스러운 선택은 무엇인가요?":
        "수많은 고난과 역경 속에서도, 타인을 배려하고 나 자신을 지키며 정직하게 삶의 길을 묵묵히 걸어온 선택이 참 자랑스럽습니다.",
    "Q. 나의 소중한 물건이나 유품을 누구에게 어떤 마음으로 전하고 싶나요?":
        "내가 항상 소중하게 지니고 다니며 일기를 적던 오래된 가죽 다이어리를 내 절친한 친구에게 전해 따뜻했던 추억의 한 조각으로 나누고 싶습니다."
  };

  static const Map<String, String> enTemplates = {
    "Q. What is a deeply cherished memory with your loved ones that you never expressed before?":
        "I remember your warm hands gently patting my shoulder on the most exhausting night. Thank you so much for always staying by my side.",
    "Q. What image of yourself do you want people to remember and hold onto after you depart?":
        "Rather than grieving, I hope people remember me with a bright smile, thinking of me as someone who always shared positive energy.",
    "Q. If you had to choose the most beautiful single moment of your life journey, when would it be?":
        "The simple family trip we took under the dazzlingly clear sky, laughing and talking freely, was the most brilliant spring day of my life.",
    "Q. If you had to depart tomorrow, who is the person you feel most apologetic towards in your heart?":
        "A faint wave of apology sweeps over my heart for my child, whom I wish I had hugged more tenderly and spent more time with.",
    "Q. What is your final word of advice or encouragement to those you leave behind?":
        "Even when rough waves of life hit you, if you hold each other's hands tight and walk step by step, warm sunlight will surely shine. Do not lose courage.",
    "Q. Looking back on your life, what is the proudest choice you would most praise yourself for?":
        "I am truly proud of my choice to walk honestly and silently through life's path, caring for others and staying true to myself through all adversities.",
    "Q. To whom and with what sentiment do you want to pass on your most precious possession?":
        "I want to pass on my old leather diary, which I always kept close to write my thoughts, to my dearest friend as a warm piece of our memories."
  };

  static List<String> getQuestions(LanguageLocale locale) {
    return locale == LanguageLocale.en ? enQuestions : koQuestions;
  }

  static String getTemplate(LanguageLocale locale, String question) {
    if (locale == LanguageLocale.en) {
      return enTemplates[question] ?? "";
    }
    return koTemplates[question] ?? "";
  }
}

class LanguageNotifier extends StateNotifier<LanguageLocale> {
  LanguageNotifier() : super(LanguageLocale.ko);

  void toggleLanguage() {
    state = state == LanguageLocale.ko ? LanguageLocale.en : LanguageLocale.ko;
  }

  void setLanguage(LanguageLocale locale) {
    state = locale;
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageLocale>((ref) {
  return LanguageNotifier();
});
