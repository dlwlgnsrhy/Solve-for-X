/// Motivational quotes categorized by life progress percentage and time of day.
class LifeQuotes {
  const LifeQuotes._();

  /// Returns a motivational quote based on life progress (0.0 - 1.0).
  static String getQuote(double progress) {
    if (progress < 0.15) {
      return '인생은 이제 막 시작되었습니다. 무한한 가능성이 당신을 기다립니다.';
    } else if (progress < 0.30) {
      return '젊음의 에너지로 꿈을 향해 나아가세요. 지금이 최고의 때입니다.';
    } else if (progress < 0.45) {
      return '인생의 정점에 가까워지고 있습니다. 이 순간을 소중히 여기세요.';
    } else if (progress < 0.60) {
      return '축적된 경험이 당신의 지혜가 되고 있습니다. 더 깊게, 더 넓게.';
    } else if (progress < 0.75) {
      return '인생의 가을, 풍성한 수확의 시기입니다. 주변과 나누세요.';
    } else if (progress < 0.90) {
      return '지혜로운 황혼이 아름답습니다. 당신의 이야기가 다음 세대에게 이어집니다.';
    } else {
      return '인생의 마지막 여정도 빛납니다. 사랑으로 채우세요.';
    }
  }

  /// Returns a motivational quote that changes based on time of day.
  static String getTimeBasedQuote() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      // Morning
      const morningQuotes = [
        '새로운 아침, 새로운 시작. 오늘도 소중한 하루를 만드세요.',
        '아침 햇살처럼 따뜻하게, 오늘을 맞이하세요.',
        '일어나서 숨을 쉴 수 있는 것만으로도 축복입니다.',
        '오늘은 당신의 것이니까, 의미 있게 채우세요.',
      ];
      return morningQuotes[DateTime.now().day % morningQuotes.length];
    } else if (hour >= 12 && hour < 17) {
      // Afternoon
      const afternoonQuotes = [
        '오후의 햇살 아래, 현재를 즐겨보세요.',
        '점심시간, 잠시 멈추고 자신을 돌아보세요.',
        '낮이 깊어질수록 하루의 의미가 선명해집니다.',
        '오늘 하루, 무엇을 이루셨나요?',
      ];
      return afternoonQuotes[DateTime.now().day % afternoonQuotes.length];
    } else if (hour >= 17 && hour < 21) {
      // Evening
      const eveningQuotes = [
        '해질녘의 아름다움처럼, 하루의 끝도 의미 있습니다.',
        '오늘 하루도 고생 많으셨습니다.',
        '저녁 하늘을 보며 감사함을 느껴보세요.',
        '한 주가 끝나갈 때, 당신의 성장을 돌아보세요.',
      ];
      return eveningQuotes[DateTime.now().day % eveningQuotes.length];
    } else {
      // Night
      const nightQuotes = [
        '별이 빛나는 밤, 당신의 인생도 그처럼 빛납니다.',
        '오늘 하루도 의미 있게 보냈음을 기억하세요.',
        '아침은 다시 옵니다. 오늘도 잘 지내셨어요.',
        '하루의 끝이 또 다른 시작의 신호입니다.',
      ];
      return nightQuotes[DateTime.now().day % nightQuotes.length];
    }
  }

  /// Returns the time-of-day label (아침/오후/저녁/밤).
  static String getTimeOfDayLabel() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '☀️ 아침';
    if (hour >= 12 && hour < 17) return '🌤️ 오후';
    if (hour >= 17 && hour < 21) return '🌅 저녁';
    return '🌙 밤';
  }

  /// Returns a short caption suitable for sharing.
  static String getShareCaption(double progress) {
    if (progress < 0.15) {
      return '인생은 이제 막 시작되었습니다 ✨';
    } else if (progress < 0.30) {
      return '젊음의 에너지로 꿈을 향해 🚀';
    } else if (progress < 0.45) {
      return '인생의 정점을 향해, 지금이 최선 💫';
    } else if (progress < 0.60) {
      return '축적된 경험, 당신의 지혜 🌟';
    } else if (progress < 0.75) {
      return '인생의 가을, 풍성한 수확 🌾';
    } else if (progress < 0.90) {
      return '지혜로운 황혼, 아름다움 그 자체 🌅';
    } else {
      return '인생의 마지막 여정도 빛납니다 🕊️';
    }
  }
}
